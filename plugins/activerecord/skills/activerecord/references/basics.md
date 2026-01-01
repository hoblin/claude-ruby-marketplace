# ActiveRecord Basics Reference

Comprehensive reference for ActiveRecord conventions, CRUD operations, attribute handling, and inheritance patterns.

## Naming Conventions

ActiveRecord uses "convention over configuration" - follow these patterns and Rails works automatically.

### Models and Tables

| Ruby Class | Database Table | Notes |
|------------|----------------|-------|
| `User` | `users` | Automatic pluralization |
| `Person` | `people` | Irregular plurals handled |
| `BookClub` | `book_clubs` | CamelCase → snake_case |
| `Admin::User` | `admin_users` | Namespace becomes prefix |

Override when needed:

```ruby
class Product < ApplicationRecord
  self.table_name = "inventory_items"
end
```

### Primary Keys

Default: `id` column (bigint for PostgreSQL/MySQL, integer for SQLite).

```ruby
class Product < ApplicationRecord
  self.primary_key = "product_id"  # Override default
end
```

### Foreign Keys

Pattern: `singularized_table_name_id`

| Association | Column Name | References |
|-------------|-------------|------------|
| `belongs_to :user` | `user_id` | `users.id` |
| `belongs_to :category` | `category_id` | `categories.id` |
| `belongs_to :admin_user` | `admin_user_id` | `admin_users.id` |

Override when needed:

```ruby
class Order < ApplicationRecord
  belongs_to :customer, class_name: "User", foreign_key: "purchaser_id"
end
```

### Magic Columns

These optional columns add automatic functionality:

| Column | Type | Behavior |
|--------|------|----------|
| `created_at` | datetime | Set once on record creation |
| `updated_at` | datetime | Updated on creation and every update |
| `lock_version` | integer | Enables optimistic locking |
| `type` | string | Single Table Inheritance discriminator |

## CRUD Operations

### Create

**`new` + `save`** - Two-step creation:

```ruby
user = User.new
user.name = "Alice"
user.email = "alice@example.com"
user.save  # Returns true/false
```

**`create`** - One-step creation:

```ruby
user = User.create(name: "Alice", email: "alice@example.com")
# Returns user object (check user.persisted? or user.errors)
```

**Bang methods** - Raise on failure:

```ruby
user = User.create!(name: "Alice")  # Raises ActiveRecord::RecordInvalid
user.save!                           # Raises ActiveRecord::RecordInvalid
```

**Bulk insert** (skips validations and callbacks):

```ruby
User.insert_all([
  { name: "Alice", email: "alice@example.com" },
  { name: "Bob", email: "bob@example.com" }
])
```

### Read

| Method | Returns | Not Found |
|--------|---------|-----------|
| `find(id)` | Record or raises | `RecordNotFound` (404) |
| `find_by(attr: val)` | Record or `nil` | `nil` |
| `where(conditions)` | `Relation` | Empty relation `[]` |

```ruby
# find - use when record MUST exist (controllers)
user = User.find(params[:id])

# find_by - use when missing record is expected
user = User.find_by(email: params[:email])
return "Not found" if user.nil?

# where - chainable queries
User.where(active: true).order(:name).limit(10)
```

### Update

| Method | Validations | Callbacks | Updates `updated_at` |
|--------|------------|-----------|---------------------|
| `update` | Yes | Yes | Yes |
| `update!` | Yes (raises) | Yes | Yes |
| `update_attribute` | No | Yes | Yes |
| `update_column` | No | No | No |
| `update_columns` | No | No | No |

```ruby
# Standard update (recommended)
user.update(name: "Bob")
user.update!(name: "Bob")  # Raises on validation failure

# Skip validations (use sparingly)
user.update_attribute(:verified, true)

# Direct SQL (dangerous - skips everything)
user.update_column(:login_count, 5)
user.update_columns(login_count: 5, last_login: Time.current)
```

### Delete vs Destroy

| Method | Callbacks | Dependent Associations | Returns |
|--------|-----------|------------------------|---------|
| `destroy` | Yes | Handled | Frozen object |
| `delete` | No | Ignored | Frozen object |

```ruby
# destroy - triggers callbacks and dependent associations
user.destroy
# Runs: before_destroy, destroy dependent children, after_destroy

# delete - direct SQL DELETE
user.delete
# Only runs: DELETE FROM users WHERE id = 123

# Bulk operations
User.where(status: :inactive).destroy_all  # With callbacks
User.where(status: :inactive).delete_all   # Without callbacks
```

**Best Practice**: Use `destroy` unless you need raw performance for bulk operations.

### Find or Create Patterns

```ruby
# Find or create by specific attributes
user = User.find_or_create_by(email: "alice@example.com")

# With block for additional attributes
user = User.find_or_create_by(email: "alice@example.com") do |u|
  u.name = "Alice"
  u.role = :member
end

# find_or_initialize_by - doesn't save
user = User.find_or_initialize_by(email: "alice@example.com")
user.save if user.new_record?

# create_or_find_by - handles race conditions (unique constraint required)
user = User.create_or_find_by(email: "alice@example.com")
```

## Dirty Tracking

Track attribute changes before and after saves.

### Before Save (Pending Changes)

```ruby
user.name = "Bob"

user.changed?                    # => true
user.name_changed?               # => true
user.name_was                    # => "Alice" (original value)
user.name_change                 # => ["Alice", "Bob"]
user.changes                     # => {"name" => ["Alice", "Bob"]}

# Check what will be saved
user.will_save_change_to_name?   # => true
user.changes_to_save             # => {"name" => ["Alice", "Bob"]}
user.name_in_database            # => "Alice"
```

### After Save (Previous Changes)

```ruby
user.save

user.saved_change_to_name?       # => true
user.saved_change_to_name        # => ["Alice", "Bob"]
user.name_before_last_save       # => "Alice"
user.name_previously_was         # => "Alice"
user.previous_changes            # => {"name" => ["Alice", "Bob"]}
```

### Reverting Changes

```ruby
user.name = "Bob"
user.restore_name!        # Reverts to original
user.name                 # => "Alice"

user.restore_attributes   # Reverts all changes
```

### Using in Callbacks

```ruby
class User < ApplicationRecord
  after_save :notify_if_email_changed

  private

  def notify_if_email_changed
    if saved_change_to_email?
      UserMailer.email_changed(self, email_before_last_save).deliver_later
    end
  end
end
```

### Partial Updates

By default, Rails only sends changed attributes in UPDATE queries:

```ruby
# With partial_updates enabled (default)
user.name = "Bob"
user.save
# SQL: UPDATE users SET name = 'Bob', updated_at = '...' WHERE id = 1

# Disable partial updates (sends all attributes)
ActiveRecord::Base.partial_updates = false
```

## Type Casting and Serialization

### Attribute API

Define or override attribute types:

```ruby
class Product < ApplicationRecord
  attribute :price, :decimal, precision: 8, scale: 2
  attribute :metadata, :json
  attribute :published_on, :date
  attribute :active, :boolean, default: true
end
```

Built-in types: `:boolean`, `:date`, `:datetime`, `:decimal`, `:float`, `:integer`, `:string`, `:text`, `:time`, `:json`

### Custom Types

```ruby
class MoneyType < ActiveRecord::Type::Value
  def cast(value)
    return nil if value.blank?
    BigDecimal(value.to_s.gsub(/[^\d.]/, ''))
  end

  def serialize(value)
    value&.to_s
  end
end

ActiveRecord::Type.register(:money, MoneyType)

class Product < ApplicationRecord
  attribute :price, :money
end
```

### Serialize (Legacy)

Store Ruby objects in text columns:

```ruby
class User < ApplicationRecord
  # Rails 7.2+ syntax (coder as keyword)
  serialize :preferences, coder: JSON, type: Hash
  serialize :tags, coder: YAML, type: Array
end
```

### Store Accessor

Key-value storage with accessors:

```ruby
class User < ApplicationRecord
  # For serialized text column
  store :settings, accessors: [:color, :language], coder: JSON

  # For native JSON column (no serialization overhead)
  store_accessor :preferences, :theme, :notifications
end

user.color = "blue"
user.theme = "dark"
user.settings  # => {"color" => "blue"}
```

**Best Practice**: Use native JSON columns (`jsonb` in PostgreSQL) with `store_accessor` instead of `serialize` for better performance and queryability.

### Accessing Raw Values

```ruby
user.created_at                    # => Mon, 01 Jan 2024 00:00:00 UTC
user.created_at_before_type_cast   # => "2024-01-01 00:00:00"
user.read_attribute_before_type_cast(:created_at)
```

## Single Table Inheritance (STI)

Store multiple model types in one table using a `type` column.

### Setup

```ruby
# Migration
class CreateVehicles < ActiveRecord::Migration[7.2]
  def change
    create_table :vehicles do |t|
      t.string :type       # Required for STI
      t.string :make
      t.string :model
      t.integer :wheels
      t.float :wing_span
      t.timestamps
    end
  end
end

# Models
class Vehicle < ApplicationRecord; end
class Car < Vehicle; end
class Truck < Vehicle; end
class Airplane < Vehicle; end
```

### Usage

```ruby
car = Car.create(make: "Toyota", model: "Camry", wheels: 4)
car.type  # => "Car"

Car.all       # SELECT * FROM vehicles WHERE type = 'Car'
Vehicle.all   # SELECT * FROM vehicles (all types)
```

### When to Use STI

| Use STI When | Avoid STI When |
|--------------|----------------|
| Subclasses share 80%+ attributes | Subclasses have divergent attributes |
| 2-4 subclasses | Many subclasses (5+) |
| Shared behavior across types | Types need different validations |
| Need to query all types together | Types rarely queried together |

### Common Pitfalls

**1. Sparse Tables**:
```ruby
# BAD - most columns null for most types
# vehicles: id, type, wheels, wing_span, sail_size, cargo_capacity
```

**2. Polymorphic + STI Conflict**:
```ruby
# BAD - saves base class name, breaks subclass associations
class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
end

car.comments  # May not work as expected
```

**3. Type Changes**:
```ruby
# Changing type is complex and error-prone
user.update(type: "Admin")  # Requires validations for both types to pass
```

### Alternatives to STI

**Delegated Types** (Rails 6.1+):

```ruby
class Entry < ApplicationRecord
  delegated_type :entryable, types: %w[Message Comment]
end

class Message < ApplicationRecord
  has_one :entry, as: :entryable, touch: true
end

class Comment < ApplicationRecord
  has_one :entry, as: :entryable, touch: true
end
```

**Separate Tables with Shared Concerns**:

```ruby
module Drivable
  extend ActiveSupport::Concern

  included do
    validates :make, :model, presence: true
  end

  def description
    "#{make} #{model}"
  end
end

class Car < ApplicationRecord
  include Drivable
end

class Motorcycle < ApplicationRecord
  include Drivable
end
```

### STI Decision Tree

```
Do models share 80%+ attributes?
├── No → Use separate tables or delegated types
└── Yes
    └── Are there 4 or fewer subclasses?
        ├── No → Use separate tables or delegated types
        └── Yes
            └── Do they share most behavior?
                ├── No → Use separate tables with concerns
                └── Yes → STI is appropriate
```

## Anti-Patterns

### CRUD Anti-Patterns

```ruby
# BAD - using delete when you need callbacks
user.delete  # Orphans dependent records

# GOOD
user.destroy

# BAD - using update_column to skip validations
user.update_column(:email, "invalid")  # No validation!

# GOOD - if you must skip validations, be explicit
user.update_attribute(:email, "valid@example.com")

# BAD - find for optional records
user = User.find(params[:user_id])  # Raises if not found

# GOOD
user = User.find_by(id: params[:user_id])
return "User not found" unless user
```

### Dirty Tracking Anti-Patterns

```ruby
# BAD - checking changes in performance-critical code
users.each do |user|
  user.update(processed: true)
  log_changes(user.previous_changes)  # Overhead for each user
end

# GOOD - bulk update without instantiation
User.where(id: user_ids).update_all(processed: true)
```

### Type Casting Anti-Patterns

```ruby
# BAD - serialize with JSON column (double serialization)
class User < ApplicationRecord
  serialize :metadata, coder: JSON  # column already jsonb
end

# GOOD - use store_accessor directly
class User < ApplicationRecord
  store_accessor :metadata, :key1, :key2
end

# BAD - Rails 7.2+ positional coder
serialize :preferences, JSON  # Deprecated

# GOOD
serialize :preferences, coder: JSON
```

### STI Anti-Patterns

```ruby
# BAD - wide sparse table
class Vehicle < ApplicationRecord
  # Has: type, wheels, wing_span, sail_size, cargo_capacity, pedals
end

# BAD - using type column for non-STI
class Product < ApplicationRecord
  # type column stores "clothing", "electronics" but no subclasses
end

# GOOD - use explicit column for categorization
class Product < ApplicationRecord
  enum :category, { clothing: 0, electronics: 1 }
end
```

## Model Lifecycle

### Object States

```ruby
user = User.new
user.new_record?        # => true
user.persisted?         # => false
user.destroyed?         # => false
user.previously_new_record?  # => false

user.save
user.new_record?        # => false
user.persisted?         # => true
user.previously_new_record?  # => true

user.destroy
user.destroyed?         # => true
user.persisted?         # => false
user.frozen?            # => true
```

### Reload

```ruby
user = User.find(1)
user.name = "Changed"
user.reload           # Refreshes from database, clears dirty tracking
user.name             # => Original value from database
```

### Touch

```ruby
user.touch              # Updates updated_at
user.touch(:last_login) # Updates last_login AND updated_at
user.touch(time: 1.hour.ago)
```

## Performance Tips

### Avoid N+1 with Associations

```ruby
# BAD - N+1 queries
User.all.each { |u| puts u.posts.count }

# GOOD - eager loading
User.includes(:posts).each { |u| puts u.posts.size }
```

### Use pluck for Single Columns

```ruby
# BAD - instantiates all models
User.all.map(&:email)

# GOOD - returns array of values
User.pluck(:email)
```

### Use select for Limited Attributes

```ruby
# BAD - loads all columns
User.all.each { |u| puts u.name }

# GOOD - loads only needed columns
User.select(:id, :name).each { |u| puts u.name }
```

### Batch Processing

```ruby
# BAD - loads all into memory
User.all.each { |u| process(u) }

# GOOD - processes in batches of 1000
User.find_each { |u| process(u) }
User.find_each(batch_size: 500) { |u| process(u) }
```
