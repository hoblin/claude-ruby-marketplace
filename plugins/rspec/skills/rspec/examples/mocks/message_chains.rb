# RSpec Mocks: Message Chains Examples
# Source: rspec-mocks gem features/working_with_legacy_code/message_chains.feature

# WARNING: receive_message_chain violates Law of Demeter.
# It often indicates:
# - Code knows too much about collaborator structure
# - Need for facade or wrapper
# - Missing encapsulation
#
# Use only for legacy code. Prefer proper encapsulation.

# receive_message_chain - stub chained method calls
RSpec.describe "receive_message_chain" do
  describe "syntax forms" do
    it "accepts dot-separated string" do
      dbl = double("collaborator")
      allow(dbl).to receive_message_chain("foo.bar.baz") { :result }

      expect(dbl.foo.bar.baz).to eq(:result)
    end

    it "accepts symbols with hash for final return" do
      dbl = double("collaborator")
      allow(dbl).to receive_message_chain(:foo, :bar, baz: :result)

      expect(dbl.foo.bar.baz).to eq(:result)
    end

    it "accepts symbols with block" do
      dbl = double("collaborator")
      allow(dbl).to receive_message_chain(:foo, :bar, :baz) { :result }

      expect(dbl.foo.bar.baz).to eq(:result)
    end
  end

  describe "intermediate objects" do
    it "creates intermediates automatically" do
      dbl = double("collaborator")
      allow(dbl).to receive_message_chain(:a, :b, :c) { "end" }

      # Each call returns a new double
      intermediate = dbl.a.b
      expect(intermediate.c).to eq("end")
    end
  end

  describe "with any_instance_of" do
    it "stubs chains on any instance" do
      allow_any_instance_of(User).to receive_message_chain("account.balance") { 100 }

      user = User.new
      expect(user.account.balance).to eq(100)
    end
  end
end

# ActiveRecord example - common legacy pattern
RSpec.describe "ActiveRecord chaining" do
  # Legacy code might do: Article.recent.published.limit(5)
  describe "stubbing scope chains" do
    it "stubs the entire chain" do
      articles = build_list(:article, 3)
      allow(Article).to receive_message_chain("recent.published.limit") { articles }

      expect(Article.recent.published.limit(5)).to eq(articles)
    end
  end
end

# Better alternatives
RSpec.describe "alternatives to message chains" do
  # PROBLEM: Code uses deep chains
  class LegacyReportGenerator
    def generate
      User.active.verified.with_orders.map(&:email)
    end
  end

  # BAD: Stubbing chain
  describe LegacyReportGenerator do
    subject(:generator) { LegacyReportGenerator.new }

    it "generates report with message chain" do
      users = build_list(:user, 2, email: "test@example.com")
      allow(User).to receive_message_chain("active.verified.with_orders") { users }

      expect(generator.generate).to eq(["test@example.com", "test@example.com"])
    end
  end

  # BETTER: Extract scope into model method
  class User < ApplicationRecord
    def self.eligible_for_report
      active.verified.with_orders
    end
  end

  class BetterReportGenerator
    def initialize(user_scope: User)
      @user_scope = user_scope
    end

    def generate
      @user_scope.eligible_for_report.map(&:email)
    end
  end

  describe BetterReportGenerator do
    subject(:generator) { BetterReportGenerator.new(user_scope:) }

    let(:user_scope) { class_double("User") }

    it "generates report with single stub" do
      users = build_list(:user, 2, email: "test@example.com")
      allow(user_scope).to receive(:eligible_for_report).and_return(users)

      expect(generator.generate).to eq(["test@example.com", "test@example.com"])
    end
  end

  # BEST: Inject the query result directly
  class CleanReportGenerator
    def initialize(user_repository:)
      @user_repository = user_repository
    end

    def generate
      @user_repository.eligible_users.map(&:email)
    end
  end

  describe CleanReportGenerator do
    subject(:generator) { CleanReportGenerator.new(user_repository:) }

    let(:user_repository) { instance_double("UserRepository") }

    it "generates report with injected dependency" do
      users = build_list(:user, 2)
      allow(users).to receive(:map).and_return(["a@test.com", "b@test.com"])
      allow(user_repository).to receive(:eligible_users).and_return(users)

      result = generator.generate
      expect(result).to eq(["a@test.com", "b@test.com"])
    end
  end
end

# When message chains might be acceptable
RSpec.describe "acceptable chain usage" do
  describe "null object chains" do
    it "stubs deep configuration access" do
      # Configuration objects often have deep chains
      config = double("config").as_null_object
      allow(config).to receive_message_chain("database.connection.pool_size") { 5 }

      expect(config.database.connection.pool_size).to eq(5)
    end
  end

  describe "test setup helpers" do
    # In test setup, brevity might outweigh purity
    it "quickly stubs Rails request chain" do
      controller = double("controller")
      allow(controller).to receive_message_chain("request.headers.[]")
        .with("Authorization")
        .and_return("Bearer token123")

      expect(controller.request.headers["Authorization"]).to eq("Bearer token123")
    end
  end
end

