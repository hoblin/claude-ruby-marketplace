# Eager Loading Examples
# Demonstrates includes, preload, eager_load, joins and N+1 prevention

# ============================================
# Sample Models for Examples
# ============================================

class Author < ApplicationRecord
  has_many :posts
  has_many :comments, through: :posts
end

class Post < ApplicationRecord
  belongs_to :author
  has_many :comments
  has_many :tags, through: :taggings
  has_many :taggings
end

class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :user
end

# ============================================
# The N+1 Problem
# ============================================

# BAD - N+1 queries (1 query + N additional queries)
posts = Post.limit(10)
posts.each do |post|
  puts post.author.name  # Each iteration triggers a query!
end
# Query 1: SELECT * FROM posts LIMIT 10
# Query 2: SELECT * FROM authors WHERE id = 1
# Query 3: SELECT * FROM authors WHERE id = 2
# ... 10 more queries!

# GOOD - Eager loading (2 queries total)
posts = Post.includes(:author).limit(10)
posts.each do |post|
  puts post.author.name  # No additional queries!
end
# Query 1: SELECT * FROM posts LIMIT 10
# Query 2: SELECT * FROM authors WHERE id IN (1, 2, 3, ...)

# ============================================
# includes - Smart Default (Auto-chooses strategy)
# ============================================

# Separate queries (preload strategy) - when just accessing data
Post.includes(:author)
# SELECT * FROM posts
# SELECT * FROM authors WHERE id IN (1, 2, 3, ...)

# Single JOIN (eager_load strategy) - when filtering by association
Post.includes(:author).where(authors: { verified: true })
# SELECT posts.*, authors.*
#   FROM posts LEFT OUTER JOIN authors ON authors.id = posts.author_id
#   WHERE authors.verified = true

# Multiple associations
Post.includes(:author, :comments)
Post.includes(:author, comments: :user)  # Nested

# ============================================
# references - Required for String Conditions
# ============================================

# ERROR - Rails doesn't know to JOIN
Post.includes(:author).where("authors.created_at > ?", 1.week.ago)
# PG::UndefinedTable: ERROR: missing FROM-clause entry for table "authors"

# CORRECT - explicitly reference the table
Post.includes(:author)
    .where("authors.created_at > ?", 1.week.ago)
    .references(:authors)
# SELECT posts.*, authors.*
#   FROM posts LEFT OUTER JOIN authors ON ...
#   WHERE authors.created_at > '2024-01-23'

# Hash conditions auto-reference
Post.includes(:author).where(authors: { verified: true })  # Works!

# ============================================
# preload - Always Separate Queries
# ============================================

# Forces separate queries regardless of conditions
Author.preload(:posts, :comments)
# SELECT * FROM authors
# SELECT * FROM posts WHERE author_id IN (1, 2, 3)
# SELECT * FROM comments WHERE author_id IN (1, 2, 3)

# CANNOT filter by preloaded association
Author.preload(:posts).where(posts: { published: true })
# ERROR! posts is not in the FROM clause

# Use When:
# - Large datasets (JOINs cause row multiplication)
# - Not filtering by associated data
# - Want predictable query behavior

# Example: preload is better here
authors = Author.preload(:posts)  # 2 queries
# vs eager_load with 1000 posts per author = massive result set

# ============================================
# eager_load - Always LEFT OUTER JOIN
# ============================================

# Forces single query with LEFT OUTER JOIN
Author.eager_load(:posts)
# SELECT authors.*, posts.*
#   FROM authors
#   LEFT OUTER JOIN posts ON posts.author_id = authors.id

# Use When:
# - Filtering by association attributes
# - Sorting by association attributes
# - Need records even without associations (LEFT join includes NULLs)

# Example: authors sorted by latest post
Author.eager_load(:posts)
      .order("posts.created_at DESC NULLS LAST")
      .distinct

# ============================================
# joins - INNER JOIN (Filtering Only)
# ============================================

# Creates JOIN but does NOT load associated records
Author.joins(:posts).where(posts: { published: true }).distinct
# SELECT DISTINCT authors.*
#   FROM authors
#   INNER JOIN posts ON posts.author_id = authors.id
#   WHERE posts.published = true

# WARNING: Accessing association still causes N+1!
Author.joins(:posts).each do |author|
  author.posts  # N+1 query here!
end

# Use When:
# - Only need to filter, not access associated data
# - Combine with includes for filtering + loading

# Pattern: joins + includes together
Author.joins(:posts)
      .includes(:posts)
      .where(posts: { published: true })
      .distinct

# ============================================
# left_outer_joins - Include Records Without Association
# ============================================

# Authors including those without posts
Author.left_outer_joins(:posts)
      .select("authors.*, COUNT(posts.id) AS posts_count")
      .group("authors.id")

# Find authors with no posts
Author.left_outer_joins(:posts).where(posts: { id: nil })

# ============================================
# Nested Eager Loading
# ============================================

# One level
Post.includes(:author)

# Two levels
Post.includes(author: :profile)

# Multiple at same level
Post.includes(:author, :comments)

# Multiple nested
Post.includes(author: [:profile, :posts])

# Deep nesting
Post.includes(comments: { user: :profile })

# Mixed
Post.includes(:author, comments: { user: :profile }, tags: :category)

# ============================================
# Eager Loading Decision Tree (Applied)
# ============================================

# Scenario 1: Display posts with author names
# Need: Access author → Use includes
posts = Post.includes(:author).limit(20)
posts.each { |p| "#{p.title} by #{p.author.name}" }

# Scenario 2: Find posts by verified authors only
# Need: Filter by association → Use eager_load or includes with references
posts = Post.eager_load(:author).where(authors: { verified: true })

# Scenario 3: Count posts per author
# Need: Filter only, no data access → Use joins
Post.joins(:author)
    .group("authors.id")
    .count

# Scenario 4: Load authors with their many posts (large dataset)
# Need: Access data, large join explosion risk → Use preload
authors = Author.preload(:posts).limit(10)

# Scenario 5: Load posts with multiple associations
# Need: Mixed access patterns
Post.includes(:author)           # Always accessed
    .includes(:comments)         # Sometimes accessed
    .preload(:tags)              # Large count, rarely accessed

# ============================================
# Performance Comparison
# ============================================

# Setup: 100 posts, each with 1 author and 50 comments

# N+1 (worst)
Post.all.each { |p| p.author; p.comments.to_a }
# 1 + 100 + 100 = 201 queries

# includes (better)
Post.includes(:author, :comments).each { |p| p.author; p.comments.to_a }
# 3 queries (posts, authors, comments)

# eager_load with many comments (can be slow)
Post.eager_load(:author, :comments).each { |p| p.author; p.comments.to_a }
# 1 query, but returns 100 * 50 = 5000 rows!

# preload is safer for large associations
Post.preload(:author, :comments).each { |p| p.author; p.comments.to_a }
# 3 queries, 100 + 100 + 5000 rows loaded separately

# ============================================
# Strict Loading - Prevent N+1 at Runtime
# ============================================

# Relation level - raises if lazy loading attempted
posts = Post.strict_loading
posts.first.author  # ActiveRecord::StrictLoadingViolationError!

# Must eager load to access
posts = Post.strict_loading.includes(:author)
posts.first.author  # Works!

# Model level - all queries are strict
class Post < ApplicationRecord
  self.strict_loading_by_default = true
end

# Association level
class Author < ApplicationRecord
  has_many :posts, strict_loading: true
end
