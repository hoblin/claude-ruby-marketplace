# Counter Cache Examples
# Optimizing association counts

# ============================================
# Basic Counter Cache
# ============================================

class Comment < ApplicationRecord
  belongs_to :post, counter_cache: true
end

class Post < ApplicationRecord
  has_many :comments, dependent: :destroy

  # Prevent manual updates to counter
  attr_readonly :comments_count
end

# Migration
# add_column :posts, :comments_count, :integer, default: 0, null: false

# ============================================
# Custom Column Name
# ============================================

class Like < ApplicationRecord
  belongs_to :article, counter_cache: :likes_total
end

class Article < ApplicationRecord
  has_many :likes, dependent: :destroy
  attr_readonly :likes_total
end

# Migration
# add_column :articles, :likes_total, :integer, default: 0, null: false

# ============================================
# Multiple Counter Caches
# ============================================

class Reply < ApplicationRecord
  belongs_to :topic, counter_cache: true
  belongs_to :forum, counter_cache: true
end

class Topic < ApplicationRecord
  belongs_to :forum
  has_many :replies, dependent: :destroy
  attr_readonly :replies_count
end

class Forum < ApplicationRecord
  has_many :topics, dependent: :destroy
  has_many :replies, dependent: :destroy
  attr_readonly :replies_count
end

# ============================================
# Backfilling Counter Caches
# ============================================

# Option 1: Simple reset (small tables)
Post.find_each do |post|
  Post.reset_counters(post.id, :comments)
end

# Option 2: Batch update (large tables, PostgreSQL)
Post.connection.execute(<<~SQL)
  UPDATE posts
  SET comments_count = (
    SELECT COUNT(*)
    FROM comments
    WHERE comments.post_id = posts.id
  )
SQL

# Option 3: Disable during backfill (prevents incorrect reads)
class Comment < ApplicationRecord
  belongs_to :post, counter_cache: { active: false }
end

# After backfill complete, change to:
class Comment < ApplicationRecord
  belongs_to :post, counter_cache: true
end

# ============================================
# Conditional Counter Cache (counter_culture gem)
# ============================================

# Built-in counter_cache doesn't support conditions
# Use counter_culture gem for advanced scenarios

# gem 'counter_culture'

class Review < ApplicationRecord
  belongs_to :product
  counter_culture :product
  counter_culture :product,
                  column_name: proc { |r| r.approved? ? "approved_reviews_count" : nil },
                  column_names: { ["reviews.approved = ?", true] => "approved_reviews_count" }
end

class Product < ApplicationRecord
  has_many :reviews
  attr_readonly :reviews_count, :approved_reviews_count
end

# Migration
# add_column :products, :reviews_count, :integer, default: 0, null: false
# add_column :products, :approved_reviews_count, :integer, default: 0, null: false

# ============================================
# Counter Cache with Polymorphic
# ============================================

class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true, counter_cache: true
end

class Post < ApplicationRecord
  has_many :comments, as: :commentable, dependent: :destroy
  attr_readonly :comments_count
end

class Photo < ApplicationRecord
  has_many :comments, as: :commentable, dependent: :destroy
  attr_readonly :comments_count
end

# Both posts and photos need comments_count column

# ============================================
# Using Counter Cache Values
# ============================================

post = Post.find(1)

# These use counter cache (no query)
post.comments.size    # Uses comments_count
post.comments.any?    # Uses comments_count
post.comments.empty?  # Uses comments_count
post.comments.count   # Uses comments_count if loaded

# These always query
post.comments.length  # Loads all records
Comment.where(post_id: post.id).count  # Direct query

# ============================================
# Performance Comparison
# ============================================

# WITHOUT counter cache - N+1 COUNT queries
Post.limit(10).each do |post|
  puts "#{post.title}: #{post.comments.count} comments"
  # Executes COUNT(*) for each post
end

# WITH counter cache - no additional queries
Post.limit(10).each do |post|
  puts "#{post.title}: #{post.comments.size} comments"
  # Uses cached comments_count
end

# ============================================
# Database Trigger Alternative (High-Write)
# ============================================

# For high-write scenarios, database triggers avoid callback overhead
# PostgreSQL example:

# CREATE OR REPLACE FUNCTION update_comments_count()
# RETURNS TRIGGER AS $$
# BEGIN
#   IF TG_OP = 'INSERT' THEN
#     UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
#   ELSIF TG_OP = 'DELETE' THEN
#     UPDATE posts SET comments_count = comments_count - 1 WHERE id = OLD.post_id;
#   ELSIF TG_OP = 'UPDATE' AND NEW.post_id != OLD.post_id THEN
#     UPDATE posts SET comments_count = comments_count - 1 WHERE id = OLD.post_id;
#     UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
#   END IF;
#   RETURN NULL;
# END;
# $$ LANGUAGE plpgsql;
#
# CREATE TRIGGER comments_count_trigger
# AFTER INSERT OR UPDATE OR DELETE ON comments
# FOR EACH ROW EXECUTE FUNCTION update_comments_count();

# ============================================
# Common Gotchas
# ============================================

# 1. delete bypasses callbacks (and counter cache)
Comment.where(post_id: 1).delete_all  # Counter NOT updated!
Comment.where(post_id: 1).destroy_all # Counter updated

# 2. Counter gets out of sync over time
# Run periodic reset job
class CounterCacheResetJob < ApplicationJob
  def perform
    Post.find_each do |post|
      Post.reset_counters(post.id, :comments)
    end
  end
end

# 3. Race conditions under high concurrency
# Database triggers or row-level locking may be needed
Post.transaction do
  post = Post.lock.find(1)
  post.comments.create!(body: "New comment")
end
