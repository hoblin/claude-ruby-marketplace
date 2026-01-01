# RSpec Matchers: Composing Matchers Examples
# Source: rspec-expectations gem features/composing_matchers.feature,
#         compound_expectations.feature

# Compound expectations with .and / &
RSpec.describe "compound matchers with .and" do
  it "combines matchers with .and" do
    expect("hello world").to start_with("hello").and end_with("world")
  end

  it "uses & as alias" do
    expect("hello world").to start_with("hello") & end_with("world")
  end

  it "chains multiple conditions" do
    expect(5).to be_positive.and be < 10
    expect([1, 2, 3]).to include(1).and include(3)
  end
end

# Compound expectations with .or / |
RSpec.describe "compound matchers with .or" do
  it "passes if any matcher passes" do
    color = %w[red green blue].sample
    expect(color).to eq("red").or eq("green").or eq("blue")
  end

  it "uses | as alias" do
    value = [true, false].sample
    expect(value).to be(true) | be(false)
  end
end

# Matcher aliases for composition
RSpec.describe "composable matcher aliases" do
  # Noun-phrase aliases read better in composed contexts:
  # be_within       => a_value_within
  # be_an_instance  => an_instance_of
  # start_with      => a_string_starting_with
  # include         => a_collection_including
  # be_a            => a_kind_of

  it "uses noun-phrase aliases in expect(...).to include" do
    expect([1, 2.5, "foo"]).to include(
      an_instance_of(Integer),
      a_value_within(0.1).of(2.5),
      a_string_starting_with("f")
    )
  end

  it "uses noun-phrase aliases with contain_exactly" do
    expect(["barn", 2.45]).to contain_exactly(
      a_value_within(0.1).of(2.5),
      a_string_starting_with("bar")
    )
  end
end

# Matchers as arguments
RSpec.describe "matchers accepting matcher arguments" do
  describe "with change" do
    it "uses composed matchers for from/to" do
      text = "foo bar"
      expect { text = "baz qux" }
        .to change { text }
        .from(a_string_matching(/foo/))
        .to(a_string_matching(/baz/))
    end

    it "uses composed matchers for delta" do
      value = 0.0
      expect { value += 1.05 }
        .to change { value }
        .by(a_value_within(0.1).of(1.0))
    end
  end

  describe "with include" do
    it "matches hash values with matchers" do
      expect(a: "food", b: "good").to include(a: a_string_matching(/foo/))
    end

    it "matches hash keys with matchers" do
      expect("food" => 1, "drink" => 2).to include(a_string_matching(/foo/))
    end
  end

  describe "with match (nested structures)" do
    it "validates deeply nested data" do
      response = {
        user: {
          name: "Alice",
          roles: ["admin", "editor"],
          settings: { theme: "dark" }
        }
      }

      expect(response).to match(
        user: {
          name: a_string_starting_with("A"),
          roles: a_collection_including("admin"),
          settings: { theme: a_kind_of(String) }
        }
      )
    end
  end
end

# Practical examples
RSpec.describe API::Response do
  subject(:response) { build(:api_response, :success) }

  describe "response structure validation" do
    it "has expected structure" do
      expect(response.body).to match(
        status: "success",
        data: {
          id: an_instance_of(Integer),
          created_at: a_string_matching(/\d{4}-\d{2}-\d{2}/),
          items: a_collection_including(
            have_attributes(name: a_kind_of(String))
          )
        }
      )
    end
  end
end

RSpec.describe User do
  describe "#update" do
    subject(:user) { create(:user, name: "Alice", updated_at: 1.day.ago) }

    it "changes name and updated_at" do
      expect { user.update(name: "Bob") }
        .to change(user, :name)
        .from(a_string_starting_with("A"))
        .to(a_string_starting_with("B"))
        .and change(user, :updated_at)
    end
  end
end

RSpec.describe "result validation" do
  subject(:result) { build(:calculation_result) }

  it "returns numeric value in expected range" do
    expect(result.value)
      .to be_a(Numeric)
      .and be_within(0.01).of(expected_value)
  end

  it "has valid status" do
    expect(result.status).to eq(:success).or eq(:partial)
  end
end
