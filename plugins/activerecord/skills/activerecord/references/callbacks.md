# ActiveRecord Callbacks Reference

Comprehensive reference for model callbacks: lifecycle hooks, transaction callbacks, ordering, halting behavior, and when to use callbacks vs alternatives.

## Callback Execution Order

### Creating a Record

```
1. before_validation
2. after_validation
3. before_save
4. around_save (before yield)
5. before_create
6. around_create (before yield)
   ─── INSERT ───
7. around_create (after yield)
8. after_create
9. around_save (after yield)
10. after_save
    ─── COMMIT ───
11. after_commit / after_rollback
```

### Updating a Record

Same as create, but `before_update`, `around_update`, `after_update` replace create callbacks.

### Destroying a Record

```
1. before_destroy
2. around_destroy (before yield)
   ─── DELETE ───
3. around_destroy (after yield)
4. after_destroy
   ─── COMMIT ───
5. after_commit / after_rollback
```

### Special Callbacks

```ruby
after_initialize  # After new() or loading from DB
after_find        # After loading from DB (before after_initialize)
after_touch       # After touch() is called
```

## Callback Declaration

### Method Reference (Preferred)

```ruby
class Article < ApplicationRecord
  before_save :normalize_title
  after_create :notify_subscribers

  private

  def normalize_title
    self.title = title.strip.titleize
  end

  def notify_subscribers
    NotificationJob.perform_later(id)
  end
end
```

### Inline Block

```ruby
class User < ApplicationRecord
  before_validation { self.email = email&.downcase&.strip }

  after_create do |user|
    AuditLog.create!(action: "user_created", record: user)
  end
end
```

### Callback Object

```ruby
class AuditLogger
  def after_create(record)
    AuditLog.create!(action: "created", record:)
  end

  def after_update(record)
    AuditLog.create!(action: "updated", record:, changes: record.previous_changes)
  end
end

class Order < ApplicationRecord
  after_create AuditLogger.new
  after_update AuditLogger.new
end
```

## Conditional Callbacks

```ruby
# Symbol (method name) - preferred for readability
before_save :normalize_card_number, if: :paid_with_card?

# Proc/Lambda - for one-liners
after_create :send_welcome_email, if: -> { email.present? }

# Multiple conditions (all must be true)
before_validation :set_defaults, if: [:new_record?, :draft?]

# Using both :if and :unless
after_save :sync_to_search, if: :published?, unless: :skip_indexing?
```

## Halting the Callback Chain

Use `throw :abort` in `before_*` callbacks to halt execution:

```ruby
class Order < ApplicationRecord
  before_save :check_stock

  private

  def check_stock
    throw(:abort) if items.any? { |item| item.out_of_stock? }
  end
end
```

**Behavior when halted:**
- `save` returns `false`
- `save!` raises `ActiveRecord::RecordNotSaved`
- `destroy` returns `false`
- `destroy!` raises `ActiveRecord::RecordNotDestroyed`
- Transaction is rolled back

**Important**: `throw :abort` does NOT add errors. Add them explicitly:

```ruby
def check_stock
  if items.any?(&:out_of_stock?)
    errors.add(:base, "Some items are out of stock")
    throw(:abort)
  end
end
```

## Transaction Callbacks

### The Critical Distinction

All `after_*` callbacks run INSIDE the transaction. External systems can't see your changes yet:

```ruby
# WRONG - Race condition!
after_save :enqueue_processing

def enqueue_processing
  ProcessingJob.perform_later(id)  # Job starts before COMMIT
  # Sidekiq: "Couldn't find Record with 'id'=123"
end
```

Use `after_commit` for external interactions:

```ruby
# CORRECT - Runs after COMMIT
after_commit :enqueue_processing, on: :create

def enqueue_processing
  ProcessingJob.perform_later(id)  # Record guaranteed to exist
end
```

### When to Use after_commit

- Enqueuing background jobs
- Updating search indexes (Elasticsearch, Algolia)
- Clearing caches
- Sending emails/notifications
- Making API calls to external services
- Any action that should only occur if the DB change is permanent

### Transaction Callback Variants

```ruby
# Fires on create, update, or destroy after commit
after_commit :refresh_cache

# Scoped to specific actions (Rails 7.1+)
after_create_commit :send_welcome_email
after_update_commit :sync_changes
after_destroy_commit :cleanup_external

# Equivalent to the above
after_commit :send_welcome_email, on: :create
after_commit :sync_changes, on: :update
after_commit :cleanup_external, on: :destroy

# Multiple actions
after_commit :reindex, on: [:create, :update]

# Rollback callback
after_rollback :log_failure
```

### after_save_commit (Rails 7.1+)

```ruby
# Fires on create OR update, not destroy
after_save_commit :sync_to_search
```

## Transaction Callback Gotchas

### Gotcha 1: Callback Deduplication

```ruby
# WRONG - Only the last one runs!
after_commit :do_something
after_commit :do_something

# Also deduplicated across variants
after_commit :sync_data
after_create_commit :sync_data
after_save_commit :sync_data
# Only one sync_data callback runs

# CORRECT - Use :on option
after_commit :sync_data, on: [:create, :update]
```

### Gotcha 2: previous_changes Behavior

`previous_changes` is reset on each save, not when the transaction closes:

```ruby
after_commit :log_changes

def log_changes
  # If record was saved twice in one transaction,
  # previous_changes only contains the LAST save's changes
end
```

### Gotcha 3: Exception Handling

Exceptions in `after_commit` callbacks:
- Bubble up to the caller
- Stop remaining `after_commit` callbacks from running
- Do NOT rollback (commit already happened)

```ruby
after_commit :might_fail
after_commit :wont_run_if_above_fails

def might_fail
  ExternalService.notify(self)  # Raises exception
rescue ExternalService::Error => e
  Rails.logger.error("Notification failed: #{e}")
  # Don't re-raise - let other callbacks run
end
```

### Gotcha 4: Testing Complications

Older Rails wrapped tests in transactions, preventing `after_commit` from firing. Fixed in Rails 5+, but be aware:

```ruby
# Use transactional fixtures carefully
# after_commit runs in Rails 5+ with proper config
```

### Gotcha 5: Callback Ordering (Rails 7.1+)

```ruby
# Rails 7.1+ default: callbacks run in definition order
config.active_record.run_after_transaction_callbacks_in_order_defined = true

# Pre-7.1 behavior: reverse order
config.active_record.run_after_transaction_callbacks_in_order_defined = false
```

## Around Callbacks

Must call `yield` or the action won't execute:

```ruby
class Article < ApplicationRecord
  around_save :measure_save_time

  private

  def measure_save_time
    start = Time.current
    yield  # REQUIRED - executes the save
    duration = Time.current - start
    Rails.logger.info("Save took #{duration}s")
  end
end
```

**Forgetting yield is a common bug** - the record won't be saved.

## Callback Ordering with prepend

Callbacks from associations (like `dependent: :destroy`) run before your callbacks. Use `prepend: true` to run first:

```ruby
class Topic < ApplicationRecord
  has_many :comments, dependent: :destroy

  # WRONG - comments already deleted when this runs
  before_destroy :log_comments

  # CORRECT - runs before dependent: :destroy
  before_destroy :log_comments, prepend: true

  private

  def log_comments
    Rails.logger.info("Destroying topic with #{comments.count} comments")
  end
end
```

## Callback Inheritance

Callbacks are inherited by subclasses:

```ruby
class Animal < ApplicationRecord
  before_save :set_kingdom
end

class Dog < Animal
  before_save :set_species
end

# Dog.create runs both: set_kingdom, then set_species
```

**Critical**: Define callbacks BEFORE associations in parent classes for proper inheritance.

## Methods That Skip Callbacks

These methods bypass ALL callbacks:

| Method | Skips Callbacks |
|--------|-----------------|
| `delete` | Yes |
| `delete_all` | Yes |
| `update_column` | Yes |
| `update_columns` | Yes |
| `update_all` | Yes |
| `insert` / `insert_all` | Yes |
| `upsert` / `upsert_all` | Yes |
| `touch_all` | Yes |
| `increment!` / `decrement!` | Yes |
| `increment_counter` / `decrement_counter` | Yes |

**Warning**: Use with caution - you may bypass critical business logic.

## Debugging Callbacks

Inspect the callback chain:

```ruby
# All save callbacks
Article._save_callbacks

# Only before_save callbacks
Article._save_callbacks.select { |cb| cb.kind == :before }

# Check if a specific callback is registered
Article._save_callbacks.map(&:filter).include?(:normalize_title)

# All validation callbacks
Article._validation_callbacks

# All create callbacks
Article._create_callbacks
```

## Anti-Patterns

### 1. Callback Hell

```ruby
# WRONG - Too much responsibility, hard to test
class User < ApplicationRecord
  after_create :send_welcome_email
  after_create :create_default_settings
  after_create :notify_admin
  after_create :sync_to_crm
  after_create :update_analytics
  after_update :sync_to_crm
  after_update :invalidate_cache
  after_destroy :cleanup_external_data
  # ... 20 more callbacks
end

# BETTER - Use a service object
class UserCreationService
  def call(user_params)
    user = User.create!(user_params)
    send_welcome_email(user)
    create_default_settings(user)
    notify_admin(user)
    sync_to_crm(user)
    user
  end
end
```

### 2. Callbacks Modifying Other Models

```ruby
# WRONG - Violates Law of Demeter
class Message < ApplicationRecord
  after_create :update_conversation_stats

  def update_conversation_stats
    conversation.update!(
      message_count: conversation.messages.count,
      last_message_at: created_at
    )
  end
end

# BETTER - Use a service or let the parent handle it
class ConversationMessageService
  def add_message(conversation, message_params)
    message = conversation.messages.create!(message_params)
    conversation.touch(:last_message_at)
    conversation.increment!(:message_count)
    message
  end
end
```

### 3. Using after_save for External Systems

```ruby
# WRONG - Race condition with background jobs
after_save :enqueue_processing

# CORRECT
after_commit :enqueue_processing, on: [:create, :update]
```

### 4. Heavy Operations in Callbacks

```ruby
# WRONG - Blocks the request
after_create :generate_thumbnail
after_create :sync_to_external_api
after_create :send_notification

# CORRECT - Defer to background jobs
after_create_commit :enqueue_post_creation_jobs

def enqueue_post_creation_jobs
  ThumbnailJob.perform_later(id)
  ExternalSyncJob.perform_later(id)
  NotificationJob.perform_later(id)
end
```

### 5. Conditional Logic Explosion

```ruby
# WRONG - Hard to follow
before_save :do_a, if: :condition_x?
before_save :do_b, if: :condition_y?
before_save :do_c, if: -> { condition_x? && !condition_z? }
after_save :do_d, unless: -> { condition_x? || condition_y? }

# BETTER - Extract to a single callback or service
before_save :prepare_for_save

def prepare_for_save
  if condition_x?
    do_a
    do_c unless condition_z?
  end
  do_b if condition_y?
end
```

### 6. Throwing abort Without Error Messages

```ruby
# WRONG - No feedback to user
before_save :validate_complex_rules

def validate_complex_rules
  throw(:abort) if invalid_state?
end

# CORRECT - Add error message
def validate_complex_rules
  if invalid_state?
    errors.add(:base, "Cannot save in current state")
    throw(:abort)
  end
end
```

## When Callbacks Are Appropriate

**Good uses:**
- Setting defaults or computed attributes on the current model
- Data normalization (strip, downcase, format)
- Simple audit logging (who changed what)
- Counter cache updates
- Maintaining data consistency within the same model

```ruby
class User < ApplicationRecord
  before_validation :normalize_email
  before_create :generate_api_key
  after_touch :update_full_name_cache

  private

  def normalize_email
    self.email = email&.downcase&.strip
  end

  def generate_api_key
    self.api_key ||= SecureRandom.hex(32)
  end

  def update_full_name_cache
    update_column(:full_name, "#{first_name} #{last_name}")
  end
end
```

## Alternatives to Callbacks

### Service Objects (Recommended)

```ruby
# app/services/user_registration_service.rb
class UserRegistrationService
  def call(params)
    user = User.create!(params)
    WelcomeMailer.welcome(user).deliver_later
    Analytics.track("user_registered", user_id: user.id)
    CrmSync.create_contact(user)
    user
  end
end

# In controller
def create
  user = UserRegistrationService.new.call(user_params)
  redirect_to user
end
```

**Benefits:**
- Explicit control flow
- Easy to test in isolation
- Clear dependencies
- No hidden side effects

### Domain Events

```ruby
# Using a simple pub/sub pattern
class User < ApplicationRecord
  after_create_commit { EventBus.publish("user.created", self) }
end

# Subscribers
EventBus.subscribe("user.created") do |user|
  WelcomeMailer.welcome(user).deliver_later
end

EventBus.subscribe("user.created") do |user|
  Analytics.track("user_registered", user_id: user.id)
end
```

**Benefits:**
- Loose coupling
- Easy to add/remove handlers
- Better for complex event-driven architectures

### Form Objects

```ruby
# app/forms/registration_form.rb
class RegistrationForm
  include ActiveModel::Model

  attr_accessor :email, :password, :terms_accepted

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }
  validates :terms_accepted, acceptance: true

  def save
    return false unless valid?

    user = User.create!(email:, password:)
    send_welcome_email(user)
    true
  end

  private

  def send_welcome_email(user)
    WelcomeMailer.welcome(user).deliver_later
  end
end
```

## Testing Callbacks

### Test the Behavior, Not the Callback

```ruby
# WRONG - Testing implementation
it "calls normalize_email before validation" do
  expect(user).to receive(:normalize_email)
  user.valid?
end

# CORRECT - Testing behavior
it "normalizes email before saving" do
  user = User.create!(email: "  JOHN@EXAMPLE.COM  ", ...)
  expect(user.email).to eq("john@example.com")
end
```

### Testing after_commit Callbacks

```ruby
# Ensure test database connection commits
# In rails_helper.rb or spec_helper.rb

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  # Rails 5+ properly handles after_commit in tests
end

# Test the side effect
it "enqueues a job after creation" do
  expect {
    User.create!(email: "test@example.com")
  }.to have_enqueued_job(WelcomeEmailJob)
end
```

### Isolating Callback Effects

```ruby
# Skip callbacks when not relevant to test
RSpec.describe User do
  describe "#full_name" do
    it "returns first and last name" do
      user = User.new(first_name: "John", last_name: "Doe")
      expect(user.full_name).to eq("John Doe")
    end
  end
end

# Don't need to trigger callbacks for this test
```

## Performance Considerations

### Callbacks Slow Down Tests

Heavy use of callbacks in factories creates cascading effects:

```ruby
# Slow - every User.create runs all callbacks
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
  end
end

# Faster - use build_stubbed when callbacks aren't needed
let(:user) { build_stubbed(:user) }
```

### Consider Database Triggers

For high-performance counter caches:

```ruby
# ActiveRecord callback - runs in Ruby, per record
after_create { parent.increment!(:children_count) }

# Database trigger - runs in DB, faster for bulk operations
# See strong_migrations gem for safe trigger management
```

## Nested Transactions

Callbacks run inside the transaction. Nested transactions without `requires_new: true` don't create savepoints:

```ruby
User.transaction do
  user = User.create!(name: "Alice")

  User.transaction do
    user.update!(name: "Bob")
    raise ActiveRecord::Rollback  # Does NOT rollback!
  end
end
# User saved as "Bob" - the rollback was ignored
```

Use `requires_new: true` for independent rollback:

```ruby
User.transaction do
  user = User.create!(name: "Alice")

  User.transaction(requires_new: true) do
    user.update!(name: "Bob")
    raise ActiveRecord::Rollback  # Creates savepoint, rolls back to "Alice"
  end
end
# User saved as "Alice"
```

**PostgreSQL Warning**: Don't rescue `ActiveRecord::StatementInvalid` inside transactions - it poisons the transaction.
