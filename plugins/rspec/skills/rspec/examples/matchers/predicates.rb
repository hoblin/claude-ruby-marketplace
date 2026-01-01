# RSpec Matchers: Predicate Examples
# Source: rspec-expectations gem features/built_in_matchers/predicates.feature

# be_* - converts to predicate method call
RSpec.describe "dynamic be_* matchers" do
  it "calls predicate methods ending in ?" do
    expect(0).to be_zero           # 0.zero?
    expect([]).to be_empty         # [].empty?
    expect(5).to be_positive       # 5.positive?
    expect(-3).to be_negative      # (-3).negative?
  end

  it "works with custom predicates" do
    user = build(:user, status: :active)

    expect(user).to be_active      # user.active?
    expect(user).not_to be_banned  # !user.banned?
  end

  it "passes arguments to predicate" do
    expect(12).to be_multiple_of(3)  # 12.multiple_of?(3)
  end
end

# have_* - converts to has_*? method call
RSpec.describe "dynamic have_* matchers" do
  it "calls has_*? methods" do
    expect({ a: 1 }).to have_key(:a)    # {a: 1}.has_key?(:a)
    expect({ a: 1 }).to have_value(1)   # {a: 1}.has_value?(1)
  end

  it "works with custom has_*? methods" do
    order = build(:order, :with_items)

    expect(order).to have_items    # order.has_items?
    expect(order).to have_discount # order.has_discount?
  end
end

# Practical examples with Rails models
RSpec.describe User do
  subject(:user) { build(:user) }

  describe "validation predicates" do
    context "with valid attributes" do
      it { is_expected.to be_valid }
    end

    context "without email" do
      subject(:user) { build(:user, email: nil) }

      it { is_expected.not_to be_valid }
    end
  end

  describe "state predicates" do
    context "when active" do
      subject(:user) { build(:user, :active) }

      it { is_expected.to be_active }
      it { is_expected.not_to be_suspended }
    end

    context "when suspended" do
      subject(:user) { build(:user, :suspended) }

      it { is_expected.to be_suspended }
      it { is_expected.not_to be_active }
    end
  end
end

RSpec.describe Order do
  subject(:order) { build(:order) }

  describe "collection predicates" do
    context "with items" do
      subject(:order) { build(:order, :with_items) }

      it { is_expected.to have_items }
    end

    context "without items" do
      it { is_expected.not_to have_items }
    end
  end
end
