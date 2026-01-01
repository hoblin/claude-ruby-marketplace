# RSpec Core: Shared Examples & Shared Context
# Source: rspec-core gem features/example_groups/shared_examples.feature

# shared_examples - reusable test assertions
RSpec.shared_examples "a collection" do
  let(:collection) { build(:collection, items: [7, 2, 4]) }

  context "initialized with 3 items" do
    it "reports correct size" do
      expect(collection.size).to eq(3)
    end
  end

  describe "#include?" do
    context "with item in collection" do
      it "returns true" do
        expect(collection.include?(7)).to be(true)
      end
    end

    context "with item not in collection" do
      it "returns false" do
        expect(collection.include?(9)).to be(false)
      end
    end
  end
end

RSpec.describe CustomArray do
  it_behaves_like "a collection"
end

RSpec.describe CustomSet do
  it_behaves_like "a collection"
end

# Passing data via positional parameters
RSpec.shared_examples "measurable" do |expected_size|
  it "has size #{expected_size}" do
    expect(subject.size).to eq(expected_size)
  end
end

RSpec.describe Bucket do
  subject(:bucket) { build(:bucket, :with_items, items_count: 3) }

  it_behaves_like "measurable", 3
end

# Passing data via keyword arguments (recommended)
RSpec.shared_examples "validatable" do |required: [], optional: []|
  required.each do |attr|
    it "validates presence of #{attr}" do
      subject.send("#{attr}=", nil)
      expect(subject).not_to be_valid
    end
  end
end

RSpec.describe User do
  subject(:user) { build(:user) }

  it_behaves_like "validatable", required: [:email, :name]
end

# Passing data via block (runtime context)
RSpec.shared_examples "a container" do
  it "is not empty" do
    expect(collection).not_to be_empty
  end
end

RSpec.describe "custom container" do
  it_behaves_like "a container" do
    let(:collection) { build_list(:item, 3) }  # Defined at runtime
  end
end

# shared_context - reusable setup (no assertions)
RSpec.shared_context "authenticated user" do
  let(:current_user) { create(:user) }

  before do
    sign_in(current_user)
  end
end

RSpec.describe DashboardController do
  include_context "authenticated user"

  it "shows dashboard" do
    get :index
    expect(response).to be_successful
  end
end

# shared_context with metadata auto-inclusion
RSpec.shared_context "with admin", :admin do
  let(:current_user) { create(:user, :admin) }

  before { sign_in(current_user) }
end

RSpec.configure do |config|
  config.include_context "with admin", :admin
end

RSpec.describe AdminController, :admin do
  it "allows admin access" do  # Context auto-included
    get :index
    expect(response).to be_successful
  end
end

# it_behaves_like vs include_examples
# PREFER it_behaves_like - creates nested context, safe
RSpec.describe Controller do
  it_behaves_like "user actions", :admin    # Nested: "behaves like user actions"
  it_behaves_like "user actions", :regular  # Separate context, no conflicts
end

# AVOID include_examples multiple times - method conflicts
# describe Controller do
#   include_examples "user actions", :admin
#   include_examples "user actions", :regular  # BAD: Overrides let definitions!
# end

# When to use shared examples
# GOOD: Interface compliance testing
RSpec.shared_examples "timestamped model" do
  it { is_expected.to respond_to(:created_at) }
  it { is_expected.to respond_to(:updated_at) }
end

RSpec.describe User do
  subject(:user) { build(:user) }

  it_behaves_like "timestamped model"
end

RSpec.describe Post do
  subject(:post) { build(:post) }

  it_behaves_like "timestamped model"
end
