# RSpec Mocks: Message Order Examples
# Source: rspec-mocks gem features/setting_constraints/message_order.feature

# NOTE: Ordered expectations can make specs brittle.
# Use only when message order is truly important.

# .ordered - enforce message sequence
RSpec.describe "message ordering" do
  describe "basic ordering" do
    it "requires messages in declared order" do
      dbl = double("collaborator")

      expect(dbl).to receive(:step_1).ordered
      expect(dbl).to receive(:step_2).ordered
      expect(dbl).to receive(:step_3).ordered

      dbl.step_1
      dbl.step_2
      dbl.step_3
    end
  end

  describe "across multiple doubles" do
    it "enforces order across collaborators" do
      collaborator_1 = double("first")
      collaborator_2 = double("second")

      expect(collaborator_1).to receive(:step_1).ordered
      expect(collaborator_2).to receive(:step_2).ordered
      expect(collaborator_1).to receive(:step_3).ordered

      collaborator_1.step_1
      collaborator_2.step_2
      collaborator_1.step_3
    end
  end

  describe "with have_received" do
    it "verifies order using spies" do
      invitation = spy("invitation")

      invitation.prepare
      invitation.send_email
      invitation.log_delivery

      expect(invitation).to have_received(:prepare).ordered
      expect(invitation).to have_received(:send_email).ordered
      expect(invitation).to have_received(:log_delivery).ordered
    end
  end

  describe "partial ordering" do
    it "only ordered expectations must be in sequence" do
      dbl = double("collaborator")

      allow(dbl).to receive(:any_time)  # Not ordered
      expect(dbl).to receive(:first).ordered
      expect(dbl).to receive(:second).ordered

      dbl.any_time  # Can be called anytime
      dbl.first
      dbl.any_time  # Still fine
      dbl.second
      dbl.any_time  # Still fine
    end
  end
end

# Practical example: transaction workflow
RSpec.describe PaymentProcessor do
  subject(:processor) { build(:payment_processor, gateway:, ledger:) }

  let(:gateway) { instance_double("PaymentGateway") }
  let(:ledger) { instance_double("Ledger") }
  let(:payment) { build(:payment, amount: 100) }

  describe "#process" do
    context "when order matters for consistency" do
      it "validates before charging" do
        # Must validate first, then charge
        expect(gateway).to receive(:validate).ordered.and_return(true)
        expect(gateway).to receive(:charge).ordered.and_return(true)
        allow(ledger).to receive(:record)

        processor.process(payment)
      end

      it "records in ledger after successful charge" do
        allow(gateway).to receive(:validate).and_return(true)

        expect(gateway).to receive(:charge).ordered.and_return(true)
        expect(ledger).to receive(:record).ordered

        processor.process(payment)
      end
    end
  end
end

# Practical example: state machine transitions
RSpec.describe OrderStateMachine do
  subject(:machine) { build(:order_state_machine, logger:) }

  let(:logger) { spy("logger") }

  describe "#complete" do
    it "transitions through states in order" do
      machine.complete

      expect(logger).to have_received(:log).with("pending -> processing").ordered
      expect(logger).to have_received(:log).with("processing -> shipped").ordered
      expect(logger).to have_received(:log).with("shipped -> delivered").ordered
    end
  end
end

# When NOT to use ordering
RSpec.describe "prefer unordered when possible" do
  subject(:notifier) { build(:multi_channel_notifier, email:, sms:, push:) }

  let(:email) { spy("email") }
  let(:sms) { spy("sms") }
  let(:push) { spy("push") }

  describe "#notify_all" do
    # BAD: Using ordered when order doesn't matter
    # it "sends all notifications in order" do
    #   expect(email).to receive(:send).ordered
    #   expect(sms).to receive(:send).ordered
    #   expect(push).to receive(:send).ordered
    #   notifier.notify_all
    # end

    # GOOD: Just verify all are called
    it "sends all notifications" do
      notifier.notify_all

      expect(email).to have_received(:send)
      expect(sms).to have_received(:send)
      expect(push).to have_received(:send)
    end
  end
end

