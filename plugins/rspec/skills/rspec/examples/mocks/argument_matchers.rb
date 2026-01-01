# RSpec Mocks: Argument Matchers Examples
# Source: rspec-mocks gem features/setting_constraints/matching_arguments.feature

# Built-in argument matchers
RSpec.describe "argument matchers" do
  describe "anything" do
    it "matches any single argument" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).with(anything)
      dbl.foo("whatever")
    end

    it "matches at specific positions" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).with(1, anything, 3)
      dbl.foo(1, "anything goes here", 3)
    end
  end

  describe "any_args" do
    it "matches any number of arguments" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).with(any_args)
      dbl.foo(1, 2, 3, 4, 5)
    end
  end

  describe "no_args" do
    it "matches zero arguments" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).with(no_args)
      dbl.foo
    end
  end

  describe "type matchers" do
    it "matches by kind_of" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).with(kind_of(Numeric))
      dbl.foo(42)
      # Also matches floats, BigDecimal, etc.
    end

    it "matches by instance_of (exact class)" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).with(instance_of(Integer))
      dbl.foo(42)
    end
  end

  describe "duck_type" do
    it "matches by method presence" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).with(duck_type(:to_s, :length))

      dbl.foo("a string")  # Has both methods
    end
  end

  describe "boolean" do
    it "matches true or false" do
      dbl = double("collaborator")
      allow(dbl).to receive(:foo).with(boolean)

      dbl.foo(true)
      dbl.foo(false)
    end
  end

  describe "hash_including" do
    it "matches partial hash" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).with(hash_including(a: 1))
      dbl.foo(a: 1, b: 2, c: 3)
    end

    it "matches nested structure" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).with(
        hash_including(user: hash_including(name: "Alice"))
      )
      dbl.foo(user: { name: "Alice", email: "alice@example.com" })
    end
  end

  describe "hash_excluding" do
    it "matches hash without specified keys" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).with(hash_excluding(:admin))
      dbl.foo(name: "Alice", role: "user")
    end
  end

  describe "array_including" do
    it "matches array containing items" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).with(array_including(1, 2))
      dbl.foo([1, 2, 3, 4])
    end
  end

  describe "array_excluding" do
    it "matches array without specified items" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).with(array_excluding(:admin))
      dbl.foo([:user, :guest])
    end
  end

  describe "regex matching" do
    it "matches strings with regex" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).with(/bar/)
      dbl.foo("foobar")
    end
  end

  describe "RSpec matchers" do
    it "uses collection matchers" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).with(a_collection_containing_exactly(1, 2, 3))
      dbl.foo([3, 1, 2])
    end

    it "uses string matchers" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).with(a_string_starting_with("Hello"))
      dbl.foo("Hello, World!")
    end

    it "uses comparison matchers" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).with(a_value > 10)
      dbl.foo(15)
    end
  end

  describe "satisfy" do
    it "matches with custom predicate" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).with(
        satisfy { |x| x[:a][:b][:c] == 5 }
      )
      dbl.foo(a: { b: { c: 5 } })
    end
  end

  describe "having_attributes" do
    it "matches object with attributes" do
      dbl = double("collaborator")
      user = build(:user, name: "Alice", email: "alice@example.com")

      expect(dbl).to receive(:process).with(
        having_attributes(name: "Alice")
      )
      dbl.process(user)
    end
  end
end

# Argument-dependent responses
RSpec.describe "conditional stubs" do
  describe "different responses by argument" do
    it "returns specific values for specific arguments" do
      dbl = double("collaborator")
      allow(dbl).to receive(:foo).and_return(:default)
      allow(dbl).to receive(:foo).with(1).and_return(:one)
      allow(dbl).to receive(:foo).with(2).and_return(:two)

      expect(dbl.foo(0)).to eq(:default)
      expect(dbl.foo(1)).to eq(:one)
      expect(dbl.foo(2)).to eq(:two)
      expect(dbl.foo(99)).to eq(:default)
    end
  end
end

# Practical example
RSpec.describe UserRepository do
  subject(:repository) { build(:user_repository, database:) }

  let(:database) { instance_double("Database") }

  describe "#find_by_attributes" do
    before do
      allow(database).to receive(:query)
        .with(hash_including(active: true))
        .and_return([build(:user, :active)])

      allow(database).to receive(:query)
        .with(hash_including(admin: true))
        .and_return([build(:user, :admin)])
    end

    it "queries active users" do
      result = repository.find_by_attributes(active: true, name: "Alice")
      expect(result.first).to be_active
    end

    it "queries admin users" do
      result = repository.find_by_attributes(admin: true, department: "IT")
      expect(result.first).to be_admin
    end
  end
end

