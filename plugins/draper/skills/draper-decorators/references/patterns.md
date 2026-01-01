# Advanced Draper Patterns

## ApplicationDecorator Base Class

Create a base decorator with shared methods:

```ruby
# app/decorators/application_decorator.rb
class ApplicationDecorator < Draper::Decorator
  # Common formatting methods
  def formatted_created_at
    h.l(created_at, format: :long)
  end

  def time_ago
    "#{h.time_ago_in_words(created_at)} ago"
  end

  def formatted_date(date, format: :long)
    return "N/A" if date.blank?
    h.l(date, format:)
  end

  def formatted_currency(amount)
    return "$0.00" if amount.blank?
    h.number_to_currency(amount)
  end

  def truncated_text(text, length: 100)
    h.truncate(text.to_s, length:, separator: ' ')
  end
end
```

## Association Decoration Patterns

### Basic Association

```ruby
class PostDecorator < ApplicationDecorator
  delegate_all
  decorates_association :author
  decorates_association :comments
end

# In view
@post.author.full_name  # Returns from AuthorDecorator
@post.comments.each { |c| c.formatted_body }  # Each is CommentDecorator
```

### With Explicit Decorator

```ruby
class PostDecorator < ApplicationDecorator
  delegate_all
  decorates_association :author, with: Users::CompactDecorator
end
```

### With Scope

```ruby
class PostDecorator < ApplicationDecorator
  delegate_all
  decorates_association :comments, scope: :approved
  decorates_association :recent_comments, scope: :recent
end
```

### With Context Propagation

```ruby
class PostDecorator < ApplicationDecorator
  delegate_all

  # Static context
  decorates_association :author, context: { display_mode: :compact }

  # Dynamic context from parent
  decorates_association :comments, context: ->(parent_context) {
    parent_context.merge(post_id: object.id)
  }
end
```

### Delegating Association Methods

```ruby
class PostDecorator < ApplicationDecorator
  delegate_all
  decorates_association :author

  delegate :avatar_tag, :profile_link, to: :author, prefix: true
end

# In view
@post.author_avatar_tag
@post.author_profile_link
```

## Context Patterns

### Controller Context Setup

```ruby
class ApplicationController < ActionController::Base
  private

  def decoration_context
    {
      current_user:,
      locale: I18n.locale,
      request_host: request.host
    }
  end

  helper_method :decorate_with_context

  def decorate_with_context(object)
    object.decorate(context: decoration_context)
  end
end

class PostsController < ApplicationController
  def show
    @post = decorate_with_context(Post.find(params[:id]))
  end
end
```

### Context-Aware Methods

```ruby
class ProductDecorator < ApplicationDecorator
  delegate_all

  def price_display
    if admin_user?
      admin_price_breakdown
    elsif premium_user?
      discounted_price
    else
      standard_price
    end
  end

  def edit_actions
    return unless can_edit?
    h.content_tag(:div, class: "actions") do
      h.link_to("Edit", h.edit_product_path(object))
    end
  end

  private

  def admin_user?
    context[:current_user]&.admin?
  end

  def premium_user?
    context[:current_user]&.premium?
  end

  def can_edit?
    context[:current_user]&.can?(:edit, object)
  end
end
```

## Collection Decorator Patterns

### Custom Collection Decorator

```ruby
# app/decorators/paginating_decorator.rb
class PaginatingDecorator < Draper::CollectionDecorator
  # Kaminari pagination
  delegate :current_page, :total_pages, :limit_value, :entry_name,
           :total_count, :offset_value, :last_page?

  # Will Paginate
  delegate :total_entries, :per_page, :previous_page, :next_page
end

# In decorator
class ProductDecorator < ApplicationDecorator
  delegate_all

  def self.collection_decorator_class
    PaginatingDecorator
  end
end

# Usage
@products = Product.page(params[:page]).decorate
@products.current_page  # Works!
```

### Collection with Summary Methods

```ruby
class OrdersDecorator < Draper::CollectionDecorator
  delegate :current_page, :total_pages

  def total_value
    h.number_to_currency(object.sum(&:total))
  end

  def summary
    "#{object.count} orders totaling #{total_value}"
  end
end
```

## Conditional Rendering Patterns

### State-Based Display

```ruby
class OrderDecorator < ApplicationDecorator
  delegate_all

  STATUS_COLORS = {
    pending: "warning",
    processing: "info",
    shipped: "primary",
    delivered: "success",
    cancelled: "danger"
  }.freeze

  def status_badge
    color = STATUS_COLORS.fetch(status.to_sym, "secondary")
    h.content_tag(:span, status.humanize, class: "badge badge-#{color}")
  end

  def actions
    case status.to_sym
    when :pending
      pending_actions
    when :processing
      processing_actions
    when :shipped
      shipped_actions
    else
      h.content_tag(:span, "No actions available", class: "text-muted")
    end
  end

  private

  def pending_actions
    h.safe_join([
      h.link_to("Process", h.process_order_path(object), method: :patch),
      h.link_to("Cancel", h.cancel_order_path(object), method: :patch)
    ], " | ")
  end
end
```

### Permission-Based Display

```ruby
class DocumentDecorator < ApplicationDecorator
  delegate_all

  def download_link
    return access_denied_message unless can_download?

    h.link_to("Download", h.download_document_path(object), class: "btn btn-primary")
  end

  def edit_section
    return unless can_edit?

    h.render("documents/edit_form", document: self)
  end

  private

  def can_download?
    return true if public?
    context[:current_user]&.can?(:download, object)
  end

  def can_edit?
    context[:current_user]&.can?(:edit, object)
  end

  def access_denied_message
    h.content_tag(:span, "Access denied", class: "text-muted")
  end
end
```

## Decorator Composition

### Multiple Decorators

```ruby
# Base decorator
class UserDecorator < ApplicationDecorator
  delegate_all

  def full_name
    "#{first_name} #{last_name}"
  end
end

# Admin-specific additions
class Users::AdminDecorator < UserDecorator
  def admin_badge
    return unless admin?
    h.content_tag(:span, "Admin", class: "badge badge-danger")
  end

  def detailed_info
    h.content_tag(:dl) do
      h.safe_join([
        h.content_tag(:dt, "Email"),
        h.content_tag(:dd, email),
        h.content_tag(:dt, "Role"),
        h.content_tag(:dd, role),
        h.content_tag(:dt, "Last Login"),
        h.content_tag(:dd, formatted_last_login)
      ])
    end
  end
end

# Controller usage
def index
  @users = User.all.decorate  # UserDecorator
end

def admin_index
  @users = Users::AdminDecorator.decorate_collection(User.all)
end
```

### Decorator with Presenters Pattern

For complex views requiring multiple models:

```ruby
# app/presenters/dashboard_presenter.rb
class DashboardPresenter
  include ActionView::Helpers::TagHelper
  include ActionView::Context

  attr_reader :user, :orders, :notifications

  def initialize(user:, orders:, notifications:, view_context:)
    @user = user.decorate
    @orders = orders.decorate
    @notifications = notifications.decorate
    @h = view_context
  end

  def summary_card
    @h.content_tag(:div, class: "card") do
      @h.safe_join([
        @h.content_tag(:h3, "Welcome, #{user.full_name}"),
        order_summary,
        notification_count
      ])
    end
  end

  private

  def order_summary
    @h.content_tag(:p, "#{orders.count} active orders")
  end

  def notification_count
    @h.content_tag(:p, "#{notifications.unread.count} unread notifications")
  end
end
```

## Draper with Turbo/Hotwire

### Broadcast Compatibility

Draper automatically decorates objects in Turbo broadcasts:

```ruby
class Comment < ApplicationRecord
  after_create_commit -> {
    broadcast_prepend_to post, :comments
    # Object is auto-decorated with CommentDecorator
  }
end
```

### Stimulus Integration

```ruby
class FormDecorator < ApplicationDecorator
  delegate_all

  def input_wrapper(field, &block)
    h.content_tag(:div,
      class: "form-group",
      data: {
        controller: "form-field",
        form_field_field_value: field
      },
      &block
    )
  end
end
```

## Caching Decorated Output

```ruby
class ProductDecorator < ApplicationDecorator
  delegate_all

  def cached_price_display
    h.cache(["product_price", object, context[:locale]]) do
      complex_price_calculation
    end
  end

  private

  def complex_price_calculation
    # Expensive formatting logic
    h.content_tag(:div, class: "price-display") do
      # ...
    end
  end
end
```

## Internationalization

```ruby
class OrderDecorator < ApplicationDecorator
  delegate_all

  def status_text
    I18n.t("orders.status.#{status}", default: status.humanize)
  end

  def formatted_total
    h.number_to_currency(total, locale: context[:locale] || I18n.locale)
  end

  def delivery_date_text
    return I18n.t("orders.no_delivery_date") if delivery_date.blank?

    I18n.l(delivery_date, format: :long)
  end
end
```

## Serialization

### JSON Serialization

```ruby
class ProductDecorator < ApplicationDecorator
  delegate_all

  # Override serializable_hash to include decorator methods
  def serializable_hash(options = nil)
    super(options).merge(
      formatted_price: formatted_price,
      display_name: display_name
    )
  end
end

# Usage
@product.decorate.to_json
# => {"id":1,"name":"Widget","formatted_price":"$10.00","display_name":"Widget (SKU-123)"}
```

### API Response Formatting

```ruby
class Api::ProductDecorator < ApplicationDecorator
  delegate_all

  def as_json(options = {})
    {
      id:,
      name:,
      price: formatted_price,
      availability: availability_status,
      links: {
        self: h.api_product_url(object),
        category: h.api_category_url(category)
      }
    }
  end

  private

  def availability_status
    in_stock? ? "available" : "out_of_stock"
  end
end
```
