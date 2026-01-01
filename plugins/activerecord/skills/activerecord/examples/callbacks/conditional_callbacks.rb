# Conditional Callbacks Examples
# Demonstrates :if, :unless, :on options and callback scoping

# =============================================================================
# Symbol Conditions (Method Names)
# =============================================================================

class Order < ApplicationRecord
  before_save :calculate_tax, if: :taxable?
  before_save :apply_discount, if: :has_coupon?
  after_create :send_confirmation, unless: :guest_checkout?
  after_save :notify_warehouse, if: :ready_for_fulfillment?

  private

  def taxable?
    !tax_exempt? && total > 0
  end

  def has_coupon?
    coupon_code.present?
  end

  def guest_checkout?
    user_id.nil?
  end

  def ready_for_fulfillment?
    saved_change_to_status? && status == "paid"
  end

  def calculate_tax
    self.tax_amount = (subtotal * tax_rate).round(2)
  end

  def apply_discount
    self.discount_amount = Coupon.find_by(code: coupon_code)&.calculate_discount(self) || 0
  end

  def send_confirmation
    OrderMailer.confirmation(self).deliver_later
  end

  def notify_warehouse
    WarehouseNotificationJob.perform_later(id)
  end
end

# =============================================================================
# Proc/Lambda Conditions
# =============================================================================

class User < ApplicationRecord
  # Simple lambda
  before_save :encrypt_password, if: -> { password.present? }

  # Lambda with record parameter
  after_create :send_welcome_email, if: ->(user) { user.email_verified? }

  # Complex inline condition
  before_validation :normalize_phone, if: -> { phone.present? && phone_changed? }

  # Using saved_change_to_attribute? in after callbacks
  after_save :sync_to_crm, if: -> { saved_change_to_email? || saved_change_to_name? }

  private

  def encrypt_password
    self.encrypted_password = BCrypt::Password.create(password)
  end

  def send_welcome_email
    WelcomeMailer.welcome(self).deliver_later
  end

  def normalize_phone
    self.phone = phone.gsub(/\D/, "")
  end

  def sync_to_crm
    CrmSyncJob.perform_later(id)
  end
end

# =============================================================================
# Multiple Conditions (Array)
# =============================================================================

class Article < ApplicationRecord
  # All conditions must be true (AND logic)
  before_save :schedule_publication,
              if: [:published?, :publication_date_set?, :not_already_scheduled?]

  # Mix of symbols and lambdas
  after_update :notify_author,
               if: [:status_changed?, -> { previous_changes[:status]&.last == "rejected" }]

  # Multiple unless conditions
  before_destroy :archive_content,
                 unless: [:draft?, :never_published?]

  private

  def published?
    status == "published"
  end

  def publication_date_set?
    publish_at.present?
  end

  def not_already_scheduled?
    !scheduled?
  end

  def status_changed?
    saved_change_to_status?
  end

  def draft?
    status == "draft"
  end

  def never_published?
    published_at.nil?
  end

  def schedule_publication
    PublicationJob.set(wait_until: publish_at).perform_later(id)
    self.scheduled = true
  end

  def notify_author
    ArticleMailer.rejection_notice(self).deliver_later
  end

  def archive_content
    ArticleArchive.create!(article_attributes: attributes)
  end
end

# =============================================================================
# Combining :if and :unless
# =============================================================================

class Payment < ApplicationRecord
  # Callback runs when :if is true AND :unless is false
  after_create :send_receipt,
               if: :successful?,
               unless: :receipt_sent?

  # Multiple conditions on both
  before_save :validate_card,
              if: [:card_payment?, :new_card?],
              unless: -> { skip_validation? || test_mode? }

  private

  def successful?
    status == "success"
  end

  def receipt_sent?
    receipt_sent_at.present?
  end

  def card_payment?
    payment_method == "card"
  end

  def new_card?
    card_token_changed?
  end

  def skip_validation?
    Rails.env.development? && ENV["SKIP_CARD_VALIDATION"]
  end

  def test_mode?
    card_token&.start_with?("tok_test_")
  end

  def send_receipt
    PaymentMailer.receipt(self).deliver_later
    update_column(:receipt_sent_at, Time.current)
  end

  def validate_card
    unless CardValidator.valid?(card_token)
      errors.add(:card_token, "is invalid")
      throw(:abort)
    end
  end
end

# =============================================================================
# :on Option - Context Scoping
# =============================================================================

class User < ApplicationRecord
  # Only on create
  before_validation :generate_username, on: :create
  after_create :send_verification_email

  # Only on update
  before_save :track_email_change, on: :update
  after_update :notify_email_change, if: :saved_change_to_email?

  # Multiple contexts
  after_save :sync_profile, on: [:create, :update]

  private

  def generate_username
    self.username ||= email.split("@").first.parameterize
  end

  def send_verification_email
    VerificationMailer.verify(self).deliver_later
  end

  def track_email_change
    self.previous_email = email_was if email_changed?
  end

  def notify_email_change
    UserMailer.email_changed(self).deliver_later
  end

  def sync_profile
    ProfileSyncJob.perform_later(id)
  end
end

# =============================================================================
# Custom Validation Contexts
# =============================================================================

class Article < ApplicationRecord
  # Standard validations run on all contexts
  validates :title, presence: true

  # Only on :publish context
  validates :body, presence: true, on: :publish
  validates :category_id, presence: true, on: :publish
  validates :meta_description, length: { maximum: 160 }, on: :publish

  # Callbacks can also use custom contexts
  before_validation :prepare_for_publish, on: :publish

  def publish!
    self.status = "published"
    self.published_at = Time.current
    save!(context: :publish)  # Runs :publish validations and callbacks
  end

  private

  def prepare_for_publish
    self.slug ||= title.parameterize
    self.excerpt ||= body.truncate(200)
  end
end

# =============================================================================
# Conditional Callbacks with Dirty Tracking
# =============================================================================

class Product < ApplicationRecord
  # Before save - use *_changed? methods
  before_save :recalculate_margin, if: :cost_or_price_changed?

  # After save - use saved_change_to_*? methods
  after_save :update_search_index, if: :searchable_fields_changed?
  after_save :notify_price_watchers, if: :price_decreased?

  private

  def cost_or_price_changed?
    cost_changed? || price_changed?
  end

  def searchable_fields_changed?
    saved_change_to_name? || saved_change_to_description? || saved_change_to_category_id?
  end

  def price_decreased?
    saved_change_to_price? && price < price_before_last_save
  end

  def recalculate_margin
    return unless cost.present? && price.present?

    self.margin = ((price - cost) / price * 100).round(2)
  end

  def update_search_index
    SearchIndexJob.perform_later("product", id)
  end

  def notify_price_watchers
    PriceAlertJob.perform_later(id, price_before_last_save, price)
  end
end

# =============================================================================
# Grouping with with_options
# =============================================================================

class Account < ApplicationRecord
  # Apply same condition to multiple callbacks
  with_options if: :premium_account? do |premium|
    premium.before_save :apply_premium_features
    premium.after_create :send_premium_welcome
    premium.after_save :sync_to_premium_crm
  end

  with_options unless: :suspended? do |active|
    active.after_save :update_activity_log
    active.after_save :refresh_dashboard_cache
  end

  private

  def premium_account?
    plan_type == "premium"
  end

  def suspended?
    status == "suspended"
  end

  def apply_premium_features
    self.storage_limit = 100.gigabytes
    self.api_rate_limit = 10_000
  end

  def send_premium_welcome
    PremiumMailer.welcome(self).deliver_later
  end

  def sync_to_premium_crm
    PremiumCrmSyncJob.perform_later(id)
  end

  def update_activity_log
    ActivityLog.create!(account: self, action: "updated")
  end

  def refresh_dashboard_cache
    Rails.cache.delete("dashboard_#{id}")
  end
end
