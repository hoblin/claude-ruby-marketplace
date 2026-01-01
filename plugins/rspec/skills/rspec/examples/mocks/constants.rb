# RSpec Mocks: Constant Stubbing Examples
# Source: rspec-mocks gem features/mutating_constants/*.feature

# stub_const - temporarily replace constant values
RSpec.describe "stub_const" do
  describe "top-level constants" do
    it "stubs constant for duration of example" do
      stub_const("FOO", 5)
      expect(FOO).to eq(5)
    end

    it "restores original value after example" do
      original = FOO rescue nil
      stub_const("FOO", 999)
      # After this example, FOO returns to original
    end
  end

  describe "nested constants" do
    it "stubs nested class constants" do
      stub_const("MyGem::SomeClass::PER_PAGE", 100)
      expect(MyGem::SomeClass::PER_PAGE).to eq(100)
    end

    it "stubs module constants" do
      stub_const("Rails::VERSION", "7.0.0")
      expect(Rails::VERSION).to eq("7.0.0")
    end
  end

  describe "replacing classes" do
    it "stubs with fake class" do
      fake_class = Class.new do
        def self.perform
          :fake_result
        end
      end

      stub_const("HeavyWorker", fake_class)
      expect(HeavyWorker.perform).to eq(:fake_result)
    end
  end

  describe "transfer_nested_constants" do
    it "transfers all nested constants" do
      fake_deck = Class.new

      stub_const("CardDeck", fake_deck, transfer_nested_constants: true)

      # Original CardDeck::SUITS is now available on fake_deck
      expect(CardDeck::SUITS).to eq(%w[hearts diamonds clubs spades])
    end

    it "transfers selected constants" do
      fake_deck = Class.new

      stub_const("CardDeck", fake_deck, transfer_nested_constants: [:SUITS])

      expect(CardDeck::SUITS).to eq(%w[hearts diamonds clubs spades])
      # Other constants like RANKS are not transferred
    end
  end

  describe "undefined constants" do
    it "can stub constants that don't exist yet" do
      stub_const("FUTURE_FEATURE_FLAG", true)
      expect(FUTURE_FEATURE_FLAG).to be(true)
      # Constant is removed after example
    end
  end
end

# hide_const - temporarily make constant undefined
RSpec.describe "hide_const" do
  describe "hiding defined constants" do
    it "makes constant undefined" do
      hide_const("SomeClass")
      expect { SomeClass }.to raise_error(NameError)
    end

    it "restores constant after example" do
      hide_const("SomeClass")
      # After this example, SomeClass is available again
    end
  end

  describe "hiding nested constants" do
    it "hides nested constant" do
      hide_const("MyGem::SomeClass::TIMEOUT")
      expect { MyGem::SomeClass::TIMEOUT }.to raise_error(NameError)
    end
  end

  describe "hiding undefined constants" do
    it "does nothing for undefined constants" do
      # Safe to call - no error raised
      hide_const("DEFINITELY_NOT_DEFINED")
    end
  end
end

# Practical examples
RSpec.describe "configuration testing" do
  describe FeatureToggle do
    describe ".enabled?" do
      context "when feature is enabled" do
        before { stub_const("FeatureToggle::FEATURES", { dark_mode: true }) }

        it "returns true" do
          expect(FeatureToggle.enabled?(:dark_mode)).to be(true)
        end
      end

      context "when feature is disabled" do
        before { stub_const("FeatureToggle::FEATURES", { dark_mode: false }) }

        it "returns false" do
          expect(FeatureToggle.enabled?(:dark_mode)).to be(false)
        end
      end
    end
  end
end

RSpec.describe "environment-dependent code" do
  describe ApiClient do
    context "in production" do
      before { stub_const("Rails.env", ActiveSupport::StringInquirer.new("production")) }

      it "uses production URL" do
        expect(ApiClient.base_url).to eq("https://api.example.com")
      end
    end

    context "in development" do
      before { stub_const("Rails.env", ActiveSupport::StringInquirer.new("development")) }

      it "uses localhost URL" do
        expect(ApiClient.base_url).to eq("http://localhost:3000")
      end
    end
  end
end

RSpec.describe "testing error handling for missing dependencies" do
  describe ExternalServiceClient do
    context "when gem is not loaded" do
      before { hide_const("ExternalGem") }

      it "raises descriptive error" do
        expect { ExternalServiceClient.connect }
          .to raise_error("ExternalGem is required. Add it to your Gemfile.")
      end
    end
  end
end

RSpec.describe "pagination configuration" do
  describe UserListController do
    subject(:controller) { build(:user_list_controller) }

    context "with custom page size" do
      before { stub_const("UserListController::DEFAULT_PAGE_SIZE", 50) }

      it "uses custom page size" do
        expect(controller.default_page_size).to eq(50)
      end
    end

    context "with default page size" do
      it "uses standard page size" do
        expect(controller.default_page_size).to eq(25)
      end
    end
  end
end

