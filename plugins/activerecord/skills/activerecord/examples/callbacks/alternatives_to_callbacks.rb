# Alternatives to Callbacks
# Demonstrates service objects, form objects, and domain events as callback alternatives

# =============================================================================
# Problem: Callback Hell
# =============================================================================

# ANTI-PATTERN: Too many responsibilities in callbacks
class UserWithCallbackHell < ApplicationRecord
  after_create :send_welcome_email
  after_create :create_default_settings
  after_create :notify_admin
  after_create :sync_to_crm
  after_create :create_audit_log
  after_create :track_signup_analytics
  after_create :create_free_trial
  after_create :send_to_marketing_list
  after_update :sync_to_crm
  after_update :update_search_index
  after_update :notify_changes
  after_destroy :cleanup_associated_data
  after_destroy :notify_admin

  # Problems:
  # - Hard to test each piece in isolation
  # - Hard to skip individual side effects
  # - Unclear execution order
  # - Slow tests (all callbacks fire on User.create!)
  # - Tight coupling
end

# =============================================================================
# Solution 1: Service Objects (Recommended)
# =============================================================================

# Clean model with minimal callbacks
class User < ApplicationRecord
  # Only keep callbacks for data integrity on the model itself
  before_validation :normalize_email
  before_create :generate_api_key

  private

  def normalize_email
    self.email = email&.downcase&.strip
  end

  def generate_api_key
    self.api_key ||= SecureRandom.hex(32)
  end
end

# Service object encapsulates the full registration workflow
class UserRegistrationService
  def initialize(user_params, referral_code: nil)
    @user_params = user_params
    @referral_code = referral_code
  end

  def call
    user = User.new(@user_params)

    ActiveRecord::Base.transaction do
      user.save!
      create_default_settings(user)
      apply_referral(user) if @referral_code
    end

    # Post-transaction side effects
    send_welcome_email(user)
    sync_to_crm(user)
    track_analytics(user)
    notify_admin(user)

    user
  rescue ActiveRecord::RecordInvalid => e
    e.record
  end

  private

  def create_default_settings(user)
    UserSettings.create!(
      user:,
      theme: "light",
      notifications_enabled: true,
      timezone: "UTC"
    )
  end

  def apply_referral(user)
    referrer = User.find_by(referral_code: @referral_code)
    return unless referrer

    Referral.create!(referrer:, referred: user)
    ReferralRewardJob.perform_later(referrer.id)
  end

  def send_welcome_email(user)
    WelcomeMailer.welcome(user).deliver_later
  end

  def sync_to_crm(user)
    CrmSyncJob.perform_later(user.id)
  end

  def track_analytics(user)
    Analytics.track("user_signed_up", user_id: user.id)
  end

  def notify_admin(user)
    AdminNotificationJob.perform_later("new_user", user.id)
  end
end

# Controller usage
class UsersController < ApplicationController
  def create
    result = UserRegistrationService.new(user_params, referral_code: params[:ref]).call

    if result.persisted?
      redirect_to dashboard_path, notice: "Welcome!"
    else
      @user = result
      render :new, status: :unprocessable_entity
    end
  end
end

# =============================================================================
# Solution 2: Form Objects
# =============================================================================

# For complex forms that span multiple models or need special validation
class RegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email, :string
  attribute :password, :string
  attribute :password_confirmation, :string
  attribute :terms_accepted, :boolean
  attribute :company_name, :string
  attribute :plan, :string, default: "free"

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }, confirmation: true
  validates :terms_accepted, acceptance: true
  validates :company_name, presence: true
  validates :plan, inclusion: { in: %w[free starter business] }

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      create_user
      create_company
      create_subscription
    end

    send_notifications
    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end

  def user
    @user
  end

  private

  def create_user
    @user = User.create!(email:, password:)
  end

  def create_company
    @company = Company.create!(name: company_name, owner: @user)
    @user.update!(company: @company)
  end

  def create_subscription
    Subscription.create!(company: @company, plan:, status: "active")
  end

  def send_notifications
    WelcomeMailer.welcome(@user).deliver_later
    CompanyMailer.setup_guide(@company).deliver_later
  end
end

# Controller usage
class RegistrationsController < ApplicationController
  def create
    @form = RegistrationForm.new(registration_params)

    if @form.save
      sign_in(@form.user)
      redirect_to onboarding_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:registration).permit(
      :email, :password, :password_confirmation,
      :terms_accepted, :company_name, :plan
    )
  end
end

# =============================================================================
# Solution 3: Domain Events
# =============================================================================

# Simple event bus implementation
class EventBus
  class << self
    def subscribers
      @subscribers ||= Hash.new { |h, k| h[k] = [] }
    end

    def subscribe(event_name, &handler)
      subscribers[event_name] << handler
    end

    def publish(event_name, payload)
      subscribers[event_name].each do |handler|
        handler.call(payload)
      rescue => e
        Rails.logger.error("Event handler failed: #{e.message}")
        ErrorTracker.capture(e)
      end
    end
  end
end

# Model publishes events
class Order < ApplicationRecord
  after_commit :publish_created, on: :create
  after_commit :publish_status_changed, on: :update, if: :saved_change_to_status?

  private

  def publish_created
    EventBus.publish("order.created", order: self)
  end

  def publish_status_changed
    EventBus.publish("order.status_changed", order: self, old_status: status_before_last_save, new_status: status)
  end
end

# Event subscribers (in config/initializers/event_subscriptions.rb)
EventBus.subscribe("order.created") do |payload|
  order = payload[:order]
  OrderMailer.confirmation(order).deliver_later
end

EventBus.subscribe("order.created") do |payload|
  order = payload[:order]
  InventoryService.reserve_items(order)
end

EventBus.subscribe("order.created") do |payload|
  order = payload[:order]
  Analytics.track("order_placed", order_id: order.id, amount: order.total)
end

EventBus.subscribe("order.status_changed") do |payload|
  order = payload[:order]
  next unless payload[:new_status] == "shipped"

  ShippingMailer.shipped(order).deliver_later
end

EventBus.subscribe("order.status_changed") do |payload|
  order = payload[:order]
  next unless payload[:new_status] == "delivered"

  ReviewRequestMailer.request_review(order).deliver_later
end

# =============================================================================
# Solution 4: Interactor Pattern
# =============================================================================

# Using the interactor gem pattern
class CreateOrder
  include Interactor::Organizer

  organize ValidateCart, CalculateTotals, ProcessPayment, CreateOrderRecord, SendConfirmation

  def call
    context.cart = context.user.cart
  end
end

class ValidateCart
  include Interactor

  def call
    if context.cart.empty?
      context.fail!(error: "Cart is empty")
    end

    if context.cart.items.any?(&:out_of_stock?)
      context.fail!(error: "Some items are out of stock")
    end
  end
end

class CalculateTotals
  include Interactor

  def call
    context.subtotal = context.cart.items.sum(&:total)
    context.tax = context.subtotal * 0.1
    context.total = context.subtotal + context.tax
  end
end

class ProcessPayment
  include Interactor

  def call
    result = PaymentGateway.charge(context.payment_method, context.total)

    if result.success?
      context.payment_id = result.payment_id
    else
      context.fail!(error: result.error_message)
    end
  end

  def rollback
    PaymentGateway.refund(context.payment_id) if context.payment_id
  end
end

class CreateOrderRecord
  include Interactor

  def call
    context.order = Order.create!(
      user: context.user,
      subtotal: context.subtotal,
      tax: context.tax,
      total: context.total,
      payment_id: context.payment_id
    )

    context.cart.items.each do |cart_item|
      context.order.line_items.create!(
        product: cart_item.product,
        quantity: cart_item.quantity,
        price: cart_item.price
      )
    end
  end

  def rollback
    context.order&.destroy
  end
end

class SendConfirmation
  include Interactor

  def call
    OrderMailer.confirmation(context.order).deliver_later
    Analytics.track("order_completed", order_id: context.order.id)
  end
end

# Controller usage
class OrdersController < ApplicationController
  def create
    result = CreateOrder.call(user: current_user, payment_method: params[:payment_method])

    if result.success?
      redirect_to order_path(result.order)
    else
      flash[:error] = result.error
      redirect_to cart_path
    end
  end
end

# =============================================================================
# When Callbacks ARE Appropriate
# =============================================================================

# Good: Simple data normalization
class Email < ApplicationRecord
  before_validation :normalize_address

  private

  def normalize_address
    self.address = address&.downcase&.strip
  end
end

# Good: Setting computed attributes
class LineItem < ApplicationRecord
  before_save :calculate_total

  private

  def calculate_total
    self.total = quantity * unit_price
  end
end

# Good: Generating defaults
class ApiKey < ApplicationRecord
  before_create :generate_key

  private

  def generate_key
    self.key = SecureRandom.hex(32)
    self.expires_at = 1.year.from_now
  end
end

# Good: Simple counter maintenance (though DB triggers might be better)
class Comment < ApplicationRecord
  belongs_to :post, counter_cache: true
end

# Good: Maintaining timestamps
class Document < ApplicationRecord
  before_update :track_modification

  private

  def track_modification
    self.last_modified_by = Current.user
    self.revision_count = (revision_count || 0) + 1
  end
end
