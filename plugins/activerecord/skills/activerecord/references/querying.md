# ActiveRecord Query Interface Reference

## Finder Methods

### find - Retrieve by Primary Key

Raises `RecordNotFound` if not found. Use when record must exist.

```ruby
User.find(1)                      # Single record
User.find([1, 2, 3])              # Array of records
User.find(1, 2, 3)                # Same as above
```

**SQL Generated:**
```sql
SELECT * FROM users WHERE id = 1
SELECT * FROM users WHERE id IN (1, 2, 3)
```

### find_by - Retrieve First Match

Returns `nil` if not found. Use when absence is acceptable.

```ruby
User.find_by(email: "test@example.com")
User.find_by(email: "test@example.com", active: true)
User.find_by("email LIKE ?", "%@example.com")
```

**find_by!** - Raises `RecordNotFound` if not found.

### where - Build Conditions

Returns a `Relation` (chainable, lazy). Does NOT execute until needed.

```ruby
# Hash conditions (safest, auto-escaped)
User.where(active: true)
User.where(role: ["admin", "moderator"])  # IN clause
User.where(age: 18..65)                   # BETWEEN
User.where(deleted_at: nil)               # IS NULL

# String conditions (use placeholders!)
User.where("age > ?", 18)
User.where("name LIKE ?", "%#{User.sanitize_sql_like(query)}%")

# Named placeholders
User.where("created_at > :date", date: 1.week.ago)
```

**where.not - Negation:**
```ruby
User.where.not(role: "admin")
User.where.not(deleted_at: nil)           # IS NOT NULL
User.where.not(status: ["banned", "suspended"])  # NOT IN
```

**where.associated / where.missing (Rails 7+):**
```ruby
Post.where.associated(:author)            # Has author
Post.where.missing(:comments)             # No comments
```

### find_or_create_by / find_or_initialize_by

```ruby
# Finds or creates (saves to DB)
User.find_or_create_by(email: "test@example.com") do |user|
  user.name = "New User"  # Only for new records
end

# Finds or builds (doesn't save)
User.find_or_initialize_by(email: "test@example.com")
```

**Race Condition Warning:** `find_or_create_by` can fail with `RecordNotUnique` under concurrent access. Use database constraints and rescue:

```ruby
begin
  User.find_or_create_by(email:)
rescue ActiveRecord::RecordNotUnique
  retry
end
```

---

## Eager Loading

### The N+1 Problem

```ruby
# BAD - N+1 queries
posts = Post.limit(10)
posts.each { |post| puts post.author.name }  # 1 + 10 queries!

# GOOD - Eager loading
posts = Post.includes(:author).limit(10)
posts.each { |post| puts post.author.name }  # 2 queries
```

### Eager Loading Methods Comparison

| Method | Strategy | Queries | Best For |
|--------|----------|---------|----------|
| `includes` | Auto-choose | 2+ separate OR 1 JOIN | Default choice |
| `preload` | Separate queries | Always 2+ | Large datasets, no filtering |
| `eager_load` | LEFT OUTER JOIN | Always 1 | Filtering/sorting by association |
| `joins` | INNER JOIN | 1 (no loading) | Filtering only |

### includes - Smart Default

Rails decides between `preload` and `eager_load` based on usage.

```ruby
# Separate queries (preload strategy)
User.includes(:posts)
# SELECT * FROM users
# SELECT * FROM posts WHERE user_id IN (1,2,3,4,5)

# Single JOIN (eager_load strategy) - when filtering
User.includes(:posts).where(posts: { published: true })
# SELECT users.*, posts.* FROM users
#   LEFT OUTER JOIN posts ON posts.user_id = users.id
#   WHERE posts.published = true
```

**references Required for String Conditions:**
```ruby
# ERROR - Rails doesn't know to JOIN
User.includes(:posts).where("posts.created_at > ?", 1.week.ago)

# CORRECT - explicitly reference
User.includes(:posts).where("posts.created_at > ?", 1.week.ago).references(:posts)
```

### preload - Always Separate Queries

Forces separate queries regardless of conditions. Cannot filter by association.

```ruby
User.preload(:posts, :comments)
# SELECT * FROM users
# SELECT * FROM posts WHERE user_id IN (...)
# SELECT * FROM comments WHERE user_id IN (...)
```

**Use When:**
- Large datasets (JOINs create cartesian explosion)
- Not filtering by associated data
- Want predictable query count

### eager_load - Always JOIN

Forces single LEFT OUTER JOIN query.

```ruby
User.eager_load(:posts)
# SELECT users.*, posts.* FROM users
#   LEFT OUTER JOIN posts ON posts.user_id = users.id
```

**Use When:**
- Filtering by association attributes
- Sorting by association attributes
- Need to include records without associations (LEFT join)

### joins - Filtering Without Loading

Creates INNER JOIN but does NOT load associated records.

```ruby
User.joins(:posts).where(posts: { published: true }).distinct
# SELECT DISTINCT users.* FROM users
#   INNER JOIN posts ON posts.user_id = users.id
#   WHERE posts.published = true

# Accessing association still causes N+1!
User.joins(:posts).each { |u| u.posts }  # N+1!
```

**Use When:**
- Only need to filter, not access associated data
- Combined with `includes` for filtering + loading

### left_outer_joins - Include Without Association

Like `joins` but uses LEFT OUTER JOIN.

```ruby
User.left_outer_joins(:posts).where(posts: { id: nil })
# Users without any posts
```

### Eager Loading Decision Tree

```
Need to access associated data?
├── NO → Use `joins` (filtering only)
└── YES → Need to filter/sort by association?
          ├── NO → Use `preload` (separate queries)
          └── YES → Large dataset with many associations?
                    ├── YES → Use `includes` with `references`
                    └── NO → Use `eager_load` (single JOIN)
```

### Nested Eager Loading

```ruby
User.includes(:posts)                           # One level
User.includes(posts: :comments)                 # Nested
User.includes(posts: [:comments, :tags])        # Multiple nested
User.includes(posts: { comments: :author })     # Deep nesting
```

---

## Scopes

### Named Scopes

```ruby
class Article < ApplicationRecord
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_author, ->(author) { where(author:) }
  scope :created_after, ->(date) { where("created_at > ?", date) }
end

# Usage - chainable
Article.published.recent.by_author(user)
```

### Scope vs Class Method

Both are equivalent, but scopes guarantee a Relation return:

```ruby
# Scope - always returns Relation (even if nil condition)
scope :active, -> { where(active: true) if some_condition }
# Returns all records if condition is false

# Class method - can return nil
def self.active
  where(active: true) if some_condition
end
# Returns nil if condition is false - breaks chaining!
```

**Recommendation:** Use scopes for simple queries, class methods for complex logic.

### default_scope - Use With Extreme Caution

**Anti-Pattern Warning:** `default_scope` causes many subtle issues:

```ruby
class Article < ApplicationRecord
  default_scope { where(published: true) }
end

# Problems:
Article.new.published     # => true (affects new records!)
Article.create            # => published: true by default
Article.all               # Always filtered
Article.unscoped.all      # Must remember to unscope

# Joins become problematic
User.joins(:articles)     # Silently filters articles
```

**Better Alternatives:**

```ruby
# 1. Explicit scope
scope :published, -> { where(published: true) }
scope :visible, -> { published }  # Semantic alias

# 2. Query object
class PublishedArticles
  def self.call
    Article.where(published: true)
  end
end
```

### Scope Merging

```ruby
class Author < ApplicationRecord
  has_many :posts
  scope :active, -> { where(active: true) }
end

class Post < ApplicationRecord
  belongs_to :author
  scope :published, -> { where(published: true) }
end

# Merge scopes from different models
Post.published.joins(:author).merge(Author.active)
```

---

## Calculations

### count, sum, average, minimum, maximum

```ruby
User.count                        # COUNT(*)
User.count(:age)                  # COUNT(age) - excludes NULL
User.distinct.count(:role)        # COUNT(DISTINCT role)

User.sum(:balance)                # SUM(balance)
User.average(:age)                # AVG(age)
User.minimum(:created_at)         # MIN(created_at)
User.maximum(:score)              # MAX(score)
```

### Grouped Calculations

```ruby
Order.group(:status).count
# => {"pending" => 5, "shipped" => 10, "delivered" => 8}

User.group(:role, :status).count
# => {["admin", "active"] => 2, ["user", "active"] => 50, ...}
```

### pluck - Efficient Value Extraction

**Use `pluck` instead of `map` for database values:**

```ruby
# BAD - loads full records into memory
User.all.map(&:email)

# GOOD - only fetches needed columns
User.pluck(:email)
# SELECT email FROM users
# => ["a@example.com", "b@example.com", ...]

# Multiple columns
User.pluck(:id, :email)
# => [[1, "a@example.com"], [2, "b@example.com"]]
```

**Key Points:**
- Returns Array, not Relation (not chainable after)
- Ignores any `.select()` - uses only pluck columns
- Type-casts values appropriately

### ids - Shortcut for Primary Keys

```ruby
User.ids                          # Equivalent to User.pluck(:id)
User.where(active: true).ids
```

### pick - Single Value

```ruby
User.where(id: 1).pick(:name)     # First value only
# Equivalent to: User.where(id: 1).limit(1).pluck(:name).first
```

---

## Batch Processing

### When to Use Batch Processing

```ruby
# BAD - loads all records into memory
User.all.each { |user| user.some_operation }

# GOOD - processes in batches
User.find_each { |user| user.some_operation }
```

### find_each - Individual Records

Yields one record at a time, loads in batches of 1000.

```ruby
User.find_each do |user|
  NewsMailer.weekly_digest(user).deliver_later
end

# With options
User.find_each(batch_size: 500, start: 1000, finish: 5000) do |user|
  # Process users with id 1000-5000 in batches of 500
end
```

### find_in_batches - Batches of Records

Yields arrays of records.

```ruby
User.find_in_batches(batch_size: 100) do |users|
  # users is an Array of 100 User objects
  ExternalApi.bulk_sync(users)
end
```

### in_batches - Batches as Relations

Yields `ActiveRecord::Relation` objects. Best for bulk operations.

```ruby
# Bulk update
User.where(status: "inactive").in_batches.update_all(archived: true)

# Bulk delete with throttling
User.where("created_at < ?", 1.year.ago).in_batches do |batch|
  batch.delete_all
  sleep(0.1)  # Throttle to reduce DB load
end
```

### Batch Processing Comparison

| Method | Yields | Returns | Best For |
|--------|--------|---------|----------|
| `find_each` | Single record | nil | Individual processing |
| `find_in_batches` | Array of records | nil | Batch operations on loaded records |
| `in_batches` | Relation | BatchEnumerator | Bulk SQL operations |

### Batch Processing Caveats

**Ordering is Ignored:**
```ruby
User.order(:name).find_each { |u| }
# WARNING: Scoped order is ignored
# Always ordered by primary key
```

**Cursor Column (Rails 7.1+):**
```ruby
# Custom cursor column
User.find_each(cursor: [:created_at, :id]) { |u| }
```

**Race Conditions:**
Batch processing is subject to race conditions if records are modified during iteration.

---

## Query Optimization

### select - Limit Columns

```ruby
# Only fetch needed columns
User.select(:id, :name, :email)

# Warning: accessing non-selected columns raises error
User.select(:id).first.email
# => ActiveModel::MissingAttributeError
```

### distinct - Remove Duplicates

```ruby
User.joins(:posts).distinct
# SELECT DISTINCT users.* FROM users INNER JOIN posts...
```

### limit and offset

```ruby
User.limit(10)                    # First 10
User.limit(10).offset(20)         # Records 21-30
```

### order

```ruby
User.order(:created_at)           # ASC by default
User.order(created_at: :desc)
User.order(:role, created_at: :desc)  # Multiple

# Prevent SQL injection - use symbols or Arel
User.order(Arel.sql("FIELD(status, 'active', 'pending', 'inactive')"))
```

### reorder - Replace Existing Order

```ruby
User.order(:name).reorder(:created_at)  # Only ordered by created_at
```

### unscope - Remove Specific Clauses

```ruby
User.where(active: true).order(:name).unscope(:order)
User.where(active: true).unscope(where: :active)
```

---

## exists?, any?, none?, one?, many?

```ruby
User.exists?(1)                   # By ID
User.exists?(email: "test@example.com")  # By conditions
User.where(active: true).exists?  # From relation

# Comparison
User.any?                         # true if count > 0
User.none?                        # true if count == 0
User.one?                         # true if count == 1
User.many?                        # true if count > 1
```

**Performance:** `exists?` is optimized - uses `SELECT 1 ... LIMIT 1`.

---

## strict_loading - Prevent N+1

```ruby
# Relation level
User.strict_loading.first.posts
# => ActiveRecord::StrictLoadingViolationError

# Model level
class User < ApplicationRecord
  self.strict_loading_by_default = true
end

# Association level
has_many :posts, strict_loading: true
```

---

## Anti-Patterns

### 1. N+1 Queries

```ruby
# BAD
Post.all.each { |p| p.author.name }

# GOOD
Post.includes(:author).each { |p| p.author.name }
```

### 2. Loading All Records for Count

```ruby
# BAD - loads all records
User.all.length
User.all.size  # Also loads if not already loaded

# GOOD - SQL COUNT
User.count
```

### 3. Using select{} Instead of where

```ruby
# BAD - loads all, filters in Ruby
User.all.select { |u| u.active? }

# GOOD - filters in database
User.where(active: true)
```

### 4. map Instead of pluck

```ruby
# BAD - instantiates all User objects
User.all.map(&:email)

# GOOD - only fetches email column
User.pluck(:email)
```

### 5. each for Bulk Operations

```ruby
# BAD - N queries
User.where(old: true).each { |u| u.update(archived: true) }

# GOOD - single query
User.where(old: true).update_all(archived: true)
```

### 6. Not Using Indexes

```ruby
# If you query by email often, add index:
add_index :users, :email

# Composite queries need composite indexes:
add_index :orders, [:user_id, :status]
```

### 7. default_scope

See Scopes section above. Almost always an anti-pattern.

### 8. Ignoring Query Cache

ActiveRecord caches identical queries within a request. Don't defeat it:

```ruby
# BAD - 2 queries
User.find(1)
User.find(1)  # Cache miss if called in different code paths

# Be aware of skip_query_cache! in batch processing
```

---

## Raw SQL When Needed

### Using Arel

```ruby
users = User.arel_table
User.where(users[:age].gt(18).and(users[:age].lt(65)))
```

### find_by_sql

```ruby
User.find_by_sql(["SELECT * FROM users WHERE age > ?", 18])
```

### execute for Non-AR Queries

```ruby
ActiveRecord::Base.connection.execute("SELECT 1")
```

### EXPLAIN for Analysis

```ruby
User.where(active: true).explain
# EXPLAIN SELECT * FROM users WHERE active = true
```

---

## See Also

- `examples/querying/` - Working code examples
- `references/associations.md` - Eager loading with associations
- `references/migrations.md` - Index strategies
