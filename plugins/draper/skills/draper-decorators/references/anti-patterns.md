# Draper Anti-Patterns and Solutions

## Anti-Pattern 1: Fat Decorator

### Problem

Stuffing all presentation logic into a single decorator creates a maintenance nightmare:

```ruby
# BAD: 500+ lines, 40+ methods
class UserDecorator < ApplicationDecorator
  delegate_all

  # Profile methods
  def full_name; end
  def avatar_tag; end
  def profile_summary; end
  def bio_excerpt; end

  # Admin methods
  def admin_badge; end
  def permissions_list; end
  def audit_log_link; end
  def role_selector; end

  # Social methods
  def twitter_link; end
  def facebook_link; end
  def linkedin_badge; end

  # Notification methods
  def notification_count; end
  def unread_badge; end
  def notification_dropdown; end

  # Settings methods
  def preferences_form; end
  def privacy_settings; end

  # ... 30 more methods
end
```

### Why It's Bad

- **Single Responsibility Violation**: One class handles many contexts
- **Divergent Change**: Changes to admin views require editing user profile decorator
- **Hard to Test**: Tests become large and unfocused
- **Cognitive Overload**: Developers must understand entire decorator to make changes

### Solution: Context-Specific Decorators

```ruby
# GOOD: Base decorator with shared methods
class UserDecorator < ApplicationDecorator
  delegate_all

  def full_name
    "#{first_name} #{last_name}"
  end

  def avatar_tag(size: :medium)
    h.image_tag(avatar_url(size), alt: full_name, class: "avatar avatar-#{size}")
  end
end

# Admin-specific presentation
class Users::AdminDecorator < UserDecorator
  def admin_badge
    return unless admin?
    h.content_tag(:span, "Admin", class: "badge badge-danger")
  end

  def permissions_list
    h.content_tag(:ul) do
      h.safe_join(permissions.map { |p| h.content_tag(:li, p) })
    end
  end

  def audit_log_link
    h.link_to("View Audit Log", h.admin_user_audit_path(object))
  end
end

# Profile page presentation
class Users::ProfileDecorator < UserDecorator
  def bio_excerpt
    h.truncate(bio, length: 200, separator: ' ')
  end

  def social_links
    links = []
    links << twitter_link if twitter_handle.present?
    links << linkedin_link if linkedin_url.present?
    h.safe_join(links, " | ")
  end
end

# Notification-specific presentation
class Users::NotificationDecorator < UserDecorator
  def unread_count_badge
    count = unread_notifications_count
    return if count.zero?

    h.content_tag(:span, count, class: "badge badge-primary")
  end
end
```

### Usage

```ruby
# Admin panel
@user = Users::AdminDecorator.decorate(User.find(params[:id]))

# Public profile
@user = Users::ProfileDecorator.decorate(User.find(params[:id]))

# Header notification widget
@user = Users::NotificationDecorator.decorate(current_user)
```

---

## Anti-Pattern 2: N+1 Queries

### Problem

Decorating without eager loading causes database performance issues:

```ruby
# Controller
def index
  @posts = Post.all.decorate  # No eager loading!
end

# Decorator
class PostDecorator < ApplicationDecorator
  delegate_all

  def author_name
    author.name  # N+1 query for each post!
  end

  def comments_count
    "#{comments.count} comments"  # Another N+1!
  end
end
```

### Why It's Bad

- Each `@post.author_name` triggers a separate query
- 100 posts = 100+ queries instead of 2
- Performance degrades linearly with collection size

### Solution: Eager Load Before Decorating

```ruby
# GOOD: Eager load associations first
class PostsController < ApplicationController
  def index
    @posts = Post.includes(:author, :comments).all.decorate
  end
end
```

### Solution: Use Counter Caches

```ruby
# Migration
add_column :posts, :comments_count, :integer, default: 0, null: false

# Model
class Comment < ApplicationRecord
  belongs_to :post, counter_cache: true
end

# Decorator - no query needed
class PostDecorator < ApplicationDecorator
  def comments_count_badge
    "#{comments_count} comments"  # Uses counter cache
  end
end
```

### Solution: Batch Loading for Complex Cases

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.includes(:author)
                 .with_attached_images  # Active Storage
                 .with_rich_text_content  # Action Text
                 .decorate
  end
end
```

---

## Anti-Pattern 3: Decorating Too Early

### Problem

Using decorated objects in business logic:

```ruby
# BAD: Passing decorator to service
class PublishService
  def call(decorated_post)
    decorated_post.update(published_at: Time.current)
    decorated_post.notify_subscribers  # Is this decorator or model method?
  end
end

# Controller
def publish
  @post = Post.find(params[:id]).decorate
  PublishService.new.call(@post)  # Decorated object in service!
end
```

### Why It's Bad

- Services should work with models, not decorators
- Confuses presentation and business logic
- Makes testing harder (do you stub model or decorator?)
- Decorator methods might be called accidentally in business logic

### Solution: Decorate at the Last Moment

```ruby
# GOOD: Services receive models
class PublishService
  def call(post)
    post.update(published_at: Time.current)
    NotificationJob.perform_later(post.id)
  end
end

# Controller - decorate only before render
class PostsController < ApplicationController
  def publish
    @post = Post.find(params[:id])
    PublishService.new.call(@post)  # Model, not decorator

    @post = @post.decorate  # Decorate right before render
    render :show
  end
end
```

### Rule of Thumb

> "Decorate at the last moment, right before you render the view."

---

## Anti-Pattern 4: Business Logic in Decorators

### Problem

Putting calculations, validations, or state changes in decorators:

```ruby
# BAD: Business logic in decorator
class OrderDecorator < ApplicationDecorator
  delegate_all

  def apply_discount(code)
    discount = Discount.find_by(code: code)
    object.update(discount_amount: discount.amount)  # State change!
  end

  def calculate_tax
    subtotal * tax_rate  # Business calculation!
  end

  def valid_for_shipping?
    items.any? && shipping_address.present?  # Validation!
  end
end
```

### Why It's Bad

- Violates separation of concerns
- Business logic becomes scattered
- Hard to test business rules in isolation
- Decorators become coupled to domain logic

### Solution: Keep Business Logic in Models/Services

```ruby
# Model handles business logic
class Order < ApplicationRecord
  def calculate_tax
    subtotal * tax_rate
  end

  def valid_for_shipping?
    items.any? && shipping_address.present?
  end
end

# Service handles state changes
class ApplyDiscountService
  def call(order, code)
    discount = Discount.find_by!(code: code)
    order.update!(discount_amount: discount.amount)
  end
end

# GOOD: Decorator only formats for display
class OrderDecorator < ApplicationDecorator
  delegate_all

  def formatted_tax
    h.number_to_currency(calculate_tax)  # Delegates to model
  end

  def shipping_status_badge
    css = valid_for_shipping? ? "success" : "warning"
    text = valid_for_shipping? ? "Ready to Ship" : "Missing Info"
    h.content_tag(:span, text, class: "badge badge-#{css}")
  end
end
```

---

## Anti-Pattern 5: Circular Decoration Reference

### Problem

Models referencing their decorators:

```ruby
# BAD: Model knows about decorator
class Post < ApplicationRecord
  def display_title
    PostDecorator.new(self).formatted_title
  end

  def render_preview
    decorator = decorate
    decorator.preview_card
  end
end
```

### Why It's Bad

- Creates circular dependency (model → decorator → model)
- Violates unidirectional data flow
- Makes models dependent on presentation layer
- Complicates testing

### Solution: Keep Models Unaware of Decorators

```ruby
# GOOD: Model has no decorator knowledge
class Post < ApplicationRecord
  def title_with_status
    "#{title} (#{status})"  # Pure model method, no formatting
  end
end

# View helper or decorator handles presentation
class PostDecorator < ApplicationDecorator
  delegate_all

  def formatted_title
    h.content_tag(:h1, title_with_status, class: css_class_for_status)
  end
end
```

---

## Anti-Pattern 6: Using Decorators in Background Jobs

### Problem

Passing decorated objects to background jobs:

```ruby
# BAD: Decorator in job
class NotificationJob < ApplicationJob
  def perform(decorated_user)
    UserMailer.notification(decorated_user).deliver_now
  end
end

# Controller
NotificationJob.perform_later(@user.decorate)
```

### Why It's Bad

- Decorators can't be serialized properly
- View context not available in background
- Job might fail or behave unexpectedly

### Solution: Pass IDs, Decorate in Mailer if Needed

```ruby
# GOOD: Job receives ID
class NotificationJob < ApplicationJob
  def perform(user_id)
    user = User.find(user_id)
    UserMailer.notification(user).deliver_now
  end
end

# Mailer can decorate if needed
class UserMailer < ApplicationMailer
  def notification(user)
    @user = user.decorate
    mail(to: @user.email)
  end
end

# Controller
NotificationJob.perform_later(@user.id)
```

---

## Anti-Pattern 7: Inconsistent Decoration

### Problem

Mixing decorated and undecorated objects in the same context:

```ruby
# BAD: Inconsistent
class PostsController < ApplicationController
  def index
    @featured_post = Post.featured.first.decorate
    @recent_posts = Post.recent.limit(5)  # Not decorated!
    @popular_posts = Post.popular.decorate
  end
end
```

### Why It's Bad

- Views must handle both types
- Leads to bugs when calling decorator methods on raw models
- Confusing for developers

### Solution: Be Consistent

```ruby
# GOOD: All decorated
class PostsController < ApplicationController
  def index
    @featured_post = Post.featured.first.decorate
    @recent_posts = Post.recent.limit(5).decorate
    @popular_posts = Post.popular.decorate
  end
end

# Or establish clear naming convention
class PostsController < ApplicationController
  def index
    @featured_post = Post.featured.first.decorate
    @recent_post_models = Post.recent.limit(5)  # Clear it's not decorated
  end
end
```

---

## Anti-Pattern 8: Overriding Model Methods Incorrectly

### Problem

Overriding model methods without maintaining compatibility:

```ruby
# BAD: Breaks model contract
class UserDecorator < ApplicationDecorator
  delegate_all

  def email
    # Original returns string, now returns HTML!
    h.mail_to(object.email, object.email)
  end
end
```

### Why It's Bad

- Code expecting string gets HTML
- Breaks form helpers that use `email`
- Violates Liskov Substitution Principle

### Solution: Use Distinct Method Names

```ruby
# GOOD: Separate presentation method
class UserDecorator < ApplicationDecorator
  delegate_all

  def email_link
    h.mail_to(email, email)
  end

  def formatted_email
    h.content_tag(:span, email, class: "email")
  end
end
```

---

## Anti-Pattern 9: Heavy Processing in Decorators

### Problem

Performing expensive operations in decorator methods:

```ruby
# BAD: Expensive operations
class ReportDecorator < ApplicationDecorator
  delegate_all

  def summary_chart
    data = object.calculate_statistics  # Expensive!
    ChartGenerator.new(data).to_svg     # More processing!
  end
end
```

### Why It's Bad

- Called multiple times per request if accessed multiple times
- No caching by default
- View rendering becomes slow

### Solution: Memoize or Pre-compute

```ruby
# GOOD: Memoize expensive operations
class ReportDecorator < ApplicationDecorator
  delegate_all

  def summary_chart
    @summary_chart ||= generate_chart
  end

  private

  def generate_chart
    ChartGenerator.new(object.statistics).to_svg
  end
end

# Better: Pre-compute in model/service
class Report < ApplicationRecord
  def statistics
    @statistics ||= StatisticsCalculator.new(self).call
  end
end
```

---

## Anti-Pattern 10: Not Using ApplicationDecorator

### Problem

Each decorator inherits directly from Draper::Decorator:

```ruby
# BAD: No shared base
class PostDecorator < Draper::Decorator
  def formatted_date
    created_at.strftime("%B %d, %Y")
  end
end

class CommentDecorator < Draper::Decorator
  def formatted_date
    created_at.strftime("%B %d, %Y")  # Duplicated!
  end
end
```

### Why It's Bad

- Code duplication across decorators
- No place for shared helper methods
- Inconsistent formatting

### Solution: Use ApplicationDecorator

```ruby
# GOOD: Shared base class
class ApplicationDecorator < Draper::Decorator
  def formatted_date(date = created_at, format: :long)
    return "N/A" if date.blank?
    h.l(date, format:)
  end

  def formatted_currency(amount)
    h.number_to_currency(amount)
  end
end

class PostDecorator < ApplicationDecorator
  delegate_all
  # formatted_date inherited
end

class CommentDecorator < ApplicationDecorator
  delegate_all
  # formatted_date inherited
end
```

---

## Summary Checklist

Before committing decorator code, verify:

- [ ] Decorator only contains presentation logic
- [ ] No business logic, validations, or state changes
- [ ] Controller eager loads associations before decorating
- [ ] Decoration happens right before rendering
- [ ] No circular references between model and decorator
- [ ] Method names don't override model methods with different return types
- [ ] Expensive operations are memoized
- [ ] All related decorators inherit from ApplicationDecorator
- [ ] Decorator isn't too large (consider splitting if >200 lines)
- [ ] Background jobs receive IDs, not decorated objects
