# RSpec Mocks: Stubbing (allow) Examples
# Source: rspec-mocks gem features/basics/allowing_messages.feature,
#         partial_test_doubles.feature

# Basic allow syntax
RSpec.describe "allow (stubbing)" do
  describe "basic stubs" do
    it "returns nil by default" do
      dbl = double("collaborator")
      allow(dbl).to receive(:foo)

      expect(dbl.foo).to be_nil
    end

    it "returns specified value with and_return" do
      dbl = double("collaborator")
      allow(dbl).to receive(:foo).and_return("bar")

      expect(dbl.foo).to eq("bar")
    end

    it "returns value with block syntax" do
      dbl = double("collaborator")
      allow(dbl).to receive(:foo) { "bar" }

      expect(dbl.foo).to eq("bar")
    end
  end

  describe "multiple stubs" do
    it "stubs multiple methods with receive_messages" do
      dbl = double("collaborator")
      allow(dbl).to receive_messages(
        title: "The RSpec Book",
        subtitle: "BDD with RSpec"
      )

      expect(dbl.title).to eq("The RSpec Book")
      expect(dbl.subtitle).to eq("BDD with RSpec")
    end
  end
end

# Partial doubles - stubbing methods on real objects
RSpec.describe "partial doubles" do
  describe "stubbing real objects" do
    it "stubs specific methods while preserving others" do
      string = "a string"
      allow(string).to receive(:length).and_return(500)

      expect(string.length).to eq(500)
      expect(string.reverse).to eq("gnirts a")  # Still works
    end

    it "stubs class methods" do
      allow(User).to receive(:find).and_return(build(:user, name: "Stubbed"))

      expect(User.find(1).name).to eq("Stubbed")
    end
  end

  describe "stub restoration" do
    # Stubs are automatically restored after each example
    it "first example stubs User.count" do
      allow(User).to receive(:count).and_return(100)
      expect(User.count).to eq(100)
    end

    it "next example has original behavior" do
      # User.count works normally again
      expect(User.count).to be_a(Integer)
    end
  end
end

# Practical example: stubbing external services
RSpec.describe WeatherService do
  subject(:service) { build(:weather_service, client:) }

  let(:client) { instance_double("HTTPClient") }

  describe "#temperature" do
    context "when API returns data" do
      before do
        allow(client).to receive(:get)
          .with("/weather", hash_including(zip: "12345"))
          .and_return(temp: 72, humidity: 45)
      end

      it "extracts temperature from response" do
        expect(service.temperature("12345")).to eq(72)
      end
    end

    context "when API returns nil" do
      before do
        allow(client).to receive(:get).and_return(nil)
      end

      it "returns default value" do
        expect(service.temperature("12345")).to eq(0)
      end
    end
  end
end

# Practical example: isolating database calls
RSpec.describe ReportGenerator do
  subject(:generator) { build(:report_generator) }

  describe "#monthly_summary" do
    let(:orders) { build_list(:order, 3, total: 100) }

    before do
      allow(Order).to receive(:where).and_return(orders)
      allow(orders).to receive(:sum).with(:total).and_return(300)
    end

    it "calculates total from orders" do
      summary = generator.monthly_summary(Date.current)
      expect(summary[:total]).to eq(300)
    end

    it "queries orders for the month" do
      generator.monthly_summary(Date.new(2024, 1, 15))

      expect(Order).to have_received(:where).with(
        created_at: Date.new(2024, 1, 1)..Date.new(2024, 1, 31)
      )
    end
  end
end

