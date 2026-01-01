# FactoryBot Reference

Comprehensive guide for test data preparation with FactoryBot in RSpec.

## Build Strategies

### Overview

| Strategy | Persisted | Database | Use Case |
|----------|-----------|----------|----------|
| `build` | No | No | Unit tests, method logic |
| `create` | Yes | Yes | Integration tests, associations |
| `build_stubbed` | Fake | No | Fastest, isolated unit tests |
| `attributes_for` | N/A | No | Controller params, form data |

### build

Constructs instance without persisting:

```ruby
user = build(:user)
user.new_record?  # => true
```

Use when:
- Testing instance methods that don't need persistence
- Testing object state and attribute logic
- Need in-memory object without database overhead

### create

Constructs and persists to database:

```ruby
user = create(:user)
user.new_record?  # => false
user.id           # => assigned by database
```

Use when:
- Testing database queries, scopes, finders
- Testing associations that require foreign keys
- Integration tests requiring persisted records

### build_stubbed

Returns fake persisted object (fastest):

```ruby
user = build_stubbed(:user)
user.persisted?   # => true (faked)
user.new_record?  # => false (faked)
user.id           # => sequential integer
user.save         # => raises RuntimeError
```

Characteristics:
- Sequential `id` assignment
- Sets `created_at` and `updated_at` to current time
- Stubs persistence methods to raise errors
- Cannot use `Marshal.dump`

Use when:
- Unit testing without database
- Mocking persisted records for speed
- Testing code that checks `persisted?`

### attributes_for

Returns hash of attributes:

```ruby
attrs = attributes_for(:user)
# => { name: "John", email: "john@example.com" }
```

Use when:
- Controller specs with params
- Testing form submissions
- Need raw attribute data

### List Methods

Build multiple records:

```ruby
users = build_list(:user, 5)
users = create_list(:user, 5, role: :admin)
users = build_stubbed_list(:user, 5)
attrs = attributes_for_list(:user, 5)

# Pair methods (exactly 2)
users = build_pair(:user)
users = create_pair(:user)

# With block for index-based customization
users = create_list(:user, 5) do |user, i|
  user.update!(position: i + 1)
end
```

## Factory Definition

### Basic Factory

```ruby
FactoryBot.define do
  factory :user do
    name { "John Doe" }
    email { "john@example.com" }
    admin { false }
  end
end
```

Key points:
- Always use block syntax `{ }` for lazy evaluation
- Factory name infers class (`:user` → `User`)
- Explicit class: `factory :admin_user, class: "User"`

### Design Principle

Define one minimal factory per class with only required attributes:

```ruby
# Good - minimal factory
factory :user do
  email { generate(:email) }  # Only required for validation
end

# Bad - too many defaults
factory :user do
  email { generate(:email) }
  name { "John" }           # Has default in model
  role { :member }          # Has default in model
  verified { false }        # Has default in model
end
```

## Sequences

Generate unique values:

### Global Sequences

```ruby
FactoryBot.define do
  sequence :email do |n|
    "person#{n}@example.com"
  end
end

generate(:email)  # => "person1@example.com"
generate(:email)  # => "person2@example.com"
```

### Factory-Scoped Sequences

```ruby
factory :user do
  sequence(:email) { |n| "user#{n}@example.com" }

  # Ruby 2.7+ numbered parameters
  sequence(:username) { "user#{_1}" }
end
```

### Without Block (Auto-increment)

```ruby
factory :post do
  sequence(:position)  # 1, 2, 3...
end

factory :task do
  sequence :priority, %i[low medium high urgent].cycle
end
```

### Uniqueness Caveat

Don't override with conflicting values:

```ruby
factory :user do
  sequence(:email) { |n| "person#{n}@example.com" }
end

# Danger zone
create(:user, email: "person1@example.com")  # Uses person1
create(:user)  # Also generates person1 → CONFLICT!
```

## Traits

Group attributes for composition:

### Definition

```ruby
factory :story do
  title { "My Story" }

  trait :published do
    published { true }
    published_at { Time.current }
  end

  trait :unpublished do
    published { false }
  end

  trait :featured do
    featured { true }
    featured_at { Time.current }
  end

  # Compose traits in child factories
  factory :featured_story, traits: [:published, :featured]
end
```

### Usage

```ruby
create(:story, :published)
create(:story, :published, :featured)
create(:story, :published, title: "Custom Title")

create_list(:story, 3, :published, :featured)
```

### Trait Precedence

Last trait wins for same attribute:

```ruby
factory :user do
  trait :active do
    status { "active" }
  end

  trait :pending do
    status { "pending" }
  end
end

create(:user, :active, :pending).status  # => "pending"
```

### Enum Traits (Rails)

Automatically generated for ActiveRecord enums:

```ruby
class Task < ApplicationRecord
  enum status: { queued: 0, started: 1, finished: 2 }
end

# Auto-generated traits
build(:task, :queued)
build(:task, :started)
build(:task, :finished)

# Disable globally
FactoryBot.automatically_define_enum_traits = false
```

## Associations

### Implicit Definition

```ruby
factory :post do
  author  # Looks for :author factory
end
```

### Explicit Definition

```ruby
factory :post do
  association :author
  association :author, factory: :user
  association :author, factory: :user, strategy: :build
end
```

### With Traits

```ruby
factory :post do
  association :author, factory: [:user, :admin]
  association :author, :admin, name: "Admin Author"
end
```

### Strategy Inheritance

Associations inherit parent's build strategy:

```ruby
post = build(:post)
post.new_record?        # => true
post.author.new_record? # => true (also built)

post = create(:post)
post.author.new_record? # => false (also created)
```

Override with explicit strategy:

```ruby
factory :post do
  association :author, strategy: :build
end
```

### has_many Associations

```ruby
factory :user do
  factory :user_with_posts do
    transient do
      posts_count { 5 }
    end

    after(:create) do |user, evaluator|
      create_list(:post, evaluator.posts_count, author: user)
      user.reload
    end
  end
end

create(:user_with_posts, posts_count: 10)
```

### Inline has_many (FactoryBot 5+)

```ruby
factory :user do
  posts { [association(:post)] }

  # Multiple with trait
  posts { Array.new(3) { association(:post, :published) } }
end
```

### Polymorphic Associations

```ruby
factory :comment do
  for_photo  # Default trait

  trait :for_photo do
    association :commentable, factory: :photo
  end

  trait :for_video do
    association :commentable, factory: :video
  end
end

create(:comment)             # On photo
create(:comment, :for_video) # On video
```

### Interconnected Associations

Use `instance` to reference object being built:

```ruby
factory :student do
  school
  profile { association :profile, student: instance, school: school }
end

# Both student and profile share same school
```

## Transient Attributes

Attributes available only within factory, not set on object:

```ruby
factory :user do
  transient do
    upcased { false }
    posts_count { 0 }
  end

  name { "John Doe" }

  after(:create) do |user, evaluator|
    user.name.upcase! if evaluator.upcased
    create_list(:post, evaluator.posts_count, author: user)
  end
end

create(:user, upcased: true, posts_count: 3)
```

## Dependent Attributes

Attributes referencing other attributes:

```ruby
factory :user do
  first_name { "Joe" }
  last_name { "Blow" }
  email { "#{first_name}.#{last_name}@example.com".downcase }
  full_name { "#{first_name} #{last_name}" }
end

create(:user, last_name: "Doe").email  # => "joe.doe@example.com"
```

Overrides flow through dependent attributes.

## Callbacks

### Available Hooks

| Callback | Timing | Strategies |
|----------|--------|------------|
| `before(:build)` | Before construction | build, create |
| `after(:build)` | After construction | build, create |
| `before(:create)` | Before save | create |
| `after(:create)` | After save | create |
| `after(:stub)` | After stubbing | build_stubbed |

### Usage

```ruby
factory :user do
  after(:build) do |user|
    user.setup_defaults
  end

  after(:create) do |user, evaluator|
    create(:profile, user: user) if evaluator.with_profile
  end

  transient do
    with_profile { false }
  end
end
```

### Callback Order

1. Global callbacks (RSpec.configure)
2. Inherited callbacks (parent factory)
3. Factory callbacks
4. Trait callbacks (in order applied)

### Skipping Callbacks

```ruby
factory :user do
  to_create { |instance| instance.save(validate: false) }
end

# Skip create entirely
factory :user do
  skip_create
end
```

## Inheritance

### Nested Factories

```ruby
factory :post do
  title { "A Title" }

  factory :published_post do
    published { true }
    published_at { Time.current }
  end

  factory :featured_post do
    featured { true }
  end
end

create(:published_post)  # Has title and published attributes
```

### Explicit Parent

```ruby
factory :admin, parent: :user do
  admin { true }
end
```

## Custom Construction

### initialize_with

For non-standard constructors:

```ruby
factory :user do
  name { "Jane Doe" }
  initialize_with { new(name: name) }
end

# With all attributes
factory :user do
  initialize_with { new(**attributes) }
end
```

### Custom Persistence

```ruby
factory :api_resource do
  to_create { |instance| instance.remote_save! }
end
```

## Context Isolation

### Best Practices

1. **Prefer build_stubbed** for unit tests:
   ```ruby
   let(:user) { build_stubbed(:user) }  # Fast, isolated
   ```

2. **Use build when persistence not needed**:
   ```ruby
   let(:user) { build(:user) }  # No database hit
   ```

3. **Reserve create for integration tests**:
   ```ruby
   let!(:user) { create(:user) }  # When database required
   ```

4. **Rewind sequences in isolation**:
   ```ruby
   before { FactoryBot.rewind_sequences }
   ```

### Avoiding Shared State

```ruby
# Bad - shared mutable state
let(:shared_user) { create(:user) }

# Good - fresh instance per example
let(:user) { build(:user) }
```

## Linting

Validate all factories:

```ruby
# In Rake task (not before(:suite) - too slow)
namespace :factory_bot do
  task lint: :environment do
    abort unless Rails.env.test?

    ActiveRecord::Base.connection.transaction do
      FactoryBot.lint(traits: true, strategy: :build, verbose: true)
      raise ActiveRecord::Rollback
    end
  end
end
```

Options:
- `traits: true` - Lint all trait combinations
- `strategy: :build` - Use build instead of create
- `verbose: true` - Show factory names as they're linted

## RSpec Integration

### Setup

```ruby
# spec/support/factory_bot.rb
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
```

Enables calling `create(:user)` instead of `FactoryBot.create(:user)`.

### Spring/Zeus Compatibility

```ruby
RSpec.configure do |config|
  config.before(:suite) { FactoryBot.reload }
end
```

## Quick Reference

### Common Patterns

```ruby
# Simple creation
user = create(:user)
user = build(:user)
user = build_stubbed(:user)
attrs = attributes_for(:user)

# With traits
user = create(:user, :admin, :verified)

# With attributes
user = create(:user, name: "Custom Name")

# With associations
post = create(:post, author: user)

# Lists
users = create_list(:user, 5)
users = create_list(:user, 5, :admin)

# Transient attributes
user = create(:user, posts_count: 3)
```

### Strategy Selection Guide

| Scenario | Strategy |
|----------|----------|
| Instance method testing | `build` |
| Method that doesn't touch DB | `build` or `build_stubbed` |
| Testing scopes/queries | `create` |
| Testing associations | `create` |
| Controller params | `attributes_for` |
| Mocking persisted objects | `build_stubbed` |
| Performance-critical unit tests | `build_stubbed` |
