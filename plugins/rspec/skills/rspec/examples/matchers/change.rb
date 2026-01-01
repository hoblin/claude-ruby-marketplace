# RSpec Matchers: Change Observation Examples
# Source: rspec-expectations gem features/built_in_matchers/change.feature

# Basic change detection
RSpec.describe "change matcher" do
  describe "block form" do
    it "detects any change" do
      counter = 0
      expect { counter += 1 }.to change { counter }
    end

    it "detects no change" do
      value = 5
      expect { value * 2 }.not_to change { value }
    end
  end

  describe "receiver/method form" do
    it "uses object and method name" do
      user = build(:user, name: "Alice")
      expect { user.name = "Bob" }.to change(user, :name)
    end
  end
end

# Chaining methods for specific changes
RSpec.describe "change with chains" do
  describe ".by(delta)" do
    it "specifies exact change amount" do
      counter = 0
      expect { counter += 5 }.to change { counter }.by(5)
    end
  end

  describe ".from(old).to(new)" do
    it "specifies before and after values" do
      value = "old"
      expect { value = "new" }.to change { value }.from("old").to("new")
    end
  end

  describe ".by_at_least(minimum)" do
    it "specifies minimum change" do
      counter = 0
      expect { counter += 5 }.to change { counter }.by_at_least(3)
    end
  end

  describe ".by_at_most(maximum)" do
    it "specifies maximum change" do
      counter = 0
      expect { counter += 5 }.to change { counter }.by_at_most(10)
    end
  end
end

# Practical example: database record changes
RSpec.describe User do
  describe "#save" do
    subject(:user) { build(:user) }

    it "increments total count" do
      expect { user.save }.to change(User, :count).by(1)
    end

    it "changes persisted status" do
      expect { user.save }.to change(user, :persisted?).from(false).to(true)
    end
  end
end

RSpec.describe Order do
  subject(:order) { create(:order, :with_items) }

  describe "#add_item" do
    let(:item) { build(:item, price: 25) }

    it "increments item count" do
      expect { order.add_item(item) }.to change { order.items.count }.by(1)
    end

    it "increases total" do
      expect { order.add_item(item) }.to change(order, :total).by(25)
    end
  end

  describe "#apply_discount" do
    let(:discount) { build(:discount, percentage: 10) }

    it "decreases total by at least discount percentage" do
      original = order.total
      min_decrease = original * 0.10

      expect { order.apply_discount(discount) }
        .to change(order, :total)
        .by_at_least(-min_decrease)
    end
  end
end

# Using composed matchers with change
RSpec.describe "change with composed matchers" do
  it "combines with be_within for floating point" do
    value = 0.0
    expect { value += 1.05 }.to change { value }.by(a_value_within(0.1).of(1.0))
  end

  it "combines with string matchers" do
    text = "foo bar"
    expect { text = "baz qux" }
      .to change { text }
      .from(a_string_matching(/foo/))
      .to(a_string_matching(/baz/))
  end
end
