# FactoryBot: Traits Examples
# Source: factory_bot gem spec/acceptance/traits_spec.rb

# Traits define reusable attribute groups.
# Compose traits for flexible test data.

# Basic trait definition
FactoryBot.define do
  factory :post do
    title { "My Post" }
    body { "Content here" }

    trait :published do
      published { true }
      published_at { Time.current }
    end

    trait :draft do
      published { false }
      published_at { nil }
    end

    trait :featured do
      featured { true }
      featured_at { Time.current }
    end

    trait :with_long_content do
      body { "A" * 1000 }
    end
  end
end

RSpec.describe "Traits" do
  describe "basic usage" do
    let(:published_post) { create(:post, :published) }

    it "applies trait attributes" do
      expect(published_post.published).to be true
      expect(published_post.published_at).to be_present
    end
  end

  describe "multiple traits" do
    let(:featured_published) { create(:post, :published, :featured) }

    it "applies all traits" do
      expect(featured_published.published).to be true
      expect(featured_published.featured).to be true
    end
  end

  describe "traits with attribute overrides" do
    let(:post) { create(:post, :published, title: "Custom Title") }

    it "applies both trait and explicit override" do
      expect(post.published).to be true
      expect(post.title).to eq("Custom Title")
    end
  end
end

# Trait precedence
FactoryBot.define do
  factory :user do
    name { "Default" }

    trait :john do
      name { "John" }
    end

    trait :jane do
      name { "Jane" }
    end
  end
end

RSpec.describe "Trait precedence" do
  describe "last trait wins" do
    it "applies traits in order" do
      user_john_jane = build(:user, :john, :jane)
      user_jane_john = build(:user, :jane, :john)

      expect(user_john_jane.name).to eq("Jane")
      expect(user_jane_john.name).to eq("John")
    end
  end

  describe "explicit overrides trump traits" do
    let(:user) { build(:user, :john, name: "Custom") }

    it "uses explicit value" do
      expect(user.name).to eq("Custom")
    end
  end
end

# Trait composition
FactoryBot.define do
  factory :article do
    title { "Article" }

    trait :published do
      status { "published" }
    end

    trait :featured do
      featured { true }
    end

    trait :popular do
      published
      featured
      views_count { 1000 }
    end

    # Child factory with traits
    factory :popular_article, traits: [:popular]
  end
end

RSpec.describe "Trait composition" do
  describe "traits referencing other traits" do
    let(:article) { build(:article, :popular) }

    it "includes composed traits" do
      expect(article.status).to eq("published")
      expect(article.featured).to be true
      expect(article.views_count).to eq(1000)
    end
  end

  describe "child factory with traits" do
    let(:popular) { build(:popular_article) }

    it "inherits traits from factory definition" do
      expect(popular.status).to eq("published")
      expect(popular.featured).to be true
    end
  end
end

# Enum traits (Rails)
FactoryBot.define do
  factory :order do
    # Assuming: enum status: { pending: 0, processing: 1, shipped: 2, delivered: 3 }
    # Auto-generated traits: :pending, :processing, :shipped, :delivered
    customer_name { "Customer" }
  end
end

RSpec.describe "Enum traits" do
  describe "auto-generated enum traits" do
    it "creates traits for each enum value" do
      pending_order = build(:order, :pending)
      shipped_order = build(:order, :shipped)

      expect(pending_order.status).to eq("pending")
      expect(shipped_order.status).to eq("shipped")
    end
  end
end

# Manual enum traits with traits_for_enum
FactoryBot.define do
  factory :task do
    # Define manually when auto-generation disabled
    traits_for_enum :priority, {low: 0, medium: 1, high: 2}
  end
end

# Global traits
FactoryBot.define do
  # Traits defined outside factories are global
  trait :timestamped do
    created_at { 1.day.ago }
    updated_at { Time.current }
  end

  trait :soft_deleted do
    deleted_at { Time.current }
  end
end

RSpec.describe "Global traits" do
  FactoryBot.define do
    factory :record do
      name { "Record" }
    end
  end

  describe "using global traits" do
    let(:record) { build(:record, :timestamped, :soft_deleted) }

    it "applies global traits to any factory" do
      expect(record.created_at).to be_present
      expect(record.deleted_at).to be_present
    end
  end
end

# Traits with callbacks
FactoryBot.define do
  factory :user do
    name { "User" }

    trait :with_posts do
      after(:create) do |user|
        create_list(:post, 3, author: user)
      end
    end

    trait :activated do
      after(:build) { |user| user.activate! }
    end

    trait :confirmed do
      after(:create) { |user| user.confirm! }
    end
  end
end

RSpec.describe "Traits with callbacks" do
  describe "trait with after(:create)" do
    let(:user) { create(:user, :with_posts) }

    it "runs callback when trait applied" do
      expect(user.posts.count).to eq(3)
    end
  end

  describe "callback order with multiple traits" do
    # Callbacks run in order traits are specified
    let(:user) { create(:user, :activated, :confirmed) }

    it "executes callbacks in trait order" do
      expect(user).to be_activated
      expect(user).to be_confirmed
    end
  end
end

# Traits with transient attributes
FactoryBot.define do
  factory :user do
    name { "User" }

    trait :with_posts do
      transient do
        posts_count { 5 }
      end

      after(:create) do |user, evaluator|
        create_list(:post, evaluator.posts_count, author: user)
      end
    end
  end
end

RSpec.describe "Traits with transient attributes" do
  describe "configurable trait behavior" do
    let(:user) { create(:user, :with_posts, posts_count: 10) }

    it "uses transient attribute in callback" do
      expect(user.posts.count).to eq(10)
    end
  end
end

# Traits in associations
FactoryBot.define do
  factory :comment do
    body { "Comment" }
    association :author, factory: [:user, :admin]
  end

  factory :post do
    title { "Post" }
    association :author, :verified, factory: :user
  end
end

RSpec.describe "Traits in associations" do
  describe "association with trait" do
    let(:comment) { create(:comment) }
    let(:post) { create(:post) }

    it "applies traits to associated factory" do
      expect(comment.author).to be_admin
      expect(post.author).to be_verified
    end
  end
end
