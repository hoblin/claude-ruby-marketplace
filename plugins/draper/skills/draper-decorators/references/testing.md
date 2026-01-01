# Testing Draper Decorators with RSpec

## Test Setup

Draper automatically integrates with RSpec. Specs in `spec/decorators/` are auto-tagged with `type: :decorator`.

### Rails Helper Inclusion

```ruby
# spec/decorators/user_decorator_spec.rb
require 'rails_helper'

RSpec.describe UserDecorator do
  # Tests go here
end
```

### View Context

Draper clears view context before each decorator spec automatically. Access helpers via `helpers` method.

## Basic Test Patterns

### Subject and Let

```ruby
RSpec.describe UserDecorator do
  subject(:decorator) { described_class.new(user) }

  let(:user) { build_stubbed(:user, first_name: "John", last_name: "Doe") }

  describe "#full_name" do
    subject(:full_name) { decorator.full_name }

    it "combines first and last name" do
      expect(full_name).to eq("John Doe")
    end
  end
end
```

### Testing Formatted Output

```ruby
RSpec.describe OrderDecorator do
  subject(:decorator) { described_class.new(order) }

  describe "#formatted_total" do
    subject(:formatted_total) { decorator.formatted_total }

    let(:order) { build_stubbed(:order, total: 99.99) }

    it "formats as currency" do
      expect(formatted_total).to eq("$99.99")
    end
  end

  describe "#formatted_created_at" do
    subject(:formatted_date) { decorator.formatted_created_at }

    let(:order) { build_stubbed(:order, created_at: Time.zone.parse("2024-03-15 10:30")) }

    it "formats date in long format" do
      expect(formatted_date).to eq("March 15, 2024 10:30")
    end
  end
end
```

### Testing Conditional Logic

```ruby
RSpec.describe PostDecorator do
  subject(:decorator) { described_class.new(post) }

  describe "#publication_status" do
    subject(:status) { decorator.publication_status }

    context "when published" do
      let(:post) { build_stubbed(:post, :published) }

      it "returns Published" do
        expect(status).to eq("Published")
      end
    end

    context "when draft" do
      let(:post) { build_stubbed(:post, :draft) }

      it "returns Draft" do
        expect(status).to eq("Draft")
      end
    end
  end
end
```

## Testing with Context

```ruby
RSpec.describe ProductDecorator do
  subject(:decorator) { described_class.new(product, context:) }

  let(:product) { build_stubbed(:product, price: 100, cost: 60) }

  describe "#price_display" do
    subject(:price_display) { decorator.price_display }

    context "without user context" do
      let(:context) { {} }

      it "shows standard price" do
        expect(price_display).to eq("$100.00")
      end
    end

    context "with admin user" do
      let(:context) { { current_user: build_stubbed(:user, :admin) } }

      it "shows price with margin" do
        expect(price_display).to include("$100.00")
        expect(price_display).to include("Margin")
      end
    end

    context "with premium user" do
      let(:context) { { current_user: build_stubbed(:user, :premium) } }

      it "shows discounted price" do
        expect(price_display).to include("discount")
      end
    end
  end
end
```

## Testing HTML Output

### With Capybara Matchers

```ruby
RSpec.describe StatusDecorator do
  subject(:decorator) { described_class.new(order) }

  describe "#status_badge" do
    subject(:badge) { decorator.status_badge }

    context "when pending" do
      let(:order) { build_stubbed(:order, status: "pending") }

      it "renders warning badge" do
        markup = Capybara.string(badge)

        expect(markup).to have_css("span.badge.badge-warning", text: "Pending")
      end
    end

    context "when completed" do
      let(:order) { build_stubbed(:order, status: "completed") }

      it "renders success badge" do
        markup = Capybara.string(badge)

        expect(markup).to have_css("span.badge.badge-success", text: "Completed")
      end
    end
  end
end
```

### Testing Links

```ruby
RSpec.describe PostDecorator do
  subject(:decorator) { described_class.new(post) }

  let(:post) { create(:post) }

  describe "#edit_link" do
    subject(:link) { decorator.edit_link }

    it "generates edit link with correct path" do
      markup = Capybara.string(link)

      expect(markup).to have_link("Edit", href: "/posts/#{post.id}/edit")
    end

    it "includes button class" do
      markup = Capybara.string(link)

      expect(markup).to have_css("a.btn")
    end
  end
end
```

### Testing Complex HTML Structures

```ruby
RSpec.describe UserDecorator do
  subject(:decorator) { described_class.new(user) }

  describe "#profile_card" do
    subject(:card) { decorator.profile_card }

    let(:user) { build_stubbed(:user, first_name: "Jane", email: "jane@example.com") }

    it "renders card with user info" do
      markup = Capybara.string(card)

      expect(markup).to have_css(".profile-card") do |card|
        expect(card).to have_css(".name", text: "Jane")
        expect(card).to have_css(".email", text: "jane@example.com")
      end
    end
  end
end
```

## Testing Associations

```ruby
RSpec.describe PostDecorator do
  subject(:decorator) { described_class.new(post) }

  let(:post) { create(:post) }
  let!(:comments) { create_list(:comment, 3, post:) }

  describe "#comments" do
    subject(:decorated_comments) { decorator.comments }

    it "returns decorated comments" do
      expect(decorated_comments).to all(be_decorated_with(CommentDecorator))
    end

    it "returns all comments" do
      expect(decorated_comments.count).to eq(3)
    end
  end

  describe "#author" do
    subject(:decorated_author) { decorator.author }

    let(:author) { create(:user) }
    let(:post) { create(:post, author:) }

    it "returns decorated author" do
      expect(decorated_author).to be_decorated_with(UserDecorator)
    end
  end
end
```

## Testing Collection Decorators

```ruby
RSpec.describe PaginatingDecorator do
  subject(:collection) { described_class.new(products) }

  let(:products) { Product.page(1).per(10) }

  before { create_list(:product, 25) }

  describe "pagination delegation" do
    it "delegates current_page" do
      expect(collection.current_page).to eq(1)
    end

    it "delegates total_pages" do
      expect(collection.total_pages).to eq(3)
    end

    it "delegates total_count" do
      expect(collection.total_count).to eq(25)
    end
  end

  describe "items" do
    it "decorates each item" do
      expect(collection.first).to be_decorated
    end
  end
end
```

## Testing Helpers Access

```ruby
RSpec.describe ProductDecorator do
  subject(:decorator) { described_class.new(product) }

  let(:product) { create(:product) }

  describe "#show_path" do
    it "uses path helper correctly" do
      expect(decorator.show_path).to eq(helpers.product_path(product))
    end
  end

  describe "#formatted_price" do
    let(:product) { build_stubbed(:product, price: 1234.56) }

    it "uses number helper" do
      expect(decorator.formatted_price).to eq(helpers.number_to_currency(1234.56))
    end
  end
end
```

## Fast Test Strategy

For unit tests without Rails overhead:

```ruby
# spec/fast_spec_helper.rb
require 'draper'
require 'active_model'

Draper::ViewContext.test_strategy :fast

# Or with specific helpers
Draper::ViewContext.test_strategy :fast do
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
end
```

```ruby
# spec/decorators/fast/product_decorator_spec.rb
require 'fast_spec_helper'
require_relative '../../../app/decorators/product_decorator'

Product = Struct.new(:name, :price, keyword_init: true) do
  extend ActiveModel::Naming
end

RSpec.describe ProductDecorator do
  subject(:decorator) { described_class.new(product) }

  let(:product) { Product.new(name: "Widget", price: 10.0) }

  describe "#display_name" do
    it "formats name" do
      expect(decorator.display_name).to eq("WIDGET")
    end
  end

  # Note: Path/URL helpers won't work in fast mode
end
```

## Shared Examples

### Common Decorator Behaviors

```ruby
# spec/support/shared_examples/decorators.rb
RSpec.shared_examples "a timestamped decorator" do
  describe "#formatted_created_at" do
    let(:model) { build_stubbed(factory, created_at: Time.zone.parse("2024-01-15")) }

    it "formats created_at" do
      expect(decorator.formatted_created_at).to eq("January 15, 2024")
    end
  end

  describe "#time_ago" do
    let(:model) { build_stubbed(factory, created_at: 2.hours.ago) }

    it "shows relative time" do
      expect(decorator.time_ago).to include("hours ago")
    end
  end
end

# Usage
RSpec.describe PostDecorator do
  subject(:decorator) { described_class.new(model) }

  let(:factory) { :post }
  let(:model) { build_stubbed(factory) }

  it_behaves_like "a timestamped decorator"
end
```

### Testing Decorated State

```ruby
RSpec.shared_examples "a decorated object" do
  it "is decorated" do
    expect(decorated).to be_decorated
  end

  it "wraps the original object" do
    expect(decorated.object).to eq(object)
  end

  it "delegates to original object" do
    expect(decorated.id).to eq(object.id)
  end
end
```

## Mocking and Stubbing

### Stubbing Model Methods

```ruby
RSpec.describe OrderDecorator do
  subject(:decorator) { described_class.new(order) }

  let(:order) { build_stubbed(:order) }

  describe "#shipping_estimate" do
    before do
      allow(order).to receive(:calculate_shipping).and_return(15.0)
    end

    it "formats shipping cost" do
      expect(decorator.shipping_estimate).to eq("$15.00")
    end
  end
end
```

### Stubbing External Services

```ruby
RSpec.describe ProductDecorator do
  subject(:decorator) { described_class.new(product) }

  let(:product) { build_stubbed(:product) }

  describe "#stock_status" do
    context "when in stock" do
      before do
        allow(product).to receive(:check_inventory).and_return(available: true, count: 10)
      end

      it "shows available" do
        expect(decorator.stock_status).to include("In Stock")
        expect(decorator.stock_status).to include("10")
      end
    end
  end
end
```

## Testing Draper Matchers

Draper provides RSpec matchers:

```ruby
RSpec.describe "Decorator matchers" do
  let(:post) { create(:post) }
  let(:decorated) { post.decorate }

  it "checks if decorated" do
    expect(decorated).to be_decorated
    expect(post).not_to be_decorated
  end

  it "checks decorator class" do
    expect(decorated).to be_decorated_with(PostDecorator)
  end
end
```

## Controller Specs with Decorators

```ruby
RSpec.describe PostsController, type: :controller do
  describe "GET #show" do
    let(:post) { create(:post) }

    before { get :show, params: { id: post.id } }

    it "assigns decorated post" do
      expect(assigns(:post)).to be_decorated
      expect(assigns(:post)).to be_decorated_with(PostDecorator)
    end
  end

  describe "GET #index" do
    before do
      create_list(:post, 3)
      get :index
    end

    it "assigns decorated collection" do
      assigns(:posts).each do |post|
        expect(post).to be_decorated
      end
    end
  end
end
```

## View Specs with Decorated Objects

```ruby
RSpec.describe "posts/show", type: :view do
  let(:post) { create(:post, title: "Test Post").decorate }

  before do
    assign(:post, post)
    render
  end

  it "displays formatted title" do
    expect(rendered).to include(post.formatted_title)
  end

  it "displays publication status" do
    expect(rendered).to have_css(".status", text: post.publication_status)
  end
end
```

## Debugging Tips

### Inspecting Decorator State

```ruby
RSpec.describe UserDecorator do
  subject(:decorator) { described_class.new(user, context: { admin: true }) }

  let(:user) { build_stubbed(:user) }

  it "has correct context" do
    expect(decorator.context).to eq(admin: true)
  end

  it "wraps correct object" do
    expect(decorator.object).to eq(user)
    expect(decorator.model).to eq(user)  # alias
  end

  it "tracks applied decorators" do
    expect(decorator.applied_decorators).to eq([UserDecorator])
  end
end
```

### Checking View Context

```ruby
RSpec.describe "view context in tests" do
  it "provides helpers" do
    expect(helpers).to respond_to(:link_to)
    expect(helpers).to respond_to(:number_to_currency)
  end

  it "uses test controller" do
    expect(Draper::ViewContext.current.controller).to be_a(ActionController::Base)
  end
end
```
