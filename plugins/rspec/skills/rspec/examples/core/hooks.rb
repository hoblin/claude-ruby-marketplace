# RSpec Core: Hooks Examples
# Source: rspec-core gem features/hooks/before_and_after_hooks.feature

# before(:example) - runs before each example
# NOTE: Use let/let! instead of before + instance variables
RSpec.describe Thing do
  let(:thing) { build(:thing) }

  it "has 0 widgets initially" do
    expect(thing.widgets.count).to eq(0)
  end

  it "can accept widgets" do
    thing.widgets << build(:widget)
    expect(thing.widgets.count).to eq(1)
  end

  it "does not share state across examples" do
    expect(thing.widgets.count).to eq(0)  # Fresh thing via let
  end
end

# Hook scopes - configuration level
# NOTE: Suite/context level hooks are configured globally
RSpec.configure do |config|
  config.before(:suite) do
    # Run once before all specs (database setup, etc.)
    DatabaseCleaner.strategy = :transaction
  end

  config.after(:suite) do
    # Run once after all specs (cleanup)
  end
end

# Conditional hooks with metadata
RSpec.configure do |config|
  config.before(:example, :authorized) do
    sign_in_as(:authorized_user)
  end

  config.before(:example, db: :clean) do
    DatabaseCleaner.clean
  end
end

RSpec.describe AdminController, :authorized do
  let(:admin) { create(:user, :admin) }

  it "allows access" do  # sign_in_as runs automatically
    get :index
    expect(response).to be_successful
  end
end

# around hooks - wrap example execution
RSpec.describe "Database transaction" do
  around(:example) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  let(:user) { create(:user) }

  it "runs inside transaction" do
    expect(user).to be_persisted
    # Transaction rolled back after example
  end
end

# around with before/after - execution order
RSpec.describe "Hook order" do
  # Output order:
  # 1. around: before
  # 2. before
  # 3. example
  # 4. after
  # 5. around: after

  around(:example) do |example|
    puts "around: before"
    example.run
    puts "around: after"
  end

  before(:example) { puts "before" }
  after(:example) { puts "after" }

  it "runs in order" do
    puts "example"
  end
end

# before(:context) - shared expensive setup
# NOTE: let/subject/mocks NOT available in before(:context)
# Use instance variables ONLY when before(:context) is required
RSpec.describe "Expensive shared setup" do
  before(:context) do
    # This is the ONE exception where instance variables are acceptable
    # because let is not supported in before(:context)
    @shared_resource = ExpensiveResource.create
  end

  after(:context) do
    @shared_resource.cleanup
  end

  it "uses shared resource" do
    expect(@shared_resource).to be_ready
  end

  it "reuses same resource" do
    expect(@shared_resource).to be_ready
  end
end

# Preferred alternative: use let! with memoization at context level
RSpec.describe "Preferred shared setup" do
  # If possible, restructure to avoid before(:context)
  let!(:resource) { create(:expensive_resource) }

  it "uses resource" do
    expect(resource).to be_ready
  end
end
