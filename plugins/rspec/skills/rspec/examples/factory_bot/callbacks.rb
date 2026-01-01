# FactoryBot: Callbacks Examples
# Source: factory_bot gem spec/acceptance/callbacks_spec.rb

# Callbacks execute at specific points during object creation.
# Available: before(:build), after(:build), before(:create),
# after(:create), after(:stub)

# Basic callbacks
FactoryBot.define do
  factory :user do
    name { "John" }

    after(:build) do |user|
      user.setup_defaults
    end

    after(:create) do |user|
      user.send_welcome_email
    end

    after(:stub) do |user|
      user.define_singleton_method(:fake?) { true }
    end
  end
end

RSpec.describe "Basic callbacks" do
  describe "after(:build)" do
    let(:user) { build(:user) }

    it "runs after object is built" do
      # setup_defaults was called
      expect(user).to be_valid
    end
  end

  describe "after(:create)" do
    let(:user) { create(:user) }

    it "runs after object is persisted" do
      # send_welcome_email was called
      expect(user).to be_persisted
    end
  end

  describe "after(:stub)" do
    let(:user) { build_stubbed(:user) }

    it "runs after stubbing" do
      expect(user.fake?).to be true
    end
  end
end

# Callback with evaluator
FactoryBot.define do
  factory :user do
    transient do
      skip_confirmation { false }
      posts_count { 0 }
    end

    after(:create) do |user, evaluator|
      user.confirm! unless evaluator.skip_confirmation
      create_list(:post, evaluator.posts_count, author: user)
    end
  end
end

RSpec.describe "Callback with evaluator" do
  describe "accessing transient attributes" do
    let(:unconfirmed_user) { create(:user, skip_confirmation: true) }
    let(:user_with_posts) { create(:user, posts_count: 3) }

    it "uses transient in callback logic" do
      expect(unconfirmed_user).not_to be_confirmed
      expect(user_with_posts.posts.count).to eq(3)
    end
  end
end

# Callback execution order
FactoryBot.define do
  factory :item do
    sequence(:log) { |n| [] }

    before(:build) { |item| item.log << "before_build" }
    after(:build) { |item| item.log << "after_build" }
    before(:create) { |item| item.log << "before_create" }
    after(:create) { |item| item.log << "after_create" }
  end
end

RSpec.describe "Callback order" do
  describe "build strategy" do
    let(:item) { build(:item) }

    it "runs build callbacks only" do
      expect(item.log).to eq(%w[before_build after_build])
    end
  end

  describe "create strategy" do
    let(:item) { create(:item) }

    it "runs all callbacks in order" do
      expect(item.log).to eq(%w[
        before_build after_build before_create after_create
      ])
    end
  end
end

# Inherited callback order
FactoryBot.define do
  factory :parent_item, class: "Item" do
    after(:create) { |item| item.log << "parent_callback" }

    factory :child_item do
      after(:create) { |item| item.log << "child_callback" }
    end
  end
end

RSpec.describe "Inherited callbacks" do
  describe "parent then child" do
    let(:item) { create(:child_item) }

    it "runs parent callbacks first" do
      # parent_callback before child_callback
      parent_idx = item.log.index("parent_callback")
      child_idx = item.log.index("child_callback")
      expect(parent_idx).to be < child_idx
    end
  end
end

# Trait callbacks
FactoryBot.define do
  factory :user do
    name { "User" }

    trait :with_avatar do
      after(:create) { |user| user.avatar.attach(io: File.open("avatar.png"), filename: "avatar.png") }
    end

    trait :activated do
      after(:build) { |user| user.activate! }
    end
  end
end

RSpec.describe "Trait callbacks" do
  describe "callback in trait" do
    let(:user) { create(:user, :with_avatar) }

    it "runs trait callback when trait applied" do
      expect(user.avatar).to be_attached
    end
  end

  describe "multiple trait callbacks" do
    let(:user) { create(:user, :activated, :with_avatar) }

    it "runs callbacks in trait order" do
      expect(user).to be_activated
      expect(user.avatar).to be_attached
    end
  end
end

# Global callbacks
FactoryBot.define do
  # Global callback - applies to ALL factories
  after(:build) do |object|
    object.metadata = {created_by: "factory"} if object.respond_to?(:metadata=)
  end

  factory :record do
    name { "Record" }
  end

  factory :document do
    title { "Document" }
  end
end

RSpec.describe "Global callbacks" do
  describe "applies to all factories" do
    let(:record) { build(:record) }
    let(:document) { build(:document) }

    it "runs for every factory" do
      expect(record.metadata[:created_by]).to eq("factory")
      expect(document.metadata[:created_by]).to eq("factory")
    end
  end
end

# Symbol#to_proc in callbacks
FactoryBot.define do
  factory :user do
    name { "user" }

    after(:build, &:normalize_name!)
    after(:create, &:index_for_search!)
  end
end

RSpec.describe "Symbol#to_proc callbacks" do
  let(:user) { create(:user) }

  it "calls method on instance" do
    # normalize_name! and index_for_search! were called
    expect(user).to be_valid
  end
end

# Multiple callbacks for same event
FactoryBot.define do
  factory :order do
    after(:create) { |order| order.calculate_totals }
    after(:create) { |order| order.update_inventory }
    after(:create) { |order| order.notify_warehouse }
  end
end

RSpec.describe "Multiple callbacks" do
  let(:order) { create(:order) }

  it "runs all callbacks in definition order" do
    # All three after(:create) callbacks ran
    expect(order.totals_calculated?).to be true
    expect(order.inventory_updated?).to be true
    expect(order.warehouse_notified?).to be true
  end
end

# Skipping create
FactoryBot.define do
  factory :api_resource do
    skip_create  # Don't call save

    name { "Resource" }
  end
end

RSpec.describe "skip_create" do
  describe "bypasses persistence" do
    let(:resource) { create(:api_resource) }

    it "doesn't persist to database" do
      expect(resource).to be_new_record
    end
  end
end

# Custom to_create
FactoryBot.define do
  factory :external_record do
    name { "External" }

    to_create { |instance| instance.remote_save! }
  end

  factory :validated_record do
    name { "Validated" }

    to_create { |instance| instance.save(validate: false) }
  end
end

RSpec.describe "Custom to_create" do
  describe "custom persistence" do
    let(:external) { create(:external_record) }

    it "uses custom create method" do
      # remote_save! was called instead of save!
      expect(external).to be_persisted
    end
  end

  describe "skip validation" do
    let(:record) { create(:validated_record) }

    it "saves without validation" do
      # save(validate: false) was called
      expect(record).to be_persisted
    end
  end
end

# to_create with evaluator
FactoryBot.define do
  factory :configurable_record do
    transient do
      persist_immediately { true }
    end

    to_create do |instance, evaluator|
      if evaluator.persist_immediately
        instance.save!
      else
        instance.queue_for_later_save
      end
    end
  end
end

RSpec.describe "to_create with evaluator" do
  describe "conditional persistence" do
    let(:immediate) { create(:configurable_record, persist_immediately: true) }
    let(:deferred) { create(:configurable_record, persist_immediately: false) }

    it "uses transient to control behavior" do
      expect(immediate).to be_persisted
      expect(deferred).to be_queued
    end
  end
end
