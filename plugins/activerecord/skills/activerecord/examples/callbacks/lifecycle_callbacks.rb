# Lifecycle Callbacks Examples
# Demonstrates before/after/around callbacks for validation, save, create, update, destroy

# =============================================================================
# Basic Callback Declaration
# =============================================================================

class Article < ApplicationRecord
  # Method reference (preferred style)
  before_validation :normalize_title
  before_save :set_published_at
  after_create :notify_subscribers
  after_update :log_changes
  before_destroy :check_deletable

  private

  def normalize_title
    self.title = title&.strip&.titleize
  end

  def set_published_at
    self.published_at ||= Time.current if published?
  end

  def notify_subscribers
    NotificationJob.perform_later(id, "article_created")
  end

  def log_changes
    Rails.logger.info("Article #{id} updated: #{previous_changes.keys.join(', ')}")
  end

  def check_deletable
    throw(:abort) if comments.any?
  end
end

# =============================================================================
# Around Callbacks (Must Yield!)
# =============================================================================

class Order < ApplicationRecord
  around_save :measure_save_time
  around_create :wrap_with_logging

  private

  def measure_save_time
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield  # CRITICAL: Must call yield or save won't happen
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    Rails.logger.info("Order save took #{(duration * 1000).round(2)}ms")
  end

  def wrap_with_logging
    Rails.logger.info("Creating order...")
    yield
    Rails.logger.info("Order #{id} created successfully")
  rescue => e
    Rails.logger.error("Order creation failed: #{e.message}")
    raise
  end
end

# =============================================================================
# Callback Ordering and Prepend
# =============================================================================

class Topic < ApplicationRecord
  has_many :comments, dependent: :destroy

  # Without prepend: runs AFTER dependent: :destroy (comments already gone)
  # before_destroy :archive_comments

  # With prepend: runs BEFORE dependent: :destroy
  before_destroy :archive_comments, prepend: true

  private

  def archive_comments
    comments.find_each do |comment|
      CommentArchive.create!(
        topic_id: id,
        content: comment.content,
        author: comment.author
      )
    end
  end
end

# =============================================================================
# Special Callbacks: after_initialize and after_find
# =============================================================================

class Configuration < ApplicationRecord
  after_initialize :set_defaults
  after_find :decrypt_secrets

  private

  def set_defaults
    # Runs for new() AND records loaded from DB
    self.settings ||= {}
    self.version ||= 1
  end

  def decrypt_secrets
    # Runs only for records loaded from DB (before after_initialize)
    self.api_key = decrypt(encrypted_api_key) if encrypted_api_key.present?
  end

  def decrypt(value)
    # decryption logic
  end
end

# =============================================================================
# Halting the Callback Chain
# =============================================================================

class Payment < ApplicationRecord
  before_save :validate_amount
  before_save :check_fraud
  before_save :reserve_funds
  after_save :send_receipt

  private

  def validate_amount
    if amount <= 0
      errors.add(:amount, "must be positive")
      throw(:abort)  # Halts chain, rolls back transaction
    end
  end

  def check_fraud
    if FraudDetector.suspicious?(self)
      errors.add(:base, "Payment flagged for review")
      throw(:abort)
    end
  end

  def reserve_funds
    # Only runs if previous callbacks didn't abort
    PaymentGateway.reserve(amount, card_token)
  end

  def send_receipt
    # Only runs if save succeeded
    PaymentMailer.receipt(self).deliver_later
  end
end

# =============================================================================
# Callback Object Pattern (Reusable)
# =============================================================================

class AuditLogger
  def after_create(record)
    AuditLog.create!(
      action: "create",
      auditable: record,
      changes: record.attributes
    )
  end

  def after_update(record)
    AuditLog.create!(
      action: "update",
      auditable: record,
      changes: record.previous_changes
    )
  end

  def after_destroy(record)
    AuditLog.create!(
      action: "destroy",
      auditable_type: record.class.name,
      auditable_id: record.id,
      changes: record.attributes
    )
  end
end

class Invoice < ApplicationRecord
  after_create AuditLogger.new
  after_update AuditLogger.new
  after_destroy AuditLogger.new
end

class Refund < ApplicationRecord
  after_create AuditLogger.new
  after_update AuditLogger.new
end

# =============================================================================
# Inline Block Callbacks
# =============================================================================

class User < ApplicationRecord
  # Simple inline normalization
  before_validation { self.email = email&.downcase&.strip }

  # Block with record parameter
  after_create do |user|
    WelcomeMailer.welcome(user).deliver_later
  end

  # Multiline block
  before_save do
    if email_changed?
      self.email_verified = false
      self.verification_token = SecureRandom.urlsafe_base64
    end
  end
end

# =============================================================================
# Validation Callbacks
# =============================================================================

class Product < ApplicationRecord
  before_validation :generate_sku, on: :create
  after_validation :log_validation_errors

  private

  def generate_sku
    self.sku ||= "PRD-#{SecureRandom.alphanumeric(8).upcase}"
  end

  def log_validation_errors
    return if errors.empty?

    Rails.logger.warn("Product validation failed: #{errors.full_messages.join(', ')}")
  end
end

# =============================================================================
# Touch Callback
# =============================================================================

class Comment < ApplicationRecord
  belongs_to :post, touch: true  # Automatically touches post on save

  after_touch :update_cache

  private

  def update_cache
    Rails.cache.delete("comment_#{id}_preview")
  end
end

# =============================================================================
# Callback Inheritance
# =============================================================================

class Document < ApplicationRecord
  before_save :set_version

  private

  def set_version
    self.version = (version || 0) + 1
  end
end

class Contract < Document
  before_save :require_signatures

  private

  def require_signatures
    throw(:abort) if requires_signature? && !signed?
  end
end

# Contract.create! runs: set_version, then require_signatures
