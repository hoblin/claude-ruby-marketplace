# RSpec Mocks: Message Expectations (expect) Examples
# Source: rspec-mocks gem features/basics/expecting_messages.feature

# expect(...).to receive - message must be called
RSpec.describe "message expectations" do
  describe "basic expectations" do
    it "fails if message is not received" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo)

      # Without calling dbl.foo, this would fail with:
      # "(Double 'collaborator').foo(*(any args)) expected: 1 time..."
      dbl.foo
    end

    it "passes when message is received" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo)
      dbl.foo
    end
  end

  describe "negative expectations" do
    it "fails if forbidden message is received" do
      dbl = double("collaborator")
      expect(dbl).not_to receive(:foo)

      # Calling dbl.foo here would fail immediately
    end
  end

  describe "custom failure messages" do
    it "provides context when expectation fails" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo), "dbl should call :foo during authentication"
      dbl.foo
    end
  end

  describe "expect vs allow" do
    it "allow permits but doesn't require calls" do
      dbl = double("collaborator")
      allow(dbl).to receive(:foo)
      # Not calling foo is fine
    end

    it "expect requires calls" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo)
      dbl.foo  # Must be called
    end
  end
end

# Practical example: verifying collaborator interactions
RSpec.describe Account do
  subject(:account) { build(:account, logger:, balance: 1000) }

  let(:logger) { instance_double("Logger") }

  describe "#close" do
    it "logs the closure event" do
      expect(logger).to receive(:info).with("Account closed")
      account.close
    end

    it "logs the final balance" do
      expect(logger).to receive(:info).with(/Balance: \d+/)
      account.close
    end
  end

  describe "#withdraw" do
    context "with sufficient funds" do
      it "does not log warnings" do
        allow(logger).to receive(:info)
        expect(logger).not_to receive(:warn)

        account.withdraw(100)
      end
    end

    context "with insufficient funds" do
      it "logs a warning" do
        allow(logger).to receive(:info)
        expect(logger).to receive(:warn).with(/insufficient funds/i)

        account.withdraw(10_000)
      end
    end
  end
end

# Practical example: event publishing
RSpec.describe OrderService do
  subject(:service) { build(:order_service, publisher:) }

  let(:publisher) { instance_double("EventPublisher") }
  let(:order) { build(:order) }

  describe "#complete" do
    it "publishes order completed event" do
      expect(publisher).to receive(:publish).with(
        "order.completed",
        hash_including(order_id: order.id)
      )

      service.complete(order)
    end

    it "publishes exactly one event" do
      expect(publisher).to receive(:publish).once
      service.complete(order)
    end
  end
end

# Combining expect and allow on same double
RSpec.describe "mixed expectations and stubs" do
  subject(:processor) { build(:payment_processor, gateway:, logger:) }

  let(:gateway) { instance_double("PaymentGateway") }
  let(:logger) { instance_double("Logger") }

  describe "#process" do
    it "charges gateway and logs result" do
      # Stub the gateway response
      allow(gateway).to receive(:charge).and_return(success: true)

      # Expect logging to happen
      expect(logger).to receive(:info).with(/Payment processed/)

      processor.process(amount: 100)
    end
  end
end

