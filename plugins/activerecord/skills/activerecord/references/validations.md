# ActiveRecord Validations Reference

Comprehensive reference for model validations: built-in validators, conditional validations, custom validators, validation contexts, and the critical distinction between model validations and database constraints.

## Built-in Validators

### Presence

```ruby
validates :name, presence: true
validates :title, :body, presence: true  # Multiple attributes
```

**Boolean Fields Gotcha**: `false.blank? == true`, so presence validation fails on `false`:

```ruby
# WRONG - fails when field is false
validates :active, presence: true

# CORRECT - use inclusion for booleans
validates :active, inclusion: { in: [true, false] }
```

### Uniqueness

```ruby
validates :email, uniqueness: true
validates :username, uniqueness: { case_sensitive: false }
validates :code, uniqueness: { scope: :account_id }  # Per-account uniqueness
validates :slug, uniqueness: { scope: [:category_id, :year] }  # Composite scope
```

**Critical**: Always pair with database unique index. See [Uniqueness Race Conditions](#uniqueness-race-conditions).

### Format

```ruby
validates :legacy_code, format: { with: /\A[A-Z]{3}-\d{4}\z/ }
validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
```

**Security Warning**: Use `\A` and `\z` for string boundaries, NOT `^` and `$`:

```ruby
# WRONG - ^ and $ match line boundaries, vulnerable to injection
validates :code, format: { with: /^[a-z]+$/ }

# CORRECT - \A and \z match string boundaries
validates :code, format: { with: /\A[a-z]+\z/ }

# If multiline is intentional, be explicit
validates :bio, format: { with: /^[a-z]+$/, multiline: true }
```

### Length

```ruby
validates :password, length: { minimum: 8 }
validates :bio, length: { maximum: 500 }
validates :pin, length: { is: 6 }
validates :username, length: { in: 3..20 }  # Range
validates :content, length: { minimum: 10, too_short: "must have at least %{count} characters" }
```

**Note**: `:maximum` alone allows nil by default (unlike `:minimum` or `:is`).

### Numericality

```ruby
validates :age, numericality: true
validates :quantity, numericality: { only_integer: true }
validates :price, numericality: { greater_than: 0 }
validates :age, numericality: { greater_than_or_equal_to: 18, less_than: 150 }
validates :discount, numericality: { in: 0..100 }
```

| Option | Description |
|--------|-------------|
| `only_integer` | Must be integer (uses regex) |
| `only_numeric` | Must be Numeric instance (no string parsing) |
| `greater_than` | > value |
| `greater_than_or_equal_to` | >= value |
| `less_than` | < value |
| `less_than_or_equal_to` | <= value |
| `equal_to` | == value |
| `in` | Within range |
| `other_than` | != value |
| `odd` / `even` | Must be odd/even |

### Inclusion / Exclusion

```ruby
validates :status, inclusion: { in: %w[draft published archived] }
validates :role, inclusion: { in: %w[admin user guest], message: "%{value} is not valid" }
validates :legacy_code, exclusion: { in: %w[RESERVED SYSTEM] }
```

**Performance**: Rails uses `cover?` for numeric/time ranges (fast), `include?` for others.

### Confirmation

```ruby
validates :password, confirmation: true
validates :password_confirmation, presence: true, if: :password_changed?  # Required!
```

**Note**: Confirmation only validates if `_confirmation` field is non-nil. Add explicit presence check.

### Acceptance

```ruby
validates :terms_of_service, acceptance: true
validates :eula, acceptance: { accept: ["yes", "1", true] }
```

Default accepts `"1"` (from HTML checkbox) and `true`.

### Associated

```ruby
validates :author, presence: true  # Ensure association exists
validates_associated :chapters     # Validate associated records too
```

**Warning**: Never use `validates_associated` on both ends of an association - causes infinite recursion.

### Comparison

```ruby
validates :end_date, comparison: { greater_than: :start_date }
validates :password, comparison: { other_than: :username }
```

## Conditional Validations

### Using :if and :unless

```ruby
# Symbol (method name) - preferred for readability
validates :card_number, presence: true, if: :paid_with_card?

# Proc/Lambda - for one-liners
validates :password, confirmation: true, unless: -> { password.blank? }

# Multiple conditions (all must be true)
validates :discount, presence: true,
  if: [:premium_user?, :promotional_period?]

# Array with mixed types
validates :special_field, presence: true,
  if: [:admin?, -> { feature_enabled?(:beta) }]
```

### Grouping with with_options

```ruby
with_options if: :is_admin? do |admin|
  admin.validates :password, length: { minimum: 10 }
  admin.validates :email, format: { with: /@company\.com\z/ }
end
```

### Dynamic allow_nil / allow_blank

```ruby
validates :nickname, length: { minimum: 3 },
  allow_blank: -> { signup_step < 3 }
```

## Custom Validators

### Inline Validation Method

```ruby
class Invoice < ApplicationRecord
  validate :total_matches_line_items

  private

  def total_matches_line_items
    calculated = line_items.sum(&:amount)
    return if total == calculated

    errors.add(:total, "doesn't match line items (expected #{calculated})")
  end
end
```

### EachValidator Class (Reusable)

```ruby
# app/validators/email_validator.rb
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank? && options[:allow_blank]

    unless URI::MailTo::EMAIL_REGEXP.match?(value)
      record.errors.add(attribute, options[:message] || "is not a valid email")
    end
  end
end

# Usage in model
class User < ApplicationRecord
  validates :email, email: true
  validates :backup_email, email: { allow_blank: true }
end
```

### Full Validator Class (Record-Level)

```ruby
# app/validators/date_range_validator.rb
class DateRangeValidator < ActiveModel::Validator
  def validate(record)
    return unless record.start_date && record.end_date

    if record.end_date <= record.start_date
      record.errors.add(:end_date, "must be after start date")
    end
  end
end

# Usage
class Event < ApplicationRecord
  validates_with DateRangeValidator
end
```

## Validation Contexts

### Built-in Contexts

```ruby
validates :email, uniqueness: true, on: :create  # Only on new records
validates :reason, presence: true, on: :update   # Only on updates
validates :name, presence: true                  # Always (no :on option)
```

### Custom Contexts

```ruby
class Article < ApplicationRecord
  validates :title, presence: true
  validates :body, presence: true
  validates :published_at, presence: true, on: :publish
  validates :reviewer_id, presence: true, on: :publish

  def publish!
    self.published_at = Time.current
    save!(context: :publish)
  end
end

# Usage
article.valid?           # Checks title, body only
article.valid?(:publish) # Checks title, body, published_at, reviewer_id
article.publish!         # Runs :publish context validations
```

### Multiple Contexts

```ruby
validates :secret_key, presence: true, on: [:create, :regenerate]
```

### Context Behavior Matrix

| Validation | `.valid?` | `.valid?(:create)` | `.valid?(:update)` | `.valid?(:custom)` |
|------------|-----------|--------------------|--------------------|---------------------|
| No `on:` | Runs | Runs | Runs | Runs |
| `on: :create` | Runs | Runs | Skips | Skips |
| `on: :update` | Runs | Skips | Runs | Skips |
| `on: :custom` | Runs | Skips | Skips | Runs |

**Note**: Validations without `on:` run in ALL contexts.

## Validation vs Database Constraint

### Decision Framework

Ask two questions:

1. **"Am I preventing bad data from being written?"** → Use database constraint
2. **"Am I preventing user-fixable errors?"** → Use model validation

**Best practice**: Use both for critical fields.

### Comparison

| Aspect | Model Validation | Database Constraint |
|--------|------------------|---------------------|
| User-friendly errors | Yes | Cryptic errors |
| Race condition safe | No | Yes |
| Can be bypassed | Yes (`update_all`, `insert_all`) | No |
| Database agnostic | Yes | May vary |
| Easy to test | Yes | Harder |
| Data integrity guarantee | Weak | Strong |

### Implementation Pattern

```ruby
# Migration - database constraints (data integrity)
class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :username, null: false
      t.integer :age
      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :username, unique: true
    add_check_constraint :users, "age >= 18", name: "users_age_check"
  end
end

# Model - validations (user experience)
class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, uniqueness: { case_sensitive: false },
            length: { in: 3..20 }
  validates :age, numericality: { greater_than_or_equal_to: 18 }, allow_nil: true
end
```

### When to Use Database Constraints

- **Always** for uniqueness (race conditions)
- **Always** for NOT NULL on critical fields
- **Always** for foreign keys (referential integrity)
- When data can be written outside Rails (other apps, raw SQL, imports)
- When validation bypass methods are used (`update_all`, `insert_all`, etc.)

### When Model Validation Is Enough

- Format validations (regex patterns)
- Complex business logic validations
- Validations that depend on other objects
- Validations needing user-friendly error messages

## Uniqueness Race Conditions

### The Problem

```
Request 1: Check DB → "alice@example.com" doesn't exist → Continue
Request 2: Check DB → "alice@example.com" doesn't exist → Continue
Request 1: INSERT INTO users (email) VALUES ('alice@example.com')  ✓
Request 2: INSERT INTO users (email) VALUES ('alice@example.com')  ✓ DUPLICATE!
```

### The Solution

```ruby
# Migration - REQUIRED
add_index :users, :email, unique: true

# Model - for user-friendly errors
validates :email, uniqueness: true
```

### Handling the Exception

```ruby
def create
  @user = User.new(user_params)
  @user.save!
rescue ActiveRecord::RecordNotUnique
  @user.errors.add(:email, "has already been taken")
  render :new, status: :unprocessable_entity
end
```

### Alternative: find_or_create_by

```ruby
# Idempotent - won't create duplicates
user = User.find_or_create_by(email: params[:email]) do |u|
  u.name = params[:name]
end

# With race condition handling
user = User.create_or_find_by(email: params[:email]) do |u|
  u.name = params[:name]
end
```

## Strict Validations

Raise exception instead of adding error:

```ruby
validates :api_key, presence: true, strict: true
# Raises ActiveModel::StrictValidationFailed

validates :token, length: { is: 32 }, strict: TokenLengthException
# Raises TokenLengthException

validates! :internal_id, presence: true  # Same as strict: true
```

Use for programmer errors (not user input errors).

## Anti-Patterns

### 1. Uniqueness Without Database Index

```ruby
# WRONG - race conditions possible
validates :email, uniqueness: true

# CORRECT - add unique index in migration
add_index :users, :email, unique: true
validates :email, uniqueness: true
```

### 2. Presence on Boolean Fields

```ruby
# WRONG - false.blank? == true
validates :active, presence: true

# CORRECT
validates :active, inclusion: { in: [true, false] }
```

### 3. Format With ^ and $

```ruby
# WRONG - vulnerable to multiline injection
validates :code, format: { with: /^[a-z]+$/ }

# CORRECT
validates :code, format: { with: /\A[a-z]+\z/ }
```

### 4. Bidirectional validates_associated

```ruby
# WRONG - infinite loop
class Author < ApplicationRecord
  has_many :books
  validates_associated :books
end

class Book < ApplicationRecord
  belongs_to :author
  validates_associated :author  # Don't do this!
end

# CORRECT - validate in one direction only
class Author < ApplicationRecord
  has_many :books
  validates_associated :books
end

class Book < ApplicationRecord
  belongs_to :author
  validates :author, presence: true
end
```

### 5. Confirmation Without Presence

```ruby
# WRONG - nil confirmation always passes
validates :password, confirmation: true

# CORRECT
validates :password, confirmation: true
validates :password_confirmation, presence: true, if: :password_changed?
```

### 6. Overusing Conditionals

```ruby
# WRONG - hard to follow
validates :field1, presence: true, if: :condition_a?
validates :field1, length: { minimum: 5 }, if: :condition_b?
validates :field2, presence: true, if: :condition_a?
validates :field2, format: { with: /.../ }, unless: :condition_c?

# BETTER - use validation contexts
validates :field1, :field2, presence: true, on: :step_one
validates :field1, length: { minimum: 5 }, on: :step_two

# Or use form objects for complex multi-step forms
```

### 7. Validating Auto-Generated Fields

```ruby
# WRONG - validates internal implementation
validates :encrypted_password, presence: true
validates :uuid, format: { with: UUID_REGEX }

# CORRECT - validate user-provided input
validates :password, presence: true, on: :create
# Let the model generate uuid internally
```

## Validation Callbacks

### before_validation

```ruby
class User < ApplicationRecord
  before_validation :normalize_email

  private

  def normalize_email
    self.email = email&.downcase&.strip
  end
end
```

**Note**: `before_validation` can throw `:abort` to halt, but `validate` methods cannot halt the chain.

### Halting Validation

```ruby
before_validation :check_preconditions

private

def check_preconditions
  throw(:abort) if skip_validation_flag
end
```

## Error Messages

### Customizing Messages

```ruby
validates :name, presence: { message: "is required" }
validates :age, numericality: { message: "must be a number" }
validates :size, inclusion: { in: %w[S M L], message: "%{value} is not a valid size" }
```

### Available Interpolations

| Variable | Description |
|----------|-------------|
| `%{value}` | Current attribute value |
| `%{attribute}` | Attribute name |
| `%{model}` | Model name |
| `%{count}` | Length/size constraint |

### errors API

```ruby
user.valid?                    # Run validations, return boolean
user.invalid?                  # Inverse of valid?
user.errors                    # ActiveModel::Errors object
user.errors[:email]            # Array of errors for :email
user.errors.full_messages      # ["Email can't be blank", "Email is invalid"]
user.errors.add(:base, "...")  # Add error not tied to attribute
user.errors.clear              # Remove all errors
```

## Performance Tips

### Avoid N+1 in Uniqueness

```ruby
# Potentially slow - queries DB on every update
validates :email, uniqueness: true

# Better - only check on create if email can't change
validates :email, uniqueness: true, on: :create
```

### Use Scoped Uniqueness

```ruby
# Scoped queries are faster with proper indexes
validates :slug, uniqueness: { scope: :account_id }

# Migration
add_index :articles, [:account_id, :slug], unique: true
```

### Prefer Database for Heavy Validations

```ruby
# Complex validation in Ruby - runs in app
validate :complex_business_rule

# Better for simple checks - use DB constraints
add_check_constraint :orders, "total >= 0", name: "orders_total_positive"
```
