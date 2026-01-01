# RSpec Matchers: Truthiness Examples
# Source: rspec-expectations gem features/built_in_matchers/be.feature, exist.feature

# be_truthy - any truthy value
RSpec.describe "be_truthy matcher" do
  it "passes for true" do
    expect(true).to be_truthy
  end

  it "passes for truthy values" do
    expect(7).to be_truthy
    expect("foo").to be_truthy
    expect([]).to be_truthy      # Empty array is truthy
    expect(0).to be_truthy       # Zero is truthy in Ruby!
  end

  it "fails for nil and false" do
    expect(nil).not_to be_truthy
    expect(false).not_to be_truthy
  end
end

# be_falsey / be_falsy - nil or false only
RSpec.describe "be_falsey matcher" do
  it "passes for nil" do
    expect(nil).to be_falsey
  end

  it "passes for false" do
    expect(false).to be_falsey
    expect(false).to be_falsy  # Alias
  end

  it "fails for truthy values" do
    expect(true).not_to be_falsey
    expect(0).not_to be_falsey   # 0 is truthy!
    expect("").not_to be_falsey  # Empty string is truthy
  end
end

# be_nil - exactly nil
RSpec.describe "be_nil matcher" do
  it "passes only for nil" do
    expect(nil).to be_nil
  end

  it "fails for false" do
    expect(false).not_to be_nil
  end
end

# be true / be false - exact boolean
RSpec.describe "exact boolean matchers" do
  it "requires exact true" do
    expect(true).to be true
    expect(1).not_to be true  # Truthy but not true
  end

  it "requires exact false" do
    expect(false).to be false
    expect(nil).not_to be false  # Falsey but not false
  end
end

# exist - calls exist? or exists?
RSpec.describe "exist matcher" do
  it "checks existence" do
    # For file-like objects
    expect(File).to exist("/tmp")
    expect(File).not_to exist("/nonexistent/path")
  end
end

# Practical example: model validations
RSpec.describe User do
  subject(:user) { build(:user) }

  describe "#admin?" do
    context "when user is admin" do
      subject(:user) { build(:user, :admin) }

      it "returns true" do
        expect(user.admin?).to be true  # Exact boolean check
      end
    end

    context "when user is not admin" do
      it "returns false" do
        expect(user.admin?).to be false  # Not just falsey
      end
    end
  end

  describe "#deleted_at" do
    context "when not deleted" do
      it "is nil" do
        expect(user.deleted_at).to be_nil
      end
    end
  end
end
