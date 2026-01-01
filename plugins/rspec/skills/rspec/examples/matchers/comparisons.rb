# RSpec Matchers: Comparison Examples
# Source: rspec-expectations gem features/built_in_matchers/comparisons.feature, be_within.feature

# Operator comparisons
RSpec.describe "comparison operators" do
  it "supports numeric comparisons" do
    expect(18).to be > 15
    expect(18).to be >= 17
    expect(18).to be <= 19
    expect(18).to be < 20
  end

  it "supports string comparisons (alphabetical)" do
    expect("Strawberry").to be < "Tomato"
    expect("Strawberry").to be > "Apple"
  end
end

# be_within - floating point tolerance
RSpec.describe "be_within matcher" do
  it "handles floating point precision" do
    radius = 3
    area = radius * radius * Math::PI

    expect(area).to be_within(0.1).of(28.3)
  end

  it "specifies acceptable delta" do
    expect(27.5).to be_within(0.5).of(27.9)
    expect(27.5).to be_within(0.5).of(28.0)
    expect(27.5).to be_within(0.5).of(27.0)
  end

  # Works with Time objects too
  it "compares times with tolerance" do
    now = Time.now
    expect(now).to be_within(1.second).of(Time.now)
  end
end

# be_between - range checking
RSpec.describe "be_between matcher" do
  it "defaults to inclusive" do
    expect(5).to be_between(1, 10)
    expect(1).to be_between(1, 10)   # Inclusive: includes 1
    expect(10).to be_between(1, 10)  # Inclusive: includes 10
  end

  it "supports explicit inclusive" do
    expect(5).to be_between(1, 10).inclusive
  end

  it "supports exclusive ranges" do
    expect(5).to be_between(1, 10).exclusive
    expect(1).not_to be_between(1, 10).exclusive  # Excludes boundaries
    expect(10).not_to be_between(1, 10).exclusive
  end
end

# Practical example
RSpec.describe Order do
  subject(:order) { build(:order, total: 150) }

  describe "#shipping_rate" do
    context "with standard order" do
      it "returns rate within expected range" do
        expect(order.shipping_rate).to be_between(5.0, 25.0)
      end
    end

    context "with heavy order" do
      subject(:order) { build(:order, :heavy, total: 500) }

      it "returns higher rate" do
        expect(order.shipping_rate).to be > 20.0
      end
    end
  end
end
