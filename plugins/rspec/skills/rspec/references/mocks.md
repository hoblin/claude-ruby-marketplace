# RSpec Mocks Reference

Comprehensive reference for test doubles, stubbing, and message expectations.

## Test Doubles

### double (Basic)

Strict double - raises on unexpected messages.

```ruby
book = double("book")
book = double("book", title: "The RSpec Book")  # with stubs
book = double(foo: "bar", baz: "qux")           # anonymous with stubs
```

### instance_double (Verifying)

Verifies against instance methods of the class.

```ruby
notifier = instance_double("ConsoleNotifier")
expect(notifier).to receive(:notify).with("message")

book = instance_double("Book", pages: 250)
```

Verification (when class loaded):
- Method exists on instance
- Argument arity matches
- Keyword arguments valid

### class_double (Verifying)

Verifies against class methods.

```ruby
notifier = class_double("ConsoleNotifier")
  .as_stubbed_const(transfer_nested_constants: true)

expect(notifier).to receive(:notify).with("message")
```

`as_stubbed_const` options:
- `transfer_nested_constants: true` - copies all nested constants
- `transfer_nested_constants: [:CONSTANT]` - selective transfer

### object_double (Verifying)

Doubles an existing object instance.

```ruby
user = object_double(User.new, save: true)
logger = object_double("MyApp::LOGGER", info: nil).as_stubbed_const
```

Use for:
- Objects with side effects
- Methods via `method_missing`
- Singleton objects

### spy

Null object double for after-the-fact verification.

```ruby
invitation = spy("invitation")
invitation.deliver  # doesn't raise
expect(invitation).to have_received(:deliver)

user_spy = instance_spy("User")
model_spy = class_spy("Model")
obj_spy = object_spy(my_object)
```

### Null Object Double

Returns itself for any message.

```ruby
dbl = double("Collaborator").as_null_object
dbl.foo.bar.bazz  # returns dbl
```

## Stubbing (allow)

### Basic Stubs

```ruby
allow(dbl).to receive(:foo)                    # returns nil
allow(dbl).to receive(:title).and_return("X")  # returns "X"
allow(dbl).to receive(:title) { "X" }          # block syntax
```

### Multiple Messages

```ruby
allow(dbl).to receive_messages(
  title: "The RSpec Book",
  subtitle: "BDD with RSpec"
)
```

### Partial Doubles (Real Objects)

```ruby
allow(string).to receive(:length).and_return(500)
allow(Person).to receive(:find).and_return(person_double)
```

Enable verification:
```ruby
RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
```

## Message Expectations (expect)

### Basic Expectations

```ruby
expect(dbl).to receive(:foo)             # must be called
expect(dbl).not_to receive(:foo)         # must NOT be called
expect(dbl).to receive(:foo), "message"  # custom failure message
```

### have_received (Spy Pattern)

```ruby
invitation = spy("invitation")
user.accept_invitation(invitation)
expect(invitation).to have_received(:accept)
expect(invitation).to have_received(:accept).with(mailer)
expect(invitation).to have_received(:deliver).twice
```

## Configuring Responses

### Return Values

```ruby
allow(dbl).to receive(:foo).and_return(14)

# Consecutive values
allow(die).to receive(:roll).and_return(1, 2, 3)
die.roll  # => 1
die.roll  # => 2
die.roll  # => 3
die.roll  # => 3 (repeats last)
```

### Raising Errors

```ruby
allow(dbl).to receive(:foo).and_raise("boom")
allow(dbl).to receive(:foo).and_raise(StandardError)
allow(dbl).to receive(:foo).and_raise(ArgumentError, "invalid")
allow(dbl).to receive(:foo).and_raise(StandardError.new("error"))
```

### Yielding

```ruby
allow(dbl).to receive(:foo).and_yield(2, 3)

# Multiple yields
allow(dbl).to receive(:foo)
  .and_yield(1)
  .and_yield(2)
  .and_yield(3)
```

### Calling Original

```ruby
expect(Calculator).to receive(:add).and_call_original
Calculator.add(2, 3)  # => 5 (real method)
```

### Block Implementation

```ruby
allow(dbl).to receive(:foo) do |arg|
  expect(arg).to eq("bar")
end

allow(loan).to receive(:payment) do |rate|
  loan.amount * rate
end

# Yield to caller's block
allow(dbl).to receive(:foo) { |&block| block.call(14) }
```

### Throwing

```ruby
allow(dbl).to receive(:foo).and_throw(:halt)
```

## Argument Matchers

### Built-in Matchers

| Matcher | Description |
|---------|-------------|
| `anything` | Any single argument |
| `any_args` | Any number of arguments |
| `no_args` | No arguments |
| `kind_of(Class)` | `arg.kind_of?(Class)` |
| `instance_of(Class)` | `arg.instance_of?(Class)` |
| `duck_type(:method)` | Responds to method(s) |
| `boolean` | `true` or `false` |
| `hash_including(key: val)` | Partial hash match |
| `hash_excluding(key: val)` | Hash without keys |
| `array_including(items)` | Array contains items |
| `array_excluding(items)` | Array without items |

### Usage

```ruby
expect(dbl).to receive(:foo).with(1, any_args)
expect(dbl).to receive(:msg).with(/abc/)
expect(dbl).to receive(:msg).with(hash_including(a: 1))
expect(dbl).to receive(:foo).with(a_collection_containing_exactly(1, 2))

# Custom
expect(dbl).to receive(:foo).with(satisfy { |x| x > 3 })
```

### Argument-Dependent Responses

```ruby
allow(dbl).to receive(:foo).and_return(:default)
allow(dbl).to receive(:foo).with(1).and_return(1)
allow(dbl).to receive(:foo).with(2).and_return(2)

dbl.foo(0)  # => :default
dbl.foo(1)  # => 1
```

## Receive Counts

```ruby
expect(dbl).to receive(:msg).once
expect(dbl).to receive(:msg).twice
expect(dbl).to receive(:msg).exactly(3).times
expect(dbl).to receive(:msg).at_least(:once)
expect(dbl).to receive(:msg).at_least(3).times
expect(dbl).to receive(:msg).at_most(:twice)
expect(dbl).to receive(:msg).at_most(3).times
```

## Message Order

```ruby
expect(collaborator_1).to receive(:step_1).ordered
expect(collaborator_2).to receive(:step_2).ordered
expect(collaborator_1).to receive(:step_3).ordered
```

## any_instance

**Warning**: Stubs the object under test, making tests unreliable, and has confusing count semantics. Acceptable for legacy code where DI refactoring isn't feasible, or for testing ActiveRecord callbacks. Prefer stubbing `ClassName.new` to return a double instead:

```ruby
# Prefer this pattern
user_double = instance_double(User, save: true)
allow(User).to receive(:new).and_return(user_double)
```

### Basic Usage

```ruby
allow_any_instance_of(Widget).to receive(:name).and_return("Wibble")
expect_any_instance_of(Widget).to receive(:name).and_return("Wobble")

allow_any_instance_of(Object).to receive_messages(
  foo: "foo",
  bar: "bar"
)
```

### Block with Instance

```ruby
allow_any_instance_of(String).to receive(:slice) do |instance, start, length|
  instance[start, length]
end
```

## Constant Stubbing

### stub_const

```ruby
stub_const("MyClass", Class.new)
stub_const("SomeModel::PER_PAGE", 5)

# Transfer nested constants
stub_const("CardDeck", Class.new, transfer_nested_constants: true)
stub_const("CardDeck", Class.new, transfer_nested_constants: [:SUITS])
```

### hide_const

```ruby
hide_const("MyClass")  # Makes constant undefined
```

## Configuration

```ruby
RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true
    mocks.allow_message_expectations_on_nil = false
  end
end
```

## Patterns

### Unit Test with Collaborator

```ruby
RSpec.describe Account do
  let(:logger) { instance_double("Logger") }
  let(:account) { Account.new(logger) }

  it "logs when closing" do
    expect(logger).to receive(:info).with("Account closed")
    account.close
  end
end
```

### Spy Pattern (Arrange-Act-Assert)

```ruby
RSpec.describe User do
  it "sends invitation" do
    invitation = spy(Invitation)

    user = User.new
    user.invite(invitation)

    expect(invitation).to have_received(:deliver)
      .with(user.email)
      .once
  end
end
```

### Stubbing External Service

```ruby
RSpec.describe WeatherService do
  it "fetches weather" do
    http_client = instance_double(HTTPClient)
    allow(http_client).to receive(:get)
      .with("/weather", hash_including(zip: "12345"))
      .and_return({ temp: 72 })

    service = WeatherService.new(http_client)
    expect(service.temperature("12345")).to eq(72)
  end
end
```

### Conditional Stubs

```ruby
allow(calculator).to receive(:compute).and_call_original
allow(calculator).to receive(:compute).with(0).and_return(0)
allow(calculator).to receive(:compute).with(-1).and_raise("Invalid")
```
