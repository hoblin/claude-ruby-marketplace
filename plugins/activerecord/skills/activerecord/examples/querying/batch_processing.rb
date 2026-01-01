# Batch Processing Examples
# Demonstrates find_each, find_in_batches, in_batches for large datasets

# ============================================
# The Problem: Loading All Records
# ============================================

# BAD - loads ALL records into memory at once
User.all.each do |user|
  NewsMailer.weekly_digest(user).deliver_later
end
# With 1 million users = 1 million User objects in memory!

# GOOD - loads in batches of 1000, GC can clean up between batches
User.find_each do |user|
  NewsMailer.weekly_digest(user).deliver_later
end
# Memory stays constant regardless of total count

# ============================================
# find_each - Process Individual Records
# ============================================

# Basic usage - yields one record at a time
User.find_each do |user|
  user.calculate_monthly_stats
end

# With batch size
User.find_each(batch_size: 500) do |user|
  # Process in batches of 500
end

# With start/finish - process subset by primary key
User.find_each(start: 1000, finish: 5000) do |user|
  # Only users with id between 1000 and 5000
end

# With scope
User.active.find_each do |user|
  # Only active users
end

# Enumerator form (for chaining)
User.find_each.map(&:email)
User.find_each.with_index { |user, i| puts "#{i}: #{user.name}" }

# ============================================
# find_in_batches - Process Batches of Records
# ============================================

# Yields arrays of records
User.find_in_batches(batch_size: 100) do |users|
  # users is Array<User> with up to 100 elements
  ExternalApi.bulk_sync(users.map(&:external_id))
end

# Practical: Bulk API calls
Product.find_in_batches(batch_size: 50) do |products|
  SearchIndex.bulk_update(products)
  sleep(0.5)  # Rate limiting
end

# With eager loading
User.includes(:profile, :preferences).find_in_batches do |users|
  users.each do |user|
    user.profile  # No N+1
  end
end

# ============================================
# in_batches - Process Batches as Relations
# ============================================

# Yields ActiveRecord::Relation objects
User.in_batches do |batch|
  # batch is a Relation, not Array
  batch.update_all(newsletter_sent_at: Time.current)
end

# Bulk update pattern
User.where(legacy: true).in_batches.update_all(migrated: true)

# Bulk delete with throttling
User.where("created_at < ?", 5.years.ago).in_batches do |batch|
  batch.delete_all
  sleep(0.1)  # Reduce database load
end

# Bulk operations via relation
Order.where(status: "pending").in_batches do |batch|
  batch.update_all(status: "cancelled", cancelled_at: Time.current)
end

# With load: true to also get records
User.in_batches(load: true) do |batch|
  batch.each { |user| user.some_instance_method }
end

# ============================================
# Comparison: When to Use Which
# ============================================

# find_each - Individual record processing
# - Sending emails one by one
# - Complex per-record logic
# - Instance methods needed
User.find_each { |u| u.send_notification }

# find_in_batches - Batch operations on loaded records
# - Bulk API calls with arrays
# - Batch exports
# - When you need the actual objects in groups
User.find_in_batches { |users| CsvExporter.export(users) }

# in_batches - SQL-level bulk operations
# - update_all, delete_all
# - Bulk SQL operations
# - Maximum efficiency, no Ruby object overhead
User.in_batches.update_all(processed: true)

# ============================================
# Important Caveats
# ============================================

# ORDERING IS IGNORED
# Batch processing always orders by primary key
User.order(:name).find_each { |u| }
# WARNING: Scoped order is ignored, will use primary key order

# RESULTS MAY BE INCONSISTENT
# If records are added/deleted during iteration, may skip/duplicate
# Solution: Use in_batches with explicit locking for critical operations

# CUSTOM ORDER WITH cursor (Rails 7.1+)
User.find_each(cursor: [:created_at, :id]) { |u| }
# Orders by created_at, then id for stability

# ============================================
# Practical Examples
# ============================================

# Example 1: Data migration
class BackfillUserSettings < ActiveRecord::Migration[7.1]
  def up
    User.in_batches do |batch|
      batch.update_all(settings: { notifications: true }.to_json)
    end
  end
end

# Example 2: Export to CSV
require "csv"

def export_users_to_csv(file_path)
  CSV.open(file_path, "w") do |csv|
    csv << ["ID", "Name", "Email", "Created At"]

    User.find_each do |user|
      csv << [user.id, user.name, user.email, user.created_at]
    end
  end
end

# Example 3: Background job processing
class ProcessAllOrdersJob < ApplicationJob
  def perform
    Order.pending.find_each do |order|
      ProcessOrderJob.perform_later(order.id)
    end
  end
end

# Example 4: Batch API sync with rate limiting
def sync_products_to_external_service
  Product.active.find_in_batches(batch_size: 25) do |products|
    ExternalService.bulk_upsert(
      products.map { |p| p.as_external_format }
    )
    sleep(1)  # Respect rate limits
  end
end

# Example 5: Data cleanup with progress tracking
def cleanup_old_sessions
  total = Session.where("created_at < ?", 30.days.ago).count
  deleted = 0

  Session.where("created_at < ?", 30.days.ago).in_batches do |batch|
    count = batch.delete_all
    deleted += count
    Rails.logger.info "Deleted #{deleted}/#{total} old sessions"
    sleep(0.05)
  end
end

# Example 6: Memory-efficient aggregation
def calculate_total_balance
  total = 0

  Account.active.find_each do |account|
    total += account.calculated_balance  # Complex calculation
  end

  total
end

# Better: Use database when possible
Account.active.sum(:balance)  # Single SQL query

# ============================================
# Batch Processing with Transactions
# ============================================

# Each batch in its own transaction
User.in_batches do |batch|
  batch.transaction do
    batch.update_all(processed: true)
    AuditLog.create!(action: "batch_processed", count: batch.count)
  end
end

# Whole operation in one transaction (careful with large datasets!)
User.transaction do
  User.in_batches.update_all(processed: true)
end
