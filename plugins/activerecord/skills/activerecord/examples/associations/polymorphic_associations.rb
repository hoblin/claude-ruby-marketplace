# Polymorphic Association Examples
# Single association belonging to multiple model types

# ============================================
# Basic Polymorphic Association
# ============================================

# Picture can belong to Employee OR Product
#
# ┌──────────────┐       ┌──────────────┐       ┌──────────────┐
# │   Employee   │       │   Picture    │       │   Product    │
# ├──────────────┤       ├──────────────┤       ├──────────────┤
# │ id           │◄──┐   │ id           │   ┌──►│ id           │
# │ name         │   │   │ imageable_type│   │   │ name         │
# │              │   └───│ imageable_id │───┘   │              │
# └──────────────┘       └──────────────┘       └──────────────┘

class Picture < ApplicationRecord
  belongs_to :imageable, polymorphic: true
end

class Employee < ApplicationRecord
  has_many :pictures, as: :imageable, dependent: :destroy
end

class Product < ApplicationRecord
  has_many :pictures, as: :imageable, dependent: :destroy
end

# Migration
# create_table :pictures do |t|
#   t.string :name
#   t.belongs_to :imageable, polymorphic: true, index: true
#   t.timestamps
# end
# Creates: imageable_type (string), imageable_id (bigint)

# ============================================
# Real-World Example: Comments
# ============================================

class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :author, class_name: "User"

  validates :body, presence: true
end

class Post < ApplicationRecord
  has_many :comments, as: :commentable, dependent: :destroy
end

class Photo < ApplicationRecord
  has_many :comments, as: :commentable, dependent: :destroy
end

class Video < ApplicationRecord
  has_many :comments, as: :commentable, dependent: :destroy
end

# Usage
post = Post.find(1)
post.comments.create!(body: "Great post!", author: current_user)

comment = Comment.last
comment.commentable      # Returns Post, Photo, or Video
comment.commentable_type # "Post", "Photo", or "Video"

# ============================================
# Real-World Example: Attachments
# ============================================

class Attachment < ApplicationRecord
  belongs_to :attachable, polymorphic: true

  has_one_attached :file
  validates :file, presence: true
end

class Message < ApplicationRecord
  has_many :attachments, as: :attachable, dependent: :destroy
end

class Task < ApplicationRecord
  has_many :attachments, as: :attachable, dependent: :destroy
end

class Project < ApplicationRecord
  has_many :attachments, as: :attachable, dependent: :destroy
end

# ============================================
# Real-World Example: Tags (Many-to-Many Polymorphic)
# ============================================

class Tag < ApplicationRecord
  has_many :taggings, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end

class Tagging < ApplicationRecord
  belongs_to :tag
  belongs_to :taggable, polymorphic: true

  validates :tag_id, uniqueness: { scope: [:taggable_type, :taggable_id] }
end

class Article < ApplicationRecord
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings
end

class Question < ApplicationRecord
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings
end

# Usage
article = Article.find(1)
article.tags.create!(name: "ruby")
article.tags << Tag.find_by(name: "rails")

Tag.find_by(name: "ruby").taggings.map(&:taggable)  # All tagged items

# ============================================
# STI Compatibility
# ============================================

# When using polymorphic with STI, store base class

class Vehicle < ApplicationRecord
  # STI base class
end

class Car < Vehicle
end

class Truck < Vehicle
end

class Insurance < ApplicationRecord
  belongs_to :insurable, polymorphic: true

  # Store base class for STI compatibility
  def insurable_type=(class_name)
    super(class_name.constantize.base_class.to_s)
  end
end

# insurance.insurable_type stores "Vehicle" not "Car"

# ============================================
# Naming Conventions
# ============================================

# Use -able suffix when association is recipient
class Picture < ApplicationRecord
  belongs_to :imageable, polymorphic: true     # Good - picture receives image action
end

class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true   # Good - receives comments
end

# Use subject form when acting
class Article < ApplicationRecord
  belongs_to :author, polymorphic: true        # Good - author is acting
  # NOT: belongs_to :authorable, polymorphic: true
end

# ============================================
# Querying Polymorphic Associations
# ============================================

# Find all pictures for a specific type
Picture.where(imageable_type: "Employee")
Picture.where(imageable_type: "Product", imageable_id: 1)

# Eager loading - must use includes, NOT joins
Employee.includes(:pictures).each do |emp|
  emp.pictures.each { |pic| puts pic.name }
end

# Cannot use joins with polymorphic (no FK)
# Employee.joins(:pictures)  # Works
# Picture.joins(:imageable)  # Error! Can't join polymorphic

# ============================================
# Limitations and Alternatives
# ============================================

# Limitations:
# 1. No database foreign key constraints
# 2. Cannot join in queries (only includes)
# 3. Type column stores class names (affects renaming)
# 4. Performance can suffer at scale

# Alternative: Delegated Types (Rails 6.1+)
# For inheritance hierarchies, consider delegated_type instead

class Entry < ApplicationRecord
  delegated_type :entryable, types: %w[Message Comment]
end

class Message < ApplicationRecord
  has_one :entry, as: :entryable, touch: true
end

class Comment < ApplicationRecord
  has_one :entry, as: :entryable, touch: true
end

# Benefits of delegated_type:
# - Single table for shared attributes
# - Proper FK constraints possible
# - Better querying capabilities
