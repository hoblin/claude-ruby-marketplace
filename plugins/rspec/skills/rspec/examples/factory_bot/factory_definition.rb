# FactoryBot: Factory Definition Examples
# Source: factory_bot gem spec/acceptance/

# Factory definitions go in spec/factories/ directory.
# Each factory maps to a model class.

# Basic factory definition
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    name { "John Doe" }
    email { "john@example.com" }
    admin { false }
  end
end

# Explicit class mapping
FactoryBot.define do
  factory :admin_user, class: "User" do
    name { "Admin" }
    admin { true }
  end

  factory :guest, class: User do
    name { "Guest" }
  end
end

# Always use block syntax for lazy evaluation
FactoryBot.define do
  factory :article do
    # Good - evaluated when factory is invoked
    title { "My Article" }
    published_at { Time.current }

    # Bad - evaluated once at load time (avoid)
    # created_date Date.today
  end
end

# Minimal factory principle
# Define only required attributes, use traits for variations
FactoryBot.define do
  # Good - minimal factory
  factory :post do
    title { "Post Title" }
    # Only what's required for validation
  end

  # Bad - too many defaults
  # factory :post do
  #   title { "Post Title" }
  #   body { "Some content" }      # Has model default
  #   published { false }          # Has model default
  #   views_count { 0 }            # Has model default
  # end
end

# Sequences
RSpec.describe "Sequences" do
  # Global sequence
  FactoryBot.define do
    sequence :email do |n|
      "person#{n}@example.com"
    end

    sequence :username do |n|
      "user_#{n}"
    end
  end

  describe "global sequences" do
    it "generates unique values" do
      first = generate(:email)
      second = generate(:email)

      expect(first).not_to eq(second)
      expect(first).to match(/person\d+@example.com/)
    end
  end

  # Factory-scoped sequence
  FactoryBot.define do
    factory :user do
      sequence(:email) { |n| "user#{n}@example.com" }
    end
  end

  # Sequence without block (auto-increment)
  FactoryBot.define do
    factory :task do
      sequence(:position)
    end
  end

  describe "auto-increment sequence" do
    it "returns sequential integers" do
      tasks = build_list(:task, 3)
      expect(tasks.map(&:position)).to eq([1, 2, 3])
    end
  end

  # Cycling sequence
  FactoryBot.define do
    factory :priority_task, class: "Task" do
      sequence(:priority, %i[low medium high urgent].cycle)
    end
  end

  # Sequence with custom starting value
  FactoryBot.define do
    sequence(:letter, "a") { |n| "letter_#{n}" }
  end

  describe "alphabetic sequence" do
    it "increments alphabetically" do
      expect(generate(:letter)).to eq("letter_a")
      expect(generate(:letter)).to eq("letter_b")
    end
  end

  # Sequence aliases
  FactoryBot.define do
    sequence(:counter, aliases: [:count, :total]) { |n| n * 10 }
  end

  describe "sequence aliases" do
    it "shares counter across aliases" do
      expect(generate(:counter)).to eq(10)
      expect(generate(:count)).to eq(20)
      expect(generate(:total)).to eq(30)
    end
  end

  # generate_list for sequences
  describe "generate_list" do
    it "generates multiple values" do
      emails = generate_list(:email, 3)
      expect(emails.length).to eq(3)
      expect(emails.uniq.length).to eq(3)
    end
  end
end

# Dependent attributes
RSpec.describe "Dependent attributes" do
  FactoryBot.define do
    factory :user do
      first_name { "John" }
      last_name { "Doe" }
      email { "#{first_name}.#{last_name}@example.com".downcase }
      full_name { "#{first_name} #{last_name}" }
    end
  end

  describe "cascading dependencies" do
    let(:user) { build(:user, first_name: "Jane") }

    it "computes dependent attributes from overrides" do
      expect(user.email).to eq("jane.doe@example.com")
      expect(user.full_name).to eq("Jane Doe")
    end
  end

  # Symbol#to_proc for dependent attributes
  FactoryBot.define do
    factory :account do
      password { "secret123" }
      password_confirmation(&:password)
    end
  end

  describe "Symbol#to_proc syntax" do
    let(:account) { build(:account) }

    it "references another attribute" do
      expect(account.password_confirmation).to eq(account.password)
    end
  end
end

# Rewind sequences
RSpec.describe "Rewinding sequences" do
  before { FactoryBot.rewind_sequences }

  it "resets sequence counters" do
    # After rewind, sequences start fresh
    user = build(:user)
    expect(user.email).to match(/user1@/)
  end
end
