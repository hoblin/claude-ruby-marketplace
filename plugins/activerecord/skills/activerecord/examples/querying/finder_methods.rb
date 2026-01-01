# Finder Methods Examples
# Demonstrates find, find_by, where, and find_or_create_by

# ============================================
# Sample Models for Examples
# ============================================

class User < ApplicationRecord
  has_many :posts
  has_many :orders

  scope :active, -> { where(active: true) }
  scope :admins, -> { where(role: "admin") }
end

# ============================================
# find - Retrieve by Primary Key
# ============================================

# Single record - raises RecordNotFound if not found
user = User.find(1)
# SELECT * FROM users WHERE id = 1

# Multiple records - returns array, raises if ANY not found
users = User.find([1, 2, 3])
users = User.find(1, 2, 3)  # Same result
# SELECT * FROM users WHERE id IN (1, 2, 3)

# Use when record MUST exist (will crash otherwise)
def show
  @user = User.find(params[:id])  # 404 if not found
end

# ============================================
# find_by - Retrieve First Match
# ============================================

# Returns nil if not found
user = User.find_by(email: "test@example.com")
# SELECT * FROM users WHERE email = 'test@example.com' LIMIT 1

# Multiple conditions
user = User.find_by(email: "test@example.com", active: true)

# With string conditions (use placeholders!)
user = User.find_by("email LIKE ?", "%@company.com")

# find_by! raises RecordNotFound
user = User.find_by!(email: "test@example.com")

# Use when absence is acceptable
def authenticate(email, password)
  user = User.find_by(email:)
  return nil unless user
  user if user.authenticate(password)
end

# ============================================
# where - Build Conditions (Returns Relation)
# ============================================

# Hash conditions - safest, auto-escaped
User.where(active: true)
User.where(role: ["admin", "moderator"])  # IN clause
User.where(age: 18..65)                   # BETWEEN
User.where(deleted_at: nil)               # IS NULL

# Chaining - lazy evaluation
users = User.where(active: true)
            .where(role: "admin")
            .order(created_at: :desc)
# Query not executed until iteration

# String conditions - ALWAYS use placeholders
User.where("age > ?", 18)
User.where("name LIKE ?", "%#{User.sanitize_sql_like(query)}%")
User.where("created_at > :date", date: 1.week.ago)

# DANGER - SQL injection!
# User.where("name = '#{params[:name]}'")  # NEVER do this!

# ============================================
# where.not - Negation
# ============================================

User.where.not(role: "admin")
# WHERE role != 'admin'

User.where.not(deleted_at: nil)
# WHERE deleted_at IS NOT NULL

User.where.not(status: ["banned", "suspended"])
# WHERE status NOT IN ('banned', 'suspended')

# ============================================
# where.associated / where.missing (Rails 7+)
# ============================================

# Users who have at least one post
User.where.associated(:posts)
# SELECT users.* FROM users
#   INNER JOIN posts ON posts.user_id = users.id

# Users with no posts
User.where.missing(:posts)
# SELECT users.* FROM users
#   LEFT OUTER JOIN posts ON posts.user_id = users.id
#   WHERE posts.id IS NULL

# ============================================
# find_or_create_by / find_or_initialize_by
# ============================================

# Finds existing or creates new record
user = User.find_or_create_by(email: "new@example.com") do |u|
  u.name = "New User"  # Only set for new records
  u.role = "member"
end

# Finds or builds (doesn't save)
user = User.find_or_initialize_by(email: "maybe@example.com")
user.new_record?  # true if not found, false if found
user.save if user.new_record?

# With scoped relation
admin = User.admins.find_or_create_by(email: "admin@example.com")

# ============================================
# Handling Race Conditions
# ============================================

# find_or_create_by can fail under concurrent access
# when two requests try to create the same unique record

# Solution 1: Rescue and retry
def find_or_create_user(email)
  User.find_or_create_by(email:)
rescue ActiveRecord::RecordNotUnique
  retry
end

# Solution 2: Use create_or_find_by (Rails 6+)
# Creates first, finds on unique constraint violation
User.create_or_find_by(email: "user@example.com")

# ============================================
# Practical Examples
# ============================================

# API controller filtering
class UsersController < ApplicationController
  def index
    @users = User.all

    @users = @users.where(role: params[:role]) if params[:role].present?
    @users = @users.where(active: true) if params[:active] == "true"
    @users = @users.where("created_at >= ?", params[:since]) if params[:since]

    @users = @users.order(params[:sort] || :created_at)
    @users = @users.limit(params[:limit] || 20)
  end
end

# Search with sanitization
def search_users(query)
  return User.none if query.blank?

  sanitized = User.sanitize_sql_like(query)
  User.where("name ILIKE :q OR email ILIKE :q", q: "%#{sanitized}%")
end
