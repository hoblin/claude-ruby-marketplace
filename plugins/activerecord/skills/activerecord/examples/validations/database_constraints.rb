# ActiveRecord Database Constraints vs Model Validations Examples

# =============================================================================
# THE RACE CONDITION PROBLEM
# =============================================================================

# SCENARIO: Two requests create users with same email simultaneously
#
# Request 1: SELECT COUNT(*) FROM users WHERE email = 'alice@example.com'  → 0
# Request 2: SELECT COUNT(*) FROM users WHERE email = 'alice@example.com'  → 0
# Request 1: Validation passes, proceeds to save
# Request 2: Validation passes, proceeds to save
# Request 1: INSERT INTO users (email) VALUES ('alice@example.com')  → Success!
# Request 2: INSERT INTO users (email) VALUES ('alice@example.com')  → Success! DUPLICATE!

# =============================================================================
# THE SOLUTION: DATABASE CONSTRAINTS + MODEL VALIDATIONS
# =============================================================================

# Migration - Data integrity layer
class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :username, null: false
      t.string :encrypted_password, null: false
      t.integer :age
      t.string :role, null: false, default: "member"
      t.timestamps
    end

    # Unique indexes prevent race conditions
    add_index :users, :email, unique: true
    add_index :users, :username, unique: true

    # Check constraints for domain rules (Rails 6.1+)
    add_check_constraint :users, "age >= 0", name: "users_age_non_negative"
    add_check_constraint :users, "role IN ('admin', 'moderator', 'member')",
      name: "users_role_valid"
  end
end

# Model - User experience layer
class User < ApplicationRecord
  # Validations provide user-friendly error messages
  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :username,
    presence: true,
    uniqueness: { case_sensitive: false },
    length: { in: 3..30 },
    format: {
      with: /\A[a-z0-9_]+\z/,
      message: "only allows lowercase letters, numbers, and underscores"
    }

  validates :age,
    numericality: { greater_than_or_equal_to: 0, only_integer: true },
    allow_nil: true

  validates :role,
    inclusion: { in: %w[admin moderator member] }
end

# =============================================================================
# HANDLING DATABASE CONSTRAINT VIOLATIONS
# =============================================================================

class UsersController < ApplicationController
  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to @user, notice: "User created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique => e
    # Handle race condition - database caught a duplicate
    if e.message.include?("email")
      @user.errors.add(:email, "has already been taken")
    elsif e.message.include?("username")
      @user.errors.add(:username, "has already been taken")
    else
      @user.errors.add(:base, "A duplicate record already exists")
    end
    render :new, status: :unprocessable_entity
  end
end

# =============================================================================
# ALTERNATIVE: RESCUE IN MODEL
# =============================================================================

class User < ApplicationRecord
  # ... validations ...

  def save_with_race_condition_handling
    save
  rescue ActiveRecord::RecordNotUnique => e
    handle_duplicate_error(e)
    false
  end

  private

  def handle_duplicate_error(exception)
    if exception.message.include?("email")
      errors.add(:email, "has already been taken")
    elsif exception.message.include?("username")
      errors.add(:username, "has already been taken")
    else
      errors.add(:base, "A duplicate record already exists")
    end
  end
end

# =============================================================================
# create_or_find_by - IDEMPOTENT OPERATIONS
# =============================================================================

class ApiController < ApplicationController
  # For idempotent API endpoints where duplicates are acceptable
  def find_or_create_user
    # find_or_create_by - tries to find first, then creates
    # Still has race condition potential
    user = User.find_or_create_by(email: params[:email]) do |u|
      u.name = params[:name]
    end

    render json: user
  end

  # create_or_find_by - tries to create first, rescues if exists
  # Better for race conditions, but requires unique index
  def create_or_find_user
    user = User.create_or_find_by(email: params[:email]) do |u|
      u.name = params[:name]
    end

    render json: user
  end
end

# =============================================================================
# COMPOSITE UNIQUE CONSTRAINTS
# =============================================================================

class CreateAppliedCoupons < ActiveRecord::Migration[7.2]
  def change
    create_table :applied_coupons do |t|
      t.references :account, null: false, foreign_key: true
      t.references :coupon, null: false, foreign_key: true
      t.timestamps
    end

    # User can only apply each coupon once per account
    add_index :applied_coupons, [:account_id, :coupon_id], unique: true
  end
end

class AppliedCoupon < ApplicationRecord
  belongs_to :account
  belongs_to :coupon

  validates :coupon_id, uniqueness: { scope: :account_id }
end

class CouponsController < ApplicationController
  def apply
    @applied = AppliedCoupon.new(account: current_account, coupon: @coupon)

    if @applied.save
      render json: { success: true }
    else
      render json: { errors: @applied.errors }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    render json: { error: "Coupon already applied" }, status: :unprocessable_entity
  end
end

# =============================================================================
# FOREIGN KEY CONSTRAINTS
# =============================================================================

class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :shipping_address, foreign_key: { to_table: :addresses }
      t.timestamps
    end
  end
end

class Order < ApplicationRecord
  belongs_to :user
  belongs_to :shipping_address, class_name: "Address", optional: true

  validates :user, presence: true

  # No need to validate shipping_address existence -
  # foreign key ensures referential integrity
end

# Handling foreign key violations
class OrdersController < ApplicationController
  def create
    @order = Order.new(order_params)
    @order.save!
    redirect_to @order
  rescue ActiveRecord::InvalidForeignKey => e
    @order.errors.add(:base, "Referenced record no longer exists")
    render :new, status: :unprocessable_entity
  end
end

# =============================================================================
# CHECK CONSTRAINTS (Rails 6.1+)
# =============================================================================

class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :quantity, null: false, default: 0
      t.string :status, null: false, default: "draft"
      t.timestamps
    end

    # Ensure price is positive
    add_check_constraint :products, "price >= 0", name: "products_price_positive"

    # Ensure quantity is non-negative
    add_check_constraint :products, "quantity >= 0", name: "products_quantity_non_negative"

    # Ensure valid status
    add_check_constraint :products, "status IN ('draft', 'active', 'discontinued')",
      name: "products_status_valid"
  end
end

class Product < ApplicationRecord
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: %w[draft active discontinued] }
end

# =============================================================================
# DECISION FRAMEWORK
# =============================================================================

# Question 1: Am I preventing bad data from being written?
#   YES → Use database constraint
#
# Question 2: Am I preventing user-fixable errors?
#   YES → Use model validation

class DecisionExample < ApplicationRecord
  # Email uniqueness:
  #   Q1: Yes, duplicate emails are bad data → DB unique index
  #   Q2: Yes, user can change email → Model validation
  #   RESULT: Use BOTH

  # Price must be positive:
  #   Q1: Yes, negative prices are bad data → DB check constraint
  #   Q2: Yes, user can fix price → Model validation
  #   RESULT: Use BOTH

  # Encrypted password format:
  #   Q1: Yes, invalid format is bad data → Maybe DB constraint
  #   Q2: No, user doesn't control encrypted value → NO model validation
  #   RESULT: DB only (if needed), handle as app error

  # Bio length maximum:
  #   Q1: Debatable, depends on system → Maybe DB constraint
  #   Q2: Yes, user can shorten bio → Model validation
  #   RESULT: Model validation sufficient, DB optional
end

# =============================================================================
# WHAT DATABASE CONSTRAINTS PROTECT AGAINST
# =============================================================================

# Methods that SKIP validations (DB constraints still apply):
class BypassExamples < ApplicationRecord
  def demonstrate_bypass
    # These all skip validations:
    update_attribute(:email, "invalid")           # Skips validations
    update_column(:email, "invalid")              # Skips validations AND callbacks
    update_columns(email: "invalid", age: -1)     # Skips validations AND callbacks
    User.update_all(email: "invalid")             # Bulk update, no validations

    # Bulk inserts skip everything:
    User.insert_all([{ email: "test@example.com" }])
    User.upsert_all([{ email: "test@example.com" }])

    # delete vs destroy:
    user.delete           # Skips callbacks
    User.delete_all       # Bulk delete, no callbacks

    # Raw SQL:
    ActiveRecord::Base.connection.execute("INSERT INTO users ...")
  end
end

# Database constraints protect against ALL of these!

# =============================================================================
# NOT NULL CONSTRAINTS
# =============================================================================

class CreateAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :accounts do |t|
      # Critical fields - null: false in DB
      t.string :name, null: false
      t.string :email, null: false

      # Optional fields - allow null
      t.string :phone
      t.text :bio

      t.timestamps
    end
  end
end

class Account < ApplicationRecord
  # Match DB constraints for user-friendly errors
  validates :name, presence: true
  validates :email, presence: true

  # Optional fields - no presence validation
end

# =============================================================================
# FULL PATTERN: CRITICAL USER MODEL
# =============================================================================

# Migration
class CreateCriticalUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :critical_users do |t|
      # Required fields
      t.string :email, null: false
      t.string :username, null: false
      t.string :encrypted_password, null: false

      # Optional but constrained
      t.integer :age
      t.decimal :balance, precision: 10, scale: 2, default: 0

      # Status with valid values
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    # Unique constraints
    add_index :critical_users, :email, unique: true
    add_index :critical_users, :username, unique: true

    # Check constraints
    add_check_constraint :critical_users, "age IS NULL OR age >= 0",
      name: "critical_users_age_valid"
    add_check_constraint :critical_users, "balance >= 0",
      name: "critical_users_balance_non_negative"
    add_check_constraint :critical_users,
      "status IN ('pending', 'active', 'suspended', 'deleted')",
      name: "critical_users_status_valid"
  end
end

# Model
class CriticalUser < ApplicationRecord
  # User-facing validations with friendly messages
  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false, message: "is already registered" },
    format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email" }

  validates :username,
    presence: true,
    uniqueness: { case_sensitive: false },
    length: { in: 3..30, message: "must be between 3 and 30 characters" },
    format: {
      with: /\A[a-z0-9_]+\z/,
      message: "can only contain lowercase letters, numbers, and underscores"
    }

  validates :age,
    numericality: {
      greater_than_or_equal_to: 0,
      only_integer: true,
      message: "must be a positive number"
    },
    allow_nil: true

  validates :balance,
    numericality: {
      greater_than_or_equal_to: 0,
      message: "cannot be negative"
    }

  validates :status,
    inclusion: {
      in: %w[pending active suspended deleted],
      message: "is not a valid status"
    }

  # Internal validation (not user-controlled)
  validates :encrypted_password, presence: true

  # Handle race conditions gracefully
  def self.create_safely(attributes)
    create!(attributes)
  rescue ActiveRecord::RecordNotUnique => e
    user = new(attributes)
    if e.message.include?("email")
      user.errors.add(:email, "is already registered")
    elsif e.message.include?("username")
      user.errors.add(:username, "is already taken")
    end
    user
  end
end
