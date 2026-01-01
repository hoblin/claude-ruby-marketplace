---
name: RSpec Testing
description: This skill should be used when the user asks to "write specs", "create spec", "add RSpec tests", "fix failing spec", or mentions RSpec, describe blocks, it blocks, expect syntax, test doubles, or matchers. Should also be used when editing *_spec.rb files, working in spec/ directory, planning implementation phases that include tests (TDD/RGRC workflow), writing Testing Strategy or Success Criteria sections, discussing unit or integration tests, or reviewing spec output and test failures. Comprehensive RSpec and FactoryBot reference with best practices, ready-to-use patterns, and examples.
---

# RSpec Testing

This skill provides comprehensive guidance for writing effective RSpec tests in Ruby and Rails applications. Use for writing new specs, fixing failing tests, understanding matchers, using test doubles, and following RSpec best practices.

## Quick Reference

### Basic Structure

```ruby
RSpec.describe Order do
  subject(:order) { described_class.new(items) }
  let(:items) { [item1, item2] }
  let(:item1) { double("item", price: 10) }
  let(:item2) { double("item", price: 20) }

  describe "#total" do
    it "sums item prices" do
      expect(order.total).to eq(30)
    end
  end

  context "with discount" do
    let(:order) { described_class.new(items, discount: 5) }

    it "applies discount" do
      expect(order.total).to eq(25)
    end
  end
end
```

### Key Concepts

| Concept | Purpose |
|---------|---------|
| `describe` / `context` | Group related examples |
| `it` / `specify` | Define individual test cases |
| `let` | Lazy-evaluated, memoized helper |
| `let!` | Eager-evaluated helper (runs before each example) |
| `subject` | Primary object under test |
| `before` / `after` | Setup and teardown hooks |
| `expect` | Make assertions |

## Writing Good Specs

### Use Named Subject for Method Tests

```ruby
describe "#calculate_total" do
  subject(:total) { order.calculate_total }

  it "returns sum of items" do
    expect(total).to eq(100)
  end
end
```

### Context Blocks for Different States

```ruby
describe "#withdraw" do
  context "with sufficient funds" do
    let(:account) { build(:account, balance: 100) }

    it "reduces balance" do
      expect { account.withdraw(50) }.to change(account, :balance).by(-50)
    end
  end

  context "with insufficient funds" do
    let(:account) { build(:account, balance: 10) }

    it "raises error" do
      expect { account.withdraw(50) }.to raise_error(InsufficientFunds)
    end
  end
end
```

## Common Matchers

### Equality

```ruby
expect(x).to eq(y)          # ==
expect(x).to eql(y)         # eql? (type-sensitive)
expect(x).to be(y)          # equal? (identity)
```

### Truthiness

```ruby
expect(x).to be_truthy      # not nil or false
expect(x).to be_falsey      # nil or false
expect(x).to be_nil
expect(x).to be true        # exactly true
```

### Comparisons

```ruby
expect(x).to be > 3
expect(x).to be_between(1, 10).inclusive
expect(x).to be_within(0.1).of(3.14)
```

### Collections

```ruby
expect(arr).to include(1, 2)
expect(arr).to contain_exactly(3, 2, 1)  # order-independent
expect(arr).to all(be_positive)
expect(str).to start_with("hello")
expect(hash).to have_key(:name)
```

### Changes

```ruby
expect { x += 1 }.to change { x }.by(1)
expect { x += 1 }.to change { x }.from(0).to(1)
expect { user.save }.to change(User, :count).by(1)
```

### Errors

```ruby
expect { raise "boom" }.to raise_error
expect { raise ArgumentError, "bad" }.to raise_error(ArgumentError, /bad/)
```

### Predicates (Dynamic)

```ruby
expect([]).to be_empty      # [].empty?
expect(user).to be_valid    # user.valid?
expect(hash).to have_key(k) # hash.has_key?(k)
```

## Test Doubles

### Types

```ruby
# Basic double (strict)
user = double("user", name: "Bob")

# Verifying doubles (recommended)
user = instance_double("User", name: "Bob")  # validates instance methods
api = class_double("Api", fetch: data)       # validates class methods
logger = object_double(Rails.logger)         # validates object methods

# Spy (null object for after-the-fact verification)
notifier = spy("notifier")
```

### Stubbing

```ruby
allow(user).to receive(:name).and_return("Bob")
allow(Api).to receive(:fetch).and_return(data)
allow(obj).to receive(:method) { computed_value }
```

### Expectations

```ruby
expect(user).to receive(:save).and_return(true)
expect(Api).to receive(:post).with(hash_including(id: 1))

# Spy pattern (verify after action)
notifier = spy("notifier")
service.call(notifier)
expect(notifier).to have_received(:notify).with("done")
```

### Argument Matchers

```ruby
expect(obj).to receive(:call).with(anything)
expect(obj).to receive(:call).with(kind_of(Integer))
expect(obj).to receive(:call).with(hash_including(a: 1))
expect(obj).to receive(:call).with(array_including(1, 2))
```

## Rails Specs

| Spec Type | Use For | Key Helpers |
|-----------|---------|-------------|
| `type: :model` | Business logic, scopes, validations | `build`, `create`, associations |
| `type: :request` | Controller actions (preferred) | `get`, `post`, `response`, `have_http_status` |
| `type: :system` | Browser/UI testing | `visit`, `fill_in`, `click_button`, `have_text` |
| `type: :job` | Background jobs | `have_enqueued_job`, `perform_now` |
| `type: :mailer` | Email delivery | `have_enqueued_mail`, `deliver_now` |
| `type: :routing` | Route resolution | `route_to`, `be_routable` |

See `examples/rails/` for complete spec templates.

## Best Practices

### Do

- Use `described_class` instead of hardcoding class name
- Use `let` for test data, `let!` when database records must exist before test
- Use **named subject** when referencing in tests: `subject(:user) { ... }`
- Use context blocks to organize different scenarios
- Use verifying doubles (`instance_double`) over plain `double`
- Name examples with verbs: `it "creates user"` not `it "should create user"`
- Keep examples focused on one behavior
- Use factories over fixtures for flexible test data
- Prefer `build_stubbed` or `build` over `create` when database not needed

### Don't

- Don't use instance variables (`@user`) - use `let` for type safety
- Don't use `before` just to trigger `let` evaluation - use `let!` instead:
  ```ruby
  # BAD - before just to initialize
  let(:user) { create(:user) }
  before { user }

  # GOOD - let! for eager evaluation
  let!(:user) { create(:user) }
  ```
  Use `before` for side-effects like `sign_in(user)` or `driven_by(:rack_test)`
- Don't use `let!` when `let` suffices (wastes resources)
- Don't test Rails framework (validations work, focus on business logic)
- Don't stub the object under test
- Avoid `any_instance_of` - prefer stubbing `ClassName.new` to return a double (see `references/mocks.md`)
- Don't use `receive_message_chain` (violates Law of Demeter)
- Don't write examples without descriptions
- Shared examples work best for testing concerns across including classes. For unique behaviors, prefer repetition over abstraction

### Factory Bot

```ruby
# Build strategies
user = build(:user)              # In-memory, not persisted
user = create(:user)             # Persisted to database
user = build_stubbed(:user)      # Fake persisted (fastest)
attrs = attributes_for(:user)    # Hash of attributes

# With traits and attributes
user = create(:user, :admin, :verified, name: "Bob")

# Lists
users = create_list(:user, 5, :admin)
```

**Strategy Selection**:
- `build_stubbed` - Unit tests without database (fastest)
- `build` - Validation tests, method tests
- `create` - Database queries, scopes, associations
- `attributes_for` - Controller params

See `references/factory_bot.md` for traits, sequences, associations, and callbacks.

## Configuration

Essential settings for `spec_helper.rb` and `rails_helper.rb`:

| Setting | Purpose |
|---------|---------|
| `verify_partial_doubles = true` | Validates stubbed methods exist |
| `filter_run_when_matching :focus` | Run only focused specs (`fit`, `fdescribe`) |
| `order = :random` | Randomize spec order to catch dependencies |
| `use_transactional_fixtures = true` | Rollback database after each spec |
| `infer_spec_type_from_file_location!` | Auto-detect spec type from path |

See `examples/core/configuration.rb` for complete setup.

## Additional Resources

### Reference Files

For detailed patterns and complete API references, consult:

- **`references/core.md`** - describe, it, hooks, let/subject, shared examples, anti-patterns
- **`references/factory_bot.md`** - Build strategies, traits, sequences, associations, callbacks
- **`references/matchers.md`** - All built-in matchers, composing matchers, custom matchers
- **`references/mocks.md`** - Test doubles, stubbing, spies, argument matchers
- **`references/rails.md`** - All Rails spec types, Rails matchers, request/system specs

### Example Files

Ready-to-use code patterns in `examples/`:

- **`examples/core/`** - Basic structure, hooks, let/subject, shared examples, configuration
- **`examples/matchers/`** - Equality, collections, change, errors, predicates, custom matchers
- **`examples/mocks/`** - Doubles, stubs, spies, argument matchers, any_instance, constants
- **`examples/rails/`** - Model, request, controller, system, job, mailer, routing specs
- **`examples/factory_bot/`** - Build strategies, traits, associations, callbacks, transients

### Running Specs

```bash
rspec                           # all specs
rspec spec/models               # directory
rspec spec/user_spec.rb         # file
rspec spec/user_spec.rb:23      # line
rspec --format doc              # documentation format
rspec --only-failures           # re-run failures
rspec --profile 10              # show slowest
```

### Debugging

```bash
rspec --seed 12345              # reproduce random order
rspec --fail-fast               # stop on first failure
rspec --backtrace               # full backtrace
```
