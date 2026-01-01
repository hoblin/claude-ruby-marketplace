# ActiveRecord Conditional Validations Examples

# =============================================================================
# :if AND :unless OPTIONS
# =============================================================================

class Order < ApplicationRecord
  # Symbol method reference (preferred for readability)
  validates :card_number, presence: true, if: :paid_with_card?
  validates :check_number, presence: true, if: :paid_with_check?
  validates :delivery_address, presence: true, unless: :pickup?

  # Lambda/Proc for one-liners
  validates :discount_code, presence: true,
    if: -> { promotional_period? && premium_customer? }

  validates :signature, presence: true,
    unless: -> { total < 100 }

  # Array of conditions (ALL must be true)
  validates :insurance_number, presence: true,
    if: [:high_value?, :requires_insurance?, :not_insured?]

  # Mixed array (symbols and procs)
  validates :manager_approval, presence: true,
    if: [:large_order?, -> { created_at > 1.day.ago }]

  private

  def paid_with_card?
    payment_method == "card"
  end

  def paid_with_check?
    payment_method == "check"
  end

  def pickup?
    delivery_method == "pickup"
  end

  def promotional_period?
    Time.current.between?(promo_start, promo_end)
  end

  def premium_customer?
    customer&.premium?
  end

  def high_value?
    total > 10_000
  end

  def requires_insurance?
    items.any?(&:fragile?)
  end

  def not_insured?
    !insured?
  end

  def large_order?
    items.count > 50
  end
end

# =============================================================================
# with_options - GROUPING VALIDATIONS
# =============================================================================

class User < ApplicationRecord
  # Group validations by condition
  with_options if: :admin? do |admin|
    admin.validates :password, length: { minimum: 12 }
    admin.validates :two_factor_enabled, inclusion: { in: [true] }
    admin.validates :security_question, presence: true
  end

  with_options if: :guest? do |guest|
    guest.validates :session_token, presence: true
    guest.validates :expires_at, presence: true
  end

  # Nested with_options
  with_options if: :active? do |active|
    active.validates :email, presence: true
    active.validates :last_sign_in_at, presence: true

    active.with_options if: :subscribed? do |subscribed|
      subscribed.validates :subscription_id, presence: true
      subscribed.validates :subscription_expires_at, presence: true
    end
  end

  private

  def admin?
    role == "admin"
  end

  def guest?
    role == "guest"
  end

  def active?
    status == "active"
  end

  def subscribed?
    subscription_status == "active"
  end
end

# =============================================================================
# DYNAMIC allow_nil AND allow_blank
# =============================================================================

class Profile < ApplicationRecord
  # Static allow_blank
  validates :bio, length: { minimum: 50 }, allow_blank: true

  # Dynamic allow_blank with Proc
  validates :phone, presence: true,
    allow_blank: -> { signup_step < 3 }

  # Dynamic allow_nil
  validates :age, numericality: { greater_than: 0 },
    allow_nil: :optional_age_field?

  private

  def optional_age_field?
    !requires_age_verification?
  end
end

# =============================================================================
# CONDITIONAL CALLBACKS WITH VALIDATIONS
# =============================================================================

class Document < ApplicationRecord
  # Normalize before validation, conditionally
  before_validation :normalize_title, if: :title_changed?
  before_validation :set_slug, unless: :slug?

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  private

  def normalize_title
    self.title = title.strip.titleize
  end

  def set_slug
    self.slug = title.parameterize if title.present?
  end
end

# =============================================================================
# HALTING VALIDATION
# =============================================================================

class ImportedRecord < ApplicationRecord
  before_validation :check_skip_validation

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  attr_accessor :skip_validation

  private

  def check_skip_validation
    throw(:abort) if skip_validation
  end
end

# Usage:
# record = ImportedRecord.new(skip_validation: true)
# record.save  # Skips all validations

# =============================================================================
# COMPLEX CONDITIONAL PATTERNS
# =============================================================================

class Subscription < ApplicationRecord
  # Different validations based on plan type
  validates :credit_card, presence: true, if: :paid_plan?
  validates :trial_ends_at, presence: true, if: :trial_plan?
  validates :enterprise_contract_id, presence: true, if: :enterprise_plan?

  # Inverse conditions
  validates :payment_method, presence: true, unless: :free_plan?

  # Combining positive and negative conditions
  validates :billing_address, presence: true,
    if: :requires_billing?,
    unless: :digital_only?

  private

  def paid_plan?
    %w[basic pro business].include?(plan_type)
  end

  def trial_plan?
    plan_type == "trial"
  end

  def enterprise_plan?
    plan_type == "enterprise"
  end

  def free_plan?
    plan_type == "free"
  end

  def requires_billing?
    paid_plan? || enterprise_plan?
  end

  def digital_only?
    products.all?(&:digital?)
  end
end

# =============================================================================
# CONTEXT-AWARE CONDITIONALS
# =============================================================================

class Article < ApplicationRecord
  # Different rules based on validation context
  validates :title, presence: true
  validates :body, presence: true

  # Only require these fields when publishing
  validates :meta_description, presence: true,
    if: -> { validation_context == :publish }
  validates :featured_image, presence: true,
    if: -> { validation_context == :publish }
  validates :published_at, presence: true,
    if: -> { validation_context == :publish }

  def publish!
    self.published_at ||= Time.current
    save!(context: :publish)
  end
end

# =============================================================================
# ANTI-PATTERNS TO AVOID
# =============================================================================

# ANTI-PATTERN: Overly complex conditionals
class BadExample < ApplicationRecord
  # WRONG: Too many conditions, hard to understand
  validates :field1, presence: true, if: :a?
  validates :field1, length: { min: 5 }, if: :b?
  validates :field1, format: { with: /.../ }, unless: :c?
  validates :field2, presence: true, if: :a?
  validates :field2, uniqueness: true, if: -> { b? && !d? }
  # ... more scattered conditionals
end

# BETTER: Group related validations or use contexts
class GoodExample < ApplicationRecord
  # Group by context
  with_options on: :step_one do
    validates :field1, :field2, presence: true
  end

  with_options on: :step_two do
    validates :field1, length: { minimum: 5 }
    validates :field2, uniqueness: true
  end

  # Or use form objects for complex multi-step flows
end

# ANTI-PATTERN: String evaluation (deprecated, slow)
class OldStyleExample < ApplicationRecord
  # WRONG: String evaluation
  # validates :name, presence: true, if: "admin?"

  # CORRECT: Symbol or proc
  validates :name, presence: true, if: :admin?
end
