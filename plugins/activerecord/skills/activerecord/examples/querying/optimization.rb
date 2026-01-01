# Query Optimization Examples
# Demonstrates pluck, calculations, select, and memory-efficient patterns

# ============================================
# pluck vs map - Value Extraction
# ============================================

# BAD - loads full User objects into memory
emails = User.all.map(&:email)
# 1. Instantiates every User object
# 2. Allocates memory for all attributes
# 3. Then extracts just email

# GOOD - only fetches email column from database
emails = User.pluck(:email)
# SELECT email FROM users
# Returns Array of strings directly

# Multiple columns - returns array of arrays
User.pluck(:id, :email)
# => [[1, "a@example.com"], [2, "b@example.com"]]

# With conditions
User.where(active: true).pluck(:email)

# ============================================
# pluck Caveats
# ============================================

# pluck returns Array, not Relation - cannot chain after
User.pluck(:email).where(active: true)  # NoMethodError!

# pluck ignores select
User.select(:id).pluck(:email)  # Still plucks email

# pluck with association requires join
Post.joins(:author).pluck("authors.name")
# SELECT authors.name FROM posts INNER JOIN authors...

# ============================================
# ids - Shortcut for Primary Keys
# ============================================

# These are equivalent
User.pluck(:id)
User.ids

# With conditions
User.active.ids
# SELECT id FROM users WHERE active = true

# ============================================
# pick - Single Value
# ============================================

# Get first matching value (Rails 6+)
User.where(admin: true).pick(:email)
# Equivalent to: User.where(admin: true).limit(1).pluck(:email).first

# Multiple columns
User.pick(:id, :email)
# => [1, "admin@example.com"]

# ============================================
# Calculations - Database-Level Math
# ============================================

# count
User.count                        # COUNT(*)
User.count(:email)                # COUNT(email) - excludes NULL
User.distinct.count(:role)        # COUNT(DISTINCT role)

# sum, average, minimum, maximum
Order.sum(:total)
Order.average(:total)
User.minimum(:created_at)
User.maximum(:login_count)

# With conditions
Order.where(status: "completed").sum(:total)
User.active.average(:age)

# ============================================
# Grouped Calculations
# ============================================

# Group by single column
Order.group(:status).count
# => {"pending" => 10, "shipped" => 25, "delivered" => 50}

Order.group(:status).sum(:total)
# => {"pending" => 1000, "shipped" => 5000, "delivered" => 10000}

# Group by multiple columns
User.group(:role, :status).count
# => {["admin", "active"] => 5, ["user", "active"] => 100, ...}

# Group by date
Order.group("DATE(created_at)").count
# Daily order counts

Order.group("DATE_TRUNC('month', created_at)").sum(:total)
# Monthly revenue (PostgreSQL)

# ============================================
# select - Limit Loaded Columns
# ============================================

# Only load needed columns - reduces memory
users = User.select(:id, :name, :email)

# WARNING: Accessing non-selected columns raises error
users.first.password_digest
# => ActiveModel::MissingAttributeError

# Select with alias
User.select("name, email, created_at AS signup_date")

# Select with calculation
User.select("*, (SELECT COUNT(*) FROM posts WHERE user_id = users.id) AS posts_count")

# ============================================
# exists? vs any? vs count
# ============================================

# exists? - most efficient for checking presence
User.where(email: "test@example.com").exists?
# SELECT 1 FROM users WHERE email = '...' LIMIT 1

# any? - also efficient, slightly different semantics
User.active.any?
# SELECT 1 FROM users WHERE active = true LIMIT 1

# count - returns number, less efficient for just checking
User.active.count > 0  # Less efficient than any?

# BAD - loads all records
User.active.to_a.any?  # Loads everything!
User.active.length > 0  # Also loads everything!

# ============================================
# size vs count vs length
# ============================================

users = User.where(active: true)

# count - always hits database
users.count  # SELECT COUNT(*) FROM users WHERE active = true

# size - smart: uses count if not loaded, length if loaded
users.size   # COUNT(*) if not loaded
users.to_a
users.size   # Uses array length (no query)

# length - always loads all records first
users.length  # SELECT * FROM users..., then .length on array

# Rule: Use size unless you specifically need count or length behavior

# ============================================
# Anti-Patterns and Fixes
# ============================================

# Anti-pattern 1: Ruby filtering instead of SQL
# BAD
User.all.select { |u| u.active? }
# GOOD
User.where(active: true)

# Anti-pattern 2: map instead of pluck
# BAD
User.all.map(&:email)
# GOOD
User.pluck(:email)

# Anti-pattern 3: each with update
# BAD - N queries
User.where(old: true).each { |u| u.update(archived: true) }
# GOOD - 1 query
User.where(old: true).update_all(archived: true)

# Anti-pattern 4: Loading for count
# BAD
User.all.length
User.all.size  # If records not yet loaded, ok; if force loading, bad
# GOOD
User.count

# Anti-pattern 5: exists check with count
# BAD
User.where(email: "test@example.com").count > 0
# GOOD
User.where(email: "test@example.com").exists?

# ============================================
# Practical Optimization Examples
# ============================================

# Example 1: Dashboard statistics (efficient)
def dashboard_stats
  {
    total_users: User.count,
    active_users: User.active.count,
    new_today: User.where("created_at >= ?", Date.current).count,
    orders_by_status: Order.group(:status).count,
    monthly_revenue: Order.completed.this_month.sum(:total)
  }
end

# Example 2: Dropdown options (efficient)
def category_options
  # Instead of Category.all.map { |c| [c.name, c.id] }
  Category.order(:name).pluck(:name, :id)
end

# Example 3: Bulk presence check
def users_exist?(emails)
  existing = User.where(email: emails).pluck(:email)
  emails.map { |e| existing.include?(e) }
end

# Example 4: Memory-efficient iteration with select
User.select(:id, :email).find_each do |user|
  # Only id and email loaded, saves memory
  SomeService.process(user.id, user.email)
end

# Example 5: Conditional eager loading
def load_posts(include_comments:)
  posts = Post.includes(:author)
  posts = posts.includes(:comments) if include_comments
  posts
end

# ============================================
# EXPLAIN for Query Analysis
# ============================================

# See query execution plan
User.where(email: "test@example.com").explain
# EXPLAIN SELECT * FROM users WHERE email = '...'

# PostgreSQL specific
User.where(email: "test@example.com").explain(:analyze)
# EXPLAIN ANALYZE SELECT * FROM users WHERE email = '...'

# Check if index is used
# Look for "Index Scan" vs "Seq Scan" in output

# ============================================
# Raw SQL When Needed
# ============================================

# Complex queries with find_by_sql
User.find_by_sql([
  "SELECT users.*, COUNT(posts.id) as post_count
   FROM users
   LEFT JOIN posts ON posts.user_id = users.id
   WHERE users.active = ?
   GROUP BY users.id
   HAVING COUNT(posts.id) > ?",
  true, 5
])

# Pure SQL execution
result = ActiveRecord::Base.connection.execute(
  "SELECT DATE(created_at), COUNT(*) FROM users GROUP BY 1"
)
result.to_a  # Array of hashes

# Using Arel for complex conditions
users = User.arel_table
User.where(
  users[:age].gt(18).and(users[:age].lt(65))
)
