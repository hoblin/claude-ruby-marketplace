# RSpec Rails: Transactions and Database Examples
# Source: rspec-rails gem features/Transactions.md

# Database transactions in RSpec Rails.
# Each example runs in a transaction that's rolled back after.
# Location: spec/rails_helper.rb configuration

# Default transactional behavior
RSpec.describe Widget, type: :model do
  describe "transaction isolation" do
    it "has no widgets initially" do
      expect(Widget.count).to eq(0)
    end

    it "has one widget after creating" do
      Widget.create!(name: "Test")
      expect(Widget.count).to eq(1)
    end

    it "has no widgets again (previous was rolled back)" do
      expect(Widget.count).to eq(0)
    end
  end
end

# Using let! for setup within transaction
RSpec.describe "let! with transactions" do
  let!(:widget) { create(:widget) }

  it "widget exists in first example" do
    expect(Widget.count).to eq(1)
    expect(Widget.first).to eq(widget)
  end

  it "widget exists in second example (recreated)" do
    # let! runs before each example
    expect(Widget.count).to eq(1)
  end
end

# before(:example) vs before(:context)
RSpec.describe "before hooks and transactions" do
  describe "before(:example)" do
    before(:example) { create(:widget, name: "Example Widget") }

    it "creates widget for each example" do
      expect(Widget.count).to eq(1)
    end

    it "has fresh widget in next example" do
      expect(Widget.count).to eq(1)
      expect(Widget.first.name).to eq("Example Widget")
    end
  end

  describe "before(:context)" do
    # WARNING: Data created in before(:context) persists across examples
    # and is NOT rolled back. Must clean up manually.

    before(:context) do
      @context_widget = Widget.create!(name: "Context Widget")
    end

    after(:context) do
      @context_widget.destroy
    end

    before(:example) do
      # Must reload to avoid stale data within transaction
      @context_widget.reload
    end

    it "uses shared context widget" do
      expect(@context_widget.name).to eq("Context Widget")
    end

    it "also sees the context widget" do
      expect(Widget.find(@context_widget.id)).to be_present
    end
  end
end

# Testing transactions explicitly
RSpec.describe "Explicit transaction testing" do
  describe "rollback behavior" do
    it "rolls back on error" do
      expect {
        Widget.transaction do
          Widget.create!(name: "Will be rolled back")
          raise ActiveRecord::Rollback
        end
      }.not_to change(Widget, :count)
    end

    it "commits without error" do
      expect {
        Widget.transaction do
          Widget.create!(name: "Will be committed")
        end
      }.to change(Widget, :count).by(1)
    end
  end
end

# Configuration example (for rails_helper.rb)
RSpec.describe "Transaction configuration" do
  # Enable transactional fixtures (default)
  # RSpec.configure do |config|
  #   config.use_transactional_fixtures = true
  # end

  it "demonstrates transactional isolation" do
    widget = create(:widget)
    expect(Widget.count).to eq(1)

    # After this test, widget won't exist
  end
end

# Database Cleaner for non-transactional scenarios
# (e.g., JavaScript tests with Selenium)
RSpec.describe "Database Cleaner setup", skip: "documentation only" do
  # Configuration example:
  #
  # RSpec.configure do |config|
  #   config.before(:suite) do
  #     DatabaseCleaner.strategy = :transaction
  #     DatabaseCleaner.clean_with(:truncation)
  #   end
  #
  #   config.around(:each) do |example|
  #     DatabaseCleaner.cleaning do
  #       example.run
  #     end
  #   end
  #
  #   # Use truncation for JS tests
  #   config.before(:each, js: true) do
  #     DatabaseCleaner.strategy = :truncation
  #   end
  #
  #   config.after(:each, js: true) do
  #     DatabaseCleaner.strategy = :transaction
  #   end
  # end
end

# Testing database constraints
RSpec.describe "Database constraints" do
  describe "unique constraint" do
    let!(:widget) { create(:widget, name: "Unique") }

    it "raises error on duplicate" do
      expect {
        create(:widget, name: "Unique")
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "foreign key constraint" do
    let(:widget) { create(:widget) }
    let!(:component) { create(:component, widget:) }

    it "prevents deletion of referenced record" do
      expect {
        widget.destroy!
      }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end
end

# Testing with specific database features
RSpec.describe "Database-specific testing" do
  describe "locking" do
    let!(:widget) { create(:widget, count: 0) }

    it "uses pessimistic locking" do
      Widget.transaction do
        locked = Widget.lock.find(widget.id)
        locked.update!(count: locked.count + 1)
      end

      expect(widget.reload.count).to eq(1)
    end
  end

  describe "advisory locks" do
    it "obtains and releases lock", skip: "database-specific" do
      Widget.with_advisory_lock("test_lock") do
        # Critical section
        expect(Widget.advisory_lock_exists?("test_lock")).to be true
      end
    end
  end
end

# Testing seeds
RSpec.describe "Database seeds", type: :model do
  # Usually seeds are loaded once in test setup
  # Here's how to test seed data

  describe "seed data" do
    before(:context) do
      # Load seeds if needed
      # Rails.application.load_seed
    end

    it "creates default categories" do
      expect(Category.count).to be > 0
    end

    it "creates admin user" do
      expect(User.find_by(role: "admin")).to be_present
    end
  end
end

# Testing database migrations
RSpec.describe "Migration testing", skip: "run separately" do
  describe "up migration" do
    it "adds new column" do
      # Assuming a pending migration adds 'status' column
      ActiveRecord::Migrator.up(
        ActiveRecord::Migrator.migrations_paths,
        20240101000000
      )

      expect(Widget.column_names).to include("status")
    end
  end

  describe "down migration" do
    it "removes column" do
      ActiveRecord::Migrator.down(
        ActiveRecord::Migrator.migrations_paths,
        20240101000000
      )

      expect(Widget.column_names).not_to include("status")
    end
  end
end

# Parallel testing considerations
RSpec.describe "Parallel test isolation" do
  # Each parallel worker has its own database
  # Transactions work within each worker

  it "works in parallel environment" do
    # Create data - won't conflict with other workers
    widget = create(:widget)
    expect(widget).to be_persisted
  end
end
