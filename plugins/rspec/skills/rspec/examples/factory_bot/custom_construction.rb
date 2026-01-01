# FactoryBot: Custom Construction Examples
# Source: factory_bot gem spec/acceptance/initialize_with_spec.rb

# initialize_with customizes how objects are constructed.
# Use for non-standard constructors or value objects.

# Basic initialize_with
FactoryBot.define do
  factory :point do
    x { 0 }
    y { 0 }

    initialize_with { Point.new(x, y) }
  end
end

RSpec.describe "Basic initialize_with" do
  let(:point) { build(:point, x: 5, y: 10) }

  it "uses custom constructor" do
    expect(point.x).to eq(5)
    expect(point.y).to eq(10)
  end
end

# Using new helper
FactoryBot.define do
  factory :user do
    name { "John" }
    email { "john@example.com" }

    # 'new' automatically calls User.new
    initialize_with { new(name:, email:) }
  end
end

RSpec.describe "new helper" do
  let(:user) { build(:user) }

  it "calls class constructor" do
    expect(user.name).to eq("John")
  end
end

# Using attributes hash
FactoryBot.define do
  factory :config do
    setting_a { "value_a" }
    setting_b { "value_b" }

    initialize_with { new(**attributes) }
  end
end

RSpec.describe "attributes hash" do
  let(:config) { build(:config) }

  it "passes all attributes to constructor" do
    expect(config.setting_a).to eq("value_a")
    expect(config.setting_b).to eq("value_b")
  end
end

# Class methods as constructors
FactoryBot.define do
  factory :user_from_api, class: "User" do
    external_id { "ext_123" }
    name { "API User" }

    initialize_with { User.from_api(external_id, name) }
  end

  factory :user_with_defaults, class: "User" do
    role { "member" }

    initialize_with { User.create_with_defaults(role) }
  end
end

RSpec.describe "Class method constructors" do
  describe "factory method" do
    let(:user) { build(:user_from_api) }

    it "uses class method" do
      expect(user.external_id).to eq("ext_123")
    end
  end
end

# Transient attributes in initialize_with
FactoryBot.define do
  factory :document do
    transient do
      template { :blank }
    end

    title { "Document" }

    initialize_with { Document.from_template(template, title:) }
  end
end

RSpec.describe "Transient in initialize_with" do
  describe "accessing transient" do
    let(:invoice) { build(:document, template: :invoice) }

    it "uses transient in constructor" do
      expect(invoice.template).to eq(:invoice)
    end
  end
end

# Non-ActiveRecord objects
FactoryBot.define do
  factory :report_generator do
    transient do
      report_name { "Monthly Report" }
      data_source { :database }
    end

    initialize_with { ReportGenerator.new(report_name, data_source) }

    skip_create  # Not an ActiveRecord model
  end
end

RSpec.describe "Plain Ruby objects" do
  let(:generator) { create(:report_generator, report_name: "Sales") }

  it "works without ActiveRecord" do
    expect(generator.report_name).to eq("Sales")
  end
end

# Value objects
FactoryBot.define do
  factory :money do
    amount { 100 }
    currency { "USD" }

    initialize_with { Money.new(amount, currency) }
    skip_create
  end
end

RSpec.describe "Value objects" do
  let(:money) { build(:money, amount: 50, currency: "EUR") }

  it "creates immutable value object" do
    expect(money.amount).to eq(50)
    expect(money.currency).to eq("EUR")
  end
end

# Singleton-like construction
FactoryBot.define do
  factory :app_config, class: "AppConfig" do
    environment { "test" }

    initialize_with { AppConfig.instance_for(environment) }
    skip_create
  end
end

# Block in constructor
FactoryBot.define do
  factory :lazy_loader do
    transient do
      load_proc { -> { "loaded" } }
    end

    initialize_with { LazyLoader.new(&load_proc) }
    skip_create
  end
end

RSpec.describe "Constructor with block" do
  let(:loader) { build(:lazy_loader) }

  it "passes block to constructor" do
    expect(loader.load).to eq("loaded")
  end
end

# Inheritance with initialize_with
FactoryBot.define do
  factory :base_model do
    name { "Base" }
    initialize_with { new(name:) }

    factory :extended_model do
      description { "Extended" }
      # Inherits initialize_with from parent
    end

    factory :custom_model do
      # Override parent's initialize_with
      initialize_with { new(name: "Custom Override") }
    end
  end
end

RSpec.describe "initialize_with inheritance" do
  describe "child inherits" do
    let(:extended) { build(:extended_model) }

    it "uses parent constructor" do
      expect(extended.name).to eq("Base")
    end
  end

  describe "child overrides" do
    let(:custom) { build(:custom_model) }

    it "uses own constructor" do
      expect(custom.name).to eq("Custom Override")
    end
  end
end

# to_create customization
FactoryBot.define do
  factory :external_resource do
    name { "Resource" }

    to_create { |instance| instance.sync_to_remote! }
  end

  factory :bulk_insertable do
    name { "Bulk" }

    to_create { |instance| instance.save(validate: false) }
  end
end

RSpec.describe "Custom to_create" do
  describe "remote sync" do
    let(:resource) { create(:external_resource) }

    it "uses custom persistence" do
      expect(resource).to be_synced
    end
  end

  describe "skip validation" do
    let(:record) { create(:bulk_insertable) }

    it "saves without validation" do
      expect(record).to be_persisted
    end
  end
end

# to_create with evaluator
FactoryBot.define do
  factory :conditional_save do
    transient do
      force { false }
    end

    name { "Record" }

    to_create do |instance, evaluator|
      if evaluator.force
        instance.save!(validate: false)
      else
        instance.save!
      end
    end
  end
end

RSpec.describe "to_create with evaluator" do
  let(:forced) { create(:conditional_save, force: true) }
  let(:normal) { create(:conditional_save, force: false) }

  it "uses transient to control behavior" do
    expect(forced).to be_persisted
    expect(normal).to be_persisted
  end
end

# skip_create for read-only objects
FactoryBot.define do
  factory :read_only_view, class: "DatabaseView" do
    name { "View" }
    skip_create
  end
end

RSpec.describe "skip_create" do
  let(:view) { create(:read_only_view) }

  it "doesn't persist" do
    expect(view).to be_new_record
  end
end

# Complex initialization
FactoryBot.define do
  factory :complex_object do
    transient do
      config { {} }
      dependencies { [] }
    end

    name { "Complex" }

    initialize_with do
      obj = ComplexObject.new(name)
      obj.configure(config)
      dependencies.each { |dep| obj.add_dependency(dep) }
      obj
    end

    skip_create
  end
end

RSpec.describe "Complex initialization" do
  let(:deps) { [build(:dependency), build(:dependency)] }
  let(:complex) { build(:complex_object, config: {key: "value"}, dependencies: deps) }

  it "performs multi-step initialization" do
    expect(complex.config[:key]).to eq("value")
    expect(complex.dependencies.count).to eq(2)
  end
end
