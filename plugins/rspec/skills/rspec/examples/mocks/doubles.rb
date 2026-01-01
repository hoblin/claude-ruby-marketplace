# RSpec Mocks: Test Doubles Examples
# Source: rspec-mocks gem features/basics/test_doubles.feature,
#         verifying_doubles/*.feature

# Basic double - strict, raises on unexpected messages
RSpec.describe "basic double" do
  it "raises on unexpected messages" do
    dbl = double("collaborator")
    expect { dbl.foo }.to raise_error(RSpec::Mocks::MockExpectationError)
  end

  it "can be created with predefined stubs" do
    dbl = double("collaborator", foo: 3, bar: 4)
    expect(dbl.foo).to eq(3)
    expect(dbl.bar).to eq(4)
  end

  it "can be anonymous with stubs" do
    dbl = double(foo: "bar", baz: "qux")
    expect(dbl.foo).to eq("bar")
    expect(dbl.baz).to eq("qux")
  end
end

# instance_double - verifies against instance methods
RSpec.describe "instance_double" do
  describe "verification" do
    it "allows stubbing existing methods" do
      notifier = instance_double("ConsoleNotifier", notify: true)
      expect(notifier.notify).to be(true)
    end

    it "raises if stubbing non-existent method" do
      notifier = instance_double("ConsoleNotifier")
      expect {
        allow(notifier).to receive(:non_existent_method)
      }.to raise_error(RSpec::Mocks::MockExpectationError, /does not implement/)
    end

    it "verifies argument arity" do
      calculator = instance_double("Calculator")
      expect {
        allow(calculator).to receive(:add).with(1, 2, 3, 4, 5)
      }.to raise_error(RSpec::Mocks::MockExpectationError, /wrong number of arguments/)
    end
  end
end

# Practical example with instance_double
RSpec.describe UserNotificationService do
  subject(:service) { build(:user_notification_service, notifier:) }

  let(:notifier) { instance_double("ConsoleNotifier") }
  let(:user) { build(:user) }

  describe "#notify" do
    it "delegates to the notifier" do
      expect(notifier).to receive(:notify).with(user.email, "Welcome!")
      service.notify(user, "Welcome!")
    end
  end
end

# class_double - verifies against class methods
RSpec.describe "class_double" do
  describe "replacing constants" do
    it "can replace the class constant with as_stubbed_const" do
      fake_mailer = class_double("UserMailer").as_stubbed_const
      allow(fake_mailer).to receive(:send_welcome)

      # Now UserMailer refers to fake_mailer within this example
      UserMailer.send_welcome
      expect(fake_mailer).to have_received(:send_welcome)
    end

    it "transfers nested constants when requested" do
      fake_class = class_double("CardDeck").as_stubbed_const(
        transfer_nested_constants: true
      )
      # CardDeck::SUITS and other constants are now available
      expect(CardDeck::SUITS).to eq(%w[hearts diamonds clubs spades])
    end

    it "can selectively transfer constants" do
      fake_class = class_double("CardDeck").as_stubbed_const(
        transfer_nested_constants: [:SUITS]
      )
      # Only SUITS is transferred
      expect(CardDeck::SUITS).to eq(%w[hearts diamonds clubs spades])
    end
  end
end

# Practical example with class_double
RSpec.describe OrderProcessor do
  subject(:processor) { build(:order_processor) }

  let(:payment_gateway) { class_double("PaymentGateway").as_stubbed_const }

  describe "#process" do
    let(:order) { build(:order, amount: 100) }

    it "charges the payment gateway" do
      expect(payment_gateway).to receive(:charge).with(100).and_return(true)
      processor.process(order)
    end
  end
end

# object_double - doubles an existing object instance
RSpec.describe "object_double" do
  describe "doubling real objects" do
    it "avoids side effects while verifying methods" do
      real_user = User.new
      user_double = object_double(real_user, save: true)

      expect(user_double.save).to be(true)
    end

    it "verifies methods exist on the real object" do
      real_user = User.new
      user_double = object_double(real_user)

      expect {
        allow(user_double).to receive(:non_existent)
      }.to raise_error(RSpec::Mocks::MockExpectationError)
    end
  end

  describe "doubling constant objects" do
    it "can replace global logger" do
      logger = object_double("MyApp::LOGGER", info: nil, error: nil).as_stubbed_const

      MyApp::LOGGER.info("test message")
      expect(logger).to have_received(:info).with("test message")
    end
  end
end

