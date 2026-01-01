# ActiveRecord Built-in Validators Examples

# =============================================================================
# PRESENCE
# =============================================================================

class User < ApplicationRecord
  validates :name, presence: true
  validates :email, :username, presence: true  # Multiple attributes
end

# Boolean fields - presence doesn't work correctly!
class Feature < ApplicationRecord
  # WRONG: false.blank? == true, so this fails for false values
  # validates :enabled, presence: true

  # CORRECT: Use inclusion for boolean fields
  validates :enabled, inclusion: { in: [true, false] }
end

# =============================================================================
# UNIQUENESS
# =============================================================================

class Account < ApplicationRecord
  # Basic uniqueness
  validates :email, uniqueness: true

  # Case-insensitive
  validates :username, uniqueness: { case_sensitive: false }

  # Scoped to another column (per-organization uniqueness)
  validates :employee_id, uniqueness: { scope: :organization_id }

  # Composite scope
  validates :slug, uniqueness: { scope: [:category_id, :year] }

  # With conditions
  validates :primary_email, uniqueness: true, if: :primary?
end

# IMPORTANT: Always add database unique index for race condition safety
# add_index :accounts, :email, unique: true
# add_index :accounts, [:organization_id, :employee_id], unique: true

# =============================================================================
# FORMAT
# =============================================================================

class Product < ApplicationRecord
  # Basic format with regex
  validates :sku, format: { with: /\A[A-Z]{3}-\d{4}\z/ }

  # Email format using Ruby's built-in regex
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }

  # With custom message
  validates :code, format: {
    with: /\A[a-z0-9_]+\z/,
    message: "only allows lowercase letters, numbers, and underscores"
  }

  # SECURITY: Always use \A and \z, not ^ and $
  # ^ and $ match line boundaries, vulnerable to injection:
  #   "valid\nmalicious" would pass /^valid$/
  # \A and \z match string boundaries, safe:
  #   "valid\nmalicious" would NOT pass /\Avalid\z/
end

# =============================================================================
# LENGTH
# =============================================================================

class Post < ApplicationRecord
  validates :title, length: { minimum: 5 }
  validates :excerpt, length: { maximum: 200 }
  validates :access_code, length: { is: 8 }
  validates :username, length: { in: 3..20 }

  # With custom messages
  validates :password, length: {
    minimum: 8,
    maximum: 72,
    too_short: "must have at least %{count} characters",
    too_long: "must have at most %{count} characters"
  }

  # Note: :maximum alone allows nil by default
  validates :bio, length: { maximum: 500 }  # nil is valid
  validates :name, length: { minimum: 1 }   # nil is NOT valid
end

# =============================================================================
# NUMERICALITY
# =============================================================================

class Order < ApplicationRecord
  # Basic numeric validation
  validates :total, numericality: true

  # Integer only
  validates :quantity, numericality: { only_integer: true }

  # Comparison operators
  validates :price, numericality: { greater_than: 0 }
  validates :discount_percent, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }

  # Range
  validates :rating, numericality: { in: 1..5 }

  # Other than
  validates :priority, numericality: { other_than: 0 }

  # Odd/even
  validates :pair_count, numericality: { even: true }

  # Allowing nil (for optional fields)
  validates :optional_score, numericality: { greater_than: 0 }, allow_nil: true
end

# =============================================================================
# INCLUSION / EXCLUSION
# =============================================================================

class Article < ApplicationRecord
  # Inclusion - value must be in list
  validates :status, inclusion: { in: %w[draft published archived] }

  # With custom message
  validates :size, inclusion: {
    in: %w[S M L XL],
    message: "%{value} is not a valid size"
  }

  # Using proc for dynamic values
  validates :category, inclusion: {
    in: -> { Category.active.pluck(:name) }
  }

  # Exclusion - value must NOT be in list
  validates :subdomain, exclusion: {
    in: %w[www admin api],
    message: "%{value} is reserved"
  }
end

# =============================================================================
# CONFIRMATION
# =============================================================================

class Registration < ApplicationRecord
  # Adds virtual password_confirmation attribute
  validates :password, confirmation: true

  # IMPORTANT: Confirmation field is optional by default!
  # Add presence validation if confirmation is required
  validates :password_confirmation, presence: true, if: :password_changed?

  # For email confirmation
  validates :email, confirmation: true
  validates :email_confirmation, presence: true, on: :create
end

# =============================================================================
# ACCEPTANCE
# =============================================================================

class Signup < ApplicationRecord
  # Virtual attribute, validates checkbox was checked
  validates :terms_of_service, acceptance: true

  # Custom accepted values
  validates :eula, acceptance: { accept: ["yes", "1", true] }

  # With message
  validates :age_verification, acceptance: {
    message: "You must confirm you are 18 or older"
  }
end

# =============================================================================
# COMPARISON
# =============================================================================

class Event < ApplicationRecord
  validates :end_date, comparison: { greater_than: :start_date }
  validates :max_attendees, comparison: { greater_than_or_equal_to: :min_attendees }
end

class User < ApplicationRecord
  validates :password, comparison: { other_than: :username }
end

# =============================================================================
# ASSOCIATED
# =============================================================================

class Author < ApplicationRecord
  has_many :books
  validates_associated :books  # Validates all books when saving author
end

class Book < ApplicationRecord
  belongs_to :author
  validates :author, presence: true  # Ensure association exists

  # WARNING: Do NOT add validates_associated :author here!
  # Bidirectional validates_associated causes infinite recursion
end

# =============================================================================
# COMBINED VALIDATIONS
# =============================================================================

class User < ApplicationRecord
  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP },
    length: { maximum: 255 }

  validates :password,
    presence: true,
    length: { minimum: 8, maximum: 72 },
    confirmation: true,
    on: :create

  validates :password_confirmation,
    presence: true,
    if: :password_required?

  validates :age,
    numericality: { greater_than_or_equal_to: 13, only_integer: true },
    allow_nil: true

  validates :username,
    presence: true,
    uniqueness: { case_sensitive: false },
    length: { in: 3..30 },
    format: {
      with: /\A[a-z0-9_]+\z/,
      message: "only allows lowercase letters, numbers, and underscores"
    }

  private

  def password_required?
    new_record? || password.present?
  end
end

# =============================================================================
# COMMON OPTIONS
# =============================================================================

class Item < ApplicationRecord
  # allow_nil - skip validation if value is nil
  validates :optional_code, format: { with: /\A[A-Z]+\z/ }, allow_nil: true

  # allow_blank - skip validation if value is blank (nil, "", " ")
  validates :notes, length: { minimum: 10 }, allow_blank: true

  # on - specify validation context
  validates :publish_date, presence: true, on: :publish

  # if/unless - conditional validation
  validates :reason, presence: true, if: :requires_reason?

  # message - custom error message
  validates :quantity, numericality: {
    greater_than: 0,
    message: "must be positive"
  }
end
