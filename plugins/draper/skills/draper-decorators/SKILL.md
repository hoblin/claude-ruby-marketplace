---
name: Draper Decorators
description: This skill should be used when the user asks to "create a decorator", "write a decorator", "move logic into decorator", "clean logic out of the view", "isn't it decorator logic", "test a decorator", or mentions Draper, keeping views clean, or representation logic in decorators. Should also be used when editing *_decorator.rb files, working in app/decorators/ directory, questioning where formatting methods belong (models vs decorators vs views), or discussing methods like full_name, formatted_*, display_* that don't belong in models. Provides guidance on Draper gem best practices for Rails applications.
version: 1.1.0
---

# Draper Decorators for Rails

This skill provides guidance for creating effective Draper decorators in Rails applications.

## Philosophy

Decorators implement separation of concerns between **business logic** (models) and **presentation logic** (views). A decorator wraps a model to add view-specific methods without polluting the model.

**What belongs in decorators:**
- Date/time formatting (`created_at.strftime("%B %d, %Y")`)
- String concatenation (`"#{first_name} #{last_name}"`)
- HTML generation (`h.content_tag(:span, status, class: css_class)`)
- Conditional rendering based on state
- Number formatting (currency, percentages)
- CSS class generation based on object state

**What does NOT belong in decorators:**
- Business logic (validations, calculations, state changes)
- Database queries (use includes in controllers)
- Anything not directly related to presentation

## Basic Structure

```ruby
# app/decorators/user_decorator.rb
class UserDecorator < ApplicationDecorator
  delegate_all

  def full_name
    "#{first_name} #{last_name}"
  end

  def formatted_created_at
    created_at.strftime("%B %d, %Y")
  end

  def status_badge
    css_class = active? ? "badge-success" : "badge-secondary"
    h.content_tag(:span, status, class: "badge #{css_class}")
  end
end
```

## Delegation Strategies

### Option 1: `delegate_all` (Convenient)

Delegates all methods to the wrapped object via `method_missing`. Use for most decorators.

```ruby
class ProductDecorator < ApplicationDecorator
  delegate_all

  def formatted_price
    h.number_to_currency(price)
  end
end
```

### Option 2: Explicit Delegation (Strict)

Explicitly declare which methods to delegate. Use for larger apps where control matters.

```ruby
class ProductDecorator < ApplicationDecorator
  delegate :id, :name, :price, :created_at, :persisted?

  def formatted_price
    h.number_to_currency(price)
  end
end
```

## Accessing the Wrapped Object

Three equivalent ways to access the model:

```ruby
class ArticleDecorator < ApplicationDecorator
  delegate_all

  def display_title
    object.title.upcase      # via 'object'
    model.title.upcase       # via 'model' (alias)
    article.title.upcase     # via model name (auto-generated)
  end
end
```

## Accessing Rails Helpers

Use `h` or `helpers` to access view helpers:

```ruby
class PostDecorator < ApplicationDecorator
  delegate_all

  def formatted_body
    h.simple_format(body)
  end

  def edit_link
    h.link_to("Edit", h.edit_post_path(object), class: "btn")
  end

  def publication_date
    h.l(published_at, format: :long)  # l is localize alias
  end
end
```

## Decorating in Controllers

Decorate **at the last moment**, right before rendering:

```ruby
class PostsController < ApplicationController
  def show
    @post = Post.find(params[:id]).decorate
  end

  def index
    @posts = Post.includes(:author).all.decorate
  end
end
```

**Critical:** Always use `includes` BEFORE decorating to avoid N+1 queries.

## Association Decoration

Use `decorates_association` to auto-decorate associations:

```ruby
class PostDecorator < ApplicationDecorator
  delegate_all
  decorates_association :author
  decorates_association :comments
  decorates_association :recent_comments, scope: :recent
end
```

In views, `@post.author` returns `AuthorDecorator`, not `Author`.

## Context Passing

Pass extra data to decorators via context:

```ruby
# Controller
@product = Product.find(params[:id]).decorate(context: { current_user: })

# Decorator
class ProductDecorator < ApplicationDecorator
  delegate_all

  def admin_price_info
    return unless context[:current_user]&.admin?
    "Cost: #{h.number_to_currency(cost)} | Margin: #{margin}%"
  end
end
```

## Collection Decoration

```ruby
# Auto-infers decorator from model
@products = Product.all.decorate

# Explicit decorator
@products = ProductDecorator.decorate_collection(Product.all)

# With pagination (use custom collection decorator)
class PaginatingDecorator < Draper::CollectionDecorator
  delegate :current_page, :total_pages, :limit_value
end

class ProductDecorator < ApplicationDecorator
  def self.collection_decorator_class
    PaginatingDecorator
  end
end
```

## Testing Decorators

Place specs in `spec/decorators/`. Draper auto-configures RSpec integration.

### Basic Pattern

```ruby
# spec/decorators/user_decorator_spec.rb
require 'rails_helper'

RSpec.describe UserDecorator do
  subject(:decorator) { described_class.new(user) }

  let(:user) { build_stubbed(:user, first_name: "John", last_name: "Doe") }

  describe "#full_name" do
    subject(:full_name) { decorator.full_name }

    it "combines first and last name" do
      expect(full_name).to eq("John Doe")
    end
  end

  describe "#formatted_created_at" do
    subject(:formatted_date) { decorator.formatted_created_at }

    let(:user) { build_stubbed(:user, created_at: Time.zone.parse("2024-01-15")) }

    it "formats date in long format" do
      expect(formatted_date).to eq("January 15, 2024")
    end
  end
end
```

### Testing with Helpers

Access helpers via `helpers` method in tests:

```ruby
RSpec.describe PostDecorator do
  subject(:decorator) { described_class.new(post) }

  let(:post) { create(:post) }

  it "generates correct path" do
    expect(decorator.edit_link).to include(helpers.edit_post_path(post))
  end
end
```

### Testing HTML Output with Capybara

```ruby
RSpec.describe StatusDecorator do
  subject(:decorator) { described_class.new(order) }

  describe "#status_badge" do
    subject(:badge) { decorator.status_badge }

    context "when completed" do
      let(:order) { build_stubbed(:order, :completed) }

      it "renders success badge" do
        markup = Capybara.string(badge)
        expect(markup).to have_css("span.badge-success", text: "Completed")
      end
    end
  end
end
```

## Common Anti-Patterns

### Fat Decorator

Split large decorators into context-specific ones:

```ruby
# Instead of one 500-line UserDecorator, use:
class Users::ProfileDecorator < ApplicationDecorator
  # Profile-related presentation
end

class Users::AdminDecorator < ApplicationDecorator
  # Admin panel presentation
end
```

### N+1 Queries

```ruby
# BAD - triggers N+1
@posts = Post.all.decorate
# In decorator: author.name triggers query per post

# GOOD - eager load first
@posts = Post.includes(:author).all.decorate
```

### Decorating Too Early

```ruby
# BAD - decorated objects in business logic
def publish(decorated_post)
  decorated_post.update(published: true)
end

# GOOD - use models for business logic
def publish(post)
  post.update(published: true)
end
# Decorate only in controller before render
```

### Using Decorators in Models

```ruby
# BAD - model references decorator
class Post < ApplicationRecord
  def display_title
    PostDecorator.new(self).formatted_title
  end
end

# GOOD - keep models unaware of decorators
```

## Quick Reference

| Method | Purpose |
|--------|---------|
| `object` / `model` | Access wrapped object |
| `h` / `helpers` | Access view helpers |
| `context` | Access passed context hash |
| `delegate_all` | Delegate all methods to object |
| `decorates_association` | Auto-decorate associations |
| `decorate` | Decorate single object |
| `decorate_collection` | Decorate collection |

## Additional Resources

### Reference Files

For detailed patterns and examples:
- **`references/patterns.md`** - Advanced patterns, association decoration, context handling
- **`references/testing.md`** - Comprehensive RSpec testing guide
- **`references/anti-patterns.md`** - Detailed anti-patterns with solutions

### Example Files

Working examples in `examples/`:
- **`examples/application_decorator.rb`** - Base decorator template
- **`examples/model_decorator.rb`** - Full decorator example
- **`examples/decorator_spec.rb`** - Complete spec template
