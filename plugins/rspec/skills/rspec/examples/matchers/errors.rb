# RSpec Matchers: Error/Exception Examples
# Source: rspec-expectations gem features/built_in_matchers/raise_error.feature,
#         throw_symbol.feature

# raise_error / raise_exception
RSpec.describe "raise_error matcher" do
  describe "basic usage" do
    it "expects any error" do
      expect { raise StandardError }.to raise_error
    end

    it "expects specific error class" do
      expect { raise ArgumentError }.to raise_error(ArgumentError)
    end

    it "expects error with message string" do
      expect { raise "boom" }.to raise_error("boom")
    end

    it "expects error with message regex" do
      expect { raise "Something went wrong" }.to raise_error(/wrong/)
    end

    it "expects class and message" do
      expect { raise ArgumentError, "invalid" }.to raise_error(ArgumentError, "invalid")
      expect { raise ArgumentError, "invalid" }.to raise_error(ArgumentError, /inv/)
    end
  end

  describe "with_message chain" do
    it "uses with_message for readability" do
      expect { raise StandardError, "detailed error" }
        .to raise_error(StandardError)
        .with_message(/detailed/)
    end
  end

  describe "block form for complex assertions" do
    it "yields error for inspection" do
      expect { raise ArgumentError, "bad input" }.to raise_error { |error|
        expect(error).to be_an(ArgumentError)
        expect(error.message).to include("bad")
      }
    end
  end

  describe "composed matchers" do
    it "uses matcher composition" do
      expect { raise ArgumentError, "invalid value" }.to raise_error(
        an_instance_of(ArgumentError).and(having_attributes(message: /invalid/))
      )
    end
  end

  describe "negative expectation" do
    it "expects no error" do
      expect { 1 + 1 }.not_to raise_error
    end
  end
end

# throw_symbol
RSpec.describe "throw_symbol matcher" do
  describe "basic usage" do
    it "expects any symbol thrown" do
      expect { throw :done }.to throw_symbol
    end

    it "expects specific symbol" do
      expect { throw :abort }.to throw_symbol(:abort)
    end

    it "expects symbol with value" do
      expect { throw :result, 42 }.to throw_symbol(:result, 42)
    end
  end

  describe "negative expectations" do
    it "expects nothing thrown" do
      expect { 1 + 1 }.not_to throw_symbol
    end

    it "expects different symbol" do
      expect { throw :foo }.not_to throw_symbol(:bar)
    end
  end
end

# Practical examples
RSpec.describe PaymentService do
  subject(:service) { build(:payment_service) }

  describe "#process" do
    context "with invalid amount" do
      it "raises ArgumentError" do
        expect { service.process(amount: -100) }
          .to raise_error(ArgumentError, /positive/)
      end
    end

    context "with invalid currency" do
      it "raises UnsupportedCurrencyError" do
        expect { service.process(amount: 100, currency: "XXX") }
          .to raise_error(UnsupportedCurrencyError)
          .with_message(/XXX/)
      end
    end

    context "when gateway fails" do
      before { allow(service).to receive(:gateway).and_raise(GatewayError) }

      it "raises PaymentFailedError with cause" do
        expect { service.process(amount: 100) }.to raise_error { |error|
          expect(error).to be_a(PaymentFailedError)
          expect(error.cause).to be_a(GatewayError)
        }
      end
    end
  end
end

RSpec.describe "early exit with throw/catch" do
  describe "batch processor" do
    subject(:processor) { build(:batch_processor) }

    it "throws :halt on critical error" do
      expect { processor.process_with_halt_on_error(bad_records) }
        .to throw_symbol(:halt)
    end

    it "throws with error details" do
      expect { processor.process_with_halt_on_error(bad_records) }
        .to throw_symbol(:halt, a_hash_including(reason: :validation_failed))
    end
  end
end
