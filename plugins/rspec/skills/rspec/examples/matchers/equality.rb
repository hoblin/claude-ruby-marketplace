# RSpec Matchers: Equality Examples
# Source: rspec-expectations gem features/built_in_matchers/equality.feature

# eq - value equality using ==
RSpec.describe "eq matcher" do
  it "compares using ==" do
    expect(5).to eq(5)
    expect("string").to eq("string")
  end

  it "allows type coercion" do
    expect(5).to eq(5.0)  # Integer == Float
  end

  it "fails for different values" do
    expect(5).not_to eq(6)
  end
end

# eql - value equivalence using eql? (type-sensitive)
RSpec.describe "eql matcher" do
  it "compares using eql?" do
    expect(5).to eql(5)
  end

  it "is type-sensitive" do
    expect(5).not_to eql(5.0)  # Integer.eql?(Float) => false
  end
end

# equal/be - object identity using equal?
RSpec.describe "equal/be matcher" do
  let(:string) { "hello" }

  it "passes for same object" do
    expect(string).to equal(string)
    expect(string).to be(string)  # be is alias for equal
  end

  it "fails for different objects with same value" do
    expect("hello").not_to equal("hello")  # Different String objects
    expect("hello").not_to be("hello")
  end
end

# Practical example: memoization verification
RSpec.describe User do
  subject(:user) { build(:user) }

  describe "#full_name" do
    it "memoizes result" do
      first_call = user.full_name
      second_call = user.full_name

      expect(first_call).to be(second_call)  # Same object returned
    end
  end
end
