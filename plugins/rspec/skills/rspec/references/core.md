# RSpec Core Reference

Comprehensive reference for RSpec's core DSL, configuration, and structure.

## Example Groups and Examples

### describe / context

Example groups are classes that inherit from `RSpec::Core::ExampleGroup`:

```ruby
RSpec.describe Order do
  context "with no items" do
    # nested context - creates a subclass
  end
end
```

- `describe` and `context` are aliases
- Blocks are evaluated eagerly when spec file loads
- Nested groups inherit from parent groups

### it / specify / example

Individual test cases:

```ruby
it "sums the prices" do
  expect(order.total).to eq(5.55)
end

# Variants with metadata:
fit "focused example"      # :focus => true
xit "skipped example"      # :skip => 'Temporarily skipped'
pending "pending example"  # :pending => true
```

## Hooks

### before / after

```ruby
before(:example) { }  # runs before each example (alias: :each)
before(:context) { }  # runs once before all examples (alias: :all)
before(:suite) { }    # runs once before entire suite (only in RSpec.configure)

after(:example) { }   # runs after each example
after(:context) { }   # runs after all examples in group
after(:suite) { }     # runs after entire suite
```

### Execution Order

```
before(:suite)    # RSpec.configure
before(:context)  # RSpec.configure
before(:context)  # parent group
before(:context)  # current group
before(:example)  # RSpec.configure
before(:example)  # parent group
before(:example)  # current group
# example runs
after(:example)   # reverse order
after(:context)   # reverse order
after(:suite)     # reverse order
```

### Conditional Hooks

```ruby
RSpec.configure do |config|
  config.before(:example, :authorized => true) do
    log_in_as :authorized_user
  end
end

RSpec.describe Something, :authorized => true do
  # before hook runs here
end
```

### Constraints

- `before(:context)` shares state via instance variables (ordering dependencies risk)
- `let`, `subject`, mocks/stubs NOT supported in `before(:context)`
- Database transactions expect `:example` scope

### around

```ruby
around(:example) do |example|
  DatabaseCleaner.cleaning do
    example.run
  end
end
```

## Memoized Helpers

### Why let Over Instance Variables

Instance variables in RSpec create critical problems:

```ruby
# BAD - typo goes unnoticed, @usre returns nil silently
before { @user = create(:user) }
it "does something" do
  expect(@usre.name).to eq("Alice")  # nil.name raises NoMethodError
end

# GOOD - typo raises NameError immediately
let(:user) { create(:user) }
it "does something" do
  expect(usre.name).to eq("Alice")  # NameError: undefined local variable
end
```

Problems with instance variables:
- **Silent failures**: Undefined instance variables return `nil` without errors
- **State leakage**: Can leak between test files and examples
- **No lazy evaluation**: Always executed in before blocks

### Why let Over Helper Methods

Always prefer `let`:
- **Memoization**: Cached within example, prevents redundant queries
- **Lazy evaluation**: Only executes when referenced
- **Overridable**: Redefine in nested contexts with `super()`
- **Type safety**: Typos raise `NameError` immediately

Use helper methods only when:
- A `let` would only be used inside another `let` definition (chain of lets)
- Setup needs parameters that vary per call within the same example

```ruby
# Always use let for test dependencies
let(:user) { create(:user) }
let(:post) { create(:post, author: user) }
let(:comment) { create(:comment, post:, author: user) }

# Helper method: parameterized setup called multiple times in one example
def create_order_with_items(count)
  order = Order.new
  count.times { order.add_item(build(:item)) }
  order
end

it "compares orders of different sizes" do
  small_order = create_order_with_items(2)
  large_order = create_order_with_items(10)
  expect(large_order.total).to be > small_order.total
end
```

### let

Lazily-evaluated, memoized helper:

```ruby
let(:user) { create(:user) }

it "uses user" do
  user         # evaluated here
  user         # returns same instance
end
```

Characteristics:
- Lazy evaluation: not invoked until first reference
- Memoized within an example (multiple calls return same value)
- NOT cached across examples (fresh for each example)
- Thread-safe by default

### let!

Same as `let` but evaluated in implicit `before` hook:

```ruby
let!(:user) { create(:user) }  # evaluated before each example
```

Use when:
- Side effects needed before example runs
- Data must exist for database queries/scopes
- Records needed for associations

```ruby
# let! needed - testing scope that queries database
let!(:active_user) { create(:user, status: :active) }
let!(:inactive_user) { create(:user, status: :inactive) }

it "finds only active users" do
  expect(User.active).to contain_exactly(active_user)
end
```

### let vs let! Decision Guide

| Use `let` when | Use `let!` when |
|----------------|-----------------|
| Value used in test body | Side effects needed before test |
| Not all examples use value | Testing database scopes/queries |
| Performance matters | Records must exist for count checks |

**Anti-pattern**: Using `let!` when `let` suffices:
```ruby
# Bad - creates data unnecessarily
let!(:admin) { create(:user, :admin) }

it "validates email format" do
  user = build(:user, email: "invalid")
  expect(user).not_to be_valid
  # admin created but never used!
end
```

### Overriding let in Nested Contexts

```ruby
let(:discount) { 0 }

it "calculates full price" do
  expect(cart.total).to eq(100)
end

context "with discount" do
  let(:discount) { 20 }  # Overrides parent

  it "applies discount" do
    expect(cart.total).to eq(80)
  end
end
```

**Using super() to extend parent values**:

```ruby
let(:params) { { name: "Item", price: 10 } }

context "with discount" do
  let(:params) { super().merge(discount: 2) }  # Must use super() with parens
end
```

### subject

Implicit or explicit test target:

```ruby
# Implicit - creates instance of described class
RSpec.describe Array do
  it { is_expected.to be_empty }  # subject is Array.new
end

# Explicit
subject { [1, 2, 3] }

# Named subject (creates both subject and named method)
subject(:account) { CheckingAccount.new(50) }
```

One-liner syntax:
- `is_expected` wraps subject in `expect(subject)`
- `should` / `should_not` (legacy syntax)

### Named Subject Best Practices

Always use named subject when referencing in tests:

```ruby
# BAD - what is "subject"?
describe Article do
  subject { Article.new }
  it "validates presence of title" do
    expect(subject).not_to be_valid  # Requires scrolling to understand
  end
end

# GOOD - intention-revealing name
describe Article do
  subject(:article) { Article.new }
  it "validates presence of title" do
    expect(article).not_to be_valid
  end
end
```

### Subject Anti-Patterns

**1. At class level, subject should be the object under test**:

At the top-level `describe`, subject represents the object being tested:

```ruby
# BAD - at class level, subject should be the object, not a method result
RSpec.describe MyService do
  subject(:response) { described_class.new.call }  # Wrong: this is a result
end

# GOOD - subject is the object instance
RSpec.describe MyService do
  subject(:service) { described_class.new }

  it "returns success" do
    expect(service.call).to be_success
  end
end
```

**Note**: Inside a `describe "#method"` block, subject CAN be the method result.
This is valid because the method IS what's being tested in that scope:

```ruby
RSpec.describe Order do
  subject(:order) { described_class.new(items) }  # Class-level: the object

  describe "#total" do
    subject(:total) { order.total }  # Method-level: the result is OK

    it "sums item prices" do
      expect(total).to eq(100)
    end
  end
end
```

**2. Multiple subjects**:
```ruby
# BAD - ambiguous which is THE subject
subject(:user) { User.new }
subject(:admin) { Admin.new }

# GOOD - one subject, rest as let
subject(:user) { User.new }
let(:admin) { Admin.new }
```

**3. Missing subject**:
```ruby
# BAD - repeated instantiation
it "returns 200" do
  expect(Pinger.new.call).to eq(200)
end

# GOOD - define subject once
subject(:pinger) { Pinger.new }
it "returns 200" do
  expect(pinger.call).to eq(200)
end
```

### Subject Placement

Subject must be first declaration in example group:

```ruby
describe UserSerializer do
  subject(:serializer) { described_class.new(user) }  # First
  let(:user) { create(:user) }                        # After subject
end
```

## Configuration

### RSpec.configure

```ruby
RSpec.configure do |config|
  # Expectations
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.max_formatted_output_length = 1000
  end

  # Mocks
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Execution
  config.order = :random
  config.fail_fast = true  # or number like 3

  # Filtering
  config.filter_run_when_matching :focus
  config.filter_run_excluding :slow

  # Persistence
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Output
  config.default_formatter = "doc"
  config.profile_examples = 10

  # Include helpers
  config.include MyHelpers
  config.include AuthHelpers, type: :request
end
```

### Configuration Files

Precedence (lowest to highest):
1. `$XDG_CONFIG_HOME/rspec/options` or `~/.rspec`
2. `./.rspec`
3. `./.rspec-local`
4. Command-line options
5. `SPEC_OPTS` environment variable

## Metadata

### Adding Metadata

```ruby
it "does something", :slow, :ui => true do
  # metadata[:slow] = true
  # metadata[:ui] = true
end

RSpec.describe "Group", :integration do
  # metadata[:integration] = true
end
```

### Accessing Metadata

```ruby
it "does something" do |example|
  example.metadata[:description]  # => "does something"
  example.metadata[:file_path]    # => "/path/to/spec.rb"
end
```

### described_class

```ruby
RSpec.describe Widget do
  it "creates instance" do
    widget = described_class.new
    expect(widget).to be_a(Widget)
  end
end
```

## Filtering

### By Tag

```bash
rspec --tag slow:true
rspec --tag ~slow         # exclude

# In configure:
config.filter_run_including :foo => :bar
config.filter_run_excluding :foo => :bar
```

### By Description

```bash
rspec --example "Homepage when logged in"
rspec -e "Homepage" -e "User"  # multiple patterns
```

### By Location

```bash
rspec spec/homepage_spec.rb:14 spec/widgets_spec.rb:40
```

### Focus Filtering

```ruby
RSpec.configure do |config|
  config.filter_run_when_matching :focus
end

fit "focused example" do  # runs only this
end
```

## Shared Examples

### What Shared Examples Are

Shared examples store test assertions (`it` blocks) for reuse across multiple test contexts. Content is only executed when included in another example group.

### shared_examples vs shared_context

| Feature | `shared_examples` | `shared_context` |
|---------|-------------------|------------------|
| Contains | Test assertions (`it` blocks) | Setup (`let`, `before`, helpers) |
| Purpose | Share behavior tests | Share configuration |
| Use when | Same behavior across classes | Same initial state needed |

### Definition

```ruby
RSpec.shared_examples "a collection" do
  it "responds to each" do
    expect(subject).to respond_to(:each)
  end
end

RSpec.shared_examples "a container" do |item|
  it "contains #{item}" do
    expect(subject).to include(item)
  end
end
```

### Passing Data INTO Shared Examples

**Method 1: Positional Parameters** (compile-time):
```ruby
RSpec.shared_examples "measurable" do |expected_size|
  it "has size #{expected_size}" do
    expect(subject.size).to eq(expected_size)
  end
end

describe Array do
  subject { [1, 2, 3] }
  it_behaves_like "measurable", 3
end
```

**Method 2: Keyword Arguments** (recommended):
```ruby
shared_examples "configurable" do |defaults: {}, required: []|
  required.each do |attr|
    it "requires #{attr}" do
      expect(subject.public_send(attr)).to be_present
    end
  end
end

describe Settings do
  it_behaves_like "configurable", required: [:timeout, :retries]
end
```

**Method 3: Block for Runtime Context**:
```ruby
RSpec.shared_examples "a collection" do
  it "is not empty" do
    expect(collection).not_to be_empty
  end
end

describe Array do
  it_behaves_like "a collection" do
    let(:collection) { [1, 2, 3] }  # Defined at runtime
  end
end
```

### Accessing Context FROM WITHIN Shared Examples

Shared examples can access from including context:
- `described_class`
- `subject`
- `let` definitions
- Metadata

```ruby
RSpec.shared_examples "timestamped" do
  it "responds to created_at" do
    expect(subject).to respond_to(:created_at)
  end

  it "is instance of described class" do
    expect(subject).to be_a(described_class)
  end
end
```

### it_behaves_like vs include_examples

| Method | Context | Safety | Output |
|--------|---------|--------|--------|
| `it_behaves_like` | Creates nested context | Safe | `behaves like X` |
| `include_examples` | Merges into current | Risky | Flat |

**Use `it_behaves_like`** (default choice):
```ruby
describe Array do
  it_behaves_like "a collection"  # Creates nested context
end
# Output: Array > behaves like a collection > responds to each
```

**Avoid `include_examples`** multiple times:
```ruby
# BAD - method conflicts, last let wins
describe Controller do
  include_examples "user actions", :admin
  include_examples "user actions", :regular  # Overrides admin let!
end

# GOOD - isolated contexts
describe Controller do
  it_behaves_like "user actions", :admin
  it_behaves_like "user actions", :regular
end
```

### Shared Context

Use for shared setup (no assertions):

```ruby
RSpec.shared_context "authenticated user" do
  let(:current_user) { create(:user) }
  before { sign_in(current_user) }
end

RSpec.describe DashboardController do
  include_context "authenticated user"

  it "shows dashboard" do
    get :index
    expect(response).to be_successful
  end
end
```

### Anti-Patterns to Avoid

**1. Over-abstraction**:
```ruby
# BAD - too much indirection
shared_context "with user" do
  let(:user) { create(:user, role: role) }
  let(:role) { :member }
end

shared_examples "authorized" do
  it "allows access" do
    expect(user.can_access?).to be true  # Where did user come from?
  end
end

# GOOD - some repetition is okay for clarity
describe Admin do
  let(:admin) { create(:user, :admin) }

  it "allows access" do
    expect(admin.can_access?).to be true
  end
end
```

**2. The Mystery Guest** (RSpec DSL Puzzle):
```ruby
# BAD - readers must hunt for definitions
describe BillingService do
  include_context "user setup"
  include_context "subscription setup"

  it "charges user" do
    BillingService.process(user)  # Where is user defined?
    expect(user.charged?).to be true
  end
end
```

**3. Hidden Dependencies**:
```ruby
# BAD - shared example requires specific let names
shared_examples "sortable" do
  it "sorts items" do
    expect(items.sort).to eq(sorted_items)  # Must define items AND sorted_items
  end
end
```

**4. Spec Explosion** (n*m problem):
Avoid including heavy shared examples in many places. If shared example has 10 assertions and included in 8 classes, you run 80 specs instead of 10+8.

### Organization

**Same file** (isolated use):
```ruby
# spec/models/user_spec.rb
RSpec.shared_examples "has timestamps" do
  it { is_expected.to respond_to(:created_at) }
end

RSpec.describe User do
  it_behaves_like "has timestamps"
end
```

**Support directory** (widespread use):
```
spec/support/
  shared_contexts/
    authenticated_user.rb
  shared_examples/
    timestampable.rb
```

Load in `rails_helper.rb`:
```ruby
Dir["./spec/support/**/*.rb"].sort.each { |f| require f }
```

### When to Use Shared Examples

**Good use cases**:
- Controller authentication (same auth checks across actions)
- Interface compliance testing
- Shared model behaviors (e.g., soft delete)

**Avoid when**:
- Models have unique behaviors
- Setup complexity exceeds benefit
- Tests become hard to understand

## CLI Options

### Common Options

```bash
rspec                          # run all in spec/
rspec spec/models              # specific directory
rspec spec/user_spec.rb        # specific file
rspec spec/user_spec.rb:23     # specific line

# Formatting
rspec --format doc             # documentation format
rspec --format progress        # dots (default)
rspec --format json --out results.json

# Execution
rspec --fail-fast              # stop on first failure
rspec --fail-fast=3            # stop after 3 failures
rspec --only-failures          # re-run only failures
rspec --next-failure           # run next failure
rspec --order random           # randomize
rspec --seed 1234              # specific seed
rspec --profile 10             # show 10 slowest
rspec --dry-run                # list without running
```

### .rspec File

```
--format documentation
--color
--require spec_helper
--order random
```

## Best Practice Patterns

### Context Blocks for States

```ruby
describe "#withdraw" do
  context "with sufficient funds" do
    it "reduces balance" do
      # ...
    end
  end

  context "with insufficient funds" do
    it "raises error" do
      # ...
    end
  end
end
```

### Named Subject in Method Describe

```ruby
describe "#calculate_total" do
  subject(:total) { order.calculate_total }

  it "sums items" do
    expect(total).to eq(100)
  end
end
```

### Helper Methods

```ruby
RSpec.describe Order do
  def create_order_with_items(count)
    order = Order.new
    count.times { order.add_item(Item.new) }
    order
  end

  it "calculates total" do
    order = create_order_with_items(3)
    expect(order.total).to eq(30)
  end
end
```

### Shared Examples for Reusable Behaviors

```ruby
shared_examples "a timestamped model" do
  it { is_expected.to respond_to(:created_at) }
  it { is_expected.to respond_to(:updated_at) }
end

RSpec.describe User do
  it_behaves_like "a timestamped model"
end
```
