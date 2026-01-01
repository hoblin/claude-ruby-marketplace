# FactoryBot: Build Strategies Examples
# Source: factory_bot gem spec/acceptance/

# Build strategies control how objects are constructed:
# - build: in-memory, not persisted
# - create: persisted to database
# - build_stubbed: fake persisted (fastest)
# - attributes_for: returns hash only

# build - constructs without persisting
RSpec.describe "build strategy" do
  describe "basic usage" do
    let(:user) { build(:user) }

    it "creates a new record" do
      expect(user).to be_new_record
    end

    it "does not persist to database" do
      expect(user).not_to be_persisted
    end

    it "can validate" do
      expect(user).to be_valid
    end
  end

  describe "with attributes" do
    let(:user) { build(:user, name: "Custom Name") }

    it "applies attribute overrides" do
      expect(user.name).to eq("Custom Name")
    end
  end

  describe "with traits" do
    let(:user) { build(:user, :admin) }

    it "applies trait attributes" do
      expect(user.admin).to be true
    end
  end

  describe "with block" do
    it "yields the built instance" do
      build(:user, name: "John") do |user|
        expect(user.name).to eq("John")
        expect(user).to be_new_record
      end
    end
  end

  describe "associations" do
    let(:post) { build(:post) }

    it "builds associations (not persisted)" do
      expect(post.author).to be_new_record
    end
  end
end

# create - constructs and persists
RSpec.describe "create strategy" do
  describe "basic usage" do
    let(:user) { create(:user) }

    it "is not a new record" do
      expect(user).not_to be_new_record
    end

    it "is persisted" do
      expect(user).to be_persisted
    end

    it "has a database ID" do
      expect(user.id).to be_present
    end
  end

  describe "associations" do
    let(:post) { create(:post) }

    it "creates associated records" do
      expect(post.author).to be_persisted
    end
  end

  describe "with block" do
    it "yields the created instance" do
      create(:user, name: "Jane") do |user|
        expect(user.name).to eq("Jane")
        expect(user).to be_persisted
      end
    end
  end
end

# build_stubbed - fake persisted (fastest)
RSpec.describe "build_stubbed strategy" do
  describe "basic usage" do
    let(:user) { build_stubbed(:user) }

    it "appears persisted" do
      expect(user).to be_persisted
    end

    it "is not a new record" do
      expect(user).not_to be_new_record
    end

    it "has a sequential ID" do
      expect(user.id).to be > 0
    end

    it "has timestamps set" do
      expect(user.created_at).to be_present
      expect(user.updated_at).to be_present
    end

    it "is not marked as changed" do
      expect(user).not_to be_changed
    end
  end

  describe "persistence methods raise" do
    let(:user) { build_stubbed(:user) }

    it "raises on save" do
      expect { user.save }.to raise_error(RuntimeError)
    end

    it "raises on destroy" do
      expect { user.destroy }.to raise_error(RuntimeError)
    end
  end

  describe "associations" do
    let(:post) { build_stubbed(:post) }

    it "stubs associations too" do
      expect(post.author).to be_persisted
      expect(post.author).not_to be_new_record
    end
  end
end

# attributes_for - returns hash only
RSpec.describe "attributes_for strategy" do
  describe "basic usage" do
    subject(:attrs) { attributes_for(:user) }

    it "returns a hash" do
      expect(attrs).to be_a(Hash)
    end

    it "includes factory attributes" do
      expect(attrs).to have_key(:name)
      expect(attrs).to have_key(:email)
    end

    it "excludes associations" do
      expect(attrs).not_to have_key(:posts)
      expect(attrs).not_to have_key(:company_id)
    end
  end

  describe "with overrides" do
    subject(:attrs) { attributes_for(:user, name: "Custom") }

    it "applies overrides" do
      expect(attrs[:name]).to eq("Custom")
    end
  end

  describe "with traits" do
    subject(:attrs) { attributes_for(:user, :admin) }

    it "applies trait attributes" do
      expect(attrs[:admin]).to be true
    end
  end

  describe "excludes transient attributes" do
    # Given factory with transient { posts_count { 5 } }
    subject(:attrs) { attributes_for(:user) }

    it "does not include transient attributes" do
      expect(attrs).not_to have_key(:posts_count)
    end
  end
end

# List methods
RSpec.describe "list methods" do
  describe "build_list" do
    let(:users) { build_list(:user, 5) }

    it "builds multiple records" do
      expect(users.length).to eq(5)
    end

    it "builds without persisting" do
      users.each do |user|
        expect(user).to be_new_record
      end
    end
  end

  describe "create_list" do
    let(:users) { create_list(:user, 3) }

    it "creates multiple records" do
      expect(users.length).to eq(3)
    end

    it "persists all records" do
      users.each do |user|
        expect(user).to be_persisted
      end
    end
  end

  describe "build_stubbed_list" do
    let(:users) { build_stubbed_list(:user, 3) }

    it "stubs multiple records" do
      users.each do |user|
        expect(user).to be_persisted
        expect(user.id).to be > 0
      end
    end
  end

  describe "attributes_for_list" do
    let(:attrs_list) { attributes_for_list(:user, 3) }

    it "returns array of hashes" do
      expect(attrs_list.length).to eq(3)
      attrs_list.each { |attrs| expect(attrs).to be_a(Hash) }
    end
  end

  describe "pair methods" do
    let(:users) { create_pair(:user) }

    it "creates exactly 2 records" do
      expect(users.length).to eq(2)
    end
  end

  describe "list with traits and overrides" do
    let(:admins) { create_list(:user, 3, :admin, name: "Admin") }

    it "applies traits to all" do
      admins.each { |user| expect(user.admin).to be true }
    end

    it "applies overrides to all" do
      admins.each { |user| expect(user.name).to eq("Admin") }
    end
  end

  describe "list with block and index" do
    it "yields each instance with index" do
      users = build_list(:user, 3) do |user, index|
        user.position = index + 1
      end

      expect(users.map(&:position)).to eq([1, 2, 3])
    end
  end
end
