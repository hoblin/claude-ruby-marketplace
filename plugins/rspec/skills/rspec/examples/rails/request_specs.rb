# RSpec Rails: Request Specs Examples
# Source: rspec-rails gem features/request_specs/

# Request specs are full-stack integration tests.
# They exercise the entire Rails stack from routing through the response.
# Preferred over controller specs for new code.
# Location: spec/requests/, spec/integration/, spec/api/

# Basic request spec
RSpec.describe "Widgets", type: :request do
  describe "GET /widgets" do
    let!(:widgets) { create_list(:widget, 3) }

    it "returns a successful response" do
      get "/widgets"
      expect(response).to have_http_status(:ok)
    end

    it "displays all widgets" do
      get "/widgets"
      widgets.each do |widget|
        expect(response.body).to include(widget.name)
      end
    end
  end

  describe "GET /widgets/:id" do
    let(:widget) { create(:widget, name: "Test Widget") }

    it "displays the widget" do
      get "/widgets/#{widget.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Test Widget")
    end
  end

  describe "POST /widgets" do
    let(:valid_params) { { widget: { name: "New Widget" } } }
    let(:invalid_params) { { widget: { name: "" } } }

    context "with valid parameters" do
      it "creates a widget" do
        expect {
          post "/widgets", params: valid_params
        }.to change(Widget, :count).by(1)
      end

      it "redirects to the widget page" do
        post "/widgets", params: valid_params

        expect(response).to redirect_to(widget_path(Widget.last))
        follow_redirect!
        expect(response.body).to include("Widget was successfully created")
      end
    end

    context "with invalid parameters" do
      it "does not create a widget" do
        expect {
          post "/widgets", params: invalid_params
        }.not_to change(Widget, :count)
      end

      it "renders the new template" do
        post "/widgets", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /widgets/:id" do
    let(:widget) { create(:widget, name: "Old Name") }

    it "updates the widget" do
      patch "/widgets/#{widget.id}", params: { widget: { name: "New Name" } }

      expect(response).to redirect_to(widget_path(widget))
      expect(widget.reload.name).to eq("New Name")
    end
  end

  describe "DELETE /widgets/:id" do
    let!(:widget) { create(:widget) }

    it "destroys the widget" do
      expect {
        delete "/widgets/#{widget.id}"
      }.to change(Widget, :count).by(-1)
    end

    it "redirects to index" do
      delete "/widgets/#{widget.id}"
      expect(response).to redirect_to(widgets_path)
    end
  end
end

# JSON API request specs
RSpec.describe "API::Widgets", type: :request do
  let(:json_headers) { { "ACCEPT" => "application/json" } }

  describe "GET /api/widgets" do
    let!(:widgets) { create_list(:widget, 3) }

    it "returns JSON response" do
      get "/api/widgets", headers: json_headers

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("application/json")
    end

    it "returns all widgets" do
      get "/api/widgets", headers: json_headers

      json = JSON.parse(response.body, symbolize_names: true)
      expect(json.length).to eq(3)
    end
  end

  describe "POST /api/widgets" do
    let(:valid_params) { { widget: { name: "New Widget" } } }

    it "creates a widget and returns 201" do
      post "/api/widgets", params: valid_params, headers: json_headers

      expect(response).to have_http_status(:created)
      expect(response.content_type).to include("application/json")
    end

    it "returns the created widget" do
      post "/api/widgets", params: valid_params, headers: json_headers

      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:name]).to eq("New Widget")
    end
  end
end

# Authentication in request specs
RSpec.describe "Authenticated requests", type: :request do
  describe "GET /dashboard" do
    context "when not authenticated" do
      it "redirects to login" do
        get "/dashboard"
        expect(response).to redirect_to(login_path)
      end
    end

    context "when authenticated" do
      let(:user) { create(:user) }

      before { sign_in(user) }

      it "shows the dashboard" do
        get "/dashboard"
        expect(response).to have_http_status(:ok)
      end
    end
  end
end

# Token-based API authentication
RSpec.describe "API Authentication", type: :request do
  let(:user) { create(:user) }
  let(:token) { user.api_token }

  describe "GET /api/profile" do
    context "without token" do
      it "returns unauthorized" do
        get "/api/profile"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with valid token" do
      it "returns the profile" do
        get "/api/profile", headers: { "Authorization" => "Bearer #{token}" }
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid token" do
      it "returns unauthorized" do
        get "/api/profile", headers: { "Authorization" => "Bearer invalid" }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

# Subdomain testing
RSpec.describe "API subdomain", type: :request do
  before { host! "api.example.com" }

  describe "GET /widgets" do
    let!(:widgets) { create_list(:widget, 2) }

    it "serves JSON from api subdomain" do
      get "/widgets", headers: { "ACCEPT" => "application/json" }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to start_with("application/json")
    end
  end
end

# Testing response headers
RSpec.describe "Response headers", type: :request do
  describe "GET /api/widgets" do
    it "includes pagination headers" do
      create_list(:widget, 25)
      get "/api/widgets"

      expect(response.headers["X-Total-Count"]).to eq("25")
      expect(response.headers["X-Page"]).to eq("1")
    end
  end

  describe "caching headers" do
    it "sets cache-control for public resources" do
      widget = create(:widget, :published)
      get "/widgets/#{widget.id}"

      expect(response.headers["Cache-Control"]).to include("public")
    end
  end
end

# Multipart file upload
RSpec.describe "File uploads", type: :request do
  describe "POST /documents" do
    let(:file) { fixture_file_upload("spec/fixtures/document.pdf", "application/pdf") }

    it "accepts file upload" do
      post "/documents", params: { document: { file: } }

      expect(response).to redirect_to(documents_path)
      expect(Document.last.file).to be_attached
    end
  end
end

# Testing redirects with follow_redirect!
RSpec.describe "Redirect chains", type: :request do
  describe "POST /login" do
    let(:user) { create(:user, password: "secret") }

    it "redirects to dashboard after login" do
      post "/login", params: { email: user.email, password: "secret" }

      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(response.body).to include("Welcome back")
    end
  end
end

# Helper for JSON response parsing
RSpec.describe "Widgets API", type: :request do
  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe "GET /api/widgets/:id" do
    let(:widget) { create(:widget, name: "Test") }

    it "returns widget attributes" do
      get "/api/widgets/#{widget.id}", headers: { "ACCEPT" => "application/json" }

      expect(json_response[:name]).to eq("Test")
      expect(json_response[:id]).to eq(widget.id)
    end
  end
end
