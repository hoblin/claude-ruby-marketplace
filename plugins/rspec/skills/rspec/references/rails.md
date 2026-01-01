# RSpec Rails Reference

Comprehensive reference for Rails-specific RSpec testing.

## Spec Types

### Directory Mappings

| Directory | Type | Example Group |
|-----------|------|---------------|
| `spec/models` | `:model` | ModelExampleGroup |
| `spec/controllers` | `:controller` | ControllerExampleGroup |
| `spec/requests` | `:request` | RequestExampleGroup |
| `spec/integration` | `:request` | RequestExampleGroup |
| `spec/api` | `:request` | RequestExampleGroup |
| `spec/routing` | `:routing` | RoutingExampleGroup |
| `spec/views` | `:view` | ViewExampleGroup |
| `spec/helpers` | `:helper` | HelperExampleGroup |
| `spec/mailers` | `:mailer` | MailerExampleGroup |
| `spec/jobs` | `:job` | JobExampleGroup |
| `spec/features` | `:feature` | FeatureExampleGroup |
| `spec/system` | `:system` | SystemExampleGroup |
| `spec/channels` | `:channel` | ChannelExampleGroup |
| `spec/mailboxes` | `:mailbox` | MailboxExampleGroup |

Enable auto-detection:
```ruby
RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
end
```

## Model Specs

Location: `spec/models/`

```ruby
RSpec.describe Post, type: :model do
  describe "#published?" do
    it "returns true when published_at is set" do
      post = Post.new(published_at: Time.current)
      expect(post).to be_published
    end
  end
end
```

## Request Specs

Location: `spec/requests/`, `spec/integration/`, `spec/api/`

Preferred for controller testing. Full stack integration.

```ruby
RSpec.describe "Widget management", type: :request do
  describe "GET /widgets" do
    it "returns widgets" do
      create_list(:widget, 3)

      get "/widgets"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("widget")
    end
  end

  describe "POST /widgets" do
    it "creates widget" do
      post "/widgets", params: { widget: { name: "New" } }

      expect(response).to redirect_to(widget_path(Widget.last))
      follow_redirect!
      expect(response.body).to include("successfully created")
    end
  end

  describe "JSON API" do
    it "returns JSON" do
      headers = { "ACCEPT" => "application/json" }
      post "/widgets", params: { widget: { name: "New" } }, headers: headers

      expect(response.content_type).to include("application/json")
      expect(response).to have_http_status(:created)
    end
  end
end
```

### Request Helpers

```ruby
# HTTP methods
get(path, params: {}, headers: {})
post(path, params: {}, headers: {})
patch(path, params: {}, headers: {})
put(path, params: {}, headers: {})
delete(path, params: {}, headers: {})

# Navigation
follow_redirect!

# Domain
before { host! "api.example.com" }
```

## System Specs

Location: `spec/system/`

Browser-based testing with Capybara. Runs within transactions.

```ruby
RSpec.describe "Widget management", type: :system do
  before do
    driven_by(:rack_test)  # or :selenium_chrome_headless
  end

  it "creates widget" do
    visit "/widgets/new"
    fill_in "Name", with: "My Widget"
    click_button "Create Widget"

    expect(page).to have_text("Widget was successfully created")
  end
end
```

### Driver Configuration

```ruby
RSpec.configure do |config|
  config.before(type: :system) do
    driven_by :selenium_chrome_headless
  end
end
```

## Feature Specs (Legacy)

Location: `spec/features/`

Older approach - prefer system specs for new code.

```ruby
RSpec.feature "Widget management", type: :feature do
  scenario "User creates widget" do
    visit "/widgets/new"
    click_button "Create Widget"
    expect(page).to have_text("successfully created")
  end
end
```

## Controller Specs

Location: `spec/controllers/`

**Note**: Request specs are generally preferred.

```ruby
RSpec.describe TeamsController, type: :controller do
  describe "GET #index" do
    it "assigns @teams" do
      team = create(:team)
      get :index
      expect(assigns(:teams)).to eq([team])
    end

    it "renders index template" do
      get :index
      expect(response).to render_template("index")
    end
  end

  describe "POST #create" do
    it "creates team" do
      expect {
        post :create, params: { team: { name: "New" } }
      }.to change(Team, :count).by(1)
    end
  end
end
```

### Controller Helpers

```ruby
# Set headers
request.headers["Authorization"] = "Bearer token"

# Access instance variables
assigns(:teams)

# Render views (stubbed by default)
render_views
```

## View Specs

Location: `spec/views/`

Three-step pattern: assign, render, assert.

```ruby
RSpec.describe "widgets/index", type: :view do
  it "displays widgets" do
    assign(:widgets, [
      Widget.new(name: "slicer"),
      Widget.new(name: "dicer")
    ])

    render

    expect(rendered).to match(/slicer/)
    expect(rendered).to match(/dicer/)
  end
end
```

### View Helpers

```ruby
# Assign instance variables
assign(:widget, widget)

# Render
render                                          # described template
render template: "widgets/widget"               # explicit template
render template: "widgets/widget", layout: "layouts/admin"
render partial: "widgets/widget", locals: { widget: widget }

# Access output
rendered

# Stub helpers
allow(view).to receive(:admin?).and_return(true)
```

## Helper Specs

Location: `spec/helpers/`

```ruby
RSpec.describe ApplicationHelper, type: :helper do
  describe "#page_title" do
    it "returns default title" do
      expect(helper.page_title).to eq("Default Title")
    end

    it "uses assigned title" do
      assign(:title, "Custom Title")
      expect(helper.page_title).to eq("Custom Title")
    end
  end
end
```

## Job Specs

Location: `spec/jobs/`

Requires `ActiveJob::Base.queue_adapter = :test`

```ruby
RSpec.describe UploadBackupsJob, type: :job do
  describe "#perform_later" do
    it "enqueues job" do
      expect {
        UploadBackupsJob.perform_later("backup")
      }.to have_enqueued_job
    end

    it "enqueues with arguments" do
      expect {
        UploadBackupsJob.perform_later("backup")
      }.to have_enqueued_job.with("backup")
    end

    it "enqueues on queue" do
      expect {
        UploadBackupsJob.perform_later("backup")
      }.to have_enqueued_job.on_queue("low")
    end

    it "enqueues at time" do
      expect {
        UploadBackupsJob.set(wait_until: Date.tomorrow.noon).perform_later
      }.to have_enqueued_job.at(Date.tomorrow.noon)
    end
  end
end
```

### Job Matchers

Block form:
```ruby
expect { Job.perform_later }.to have_enqueued_job
expect { Job.perform_later }.to have_enqueued_job(Job)
expect { Job.perform_later }.to have_enqueued_job.with(args)
expect { Job.perform_later }.to have_enqueued_job.on_queue("queue")
expect { Job.perform_later }.to have_enqueued_job.at(time)
expect { Job.perform_later }.to have_enqueued_job.at_priority(5)
```

Imperative form:
```ruby
Job.perform_later
expect(Job).to have_been_enqueued
expect(Job).to have_been_enqueued.exactly(:once)
expect(Job).to have_been_enqueued.at_least(:twice)
```

## Mailer Specs

Location: `spec/mailers/`

```ruby
RSpec.describe NotificationMailer, type: :mailer do
  describe "welcome" do
    let(:user) { create(:user) }
    let(:mail) { NotificationMailer.welcome(user) }

    it "renders headers" do
      expect(mail.subject).to eq("Welcome")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["noreply@example.com"])
    end

    it "renders body" do
      expect(mail.body.encoded).to include("Welcome")
    end
  end
end
```

## Routing Specs

Location: `spec/routing/`

```ruby
RSpec.describe "routes", type: :routing do
  it "routes to show" do
    expect(get: "/widgets/1").to route_to(
      controller: "widgets",
      action: "show",
      id: "1"
    )
  end

  it "does not route" do
    expect(delete: "/widgets/1").not_to be_routable
  end
end
```

## Rails Matchers

### have_http_status

```ruby
expect(response).to have_http_status(200)
expect(response).to have_http_status(:ok)
expect(response).to have_http_status(:success)    # 2xx
expect(response).to have_http_status(:redirect)   # 3xx
expect(response).to have_http_status(:error)      # 5xx
expect(response).to have_http_status(:missing)    # 404
```

### redirect_to

```ruby
expect(response).to redirect_to(widget_url(widget))
expect(response).to redirect_to(action: :show, id: 1)
expect(response).to redirect_to(widget)
expect(response).to redirect_to("/widgets/1")
```

### render_template

```ruby
expect(response).to render_template(:index)
expect(response).to render_template("widgets/index")
expect(response).to render_template(partial: "_widget")
```

### route_to

```ruby
expect(get: "/widgets/1").to route_to(
  controller: "widgets",
  action: "show",
  id: "1"
)
```

### be_routable

```ruby
expect(get: "/widgets/1").to be_routable
expect(delete: "/admin").not_to be_routable
```

### be_a_new

```ruby
expect(assigns(:widget)).to be_a_new(Widget)
```

### be_valid (with shoulda-matchers)

```ruby
expect(widget).to be_valid
expect(widget).not_to be_valid
```

## Configuration

### rails_helper.rb

```ruby
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

abort("Production!") if Rails.env.production?

require "rspec/rails"

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join("spec/fixtures")]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
```

### Transactional Fixtures

Each example runs in a database transaction:
- Data created in example is rolled back
- Each example starts with clean database
- `before(:example)` data is rolled back
- `before(:context)` data persists (manually clean up)

### Factory Bot Integration

```ruby
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

# Usage
user = create(:user)
user = build(:user)
attributes = attributes_for(:user)
```

### Database Cleaner (for JS tests)

```ruby
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end
end
```

## Common Patterns

### Authentication Helper

```ruby
module AuthenticationHelpers
  def sign_in(user)
    post "/sessions", params: { email: user.email, password: "password" }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
```

### JSON Response Helper

```ruby
def json_response
  JSON.parse(response.body, symbolize_names: true)
end

# Usage
expect(json_response[:name]).to eq("Widget")
```

### Shared Examples for Resources

```ruby
RSpec.shared_examples "a protected resource" do
  context "when not authenticated" do
    it "returns unauthorized" do
      make_request
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

RSpec.describe "Widgets", type: :request do
  describe "GET /widgets" do
    it_behaves_like "a protected resource" do
      def make_request
        get "/widgets"
      end
    end
  end
end
```
