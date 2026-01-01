# RSpec Rails: Rails-Specific Matchers Examples
# Source: rspec-rails gem features/matchers/

# Rails-specific matchers for testing HTTP responses,
# redirects, templates, and more.

# have_http_status - testing response codes
RSpec.describe "have_http_status", type: :request do
  describe "numeric status codes" do
    it "matches exact code" do
      get "/widgets"
      expect(response).to have_http_status(200)
    end

    it "matches created status" do
      post "/widgets", params: { widget: { name: "New" } }
      expect(response).to have_http_status(201)
    end
  end

  describe "symbolic status names" do
    it "matches :ok" do
      get "/widgets"
      expect(response).to have_http_status(:ok)
    end

    it "matches :created" do
      post "/api/widgets", params: { widget: { name: "New" } },
        headers: { "ACCEPT" => "application/json" }
      expect(response).to have_http_status(:created)
    end

    it "matches :not_found" do
      get "/widgets/nonexistent"
      expect(response).to have_http_status(:not_found)
    end

    it "matches :unprocessable_entity" do
      post "/widgets", params: { widget: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "matches :unauthorized" do
      get "/admin/dashboard"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "status type matchers" do
    it "matches :success (any 2xx)" do
      get "/widgets"
      expect(response).to have_http_status(:success)
    end

    it "matches :redirect (any 3xx)" do
      post "/widgets", params: { widget: { name: "New" } }
      expect(response).to have_http_status(:redirect)
    end

    it "matches :error (any 5xx)" do
      allow_any_instance_of(WidgetsController).to receive(:index).and_raise(StandardError)
      get "/widgets"
      expect(response).to have_http_status(:error)
    end

    it "matches :missing (404)" do
      get "/nonexistent"
      expect(response).to have_http_status(:missing)
    end
  end
end

# redirect_to - testing redirects
RSpec.describe "redirect_to", type: :controller do
  controller WidgetsController do
    def create
      @widget = Widget.create!(params.require(:widget).permit(:name))
      redirect_to @widget
    end
  end

  describe "POST #create" do
    let(:valid_params) { { widget: { name: "Test" } } }

    it "redirects to URL" do
      post :create, params: valid_params
      expect(response).to redirect_to(widget_url(assigns(:widget)))
    end

    it "redirects to path" do
      post :create, params: valid_params
      expect(response).to redirect_to("/widgets/#{assigns(:widget).id}")
    end

    it "redirects to hash" do
      post :create, params: valid_params
      expect(response).to redirect_to(action: :show, id: assigns(:widget).id)
    end

    it "redirects to record" do
      post :create, params: valid_params
      expect(response).to redirect_to(assigns(:widget))
    end
  end
end

# render_template - testing template rendering
RSpec.describe "render_template", type: :controller do
  controller WidgetsController do
  end

  describe "GET #index" do
    it "renders index template" do
      get :index
      expect(response).to render_template(:index)
    end

    it "renders with full path" do
      get :index
      expect(response).to render_template("widgets/index")
    end

    it "does not render other templates" do
      get :index
      expect(response).not_to render_template("widgets/show")
    end
  end

  describe "layout rendering" do
    it "renders with application layout" do
      get :index
      expect(response).to render_template("layouts/application")
    end

    it "does not render admin layout" do
      get :index
      expect(response).not_to render_template("layouts/admin")
    end
  end

  describe "partial rendering" do
    render_views

    it "renders partial" do
      create_list(:widget, 2)
      get :index
      expect(response).to render_template(partial: "_widget")
    end
  end
end

# route_to - testing routes
RSpec.describe "route_to", type: :routing do
  describe "shortcut syntax" do
    it "routes with controller#action" do
      expect(get: "/widgets").to route_to("widgets#index")
    end

    it "routes with id" do
      expect(get: "/widgets/1").to route_to("widgets#show", id: "1")
    end
  end

  describe "hash syntax" do
    it "routes with full hash" do
      expect(get: "/widgets").to route_to(
        controller: "widgets",
        action: "index"
      )
    end

    it "routes with params" do
      expect(get: "/widgets/1").to route_to(
        controller: "widgets",
        action: "show",
        id: "1"
      )
    end
  end

  describe "negative matching" do
    it "does not route nonexistent paths" do
      expect(get: "/nonexistent").not_to route_to("widgets#index")
    end
  end
end

# be_routable - testing route existence
RSpec.describe "be_routable", type: :routing do
  describe "routable paths" do
    it "matches existing routes" do
      expect(get: "/widgets").to be_routable
      expect(post: "/widgets").to be_routable
      expect(get: "/widgets/1").to be_routable
    end
  end

  describe "non-routable paths" do
    it "does not match nonexistent routes" do
      expect(put: "/widgets").not_to be_routable
      expect(delete: "/admin/destroy_all").not_to be_routable
    end
  end
end

# be_a_new - testing new records
RSpec.describe "be_a_new", type: :controller do
  controller WidgetsController do
    def new
      @widget = Widget.new
    end
  end

  describe "GET #new" do
    it "assigns a new widget" do
      get :new
      expect(assigns(:widget)).to be_a_new(Widget)
    end
  end

  describe "after save" do
    let(:widget) { Widget.create!(name: "Saved") }

    it "is not a new widget" do
      expect(widget).not_to be_a_new(Widget)
    end
  end

  describe "with attributes" do
    it "matches with expected attributes" do
      widget = Widget.new(name: "Test")
      expect(widget).to be_a_new(Widget).with(name: "Test")
    end
  end
end

# be_valid - testing model validity
RSpec.describe "be_valid", type: :model do
  describe Widget do
    it "is valid with valid attributes" do
      widget = Widget.new(name: "Valid Widget")
      expect(widget).to be_valid
    end

    it "is not valid without required attributes" do
      widget = Widget.new(name: nil)
      expect(widget).not_to be_valid
    end

    it "validates with context" do
      widget = Widget.new(name: "Test")
      expect(widget).to be_valid(:create)
    end
  end
end

# have_enqueued_job - testing job enqueuing
RSpec.describe "have_enqueued_job", type: :job do
  describe "block form" do
    it "matches enqueued job" do
      expect {
        ProcessJob.perform_later("data")
      }.to have_enqueued_job
    end

    it "matches specific job class" do
      expect {
        ProcessJob.perform_later("data")
      }.to have_enqueued_job(ProcessJob)
    end

    it "matches with arguments" do
      expect {
        ProcessJob.perform_later("data", 123)
      }.to have_enqueued_job.with("data", 123)
    end

    it "matches on queue" do
      expect {
        ProcessJob.perform_later
      }.to have_enqueued_job.on_queue("default")
    end

    it "matches at time" do
      scheduled_time = 1.hour.from_now
      expect {
        ProcessJob.set(wait_until: scheduled_time).perform_later
      }.to have_enqueued_job.at(scheduled_time)
    end
  end

  describe "imperative form" do
    before { ProcessJob.perform_later }

    it "verifies job was enqueued" do
      expect(ProcessJob).to have_been_enqueued
    end

    it "verifies enqueue count" do
      ProcessJob.perform_later
      expect(ProcessJob).to have_been_enqueued.exactly(:twice)
    end
  end
end

# have_broadcasted_to - testing ActionCable broadcasts
RSpec.describe "have_broadcasted_to", type: :channel do
  describe "broadcasting messages" do
    it "matches broadcast to channel" do
      expect {
        ActionCable.server.broadcast("notifications", text: "Hello!")
      }.to have_broadcasted_to("notifications")
    end

    it "matches with message content" do
      expect {
        ActionCable.server.broadcast("notifications", text: "Hello!")
      }.to have_broadcasted_to("notifications").with(text: "Hello!")
    end

    it "matches broadcast count" do
      expect {
        2.times { ActionCable.server.broadcast("notifications", text: "Hi") }
      }.to have_broadcasted_to("notifications").exactly(:twice)
    end
  end

  describe "broadcasting to record" do
    let(:user) { create(:user) }

    it "matches broadcast to model" do
      expect {
        ChatChannel.broadcast_to(user, text: "Message")
      }.to have_broadcasted_to(user)
    end
  end
end

# send_email - testing email sending (rspec-rails 7.0+)
RSpec.describe "send_email", type: :mailer do
  describe "email sending" do
    it "matches sent email" do
      expect {
        NotificationsMailer.welcome(user).deliver_now
      }.to send_email
    end

    it "matches email attributes" do
      user = create(:user, email: "test@example.com")

      expect {
        NotificationsMailer.welcome(user).deliver_now
      }.to send_email(
        from: "noreply@example.com",
        to: "test@example.com",
        subject: "Welcome!"
      )
    end
  end
end

# match_array for ActiveRecord relations
RSpec.describe "match_array with relations", type: :model do
  let!(:widgets) { create_list(:widget, 3) }

  it "matches relation regardless of order" do
    expect(Widget.all).to match_array(widgets)
  end

  it "matches scope results" do
    published = create_list(:widget, 2, :published)
    expect(Widget.published).to match_array(published)
  end
end
