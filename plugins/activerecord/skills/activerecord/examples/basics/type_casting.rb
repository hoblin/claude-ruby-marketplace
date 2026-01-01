# ActiveRecord Type Casting and Serialization Examples

# =============================================================================
# ATTRIBUTE API
# =============================================================================

class Product < ApplicationRecord
  # Override database-inferred types
  attribute :price, :decimal, precision: 8, scale: 2
  attribute :quantity, :integer, default: 0
  attribute :active, :boolean, default: true

  # JSON attributes
  attribute :metadata, :json, default: {}

  # Date/time with defaults
  attribute :published_on, :date
  attribute :sale_ends_at, :datetime
end

# Usage
product = Product.new
product.price = "19.99"       # Cast to BigDecimal
product.quantity = "5"        # Cast to Integer
product.active = "yes"        # Cast to true
product.metadata = { foo: 1 } # Stored as JSON

# =============================================================================
# CUSTOM TYPES
# =============================================================================

# Money stored as cents in database
class MoneyType < ActiveRecord::Type::Value
  def cast(value)
    return nil if value.blank?
    case value
    when Money then value
    when Numeric then Money.new(value * 100)
    when String then Money.new(value.to_d * 100)
    end
  end

  def deserialize(value)
    return nil if value.nil?
    Money.new(value.to_i)
  end

  def serialize(value)
    return nil if value.nil?
    value.cents
  end
end

# Register globally
ActiveRecord::Type.register(:money, MoneyType)

# Use in model
class Invoice < ApplicationRecord
  attribute :total, :money
  attribute :tax, :money
end

# =============================================================================
# VALUE OBJECT TYPE
# =============================================================================

# Email value object
class EmailAddress
  attr_reader :address

  def initialize(address)
    @address = address.to_s.downcase.strip
  end

  def domain
    address.split("@").last
  end

  def to_s
    address
  end

  def ==(other)
    address == other.to_s
  end
end

class EmailType < ActiveRecord::Type::Value
  def cast(value)
    return nil if value.blank?
    EmailAddress.new(value)
  end

  def serialize(value)
    value&.to_s
  end
end

ActiveRecord::Type.register(:email, EmailType)

class User < ApplicationRecord
  attribute :email, :email
end

# Usage
user = User.new(email: " ALICE@Example.COM ")
user.email.address  # => "alice@example.com"
user.email.domain   # => "example.com"

# =============================================================================
# SERIALIZE (Legacy - for text columns)
# =============================================================================

class Setting < ApplicationRecord
  # Rails 7.2+ syntax (keyword argument)
  serialize :preferences, coder: JSON, type: Hash
  serialize :tags, coder: YAML, type: Array

  # With type enforcement
  serialize :config, coder: JSON, type: Hash
  # Raises ActiveRecord::SerializationTypeMismatch for non-Hash
end

# Usage
setting = Setting.new
setting.preferences = { theme: "dark", language: "en" }
setting.tags = ["important", "featured"]
setting.save

# Database stores: '{"theme":"dark","language":"en"}'

# =============================================================================
# STORE ACCESSOR (Recommended for JSON columns)
# =============================================================================

class User < ApplicationRecord
  # For serialized text column
  store :settings, accessors: [:theme, :language], coder: JSON

  # For native JSON/JSONB column (PostgreSQL)
  store_accessor :preferences, :notifications, :digest_frequency

  # With prefix to avoid conflicts
  store_accessor :preferences, :email_enabled, prefix: :pref
  # Creates: pref_email_enabled, pref_email_enabled=
end

# Usage
user = User.new
user.theme = "dark"
user.notifications = true
user.pref_email_enabled = true

user.settings  # => {"theme" => "dark"}

# Dirty tracking works
user.theme = "light"
user.theme_changed?  # => true

# =============================================================================
# STORE WITH DEFAULTS
# =============================================================================

class Profile < ApplicationRecord
  store_accessor :settings, :receive_newsletter, :locale

  after_initialize :set_defaults

  private

  def set_defaults
    return unless new_record?
    self.receive_newsletter ||= true
    self.locale ||= "en"
  end
end

# =============================================================================
# QUERYING JSON COLUMNS (PostgreSQL)
# =============================================================================

# Direct JSON query (PostgreSQL)
User.where("preferences->>'notifications' = ?", "true")

# Using store_accessor doesn't help with queries
# Must use raw JSON operators

# =============================================================================
# ENUM ATTRIBUTES
# =============================================================================

class Order < ApplicationRecord
  enum :status, {
    pending: 0,
    processing: 1,
    shipped: 2,
    delivered: 3,
    cancelled: 4
  }

  # With prefix
  enum :payment_status, {
    unpaid: 0,
    paid: 1,
    refunded: 2
  }, prefix: true
end

# Usage
order = Order.new
order.status = :pending
order.pending?         # => true
order.shipped!         # Updates and saves

# Queries
Order.pending          # Scope for pending orders
Order.where.not(status: :cancelled)

# With prefix
order.payment_status_paid!
order.payment_status_unpaid?

# =============================================================================
# BEFORE TYPE CAST
# =============================================================================

user = User.find(1)

# Get value before type casting
user.created_at                    # => Mon, 01 Jan 2024 00:00:00 UTC
user.created_at_before_type_cast   # => "2024-01-01 00:00:00"

# All attributes before type cast
user.attributes_before_type_cast
# => {"id" => "1", "name" => "Alice", "created_at" => "2024-01-01 00:00:00"}

# =============================================================================
# TYPE COERCION EDGE CASES
# =============================================================================

class Post < ApplicationRecord
  # Boolean coercion
  attribute :published, :boolean
end

post = Post.new
post.published = "1"       # => true
post.published = "0"       # => false
post.published = "true"    # => true
post.published = "false"   # => false
post.published = ""        # => nil
post.published = "yes"     # => true (in Rails 7+)

# Integer coercion
class Item < ApplicationRecord
  attribute :quantity, :integer
end

item = Item.new
item.quantity = "10"       # => 10
item.quantity = "10.5"     # => 10 (truncated)
item.quantity = "abc"      # => 0

# =============================================================================
# ENCRYPTED ATTRIBUTES (Rails 7+)
# =============================================================================

class User < ApplicationRecord
  encrypts :ssn
  encrypts :email, deterministic: true  # Allows querying

  # With custom key
  encrypts :medical_notes, key: :medical_encryption_key
end

# Usage
user = User.create(ssn: "123-45-6789")
# Database stores encrypted value

User.find_by(email: "alice@example.com")  # Works with deterministic: true

# =============================================================================
# COMPOSED_OF (Value Objects without Custom Types)
# =============================================================================

class Customer < ApplicationRecord
  composed_of :address,
    class_name: "Address",
    mapping: [
      [:address_street, :street],
      [:address_city, :city],
      [:address_zip, :zip]
    ]
end

class Address
  attr_reader :street, :city, :zip

  def initialize(street:, city:, zip:)
    @street = street
    @city = city
    @zip = zip
  end

  def full_address
    "#{street}, #{city} #{zip}"
  end
end

# Usage
customer = Customer.new
customer.address = Address.new(
  street: "123 Main St",
  city: "Anytown",
  zip: "12345"
)
customer.address.full_address  # => "123 Main St, Anytown 12345"
