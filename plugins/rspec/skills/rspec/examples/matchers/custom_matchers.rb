# RSpec Matchers: Custom Matcher Examples
# Source: rspec-expectations gem features/custom_matchers/define_matcher.feature

# Basic custom matcher using DSL
RSpec::Matchers.define :be_a_multiple_of do |expected|
  match do |actual|
    actual % expected == 0
  end
end

RSpec.describe "be_a_multiple_of matcher" do
  it "passes for multiples" do
    expect(9).to be_a_multiple_of(3)
    expect(12).to be_a_multiple_of(4)
  end

  it "fails for non-multiples" do
    expect(9).not_to be_a_multiple_of(4)
  end
end

# Custom matcher with messages and description
RSpec::Matchers.define :be_in_range do |min, max|
  match do |actual|
    actual >= min && actual <= max
  end

  failure_message do |actual|
    "expected #{actual} to be between #{min} and #{max}"
  end

  failure_message_when_negated do |actual|
    "expected #{actual} not to be between #{min} and #{max}"
  end

  description do
    "be in range #{min}..#{max}"
  end
end

RSpec.describe "be_in_range matcher" do
  it "passes for values in range" do
    expect(5).to be_in_range(1, 10)
  end

  it "provides readable description" do
    # In output: "should be in range 1..10"
    expect(5).to be_in_range(1, 10)
  end
end

# Custom matcher with chaining
RSpec::Matchers.define :have_errors_on do |attribute|
  chain :with_message do |message|
    @expected_message = message
  end

  match do |model|
    model.valid?
    errors = model.errors[attribute]

    if @expected_message
      errors.include?(@expected_message)
    else
      errors.any?
    end
  end

  failure_message do |model|
    if @expected_message
      "expected #{model.class} to have error '#{@expected_message}' on #{attribute}, " \
        "but got: #{model.errors[attribute].inspect}"
    else
      "expected #{model.class} to have errors on #{attribute}"
    end
  end
end

RSpec.describe "have_errors_on matcher with chaining" do
  subject(:user) { build(:user, email: nil) }

  it "checks for any error on attribute" do
    expect(user).to have_errors_on(:email)
  end

  it "checks for specific error message" do
    expect(user).to have_errors_on(:email).with_message("can't be blank")
  end
end

# Custom matcher with diffable output
RSpec::Matchers.define :match_json_structure do |expected|
  diffable  # Enables diff output on failure

  match do |actual|
    @actual_parsed = JSON.parse(actual)
    structure_matches?(expected, @actual_parsed)
  end

  def structure_matches?(expected, actual)
    case expected
    when Hash
      expected.all? { |k, v| actual.key?(k.to_s) && structure_matches?(v, actual[k.to_s]) }
    when Array
      expected.all? { |v| actual.any? { |a| structure_matches?(v, a) } }
    when Class
      actual.is_a?(expected)
    else
      true
    end
  end
end

# Custom matcher supporting block expectations
RSpec::Matchers.define :complete_within do |timeout|
  supports_block_expectations  # Required for expect { }

  match do |block|
    started = Time.now
    block.call
    Time.now - started < timeout
  end

  failure_message do
    "expected block to complete within #{timeout} seconds"
  end
end

RSpec.describe "complete_within matcher" do
  it "passes for fast operations" do
    expect { 1 + 1 }.to complete_within(1.second)
  end
end

# Custom class-based matcher (from scratch)
class BeValidJSON
  include RSpec::Matchers::Composable

  def matches?(actual)
    @actual = actual
    JSON.parse(actual)
    true
  rescue JSON::ParserError => e
    @error = e
    false
  end

  def failure_message
    "expected valid JSON, got parse error: #{@error.message}"
  end

  def failure_message_when_negated
    "expected invalid JSON, but it parsed successfully"
  end

  def description
    "be valid JSON"
  end
end

def be_valid_json
  BeValidJSON.new
end

RSpec.describe "be_valid_json matcher" do
  it "passes for valid JSON" do
    expect('{"key": "value"}').to be_valid_json
  end

  it "fails for invalid JSON" do
    expect("{invalid}").not_to be_valid_json
  end
end

# Negated matcher using define_negated_matcher
RSpec::Matchers.define_negated_matcher :exclude, :include

RSpec.describe "negated matcher" do
  it "reads more naturally" do
    expect([1, 2, 3]).to exclude(4)
    expect("hello").to exclude("xyz")
  end
end

# Aliased matcher
RSpec::Matchers.alias_matcher :a_user_with, :have_attributes

RSpec.describe "aliased matcher" do
  it "provides domain-specific language" do
    users = [
      build(:user, name: "Alice", role: :admin),
      build(:user, name: "Bob", role: :member)
    ]

    expect(users).to include(a_user_with(name: "Alice", role: :admin))
  end
end
