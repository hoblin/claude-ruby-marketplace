# RSpec Matchers: Yield Examples
# Source: rspec-expectations gem features/built_in_matchers/yield.feature

# NOTE: All yield matchers require a block probe |b|

# yield_control - detects any yield
RSpec.describe "yield_control matcher" do
  it "passes when block is yielded to" do
    expect { |b| 5.tap(&b) }.to yield_control
  end

  it "fails when block is not yielded to" do
    expect { |b| "no yield" }.not_to yield_control
  end

  describe "with counts" do
    it "specifies exact yield count" do
      expect { |b| 3.times(&b) }.to yield_control.exactly(3).times
      expect { |b| 2.times(&b) }.to yield_control.twice
    end

    it "specifies minimum yields" do
      expect { |b| 5.times(&b) }.to yield_control.at_least(3).times
      expect { |b| 5.times(&b) }.to yield_control.at_least(:once)
    end

    it "specifies maximum yields" do
      expect { |b| 2.times(&b) }.to yield_control.at_most(5).times
      expect { |b| 1.times(&b) }.to yield_control.at_most(:twice)
    end
  end
end

# yield_with_no_args - yield without arguments
RSpec.describe "yield_with_no_args matcher" do
  it "passes when yielded without arguments" do
    expect { |b| yield_nothing(&b) }.to yield_with_no_args
  end

  def yield_nothing
    yield
  end

  it "fails when yielded with arguments" do
    expect { |b| yield_with_value(&b) }.not_to yield_with_no_args
  end

  def yield_with_value
    yield 42
  end
end

# yield_with_args - yield with specific arguments
RSpec.describe "yield_with_args matcher" do
  it "passes for any arguments" do
    expect { |b| "foo".tap(&b) }.to yield_with_args
  end

  it "matches exact values" do
    expect { |b| yield_value(42, &b) }.to yield_with_args(42)
    expect { |b| yield_values("a", "b", &b) }.to yield_with_args("a", "b")
  end

  it "matches types (uses ===)" do
    expect { |b| yield_value(42, &b) }.to yield_with_args(Integer)
    expect { |b| yield_value("foo", &b) }.to yield_with_args(String)
  end

  it "matches with regex" do
    expect { |b| yield_value("foobar", &b) }.to yield_with_args(/bar/)
  end

  def yield_value(val)
    yield val
  end

  def yield_values(*vals)
    yield(*vals)
  end
end

# yield_successive_args - multiple yields with different args
RSpec.describe "yield_successive_args matcher" do
  it "matches each yielded value in order" do
    expect { |b| [1, 2, 3].each(&b) }.to yield_successive_args(1, 2, 3)
  end

  it "works with hashes" do
    expect { |b| { a: 1, b: 2 }.each(&b) }.to yield_successive_args([:a, 1], [:b, 2])
  end

  it "works with composed matchers" do
    expect { |b| [1, 2, 3].each(&b) }
      .to yield_successive_args(a_value < 2, 2, a_value > 2)
  end
end

# Practical examples
RSpec.describe File do
  describe ".open with block" do
    it "yields file handle" do
      expect { |b| File.open("/tmp/test.txt", "w", &b) }
        .to yield_with_args(an_instance_of(File))
    end
  end
end

RSpec.describe Enumerator do
  describe "#each_with_index" do
    it "yields element and index pairs" do
      enum = %w[a b c].each_with_index

      expect { |b| enum.each(&b) }
        .to yield_successive_args(["a", 0], ["b", 1], ["c", 2])
    end
  end
end

RSpec.describe "Database transaction" do
  describe ".transaction" do
    it "yields control for block execution" do
      expect { |b| ActiveRecord::Base.transaction(&b) }.to yield_control
    end

    it "yields without arguments" do
      expect { |b| ActiveRecord::Base.transaction(&b) }.to yield_with_no_args
    end
  end
end

RSpec.describe BatchProcessor do
  subject(:processor) { build(:batch_processor) }

  describe "#process_each" do
    let(:items) { build_list(:item, 3) }

    it "yields each item" do
      expect { |b| processor.process_each(items, &b) }
        .to yield_successive_args(*items)
    end

    it "yields expected number of times" do
      expect { |b| processor.process_each(items, &b) }
        .to yield_control.exactly(3).times
    end
  end
end
