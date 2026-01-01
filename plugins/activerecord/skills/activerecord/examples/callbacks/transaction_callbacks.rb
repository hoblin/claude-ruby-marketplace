# Transaction Callbacks Examples
# Demonstrates after_commit, after_rollback, and transaction gotchas

# =============================================================================
# The Critical Difference: after_save vs after_commit
# =============================================================================

class Order < ApplicationRecord
  # WRONG - Race condition with background jobs
  # The job may start before the transaction commits
  # after_save :enqueue_processing_wrong

  # CORRECT - Job runs after transaction commits
  after_commit :enqueue_processing, on: :create

  private

  def enqueue_processing_wrong
    # Sidekiq might query: "Couldn't find Order with 'id'=123"
    # because the transaction hasn't committed yet
    OrderProcessingJob.perform_later(id)
  end

  def enqueue_processing
    # Transaction committed - record guaranteed to exist
    OrderProcessingJob.perform_later(id)
  end
end

# =============================================================================
# Transaction Callback Variants (Rails 7.1+)
# =============================================================================

class Article < ApplicationRecord
  # Fires on any commit (create, update, or destroy)
  after_commit :clear_cache

  # Scoped to specific actions
  after_create_commit :notify_followers
  after_update_commit :sync_to_search
  after_destroy_commit :cleanup_attachments

  # Fires on create OR update (not destroy)
  after_save_commit :reindex_content

  # Equivalent to after_create_commit + after_update_commit
  after_commit :update_analytics, on: [:create, :update]

  # Rollback callback
  after_rollback :log_failure

  private

  def clear_cache
    Rails.cache.delete("article_#{id}")
    Rails.cache.delete("articles_list")
  end

  def notify_followers
    author.followers.find_each do |follower|
      NotificationJob.perform_later(follower.id, "new_article", id)
    end
  end

  def sync_to_search
    SearchIndexJob.perform_later("update", self.class.name, id)
  end

  def cleanup_attachments
    AttachmentCleanupJob.perform_later(attachment_keys)
  end

  def reindex_content
    FullTextIndexJob.perform_later(id)
  end

  def update_analytics
    AnalyticsJob.perform_later("article_saved", id: id)
  end

  def log_failure
    Rails.logger.error("Article #{id || 'new'} save failed, transaction rolled back")
  end
end

# =============================================================================
# Gotcha: Callback Deduplication
# =============================================================================

class Product < ApplicationRecord
  # WRONG - Only the LAST one runs due to deduplication
  after_commit :sync_inventory
  after_commit :sync_inventory  # This one "wins"

  # Also deduplicated across variants!
  after_commit :notify_warehouse
  after_create_commit :notify_warehouse  # These are considered duplicates
  after_save_commit :notify_warehouse

  # CORRECT - Use :on option
  after_commit :sync_inventory, on: [:create, :update]
  after_commit :notify_warehouse, on: :create

  private

  def sync_inventory
    InventorySyncJob.perform_later(id)
  end

  def notify_warehouse
    WarehouseNotificationJob.perform_later(id)
  end
end

# =============================================================================
# Gotcha: Exception Handling in after_commit
# =============================================================================

class Payment < ApplicationRecord
  after_commit :notify_external_service
  after_commit :update_analytics
  after_commit :send_receipt

  private

  def notify_external_service
    # If this raises, update_analytics and send_receipt won't run!
    ExternalPaymentService.notify(self)
  rescue ExternalPaymentService::Error => e
    # Handle gracefully - don't let it bubble up
    Rails.logger.error("External notification failed: #{e.message}")
    ErrorTracker.capture(e)
    # Don't re-raise - let other callbacks run
  end

  def update_analytics
    Analytics.track("payment_completed", amount:, user_id:)
  rescue => e
    Rails.logger.error("Analytics failed: #{e.message}")
  end

  def send_receipt
    PaymentMailer.receipt(self).deliver_later
  end
end

# =============================================================================
# Gotcha: previous_changes in after_commit
# =============================================================================

class User < ApplicationRecord
  after_commit :log_changes

  private

  def log_changes
    # WARNING: If the record was saved multiple times in one transaction,
    # previous_changes only contains the LAST save's changes

    # If transaction did: user.save, then user.save again
    # previous_changes only shows changes from the second save

    Rails.logger.info("User #{id} changed: #{previous_changes.inspect}")
  end
end

# =============================================================================
# Gotcha: after_commit Also Fires on Destroy
# =============================================================================

class Subscription < ApplicationRecord
  # Be careful! This fires on CREATE, UPDATE, AND DESTROY
  after_commit :sync_to_billing

  # If you only want create/update:
  after_save_commit :sync_to_billing_safe

  # Or be explicit:
  after_commit :sync_to_billing_explicit, on: [:create, :update]

  private

  def sync_to_billing
    # This will run on destroy too - might not be what you want!
    BillingService.sync(self)
  end

  def sync_to_billing_safe
    BillingService.sync(self)
  end

  def sync_to_billing_explicit
    BillingService.sync(self)
  end
end

# =============================================================================
# Transaction Callback Ordering (Rails 7.1+)
# =============================================================================

class Invoice < ApplicationRecord
  # Rails 7.1+ default: runs in definition order
  after_commit :step_one   # Runs first
  after_commit :step_two   # Runs second
  after_commit :step_three # Runs third

  # Pre-7.1 behavior (if configured): reverse order
  # config.active_record.run_after_transaction_callbacks_in_order_defined = false

  private

  def step_one
    Rails.logger.info("Step 1: Generate PDF")
    PdfGeneratorJob.perform_later(id)
  end

  def step_two
    Rails.logger.info("Step 2: Send email")
    InvoiceMailer.send_invoice(self).deliver_later
  end

  def step_three
    Rails.logger.info("Step 3: Update dashboard")
    DashboardRefreshJob.perform_later(user_id)
  end
end

# =============================================================================
# Real-World Pattern: External System Sync
# =============================================================================

class Customer < ApplicationRecord
  after_create_commit :create_in_crm
  after_update_commit :update_in_crm
  after_destroy_commit :delete_from_crm

  private

  def create_in_crm
    CrmSyncJob.perform_later("create", id)
  end

  def update_in_crm
    # Only sync if relevant fields changed
    relevant_changes = previous_changes.keys & %w[name email phone company]
    return if relevant_changes.empty?

    CrmSyncJob.perform_later("update", id, changes: previous_changes.slice(*relevant_changes))
  end

  def delete_from_crm
    # Can't use id lookup since record is gone
    CrmSyncJob.perform_later("delete", crm_external_id)
  end
end

# =============================================================================
# Real-World Pattern: Search Index Management
# =============================================================================

class Post < ApplicationRecord
  after_save_commit :update_search_index
  after_destroy_commit :remove_from_search_index

  private

  def update_search_index
    SearchIndexJob.perform_later(
      action: "index",
      type: "post",
      id:,
      body: {
        title:,
        content:,
        author_name: author.name,
        published_at:,
        tags: tags.pluck(:name)
      }
    )
  end

  def remove_from_search_index
    SearchIndexJob.perform_later(
      action: "delete",
      type: "post",
      id:
    )
  end
end

# =============================================================================
# Real-World Pattern: Cache Invalidation
# =============================================================================

class Category < ApplicationRecord
  has_many :products

  after_commit :invalidate_caches

  private

  def invalidate_caches
    Rails.cache.delete("category_#{id}")
    Rails.cache.delete("category_#{id}_products")
    Rails.cache.delete("categories_tree")
    Rails.cache.delete("navigation_menu")

    # Invalidate parent category caches if nested
    parent&.invalidate_caches if parent_id_previously_changed?
  end
end

# =============================================================================
# Nested Transactions and Callbacks
# =============================================================================

class Transfer < ApplicationRecord
  def self.create_with_ledger_entries!(from_account:, to_account:, amount:)
    transaction do
      transfer = create!(from_account:, to_account:, amount:)

      # Nested transaction - callbacks still wait for outer commit
      transaction(requires_new: true) do
        LedgerEntry.create!(account: from_account, amount: -amount, transfer:)
        LedgerEntry.create!(account: to_account, amount:, transfer:)
      end

      transfer
    end
    # after_commit callbacks run here, after outer transaction commits
  end

  after_commit :notify_accounts, on: :create

  private

  def notify_accounts
    TransferNotificationJob.perform_later(id)
  end
end
