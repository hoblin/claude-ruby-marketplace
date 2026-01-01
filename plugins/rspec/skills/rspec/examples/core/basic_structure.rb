# RSpec Core: Basic Structure Examples
# Source: rspec-core gem features/example_groups/basic_structure.feature

# Basic describe/context/it structure
RSpec.describe Order do
  context "with no items" do
    let(:order) { build(:order) }

    it "has zero total" do
      expect(order.total).to eq(0)
    end
  end

  context "with one item" do
    let(:order) { build(:order) }
    let(:item) { build(:item, price: 10) }

    before { order.add_item(item) }

    it "has item price as total" do
      expect(order.total).to eq(10)
    end
  end
end

# Method-focused describe blocks
RSpec.describe Calculator do
  subject(:calculator) { build(:calculator) }

  describe "#add" do
    subject(:result) { calculator.add(2, 3) }

    it "sums two numbers" do
      expect(result).to eq(5)
    end
  end

  describe ".from_string" do
    subject(:calc) { described_class.from_string("2+3") }

    it "parses expression" do
      expect(calc.result).to eq(5)
    end
  end
end

# Nested contexts for state variations
RSpec.describe BankAccount do
  describe "#withdraw" do
    subject(:account) { build(:bank_account, balance:) }

    context "with sufficient funds" do
      let(:balance) { 100 }

      it "reduces balance" do
        account.withdraw(50)
        expect(account.balance).to eq(50)
      end
    end

    context "with insufficient funds" do
      let(:balance) { 10 }

      it "raises InsufficientFundsError" do
        expect { account.withdraw(50) }.to raise_error(InsufficientFundsError)
      end
    end
  end
end
