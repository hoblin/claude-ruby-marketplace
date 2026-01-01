# RSpec Mocks: Configuring Responses Examples
# Source: rspec-mocks gem features/configuring_responses/*.feature

# and_return - return specified values
RSpec.describe "and_return" do
  describe "single value" do
    it "returns the value on every call" do
      dbl = double("collaborator")
      allow(dbl).to receive(:foo).and_return(14)

      expect(dbl.foo).to eq(14)
      expect(dbl.foo).to eq(14)
    end
  end

  describe "consecutive values" do
    it "returns values in sequence" do
      die = double("die")
      allow(die).to receive(:roll).and_return(1, 2, 3)

      expect(die.roll).to eq(1)
      expect(die.roll).to eq(2)
      expect(die.roll).to eq(3)
      expect(die.roll).to eq(3)  # Repeats last value
    end
  end
end

# and_raise - raise exceptions
RSpec.describe "and_raise" do
  describe "various forms" do
    it "raises with string message" do
      dbl = double("collaborator")
      allow(dbl).to receive(:foo).and_raise("boom")

      expect { dbl.foo }.to raise_error("boom")
    end

    it "raises specified error class" do
      dbl = double("collaborator")
      allow(dbl).to receive(:foo).and_raise(ArgumentError)

      expect { dbl.foo }.to raise_error(ArgumentError)
    end

    it "raises error class with message" do
      dbl = double("collaborator")
      allow(dbl).to receive(:foo).and_raise(ArgumentError, "invalid")

      expect { dbl.foo }.to raise_error(ArgumentError, "invalid")
    end

    it "raises error instance" do
      dbl = double("collaborator")
      error = StandardError.new("specific error")
      allow(dbl).to receive(:foo).and_raise(error)

      expect { dbl.foo }.to raise_error(error)
    end
  end
end

# and_yield - yield to blocks
RSpec.describe "and_yield" do
  describe "yielding arguments" do
    it "yields specified values to block" do
      dbl = double("collaborator")
      allow(dbl).to receive(:foo).and_yield(2, 3)

      x = y = nil
      dbl.foo { |a, b| x, y = a, b }

      expect(x).to eq(2)
      expect(y).to eq(3)
    end
  end

  describe "multiple yields" do
    it "yields multiple times" do
      dbl = double("collaborator")
      allow(dbl).to receive(:each)
        .and_yield(1)
        .and_yield(2)
        .and_yield(3)

      yielded = []
      dbl.each { |x| yielded << x }

      expect(yielded).to eq([1, 2, 3])
    end
  end
end

# and_call_original - call real implementation
RSpec.describe "and_call_original" do
  describe "partial double with original" do
    it "calls through to real method" do
      expect(Calculator).to receive(:add).and_call_original
      expect(Calculator.add(2, 3)).to eq(5)
    end

    it "combines with specific stubs" do
      allow(Calculator).to receive(:add).and_call_original
      allow(Calculator).to receive(:add).with(2, 3).and_return(-5)

      expect(Calculator.add(2, 2)).to eq(4)   # Calls original
      expect(Calculator.add(2, 3)).to eq(-5)  # Uses stub
    end
  end
end

# Block implementation - dynamic behavior
RSpec.describe "block implementation" do
  describe "simple block" do
    it "returns block result" do
      dbl = double("collaborator")
      allow(dbl).to receive(:foo) { 14 }

      expect(dbl.foo).to eq(14)
    end
  end

  describe "block with arguments" do
    it "receives call arguments" do
      dbl = double("collaborator")
      allow(dbl).to receive(:greet) { |name| "Hello, #{name}!" }

      expect(dbl.greet("Alice")).to eq("Hello, Alice!")
    end
  end

  describe "calculations" do
    it "performs dynamic calculations" do
      loan = double("loan", amount: 1000)
      allow(loan).to receive(:payment_for_rate) { |rate| loan.amount * rate }

      expect(loan.payment_for_rate(0.05)).to eq(50)
      expect(loan.payment_for_rate(0.10)).to eq(100)
    end
  end

  describe "yielding to caller's block" do
    it "invokes caller's block from implementation" do
      dbl = double("collaborator")
      allow(dbl).to receive(:process) { |&block| block.call(14) }

      result = nil
      dbl.process { |x| result = x * 2 }

      expect(result).to eq(28)
    end
  end

  describe "simulating failures" do
    it "simulates transient errors" do
      client = double("client")
      call_count = 0

      allow(client).to receive(:fetch_data) do
        call_count += 1
        call_count.odd? ? raise("timeout") : { count: 15 }
      end

      expect { client.fetch_data }.to raise_error("timeout")
      expect(client.fetch_data).to eq(count: 15)
      expect { client.fetch_data }.to raise_error("timeout")
    end
  end
end

# and_throw - throw symbols
RSpec.describe "and_throw" do
  it "throws specified symbol" do
    dbl = double("collaborator")
    allow(dbl).to receive(:halt).and_throw(:abort)

    expect { dbl.halt }.to throw_symbol(:abort)
  end

  it "throws symbol with value" do
    dbl = double("collaborator")
    allow(dbl).to receive(:halt).and_throw(:result, 42)

    expect { dbl.halt }.to throw_symbol(:result, 42)
  end
end

# and_invoke - mixed responses per call
RSpec.describe "and_invoke" do
  it "executes different lambdas per call" do
    dbl = double("collaborator")
    allow(dbl).to receive(:foo).and_invoke(
      -> { raise "first call fails" },
      -> { "second call succeeds" }
    )

    expect { dbl.foo }.to raise_error("first call fails")
    expect(dbl.foo).to eq("second call succeeds")
  end
end

# Practical example: API client with retry
RSpec.describe ApiClient do
  subject(:client) { build(:api_client, http:) }

  let(:http) { instance_double("Net::HTTP") }

  describe "#fetch_with_retry" do
    context "when first request times out" do
      before do
        allow(http).to receive(:get).and_invoke(
          -> { raise Timeout::Error },
          -> { { data: "success" } }
        )
      end

      it "retries and succeeds" do
        expect(client.fetch_with_retry("/api")).to eq(data: "success")
      end
    end
  end
end

