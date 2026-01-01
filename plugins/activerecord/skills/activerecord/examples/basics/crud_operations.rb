# ActiveRecord CRUD Operations Examples

# =============================================================================
# CREATE
# =============================================================================

# Two-step creation
user = User.new
user.name = "Alice"
user.email = "alice@example.com"
if user.save
  puts "User created: #{user.id}"
else
  puts "Errors: #{user.errors.full_messages}"
end

# One-step creation
user = User.create(name: "Bob", email: "bob@example.com")
if user.persisted?
  puts "User created: #{user.id}"
end

# With block
user = User.create(email: "charlie@example.com") do |u|
  u.name = "Charlie"
  u.role = :admin
end

# Bang methods (raise on failure)
begin
  user = User.create!(name: "", email: "invalid")
rescue ActiveRecord::RecordInvalid => e
  puts "Validation failed: #{e.message}"
end

# Bulk insert (skips validations and callbacks)
User.insert_all([
  { name: "User 1", email: "user1@example.com", created_at: Time.current, updated_at: Time.current },
  { name: "User 2", email: "user2@example.com", created_at: Time.current, updated_at: Time.current }
])

# Upsert (insert or update on conflict)
User.upsert_all(
  [{ email: "alice@example.com", name: "Alice Updated" }],
  unique_by: :email
)

# =============================================================================
# READ
# =============================================================================

# find - raises RecordNotFound if not found
user = User.find(1)

# find with multiple IDs
users = User.find([1, 2, 3])  # Returns array, raises if ANY not found

# find_by - returns nil if not found
user = User.find_by(email: "alice@example.com")
user = User.find_by(status: :active, role: :admin)

# find_by! - raises if not found
user = User.find_by!(email: "nonexistent@example.com")

# where - returns Relation
users = User.where(active: true)
users = User.where("created_at > ?", 1.week.ago)
users = User.where(role: [:admin, :moderator])

# Chainable queries
users = User
  .where(active: true)
  .where.not(role: :guest)
  .order(created_at: :desc)
  .limit(10)

# First/last
user = User.first
user = User.last
user = User.order(:name).first(5)  # First 5 by name

# Take (no order guarantee, faster)
user = User.take
users = User.take(3)

# =============================================================================
# UPDATE
# =============================================================================

# Standard update (with validations and callbacks)
user = User.find(1)
user.update(name: "New Name")

# Update with bang (raises on failure)
user.update!(name: "New Name")

# Multiple attributes
user.update(
  name: "New Name",
  email: "newemail@example.com",
  settings: { theme: "dark" }
)

# Update attribute (skips validations, runs callbacks)
user.update_attribute(:verified, true)

# Update column (skips validations AND callbacks)
user.update_column(:login_count, user.login_count + 1)

# Update columns (multiple)
user.update_columns(
  login_count: user.login_count + 1,
  last_login_at: Time.current
)

# Conditional update
user.update(status: :premium) if user.eligible_for_premium?

# Bulk update (skips validations and callbacks)
User.where(status: :trial).update_all(status: :expired)
User.where("last_login_at < ?", 1.year.ago).update_all(active: false)

# Update with SQL expression
User.update_all("login_count = login_count + 1")

# =============================================================================
# DELETE / DESTROY
# =============================================================================

# Destroy (with callbacks and dependent associations)
user = User.find(1)
user.destroy
puts user.destroyed?  # => true
puts user.frozen?     # => true

# Delete (skip callbacks, orphans dependent records)
user = User.find(2)
user.delete

# Bulk destroy (with callbacks)
User.where(status: :banned).destroy_all

# Bulk delete (without callbacks)
User.where(status: :banned).delete_all

# Delete by ID
User.destroy(5)       # With callbacks
User.delete(5)        # Without callbacks

# =============================================================================
# FIND OR CREATE
# =============================================================================

# Find or create
user = User.find_or_create_by(email: "alice@example.com")

# With additional attributes via block
user = User.find_or_create_by(email: "alice@example.com") do |u|
  u.name = "Alice"
  u.role = :member
end

# Find or initialize (doesn't save)
user = User.find_or_initialize_by(email: "newuser@example.com")
user.name = "New User"
user.save if user.new_record?

# Create or find (handles race conditions - requires unique constraint)
user = User.create_or_find_by(email: "alice@example.com") do |u|
  u.name = "Alice"
end

# =============================================================================
# PRACTICAL PATTERNS
# =============================================================================

# Safe lookup with fallback
def find_user(id)
  User.find_by(id:) || User.new(name: "Guest")
end

# Idempotent create
def ensure_default_category
  Category.find_or_create_by!(name: "Uncategorized") do |c|
    c.slug = "uncategorized"
    c.position = 0
  end
end

# Soft delete pattern
class User < ApplicationRecord
  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  def soft_delete
    update(deleted_at: Time.current)
  end

  def restore
    update(deleted_at: nil)
  end
end

# Increment/decrement counters
user.increment!(:login_count)
user.decrement!(:credits)

# Toggle boolean
user.toggle!(:email_notifications)
