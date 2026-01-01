# RSpec Mocks: Receive Counts Examples
# Source: rspec-mocks gem features/setting_constraints/receive_counts.feature

# NOTE: Default expectation is once unless specified

# Exact counts
RSpec.describe "exact receive counts" do
  describe "once (default)" do
    it "expects exactly one call" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).once
      dbl.foo
    end
  end

  describe "twice" do
    it "expects exactly two calls" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).twice
      dbl.foo
      dbl.foo
    end
  end

  describe "exactly(n).times" do
    it "expects specific number of calls" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).exactly(3).times
      3.times { dbl.foo }
    end

    it "uses .time for singular" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).exactly(1).time
      dbl.foo
    end
  end
end

# Minimum counts
RSpec.describe "at_least counts" do
  describe "at_least(:once)" do
    it "passes with one or more calls" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).at_least(:once)
      dbl.foo
      dbl.foo  # Additional calls are fine
    end
  end

  describe "at_least(:twice)" do
    it "passes with two or more calls" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).at_least(:twice)
      dbl.foo
      dbl.foo
      dbl.foo  # Additional calls are fine
    end
  end

  describe "at_least(n).times" do
    it "passes with n or more calls" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).at_least(3).times
      5.times { dbl.foo }
    end
  end
end

# Maximum counts
RSpec.describe "at_most counts" do
  describe "at_most(:once)" do
    it "passes with zero or one call" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).at_most(:once)
      dbl.foo
    end

    it "also passes with zero calls" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).at_most(:once)
      # Not called - still passes
    end
  end

  describe "at_most(:twice)" do
    it "passes with up to two calls" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).at_most(:twice)
      dbl.foo
    end
  end

  describe "at_most(n).times" do
    it "passes with n or fewer calls" do
      dbl = double("collaborator")
      expect(dbl).to receive(:foo).at_most(3).times
      2.times { dbl.foo }
    end
  end
end

# have_received with counts
RSpec.describe "have_received with counts" do
  it "verifies exact count" do
    invitation = spy("invitation")
    invitation.deliver
    invitation.deliver

    expect(invitation).to have_received(:deliver).twice
  end

  it "verifies minimum count" do
    invitation = spy("invitation")
    5.times { invitation.deliver }

    expect(invitation).to have_received(:deliver).at_least(3).times
  end

  it "verifies maximum count" do
    invitation = spy("invitation")
    2.times { invitation.deliver }

    expect(invitation).to have_received(:deliver).at_most(5).times
  end
end

# Practical example
RSpec.describe BankAccount do
  subject(:account) { build(:bank_account, logger:) }

  let(:logger) { instance_double("Logger") }

  describe "#transfer" do
    context "successful transfer" do
      before do
        allow(logger).to receive(:info)
      end

      it "logs exactly twice (start and end)" do
        expect(logger).to receive(:info).twice

        account.transfer(to: build(:bank_account), amount: 100)
      end
    end
  end

  describe "#batch_transfer" do
    let(:recipients) { build_list(:bank_account, 5) }

    before do
      allow(logger).to receive(:info)
    end

    it "logs at least once per recipient" do
      expect(logger).to receive(:info).at_least(5).times

      account.batch_transfer(recipients:, amount: 50)
    end
  end
end

# Practical example: rate limiting
RSpec.describe RateLimitedClient do
  subject(:client) { build(:rate_limited_client, api:) }

  let(:api) { instance_double("ExternalApi") }

  describe "#fetch_all" do
    before do
      allow(api).to receive(:fetch).and_return(data: [])
    end

    it "makes at most 10 API calls" do
      expect(api).to receive(:fetch).at_most(10).times

      client.fetch_all(max_pages: 20)
    end
  end
end

