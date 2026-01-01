# RSpec Matchers: Type/Class Examples
# Source: rspec-expectations gem features/built_in_matchers/types.feature, respond_to.feature

# be_instance_of - exact class match
RSpec.describe "be_instance_of matcher" do
  it "matches exact class only" do
    expect(17.0).to be_instance_of(Float)
    expect(17.0).to be_an_instance_of(Float)  # Alias
  end

  it "does NOT match superclass" do
    expect(17.0).not_to be_instance_of(Numeric)  # Float < Numeric
  end
end

# be_kind_of / be_a - class hierarchy match
RSpec.describe "be_kind_of matcher" do
  it "matches actual class" do
    expect(17.0).to be_kind_of(Float)
    expect(17.0).to be_a(Float)    # Alias
    expect(17.0).to be_an(Integer) # Grammatical alias (fails - just for example)
  end

  it "matches superclass" do
    expect(17.0).to be_kind_of(Numeric)
    expect(17.0).to be_a(Object)
  end

  it "matches included modules" do
    expect([1, 2, 3]).to be_kind_of(Enumerable)
  end
end

# respond_to - interface checking
RSpec.describe "respond_to matcher" do
  it "checks method existence" do
    expect("string").to respond_to(:length)
    expect("string").to respond_to(:upcase, :downcase)  # Multiple
    expect("string").not_to respond_to(:foo)
  end

  it "checks argument count" do
    expect(7).to respond_to(:zero?).with(0).arguments
    expect(7).to respond_to(:between?).with(2).arguments
  end

  it "checks argument range" do
    # Methods with optional arguments
    expect([]).to respond_to(:first).with(0..1).arguments
  end

  it "checks keyword arguments" do
    service = build(:payment_service)

    expect(service).to respond_to(:process).with_keywords(:amount, :currency)
    expect(service).to respond_to(:process).with(1).argument.and_keywords(:amount)
  end
end

# Practical example: duck typing
RSpec.describe "exportable object" do
  subject(:exporter) { build(:csv_exporter) }

  it "implements exportable interface" do
    expect(exporter).to respond_to(:export).with(1).argument
    expect(exporter).to respond_to(:headers)
    expect(exporter).to respond_to(:rows)
  end
end

# Practical example: model type checking
RSpec.describe User do
  subject(:user) { build(:user) }

  it "is an ApplicationRecord" do
    expect(user).to be_a(ApplicationRecord)
  end

  it "includes Authenticatable" do
    expect(user).to be_kind_of(Authenticatable)
  end
end
