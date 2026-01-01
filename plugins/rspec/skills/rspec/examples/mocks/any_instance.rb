# RSpec Mocks: any_instance Examples
# Source: rspec-mocks gem features/working_with_legacy_code/any_instance.feature

# WARNING: any_instance is discouraged. It often indicates:
# - Missing dependency injection
# - Tight coupling in design
# - Need for refactoring
#
# Prefer instance_double with explicit injection.
# Use any_instance only for legacy code you can't easily refactor.

# allow_any_instance_of - stub method on all instances
RSpec.describe "allow_any_instance_of" do
  describe "basic usage" do
    it "stubs method on any instance" do
      allow_any_instance_of(Widget).to receive(:name).and_return("Stubbed")

      widget1 = Widget.new
      widget2 = Widget.new

      expect(widget1.name).to eq("Stubbed")
      expect(widget2.name).to eq("Stubbed")
    end
  end

  describe "with receive_messages" do
    it "stubs multiple methods" do
      allow_any_instance_of(Widget).to receive_messages(
        name: "Stubbed",
        price: 100
      )

      widget = Widget.new
      expect(widget.name).to eq("Stubbed")
      expect(widget.price).to eq(100)
    end
  end

  describe "with arguments" do
    it "matches specific arguments" do
      allow_any_instance_of(Calculator).to receive(:add).with(1, 2).and_return(100)

      calc = Calculator.new
      expect(calc.add(1, 2)).to eq(100)
    end
  end

  describe "block receives instance" do
    it "passes instance as first argument to block" do
      allow_any_instance_of(String).to receive(:slice) do |instance, start, length|
        "Instance: #{instance[start, length]}"
      end

      expect("hello world".slice(0, 5)).to eq("Instance: hello")
    end
  end

  describe "consecutive return values" do
    it "applies per instance, not globally" do
      allow_any_instance_of(Counter).to receive(:value).and_return(1, 2, 3)

      first = Counter.new
      second = Counter.new

      # Each instance gets its own sequence
      expect(first.value).to eq(1)
      expect(first.value).to eq(2)
      expect(second.value).to eq(1)  # New instance, new sequence
      expect(first.value).to eq(3)
    end
  end
end

# expect_any_instance_of - expect at least one instance receives message
RSpec.describe "expect_any_instance_of" do
  describe "basic expectation" do
    it "passes if any instance receives the message" do
      expect_any_instance_of(Widget).to receive(:save)

      widget = Widget.new
      widget.save
    end
  end

  describe "with return value" do
    it "returns specified value and verifies call" do
      expect_any_instance_of(Widget).to receive(:save).and_return(true)

      widget = Widget.new
      expect(widget.save).to be(true)
    end
  end
end

# Legacy code example - why any_instance exists
RSpec.describe "legacy code scenario" do
  # Imagine this service creates its own dependencies internally
  # and we can't easily inject them
  class LegacyOrderService
    def process(order_id)
      order = Order.find(order_id)  # Creates Order internally
      order.process
      order.save
    end
  end

  describe LegacyOrderService do
    subject(:service) { LegacyOrderService.new }

    # Using any_instance because we can't inject Order
    it "processes and saves the order" do
      allow(Order).to receive(:find).and_return(build(:order))
      expect_any_instance_of(Order).to receive(:process)
      expect_any_instance_of(Order).to receive(:save)

      service.process(1)
    end
  end

  # BETTER: Refactor to use dependency injection
  class RefactoredOrderService
    def initialize(order_repository: Order)
      @order_repository = order_repository
    end

    def process(order_id)
      order = @order_repository.find(order_id)
      order.process
      order.save
    end

    private

    attr_reader :order_repository
  end

  describe RefactoredOrderService do
    subject(:service) { RefactoredOrderService.new(order_repository:) }

    let(:order_repository) { class_double("Order") }
    let(:order) { instance_double("Order") }

    it "processes and saves the order" do
      allow(order_repository).to receive(:find).and_return(order)
      expect(order).to receive(:process)
      expect(order).to receive(:save)

      service.process(1)
    end
  end
end

# When any_instance might be acceptable
RSpec.describe "acceptable any_instance usage" do
  describe "testing framework extensions" do
    # Testing behavior added to core classes
    it "stubs String extension method" do
      allow_any_instance_of(String).to receive(:custom_method).and_return("extended")

      expect("test".custom_method).to eq("extended")
    end
  end

  describe "testing monkey patches in legacy code" do
    it "verifies behavior without refactoring" do
      expect_any_instance_of(LegacyModel).to receive(:legacy_callback)

      LegacyModel.create(name: "test")
    end
  end
end

