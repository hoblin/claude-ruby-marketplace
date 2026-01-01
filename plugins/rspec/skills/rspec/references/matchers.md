# RSpec Matchers Reference

Comprehensive reference for RSpec's built-in matchers and custom matcher creation.

## Equality Matchers

### eq(expected)

Uses `==` operator. Diffable.

```ruby
expect(5).to eq(5)
expect(actual).not_to eq(expected)
```

### eql(expected)

Uses `eql?` method (type-sensitive).

```ruby
expect(5).to eql(5)
expect(5).not_to eql(5.0)  # Integer vs Float
```

### equal(expected) / be(expected)

Uses `equal?` method (object identity).

```ruby
expect(actual).to be(expected)
expect(actual).to equal(expected)
```

## Comparison Matchers

### Operators

```ruby
expect(5).to be > 3
expect(5).to be >= 5
expect(5).to be < 10
expect(5).to be <= 5
```

### be_within

```ruby
expect(result).to be_within(0.5).of(3.0)
expect(Math::PI).to be_within(0.01).of(3.14)
```

### be_between

```ruby
expect(5).to be_between(1, 10)           # inclusive (default)
expect(5).to be_between(1, 10).inclusive
expect(5).to be_between(1, 5).exclusive  # fails - 5 not in (1, 5)
```

## Type/Class Matchers

### be_an_instance_of / be_instance_of

Uses `instance_of?` - exact class match.

```ruby
expect(5).to be_an_instance_of(Integer)
expect(5).not_to be_an_instance_of(Numeric)
```

### be_a_kind_of / be_a / be_an

Uses `kind_of?` - includes ancestors.

```ruby
expect(5).to be_a_kind_of(Integer)
expect(5).to be_a_kind_of(Numeric)
expect(5).to be_a(Integer)
expect(5).to be_an(Integer)
```

### respond_to

```ruby
expect("string").to respond_to(:length)
expect(obj).to respond_to(:foo, :bar)
expect(obj).to respond_to(:foo).with(2).arguments
expect(obj).to respond_to(:bar).with_keywords(:a, :b)
```

## Truthiness Matchers

### be_truthy

Passes for any value except `nil` and `false`.

```ruby
expect(1).to be_truthy
expect("").to be_truthy
expect(nil).not_to be_truthy
```

### be_falsey / be_falsy

Passes for `nil` or `false`.

```ruby
expect(nil).to be_falsey
expect(false).to be_falsy
expect(0).not_to be_falsey  # 0 is truthy in Ruby
```

### be_nil

```ruby
expect(nil).to be_nil
expect(false).not_to be_nil
```

### be true / be false

Exact boolean match.

```ruby
expect(actual).to be true   # actual == true
expect(actual).to be false  # actual == false
```

### exist

Calls `exist?` or `exists?` method.

```ruby
expect(File).to exist("path/to/file")
expect(obj).to exist
```

## Predicate Matchers

### be_* (Dynamic)

Converts to predicate method call.

```ruby
expect([]).to be_empty        # [].empty?
expect(obj).to be_valid       # obj.valid?
expect(user).to be_active     # user.active?
expect(user).to be_an_admin   # user.admin?
```

### have_* (Dynamic)

Converts to `has_*?` method call.

```ruby
expect({a: 1}).to have_key(:a)  # {a: 1}.has_key?(:a)
expect(list).to have_items      # list.has_items?
```

## Collection Matchers

### include

```ruby
# Arrays
expect([1, 2, 3]).to include(1)
expect([1, 2, 3]).to include(1, 2)

# Strings
expect("hello").to include("ell")

# Hashes
expect({a: 1, b: 2}).to include(:a)
expect({a: 1, b: 2}).to include(a: 1)
expect({a: 1, b: 2}).to include(a: 1, b: 2)
```

### contain_exactly / match_array

Order-independent array matching.

```ruby
expect([1, 2, 3]).to contain_exactly(3, 2, 1)
expect([1, 2, 3]).to match_array([3, 2, 1])
```

### start_with / end_with

```ruby
expect("this string").to start_with("this")
expect([0, 1, 2]).to start_with(0, 1)

expect("this string").to end_with("ring")
expect([0, 1, 2, 3]).to end_with(2, 3)
```

### cover

For ranges.

```ruby
expect(1..10).to cover(5)
expect(1..10).to cover(4, 6)
expect(1..10).not_to cover(11)
```

### all

Every element matches.

```ruby
expect([1, 3, 5]).to all(be_odd)
expect([1, 3, 5]).to all(be_odd.and be_an(Integer))
```

### have_attributes

```ruby
Person = Struct.new(:name, :age)
person = Person.new("Bob", 32)

expect(person).to have_attributes(name: "Bob", age: 32)
expect(person).to have_attributes(name: a_string_starting_with("B"))
```

## Pattern Matching

### match

```ruby
# Regex
expect(email).to match(/^[\w.]+@[\w.]+\.\w+$/)
expect("foo@example.com").to match("example.com")

# Nested data structures
expect(hash).to match(
  a: {
    b: a_collection_containing_exactly(
      a_string_starting_with("f"),
      an_instance_of(Integer)
    )
  }
)
```

## Change Observation

### change

```ruby
# Block form
expect { counter += 1 }.to change { counter }
expect { counter += 1 }.to change { counter }.by(1)
expect { counter += 1 }.to change { counter }.from(0).to(1)

# Object/method form
expect { user.save }.to change(user, :updated_at)
```

### Chaining

```ruby
expect { x += 5 }.to change { x }.by(5)
expect { x += 5 }.to change { x }.by_at_least(3)
expect { x += 5 }.to change { x }.by_at_most(10)
expect { x = 10 }.to change { x }.from(0).to(10)
```

## Error Matchers

### raise_error / raise_exception

```ruby
# Any error
expect { raise }.to raise_error

# Specific class
expect { raise StandardError }.to raise_error(StandardError)

# With message
expect { raise "boom" }.to raise_error("boom")
expect { raise StandardError, "boom" }.to raise_error(StandardError, "boom")

# Message regex
expect { raise StandardError, "boom" }.to raise_error(StandardError, /boo/)

# Block for complex assertions
expect { raise StandardError, "boom" }.to raise_error { |error|
  expect(error.message).to eq("boom")
}
```

### throw_symbol

```ruby
expect { throw :done }.to throw_symbol
expect { throw :done }.to throw_symbol(:done)
expect { throw :done, "value" }.to throw_symbol(:done, "value")
```

## Output Matchers

### output

```ruby
# Stdout
expect { print "foo" }.to output.to_stdout
expect { print "foo" }.to output("foo").to_stdout
expect { print "foo" }.to output(/foo/).to_stdout

# Stderr
expect { warn "foo" }.to output.to_stderr
expect { warn "foo" }.to output("foo\n").to_stderr

# Subprocess
expect { system('echo foo') }.to output("foo\n").to_stdout_from_any_process
```

## Yield Matchers

All require block probe `|b|`.

### yield_control

```ruby
expect { |b| 5.tap(&b) }.to yield_control
expect { |b| "a".to_sym }.not_to yield_control
```

### yield_with_no_args

```ruby
expect { |b| User.transaction(&b) }.to yield_with_no_args
```

### yield_with_args

```ruby
expect { |b| 5.tap(&b) }.to yield_with_args
expect { |b| 5.tap(&b) }.to yield_with_args(5)
expect { |b| 5.tap(&b) }.to yield_with_args(Integer)
```

### yield_successive_args

```ruby
expect { |b| [1, 2, 3].each(&b) }.to yield_successive_args(1, 2, 3)
expect { |b| {a: 1, b: 2}.each(&b) }.to yield_successive_args([:a, 1], [:b, 2])
```

## Satisfy Matcher

Custom predicate logic - useful for complex conditions.

```ruby
expect(5).to satisfy { |n| n > 3 }
expect(5).to satisfy("be greater than 3") { |n| n > 3 }

# Complex validation
expect(response).to satisfy("be valid JSON with user data") { |r|
  json = JSON.parse(r.body)
  json["user"].present? && json["user"]["id"].is_a?(Integer)
}
```

## Composing Matchers

### .and / &

```ruby
expect(alphabet).to start_with("a").and end_with("z")
expect(alphabet).to start_with("a") & end_with("z")
expect([1, 3, 5]).to all(be_odd.and be_an(Integer))
```

### .or / |

```ruby
expect(color).to eq("red").or eq("green").or eq("yellow")
expect(color).to eq("red") | eq("green") | eq("yellow")
```

### Matcher Arguments

Matchers can accept other matchers as arguments:

```ruby
# Change with matcher
expect { k += 1.05 }.to change { k }.by(a_value_within(0.1).of(1.0))

# Collection with matchers
expect([1, 2.5]).to contain_exactly(
  an_instance_of(Integer),
  a_value_within(0.1).of(2.5)
)

# Include with nested matcher
expect(hash).to include(a: a_string_matching(/foo/))
```

## Composable Aliases

Every matcher has noun-form aliases for composition:

| Verb Form | Noun Form |
|-----------|-----------|
| `eq(x)` | `an_object_eq_to(x)` |
| `be_within(x).of(y)` | `a_value_within(x).of(y)` |
| `start_with(x)` | `a_string_starting_with(x)` |
| `include(x)` | `a_collection_including(x)` |
| `be_a(X)` | `a_kind_of(X)` |
| `be_an_instance_of(X)` | `an_instance_of(X)` |

## Aggregate Failures

Collect multiple failures instead of stopping at first:

```ruby
aggregate_failures("user validation") do
  expect(user.name).to eq("Bob")
  expect(user.age).to be > 18
  expect(user.email).to match(/@/)
end
```

## Custom Matchers

### Using DSL

```ruby
RSpec::Matchers.define :be_in_zone do |zone|
  match do |player|
    player.in_zone?(zone)
  end

  failure_message do |player|
    "expected #{player} to be in zone #{zone}"
  end

  failure_message_when_negated do |player|
    "expected #{player} not to be in zone #{zone}"
  end

  description do
    "be in zone #{zone}"
  end
end

# With chaining
RSpec::Matchers.define :have_errors_on do |key|
  chain :with do |message|
    @message = message
  end

  match do |actual|
    actual.errors[key] == @message
  end
end

expect(user).to have_errors_on(:email).with("can't be blank")
```

### Available DSL Methods

- `match(options = {}, &block)` - Main matching logic
- `match_when_negated(&block)` - Custom negative matching
- `failure_message(&block)` - Positive failure message
- `failure_message_when_negated(&block)` - Negative failure message
- `description(&block)` - Matcher description
- `diffable` - Enable diff output
- `supports_block_expectations` - Allow `expect { }`
- `chain(method, *attrs, &block)` - Fluent interface methods

### From Scratch

```ruby
class BeInZone
  include RSpec::Matchers::Composable

  def initialize(expected)
    @expected = expected
  end

  def matches?(actual)
    @actual = actual
    @actual.in_zone?(@expected)
  end

  def failure_message
    "expected #{@actual.inspect} to be in zone #{@expected}"
  end

  def failure_message_when_negated
    "expected #{@actual.inspect} not to be in zone #{@expected}"
  end

  def description
    "be in zone #{@expected}"
  end
end

def be_in_zone(expected)
  BeInZone.new(expected)
end
```

### Aliasing and Negation

```ruby
# Create alias with description transformation
RSpec::Matchers.alias_matcher :a_list_that_sums_to, :sum_to

# Create negated matcher
RSpec::Matchers.define_negated_matcher :exclude, :include
expect([1, 2]).to exclude(3)
```
