# ActiveRecord Validation Contexts Examples

# =============================================================================
# BUILT-IN CONTEXTS: :create AND :update
# =============================================================================

class User < ApplicationRecord
  # Always validates (no :on option)
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Only on create (new records)
  validates :password, presence: true, length: { minimum: 8 }, on: :create
  validates :password_confirmation, presence: true, on: :create
  validates :terms_accepted, acceptance: true, on: :create

  # Only on update (existing records)
  validates :reason_for_change, presence: true, on: :update
end

# Usage:
# user = User.new(email: "test@example.com")
# user.valid?           # Checks email (always) + password, password_confirmation, terms (create)
# user.valid?(:create)  # Same as above
# user.valid?(:update)  # Checks email (always) + reason_for_change (update)

# =============================================================================
# CUSTOM CONTEXTS
# =============================================================================

class Article < ApplicationRecord
  # Basic validations (always run)
  validates :title, presence: true
  validates :body, presence: true

  # Publishing context - stricter requirements
  validates :meta_description, presence: true, on: :publish
  validates :meta_keywords, presence: true, on: :publish
  validates :featured_image, presence: true, on: :publish
  validates :category_id, presence: true, on: :publish
  validates :published_at, presence: true, on: :publish

  # Archiving context
  validates :archived_reason, presence: true, on: :archive
  validates :archived_by_id, presence: true, on: :archive

  # Feature context
  validates :featured_position, presence: true,
    numericality: { greater_than: 0 }, on: :feature

  def publish!
    self.published_at ||= Time.current
    self.status = "published"
    save!(context: :publish)
  end

  def archive!(reason:, by:)
    self.archived_reason = reason
    self.archived_by_id = by.id
    self.status = "archived"
    save!(context: :archive)
  end

  def feature!(position:)
    self.featured_position = position
    self.status = "featured"
    save!(context: :feature)
  end
end

# Usage:
# article = Article.new(title: "Hello", body: "World")
# article.valid?           # true - basic validations pass
# article.valid?(:publish) # false - missing meta_description, etc.
# article.publish!         # Raises if publish validations fail

# =============================================================================
# MULTIPLE CONTEXTS
# =============================================================================

class Document < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true

  # Runs on both create and custom context
  validates :author_id, presence: true, on: [:create, :submit]

  # Runs on multiple custom contexts
  validates :reviewer_id, presence: true, on: [:review, :approve, :reject]
  validates :review_notes, presence: true, on: [:approve, :reject]

  # Different validations for different approval levels
  validates :manager_approval, inclusion: { in: [true] }, on: :final_approve
  validates :director_approval, inclusion: { in: [true] }, on: :final_approve
end

# =============================================================================
# CONTEXT BEHAVIOR MATRIX
# =============================================================================

class ContextDemo < ApplicationRecord
  validates :always_field, presence: true                    # No :on
  validates :create_field, presence: true, on: :create
  validates :update_field, presence: true, on: :update
  validates :custom_field, presence: true, on: :custom
  validates :multi_field, presence: true, on: [:create, :custom]
end

# Behavior:
# .valid?            => always_field, create_field (if new), update_field (if persisted)
# .valid?(:create)   => always_field, create_field
# .valid?(:update)   => always_field, update_field
# .valid?(:custom)   => always_field, custom_field
# save               => uses :create for new, :update for existing
# save(context: :x)  => uses custom context :x

# =============================================================================
# WORKFLOW-BASED CONTEXTS (STATE MACHINE STYLE)
# =============================================================================

class Order < ApplicationRecord
  # Base validations
  validates :customer_id, presence: true
  validates :line_items, presence: true

  # Context: placing order
  validates :billing_address, presence: true, on: :place
  validates :shipping_address, presence: true, on: :place
  validates :payment_method, presence: true, on: :place

  # Context: processing payment
  validates :payment_token, presence: true, on: :process_payment
  validates :payment_amount, numericality: { greater_than: 0 }, on: :process_payment

  # Context: shipping
  validates :tracking_number, presence: true, on: :ship
  validates :carrier, presence: true, on: :ship
  validates :shipped_at, presence: true, on: :ship

  # Context: completing
  validates :delivered_at, presence: true, on: :complete

  # Context: canceling
  validates :cancellation_reason, presence: true, on: :cancel
  validates :cancelled_at, presence: true, on: :cancel

  def place!
    save!(context: :place)
  end

  def process_payment!(token:)
    self.payment_token = token
    self.payment_amount = total
    save!(context: :process_payment)
  end

  def ship!(tracking:, carrier:)
    self.tracking_number = tracking
    self.carrier = carrier
    self.shipped_at = Time.current
    save!(context: :ship)
  end

  def complete!
    self.delivered_at = Time.current
    save!(context: :complete)
  end

  def cancel!(reason:)
    self.cancellation_reason = reason
    self.cancelled_at = Time.current
    save!(context: :cancel)
  end
end

# =============================================================================
# MULTI-STEP FORM CONTEXTS
# =============================================================================

class Registration < ApplicationRecord
  # Step 1: Basic info
  validates :email, presence: true, on: :step_one
  validates :password, presence: true, length: { minimum: 8 }, on: :step_one

  # Step 2: Personal info
  validates :first_name, presence: true, on: :step_two
  validates :last_name, presence: true, on: :step_two
  validates :date_of_birth, presence: true, on: :step_two

  # Step 3: Preferences
  validates :newsletter_preference, inclusion: { in: [true, false] }, on: :step_three
  validates :terms_accepted, acceptance: true, on: :step_three

  # Final validation includes all steps
  validates :email, :password, presence: true, on: :finalize
  validates :first_name, :last_name, :date_of_birth, presence: true, on: :finalize
  validates :terms_accepted, acceptance: true, on: :finalize

  def complete_step!(step)
    context = "step_#{step}".to_sym
    save!(context:)
  end

  def finalize!
    save!(context: :finalize)
  end
end

# Controller usage:
# def step_one
#   @registration.assign_attributes(step_one_params)
#   if @registration.valid?(:step_one)
#     @registration.save(validate: false)
#     redirect_to step_two_path
#   else
#     render :step_one
#   end
# end

# =============================================================================
# PERMISSION-BASED CONTEXTS
# =============================================================================

class Post < ApplicationRecord
  validates :title, presence: true
  validates :body, presence: true

  # Regular user context
  validates :content_warning, presence: true, on: :user_publish,
    if: :contains_sensitive_content?

  # Admin context - can skip content warning
  # No additional validations needed

  # Moderator context
  validates :moderation_note, presence: true, on: :moderator_edit

  def publish_as_user!
    save!(context: :user_publish)
  end

  def publish_as_admin!
    save!  # No special context, uses defaults
  end

  def edit_as_moderator!
    save!(context: :moderator_edit)
  end

  private

  def contains_sensitive_content?
    # Check for sensitive keywords
    sensitive_keywords = %w[violence explicit]
    sensitive_keywords.any? { |kw| body&.downcase&.include?(kw) }
  end
end

# =============================================================================
# CHECKING CONTEXT IN CONDITIONALS
# =============================================================================

class Invoice < ApplicationRecord
  validates :amount, presence: true
  validates :due_date, presence: true

  # Access current context in conditions
  validates :tax_number, presence: true,
    if: -> { validation_context == :business }

  validates :personal_id, presence: true,
    if: -> { validation_context == :personal }

  # Combine context check with other conditions
  validates :rush_fee, presence: true,
    if: -> { validation_context == :rush && amount > 1000 }
end

# =============================================================================
# CONTEXT WITH validates_with
# =============================================================================

class ComplexOrderValidator < ActiveModel::Validator
  def validate(record)
    case record.validation_context
    when :place
      validate_for_placement(record)
    when :ship
      validate_for_shipping(record)
    else
      validate_basic(record)
    end
  end

  private

  def validate_basic(record)
    record.errors.add(:base, "Order must have items") if record.line_items.empty?
  end

  def validate_for_placement(record)
    validate_basic(record)
    validate_inventory(record)
    validate_payment_method(record)
  end

  def validate_for_shipping(record)
    validate_address(record)
    validate_weight(record)
  end

  def validate_inventory(record)
    record.line_items.each do |item|
      unless item.product.in_stock?(item.quantity)
        record.errors.add(:base, "#{item.product.name} is out of stock")
      end
    end
  end

  def validate_payment_method(record)
    unless record.payment_method&.valid_for?(record.total)
      record.errors.add(:payment_method, "is not valid for this order")
    end
  end

  def validate_address(record)
    unless record.shipping_address&.deliverable?
      record.errors.add(:shipping_address, "is not a valid shipping destination")
    end
  end

  def validate_weight(record)
    if record.total_weight > 50.kilograms
      record.errors.add(:base, "Order exceeds maximum shipping weight")
    end
  end
end

class Order < ApplicationRecord
  validates_with ComplexOrderValidator
end

# =============================================================================
# ANTI-PATTERNS TO AVOID
# =============================================================================

# ANTI-PATTERN: Mixing contexts with conditionals incorrectly
class BadExample < ApplicationRecord
  # This won't work as expected!
  # When you call valid?(:admin), the :create context is NOT also applied
  validates :field, presence: true, on: :create
  validates :admin_field, presence: true, on: :admin

  # If you call valid?(:admin) on a new record,
  # the :create validation is NOT run!
end

# BETTER: Explicitly include all needed contexts
class GoodExample < ApplicationRecord
  validates :field, presence: true  # No :on, runs always
  validates :admin_field, presence: true, on: :admin
end

# Or use multiple contexts
class AlsoGood < ApplicationRecord
  validates :field, presence: true, on: [:create, :admin]
  validates :admin_field, presence: true, on: :admin
end
