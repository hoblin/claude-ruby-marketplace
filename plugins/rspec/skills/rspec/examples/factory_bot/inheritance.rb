# FactoryBot: Inheritance Examples
# Source: factory_bot gem spec/acceptance/parent_spec.rb

# Child factories inherit attributes, traits, and callbacks
# from parent factories.

# Nested factories (implicit inheritance)
FactoryBot.define do
  factory :user do
    name { "John Doe" }
    email { "#{name.parameterize}@example.com" }
    role { "member" }

    factory :admin do
      role { "admin" }
      admin_since { Time.current }
    end

    factory :moderator do
      role { "moderator" }
    end

    factory :guest do
      name { "Guest User" }
      role { "guest" }
    end
  end
end

RSpec.describe "Nested factories" do
  describe "inherit parent attributes" do
    let(:admin) { build(:admin) }

    it "has parent attributes" do
      expect(admin.email).to include("@example.com")
    end

    it "overrides specified attributes" do
      expect(admin.role).to eq("admin")
    end

    it "adds child-specific attributes" do
      expect(admin.admin_since).to be_present
    end
  end

  describe "dependent attribute inheritance" do
    let(:guest) { build(:guest) }

    it "cascades changes through dependent attributes" do
      # name changed, so email changes too
      expect(guest.email).to eq("guest-user@example.com")
    end
  end
end

# Explicit parent
FactoryBot.define do
  factory :user do
    name { "User" }

    factory :active_user do
      active { true }
    end
  end

  factory :super_user, parent: :active_user do
    superpower { true }
  end
end

RSpec.describe "Explicit parent" do
  describe "parent: option" do
    let(:super_user) { build(:super_user) }

    it "inherits from specified parent" do
      expect(super_user.active).to be true
      expect(super_user.superpower).to be true
    end
  end
end

# Parent overrides nesting
FactoryBot.define do
  factory :base_user, class: "User" do
    name { "Base" }

    factory :child_user do
      name { "Child" }

      # Despite nesting, inherits from :special_user
      factory :override_user, parent: :special_user do
        name { "Override" }
      end
    end
  end

  factory :special_user, class: "User" do
    name { "Special" }
    special { true }
  end
end

RSpec.describe "Parent overrides nesting" do
  describe "explicit parent takes precedence" do
    let(:override) { build(:override_user) }

    it "inherits from parent: not nesting context" do
      # Has special from :special_user parent
      expect(override.special).to be true
      expect(override.name).to eq("Override")
    end
  end
end

# Trait inheritance
FactoryBot.define do
  factory :post do
    title { "Post" }

    trait :published do
      published { true }
    end

    trait :featured do
      featured { true }
    end

    factory :blog_post do
      title { "Blog Post" }
      # Traits from parent available

      factory :featured_blog_post do
        featured  # Grandparent trait
      end
    end
  end
end

RSpec.describe "Trait inheritance" do
  describe "traits available to children" do
    let(:published_blog) { build(:blog_post, :published) }

    it "uses parent traits" do
      expect(published_blog.published).to be true
    end
  end

  describe "grandparent traits" do
    let(:featured) { build(:featured_blog_post) }

    it "inherits traits from grandparent" do
      expect(featured.featured).to be true
    end
  end
end

# Callback inheritance
FactoryBot.define do
  factory :record do
    sequence(:log) { [] }

    after(:create) { |r| r.log << "parent" }

    factory :child_record do
      after(:create) { |r| r.log << "child" }

      factory :grandchild_record do
        after(:create) { |r| r.log << "grandchild" }
      end
    end
  end
end

RSpec.describe "Callback inheritance" do
  describe "callbacks execute in order" do
    let(:grandchild) { create(:grandchild_record) }

    it "runs parent callbacks first" do
      expect(grandchild.log).to eq(%w[parent child grandchild])
    end
  end
end

# Deep inheritance chain
FactoryBot.define do
  factory :vehicle do
    wheels { 4 }
    engine { true }

    factory :car do
      doors { 4 }

      factory :sedan do
        body_type { "sedan" }
      end

      factory :suv do
        body_type { "suv" }
        wheels { 4 }  # Same as parent, explicit for clarity
      end
    end

    factory :motorcycle do
      wheels { 2 }
      doors { 0 }
    end
  end
end

RSpec.describe "Deep inheritance" do
  describe "multi-level hierarchy" do
    let(:sedan) { build(:sedan) }

    it "inherits all ancestor attributes" do
      expect(sedan.wheels).to eq(4)    # from :vehicle
      expect(sedan.engine).to be true  # from :vehicle
      expect(sedan.doors).to eq(4)     # from :car
      expect(sedan.body_type).to eq("sedan")
    end
  end
end

# Overriding inherited attributes
FactoryBot.define do
  factory :employee do
    name { "Employee" }
    salary { 50_000 }
    department { "General" }

    factory :manager do
      salary { 80_000 }
      department { "Management" }

      factory :executive do
        salary { 150_000 }
        department { "Executive" }
        stock_options { true }
      end
    end
  end
end

RSpec.describe "Overriding inherited attributes" do
  describe "each level can override" do
    let(:employee) { build(:employee) }
    let(:manager) { build(:manager) }
    let(:executive) { build(:executive) }

    it "uses most specific value" do
      expect(employee.salary).to eq(50_000)
      expect(manager.salary).to eq(80_000)
      expect(executive.salary).to eq(150_000)
    end
  end
end

# Inheriting associations
FactoryBot.define do
  factory :post do
    title { "Post" }
    user

    factory :published_post do
      published { true }
      # Inherits user association
    end
  end
end

RSpec.describe "Association inheritance" do
  describe "child inherits associations" do
    let(:published) { build(:published_post) }

    it "has parent association" do
      expect(published.user).to be_present
    end
  end
end

# initialize_with inheritance
FactoryBot.define do
  factory :custom_object do
    name { "Custom" }
    initialize_with { new(name:) }

    factory :child_custom do
      description { "Child" }
      # Inherits initialize_with
    end

    factory :override_custom do
      initialize_with { new(name: "Overridden") }
    end
  end
end

RSpec.describe "initialize_with inheritance" do
  describe "child inherits constructor" do
    let(:child) { build(:child_custom) }

    it "uses parent initialize_with" do
      expect(child.name).to eq("Custom")
    end
  end

  describe "child can override" do
    let(:override) { build(:override_custom) }

    it "uses own initialize_with" do
      expect(override.name).to eq("Overridden")
    end
  end
end
