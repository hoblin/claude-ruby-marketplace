# FactoryBot: Transient Attributes Examples
# Source: factory_bot gem spec/acceptance/transient_attributes_spec.rb

# Transient attributes exist only during factory execution.
# They're available in attribute definitions and callbacks,
# but not set on the final object.

# Basic transient attributes
FactoryBot.define do
  factory :user do
    transient do
      upcased { false }
      prefix { "" }
    end

    name { "#{prefix}John Doe" }

    after(:create) do |user, evaluator|
      user.name.upcase! if evaluator.upcased
    end
  end
end

RSpec.describe "Transient attributes" do
  describe "in attribute definitions" do
    let(:user) { build(:user, prefix: "Mr. ") }

    it "uses transient in attribute computation" do
      expect(user.name).to eq("Mr. John Doe")
    end
  end

  describe "in callbacks" do
    let(:user) { create(:user, upcased: true) }

    it "accesses transient via evaluator" do
      expect(user.name).to eq("JOHN DOE")
    end
  end

  describe "not on final object" do
    let(:user) { build(:user, upcased: true) }

    it "does not set transient as attribute" do
      expect(user).not_to respond_to(:upcased)
      expect(user).not_to respond_to(:prefix)
    end
  end
end

# Transient with attributes_for
RSpec.describe "Transient with attributes_for" do
  FactoryBot.define do
    factory :product do
      transient do
        discount { 0 }
      end

      name { "Product" }
      price { 100 - discount }
    end
  end

  describe "excludes transient from hash" do
    subject(:attrs) { attributes_for(:product, discount: 20) }

    it "computes attributes using transient" do
      expect(attrs[:price]).to eq(80)
    end

    it "excludes transient from result" do
      expect(attrs).not_to have_key(:discount)
    end
  end
end

# Transient sequences
FactoryBot.define do
  factory :numbered_item do
    transient do
      sequence(:counter)
    end

    name { "Item ##{counter}" }
  end
end

RSpec.describe "Transient sequences" do
  describe "sequence in transient block" do
    let(:items) { build_list(:numbered_item, 3) }

    it "increments across instances" do
      names = items.map(&:name)
      expect(names).to eq(["Item #1", "Item #2", "Item #3"])
    end
  end
end

# Transient for dynamic associations
FactoryBot.define do
  factory :author do
    name { "Author" }

    transient do
      books_count { 0 }
      published_books_count { 0 }
    end

    after(:create) do |author, evaluator|
      create_list(:book, evaluator.books_count, author:)
      create_list(:book, evaluator.published_books_count, :published, author:)
    end
  end
end

RSpec.describe "Transient for associations" do
  describe "controlling association count" do
    let(:author) { create(:author, books_count: 3, published_books_count: 2) }

    it "creates specified associations" do
      expect(author.books.count).to eq(5)
      expect(author.books.published.count).to eq(2)
    end
  end
end

# Transient objects
FactoryBot.define do
  factory :invoice do
    transient do
      customer { build(:customer) }
    end

    customer_name { customer.name }
    customer_email { customer.email }
    customer_id { customer.id }
  end
end

RSpec.describe "Transient objects" do
  describe "using object properties" do
    let(:vip_customer) { build(:customer, :vip, name: "VIP Corp") }
    let(:invoice) { build(:invoice, customer: vip_customer) }

    it "extracts properties from transient object" do
      expect(invoice.customer_name).to eq("VIP Corp")
      expect(invoice.customer_email).to eq(vip_customer.email)
    end
  end
end

# Transient with defaults
FactoryBot.define do
  factory :notification do
    transient do
      recipient { nil }
      send_email { true }
    end

    user { recipient || association(:user) }

    after(:create) do |notification, evaluator|
      NotificationMailer.send(notification) if evaluator.send_email
    end
  end
end

RSpec.describe "Transient with defaults" do
  describe "nil default with fallback" do
    let(:notification) { create(:notification) }
    let(:specific_user) { create(:user) }
    let(:targeted_notification) { create(:notification, recipient: specific_user) }

    it "uses fallback when transient is nil" do
      expect(notification.user).to be_a(User)
    end

    it "uses provided value when given" do
      expect(targeted_notification.user).to eq(specific_user)
    end
  end

  describe "boolean transient" do
    let(:silent_notification) { create(:notification, send_email: false) }

    it "respects boolean transient" do
      # Email not sent when send_email: false
      expect(silent_notification).to be_persisted
    end
  end
end

# Transient inheritance
FactoryBot.define do
  factory :base_record do
    transient do
      metadata { {} }
    end

    name { "Record" }
  end

  factory :special_record, parent: :base_record do
    transient do
      priority { "normal" }
    end

    name { "Special #{priority} Record" }
  end
end

RSpec.describe "Transient inheritance" do
  describe "child inherits parent transient" do
    let(:record) { build(:special_record, metadata: {key: "value"}) }

    it "has access to parent transient" do
      # metadata from parent is available
      expect(record.name).to include("Special")
    end
  end

  describe "child adds own transient" do
    let(:urgent) { build(:special_record, priority: "urgent") }

    it "uses child-specific transient" do
      expect(urgent.name).to eq("Special urgent Record")
    end
  end
end
