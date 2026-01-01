# Self-Referential Association Examples
# Model relates to itself for hierarchies and graphs

# ============================================
# Simple Hierarchy: Manager/Subordinates
# ============================================

class Employee < ApplicationRecord
  # Employee has one manager (who is also an Employee)
  belongs_to :manager,
             class_name: "Employee",
             optional: true,
             inverse_of: :subordinates

  # Employee has many subordinates (who are also Employees)
  has_many :subordinates,
           class_name: "Employee",
           foreign_key: "manager_id",
           dependent: :nullify,
           inverse_of: :manager

  validates :name, presence: true

  # Convenience methods
  def top_manager?
    manager.nil?
  end

  def direct_reports_count
    subordinates.count
  end
end

# Migration
# create_table :employees do |t|
#   t.string :name, null: false
#   t.belongs_to :manager, foreign_key: { to_table: :employees }
#   t.timestamps
# end

# Usage
ceo = Employee.create!(name: "CEO")
vp = Employee.create!(name: "VP Engineering", manager: ceo)
dev = Employee.create!(name: "Developer", manager: vp)

dev.manager          # => VP Engineering
vp.subordinates      # => [Developer]
ceo.subordinates     # => [VP Engineering]

# ============================================
# Friendship: Many-to-Many Self-Join
# ============================================

class User < ApplicationRecord
  has_many :friendships, dependent: :destroy
  has_many :friends, through: :friendships

  # Inverse friendships (where user is the friend)
  has_many :inverse_friendships,
           class_name: "Friendship",
           foreign_key: "friend_id",
           dependent: :destroy
  has_many :inverse_friends,
           through: :inverse_friendships,
           source: :user

  def all_friends
    friends + inverse_friends
  end

  def friend_with?(other_user)
    friends.include?(other_user) || inverse_friends.include?(other_user)
  end
end

class Friendship < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: "User"

  validates :user_id, uniqueness: { scope: :friend_id }
  validate :not_self_friend

  private

  def not_self_friend
    errors.add(:friend, "can't be yourself") if user_id == friend_id
  end
end

# Migration
# create_table :friendships do |t|
#   t.belongs_to :user, null: false, foreign_key: true
#   t.belongs_to :friend, null: false, foreign_key: { to_table: :users }
#   t.timestamps
# end
# add_index :friendships, [:user_id, :friend_id], unique: true

# Usage
alice = User.create!(name: "Alice")
bob = User.create!(name: "Bob")

Friendship.create!(user: alice, friend: bob)
alice.friends.include?(bob)     # => true
bob.inverse_friends.include?(alice)  # => true

# ============================================
# Bidirectional Friendship (Mutual)
# ============================================

class User < ApplicationRecord
  has_many :friendships, dependent: :destroy
  has_many :friends, through: :friendships

  def befriend(other_user)
    return if self == other_user
    return if friend_with?(other_user)

    # Create bidirectional friendship
    transaction do
      friendships.create!(friend: other_user)
      other_user.friendships.create!(friend: self)
    end
  end

  def unfriend(other_user)
    transaction do
      friendships.find_by(friend: other_user)&.destroy
      other_user.friendships.find_by(friend: self)&.destroy
    end
  end

  def friend_with?(other_user)
    friends.exists?(id: other_user.id)
  end
end

# ============================================
# Tree Structure: Parent/Children
# ============================================

class Category < ApplicationRecord
  belongs_to :parent,
             class_name: "Category",
             optional: true,
             inverse_of: :children,
             counter_cache: :children_count

  has_many :children,
           class_name: "Category",
           foreign_key: "parent_id",
           dependent: :destroy,
           inverse_of: :parent

  validates :name, presence: true

  scope :roots, -> { where(parent_id: nil) }
  scope :leaves, -> { where(children_count: 0) }

  def root?
    parent_id.nil?
  end

  def leaf?
    children.empty?
  end

  def ancestors
    node = self
    result = []
    while node.parent
      result << node.parent
      node = node.parent
    end
    result.reverse
  end

  def descendants
    children.flat_map { |c| [c] + c.descendants }
  end

  def depth
    ancestors.size
  end
end

# Migration
# create_table :categories do |t|
#   t.string :name, null: false
#   t.belongs_to :parent, foreign_key: { to_table: :categories }
#   t.integer :children_count, default: 0, null: false
#   t.timestamps
# end

# Usage
electronics = Category.create!(name: "Electronics")
phones = Category.create!(name: "Phones", parent: electronics)
smartphones = Category.create!(name: "Smartphones", parent: phones)

smartphones.ancestors  # => [Electronics, Phones]
electronics.descendants  # => [Phones, Smartphones]
Category.roots  # => [Electronics]

# ============================================
# Adjacency List with Recursive CTE
# ============================================

class Category < ApplicationRecord
  # ... same associations as above ...

  # PostgreSQL recursive query for full tree
  def self.tree_for(root_id)
    sql = <<~SQL
      WITH RECURSIVE category_tree AS (
        SELECT id, name, parent_id, 0 AS depth
        FROM categories
        WHERE id = :root_id
        UNION ALL
        SELECT c.id, c.name, c.parent_id, ct.depth + 1
        FROM categories c
        INNER JOIN category_tree ct ON c.parent_id = ct.id
      )
      SELECT * FROM category_tree ORDER BY depth, name
    SQL

    find_by_sql([sql, { root_id: }])
  end

  def full_path
    self.class.ancestors_for(id).pluck(:name).join(" > ")
  end

  def self.ancestors_for(category_id)
    sql = <<~SQL
      WITH RECURSIVE ancestors AS (
        SELECT id, name, parent_id, 0 AS depth
        FROM categories
        WHERE id = :category_id
        UNION ALL
        SELECT c.id, c.name, c.parent_id, a.depth + 1
        FROM categories c
        INNER JOIN ancestors a ON c.id = a.parent_id
      )
      SELECT * FROM ancestors ORDER BY depth DESC
    SQL

    find_by_sql([sql, { category_id: }])
  end
end

# ============================================
# Follower/Following Pattern
# ============================================

class User < ApplicationRecord
  # Users I follow
  has_many :active_follows,
           class_name: "Follow",
           foreign_key: "follower_id",
           dependent: :destroy
  has_many :following, through: :active_follows, source: :followed

  # Users who follow me
  has_many :passive_follows,
           class_name: "Follow",
           foreign_key: "followed_id",
           dependent: :destroy
  has_many :followers, through: :passive_follows, source: :follower

  def follow(other_user)
    following << other_user unless self == other_user
  end

  def unfollow(other_user)
    active_follows.find_by(followed: other_user)&.destroy
  end

  def following?(other_user)
    following.exists?(id: other_user.id)
  end
end

class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  validates :follower_id, uniqueness: { scope: :followed_id }
  validate :not_self_follow

  private

  def not_self_follow
    errors.add(:followed, "can't follow yourself") if follower_id == followed_id
  end
end

# Migration
# create_table :follows do |t|
#   t.belongs_to :follower, null: false, foreign_key: { to_table: :users }
#   t.belongs_to :followed, null: false, foreign_key: { to_table: :users }
#   t.timestamps
# end
# add_index :follows, [:follower_id, :followed_id], unique: true
