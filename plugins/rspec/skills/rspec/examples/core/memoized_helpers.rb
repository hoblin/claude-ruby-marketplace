# RSpec Core: Memoized Helpers Examples
# Source: rspec-core gem features/helper_methods/let.feature

# let - lazy evaluation and memoization
RSpec.describe "let behavior" do
  let(:user) { build(:user) }

  it "memoizes within an example" do
    expect(user).to be(user)  # Same object instance
  end

  it "creates fresh instance for each example" do
    expect(user.object_id).not_to eq(0)  # New user each time
  end
end

# let! - eager evaluation (before hook)
RSpec.describe "let! behavior" do
  let!(:user) { create(:user) }

  it "creates user before example runs" do
    # User already exists in database
    expect(User.count).to eq(1)
  end
end

# When to use let vs let!
RSpec.describe User do
  # Use let - value referenced in test body
  let(:user) { build(:user) }

  it "validates email format" do
    user.email = "invalid"
    expect(user).not_to be_valid
  end
end

RSpec.describe User, ".active scope" do
  # Use let! - records must exist for database query
  let!(:active_user) { create(:user, status: :active) }
  let!(:inactive_user) { create(:user, status: :inactive) }

  it "returns only active users" do
    expect(User.active).to contain_exactly(active_user)
  end
end

# Overriding let in nested contexts
RSpec.describe ShoppingCart do
  subject(:cart) { build(:shopping_cart, items: [item], discount:) }

  let(:discount) { 0 }
  let(:item) { build(:item, price: 100) }

  it "calculates full price" do
    expect(cart.total).to eq(100)
  end

  context "with discount" do
    let(:discount) { 20 }  # Override parent definition

    it "applies discount" do
      expect(cart.total).to eq(80)
    end
  end
end

# Using super() to extend parent let
RSpec.describe "API request" do
  let(:params) { { name: "Item", price: 10 } }

  context "with discount" do
    let(:params) { super().merge(discount: 2) }  # Extend parent

    it "includes discount in params" do
      expect(params).to eq(name: "Item", price: 10, discount: 2)
    end
  end
end

# Named subject - always use named subjects
RSpec.describe Article do
  subject(:article) { build(:article, title: "Hello") }

  it "validates presence of body" do
    expect(article).not_to be_valid
    expect(article.errors[:body]).to include("can't be blank")
  end
end

# Subject for method testing
RSpec.describe Calculator do
  subject(:calculator) { build(:calculator) }

  describe "#add" do
    subject(:result) { calculator.add(2, 3) }

    it { is_expected.to eq(5) }
  end
end

# Subject placement - always first in example group
RSpec.describe UserSerializer do
  subject(:serializer) { described_class.new(user) }  # First
  let(:user) { create(:user, name: "Alice") }         # After subject

  it "serializes name" do
    expect(serializer.as_json[:name]).to eq("Alice")
  end
end

# Anti-pattern: let! when let suffices
RSpec.describe "Unnecessary let!" do
  # BAD - creates data unnecessarily
  # let!(:admin) { create(:user, :admin) }

  # GOOD - use let, only creates when referenced
  let(:admin) { create(:user, :admin) }

  it "validates email format" do
    user = build(:user, email: "invalid")
    expect(user).not_to be_valid
    # admin never used, never created
  end
end

# Helper methods for complex setup
RSpec.describe Order do
  def create_order_with_items(count)
    order = build(:order)
    count.times { order.add_item(build(:item)) }
    order
  end

  it "calculates total for multiple items" do
    order = create_order_with_items(3)
    expect(order.items.count).to eq(3)
  end
end
