# RSpec Matchers: Collection Examples
# Source: rspec-expectations gem features/built_in_matchers/include.feature,
#         contain_exactly.feature, all.feature, have_attributes.feature

# include - partial matching
RSpec.describe "include matcher" do
  describe "with arrays" do
    it "checks single element" do
      expect([1, 2, 3]).to include(1)
    end

    it "checks multiple elements" do
      expect([1, 2, 3]).to include(1, 2)
      expect([1, 2, 3]).to include(1, 2, 3)
    end

    it "works with composed matchers" do
      expect([1, 3, 7]).to include(a_kind_of(Integer))
      expect([1, 3, 7]).to include(be_odd.and be < 10)
    end
  end

  describe "with strings" do
    it "checks substring" do
      expect("hello world").to include("world")
      expect("hello world").to include("hello", "world")
    end

    it "works with regex" do
      expect("hello world").to include(/wor.d/)
    end
  end

  describe "with hashes" do
    let(:hash) { { a: 1, b: 2, c: 3 } }

    it "checks key existence" do
      expect(hash).to include(:a)
      expect(hash).to include(:a, :b)
    end

    it "checks key-value pairs" do
      expect(hash).to include(a: 1)
      expect(hash).to include(a: 1, b: 2)
    end
  end

  describe "with counts" do
    let(:items) { [{ type: :a }, { type: :b }, { type: :a }] }

    it "specifies occurrence count" do
      expect(items).to include(have_key(:type)).exactly(3).times
      expect(items).to include(type: :a).twice
      expect(items).to include(type: :b).once
    end
  end
end

# contain_exactly / match_array - order-independent full match
RSpec.describe "contain_exactly matcher" do
  it "matches regardless of order" do
    expect([1, 2, 3]).to contain_exactly(3, 2, 1)
    expect([1, 2, 3]).to contain_exactly(2, 3, 1)
  end

  it "requires all elements present" do
    expect([1, 2, 3]).not_to contain_exactly(1, 2)      # Missing 3
    expect([1, 2, 3]).not_to contain_exactly(1, 2, 3, 4) # Extra 4
  end

  it "works with composed matchers" do
    expect(["barn", 2.45]).to contain_exactly(
      a_value_within(0.1).of(2.5),
      a_string_starting_with("bar")
    )
  end

  it "has match_array alias" do
    expect([1, 2, 3]).to match_array([3, 2, 1])
  end
end

# start_with / end_with
RSpec.describe "start_with/end_with matchers" do
  describe "with strings" do
    it "checks prefix/suffix" do
      expect("hello world").to start_with("hello")
      expect("hello world").to end_with("world")
    end
  end

  describe "with arrays" do
    it "checks first/last elements" do
      expect([0, 1, 2, 3]).to start_with(0)
      expect([0, 1, 2, 3]).to start_with(0, 1)
      expect([0, 1, 2, 3]).to end_with(3)
      expect([0, 1, 2, 3]).to end_with(2, 3)
    end
  end
end

# all - every element matches
RSpec.describe "all matcher" do
  it "requires all elements to match" do
    expect([1, 3, 5]).to all(be_odd)
    expect([1, 3, 5]).to all(be_an(Integer))
    expect([1, 3, 5]).to all(be < 10)
  end

  it "works with compound matchers" do
    expect([1, 3, 5]).to all(be_odd.and be_an(Integer))
    expect([1, 4, 21]).to all(be_odd.or be < 10)
  end

  it "provides clear failure messages" do
    # When one element fails, message shows which
    expect(["foo", "bar", "baz"]).to all(be_a(String).and include("a"))
  end
end

# have_attributes - object attribute matching
RSpec.describe "have_attributes matcher" do
  subject(:user) { build(:user, name: "Alice", age: 25) }

  it "checks single attribute" do
    expect(user).to have_attributes(name: "Alice")
  end

  it "checks multiple attributes" do
    expect(user).to have_attributes(name: "Alice", age: 25)
  end

  it "works with composed matchers" do
    expect(user).to have_attributes(name: a_string_starting_with("A"))
    expect(user).to have_attributes(age: a_value > 18)
  end
end

# Practical example: testing query results
RSpec.describe User, ".active scope" do
  let!(:active_users) { create_list(:user, 3, :active) }
  let!(:inactive_user) { create(:user, :inactive) }

  subject(:results) { described_class.active }

  it "returns only active users" do
    expect(results).to contain_exactly(*active_users)
    expect(results).not_to include(inactive_user)
  end

  it "returns users with expected attributes" do
    expect(results).to all(have_attributes(status: "active"))
  end
end
