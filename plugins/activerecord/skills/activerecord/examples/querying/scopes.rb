# Scopes Examples
# Demonstrates named scopes, scope vs class method, default_scope issues

# ============================================
# Named Scopes - Basic Usage
# ============================================

class Article < ApplicationRecord
  belongs_to :author
  has_many :comments

  # Simple scope
  scope :published, -> { where(published: true) }
  scope :draft, -> { where(published: false) }

  # Ordering scope
  scope :recent, -> { order(created_at: :desc) }
  scope :oldest, -> { order(created_at: :asc) }

  # Scope with argument
  scope :by_author, ->(author) { where(author:) }
  scope :created_after, ->(date) { where("created_at > ?", date) }
  scope :created_between, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  # Scope with optional argument
  scope :tagged, ->(tag = nil) {
    tag ? joins(:tags).where(tags: { name: tag }) : all
  }

  # Complex scope
  scope :featured, -> {
    published
      .where(featured: true)
      .where("published_at > ?", 1.week.ago)
  }
end

# Usage - scopes are chainable
Article.published.recent
Article.published.by_author(current_user).recent
Article.draft.created_after(1.month.ago)

# ============================================
# Scope Chaining
# ============================================

# All scopes return Relations - fully chainable
articles = Article.published
                  .recent
                  .by_author(current_user)
                  .limit(10)

# Scopes work with associations
author.articles.published.recent

# Scopes work with finder methods
Article.published.find_by(slug: "hello-world")
Article.recent.first
Article.published.count

# ============================================
# Scope vs Class Method
# ============================================

class Post < ApplicationRecord
  # SCOPE - always returns Relation
  scope :active, -> {
    if Feature.enabled?(:soft_delete)
      where(deleted_at: nil)
    end
    # Returns nil if condition false, but Rails converts to .all
  }

  # CLASS METHOD - can return nil (breaks chaining!)
  def self.active_method
    if Feature.enabled?(:soft_delete)
      where(deleted_at: nil)
    end
    # Returns nil if condition false - breaks chaining!
  end
end

# Scope handles nil gracefully
Post.active.recent  # Works even if condition returns nil

# Class method breaks
Post.active_method.recent  # NoMethodError if active_method returns nil!

# CLASS METHOD is better when:
# - Complex logic with early returns
# - Need to accept block
# - Want explicit control over return value

# Good class method example
class Post < ApplicationRecord
  def self.search(query)
    return none if query.blank?  # Explicit empty result

    sanitized = sanitize_sql_like(query)
    where("title ILIKE :q OR body ILIKE :q", q: "%#{sanitized}%")
  end
end

# ============================================
# default_scope - USE WITH EXTREME CAUTION
# ============================================

# Anti-pattern example - DO NOT DO THIS
class Article < ApplicationRecord
  default_scope { where(published: true) }  # Dangerous!
end

# Problem 1: Affects NEW records
Article.new.published  # => true (unexpected default!)
Article.create(title: "Draft")  # published: true automatically!

# Problem 2: Hidden filtering everywhere
Article.all           # Only published articles
Article.count         # Only counts published
Article.find(id)      # Fails silently if unpublished!

# Problem 3: Affects joins
Author.joins(:articles)  # Only joins published articles

# Problem 4: Must remember to unscope
Article.unscoped.all            # All articles
Article.unscoped { Article.all }  # Block form

# ============================================
# Better Alternatives to default_scope
# ============================================

class Article < ApplicationRecord
  # Alternative 1: Explicit scopes
  scope :published, -> { where(published: true) }
  scope :visible, -> { published }  # Semantic alias

  # Alternative 2: Query object
  class PublishedArticles
    def self.call
      Article.where(published: true)
    end
  end

  # Alternative 3: Explicit default in controller
  def index
    @articles = Article.published
  end
end

# When default_scope IS acceptable (rare):
# - Ordering only (not filtering)
# - Truly universal constraint (multi-tenant tenant_id)

class Tenant < ApplicationRecord
  # Ordering default_scope is less dangerous
  default_scope { order(:name) }
end

class Document < ApplicationRecord
  # Multi-tenant - MUST always filter
  default_scope { where(tenant_id: Current.tenant_id) }
end

# ============================================
# Merging Scopes
# ============================================

class Author < ApplicationRecord
  has_many :articles
  scope :active, -> { where(active: true) }
  scope :verified, -> { where(verified: true) }
end

class Article < ApplicationRecord
  belongs_to :author
  scope :published, -> { where(published: true) }
  scope :recent, -> { where("created_at > ?", 1.week.ago) }
end

# Merge scopes from different models
Article.published
       .joins(:author)
       .merge(Author.active)
# SELECT articles.* FROM articles
#   INNER JOIN authors ON authors.id = articles.author_id
#   WHERE articles.published = true
#   AND authors.active = true

# Merge multiple scopes
Article.published
       .joins(:author)
       .merge(Author.active.verified)

# Merge with association scope
class Author < ApplicationRecord
  has_many :articles
  has_many :published_articles, -> { published }, class_name: "Article"
end

# ============================================
# unscoped - Removing Scopes
# ============================================

# Remove all scopes (including default_scope)
Article.unscoped.all

# Block form - only affects block
Article.unscoped do
  Article.where(id: 1)  # No default_scope
end

# unscope - remove specific clauses
Article.published.recent.unscope(:order)
# Removes order, keeps where

Article.published.where(featured: true).unscope(where: :published)
# Removes published condition, keeps featured

# reorder - replace order
Article.order(:title).reorder(:created_at)
# Only ordered by created_at

# rewhere - replace where (Rails 7+)
Article.where(status: "draft").rewhere(status: "published")
# status = 'published' only

# ============================================
# Practical Scope Patterns
# ============================================

class Order < ApplicationRecord
  # Status scopes
  scope :pending, -> { where(status: "pending") }
  scope :processing, -> { where(status: "processing") }
  scope :completed, -> { where(status: "completed") }
  scope :cancelled, -> { where(status: "cancelled") }

  # Time-based scopes
  scope :today, -> { where(created_at: Time.current.all_day) }
  scope :this_week, -> { where(created_at: Time.current.all_week) }
  scope :this_month, -> { where(created_at: Time.current.all_month) }

  # Aggregate scopes
  scope :high_value, -> { where("total > ?", 1000) }
  scope :with_items, -> { joins(:order_items).distinct }

  # Boolean shortcuts
  scope :paid, -> { where(paid: true) }
  scope :unpaid, -> { where(paid: false) }

  # Negation pattern
  scope :not_cancelled, -> { where.not(status: "cancelled") }
  scope :active, -> { not_cancelled.where.not(status: "completed") }
end

# Combining scopes for reports
Order.this_month.completed.sum(:total)
Order.today.pending.count
Order.this_week.high_value.paid.includes(:customer)
