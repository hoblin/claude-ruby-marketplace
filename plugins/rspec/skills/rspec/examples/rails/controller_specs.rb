# RSpec Rails: Controller Specs Examples
# Source: rspec-rails gem features/controller_specs/

# NOTE: Request specs are generally preferred for new code.
# Controller specs are useful for testing specific controller behavior in isolation.
# Location: spec/controllers/

# Basic controller spec
RSpec.describe WidgetsController, type: :controller do
  describe "GET #index" do
    let!(:widgets) { create_list(:widget, 3) }

    it "returns a successful response" do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it "assigns @widgets" do
      get :index
      expect(assigns(:widgets)).to match_array(widgets)
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe "GET #show" do
    let(:widget) { create(:widget) }

    it "assigns @widget" do
      get :show, params: { id: widget.id }
      expect(assigns(:widget)).to eq(widget)
    end
  end

  describe "GET #new" do
    it "assigns a new widget" do
      get :new
      expect(assigns(:widget)).to be_a_new(Widget)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      let(:valid_params) { { widget: attributes_for(:widget) } }

      it "creates a new Widget" do
        expect {
          post :create, params: valid_params
        }.to change(Widget, :count).by(1)
      end

      it "redirects to the created widget" do
        post :create, params: valid_params
        expect(response).to redirect_to(Widget.last)
      end
    end

    context "with invalid params" do
      let(:invalid_params) { { widget: { name: "" } } }

      it "does not create a Widget" do
        expect {
          post :create, params: invalid_params
        }.not_to change(Widget, :count)
      end

      it "renders the new template" do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
    end
  end

  describe "PATCH #update" do
    let(:widget) { create(:widget, name: "Old Name") }

    context "with valid params" do
      it "updates the widget" do
        patch :update, params: { id: widget.id, widget: { name: "New Name" } }
        expect(widget.reload.name).to eq("New Name")
      end

      it "redirects to the widget" do
        patch :update, params: { id: widget.id, widget: { name: "New Name" } }
        expect(response).to redirect_to(widget)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:widget) { create(:widget) }

    it "destroys the widget" do
      expect {
        delete :destroy, params: { id: widget.id }
      }.to change(Widget, :count).by(-1)
    end

    it "redirects to index" do
      delete :destroy, params: { id: widget.id }
      expect(response).to redirect_to(widgets_url)
    end
  end
end

# render_views - actually render templates (stubbed by default)
RSpec.describe WidgetsController, type: :controller do
  render_views

  describe "GET #index" do
    let!(:widget) { create(:widget, name: "My Widget") }

    it "renders widget name in body" do
      get :index
      expect(response.body).to include("My Widget")
    end
  end
end

# Testing different response formats
RSpec.describe WidgetsController, type: :controller do
  describe "POST #create" do
    let(:valid_params) { { widget: attributes_for(:widget) } }

    it "responds to HTML by default" do
      post :create, params: valid_params
      expect(response.content_type).to include("text/html")
    end

    it "responds to JSON when requested" do
      post :create, params: valid_params.merge(format: :json)
      expect(response.content_type).to include("application/json")
    end
  end
end

# Anonymous controllers for testing base controller behavior
RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      raise ApplicationController::AccessDenied
    end
  end

  describe "handling AccessDenied exceptions" do
    it "redirects to the 401 page" do
      get :index
      expect(response).to redirect_to("/401.html")
    end
  end
end

# Testing custom controller action
RSpec.describe ApplicationController, type: :controller do
  controller do
    def custom_action
      render plain: "Custom response"
    end
  end

  before do
    routes.draw { get "custom_action" => "anonymous#custom_action" }
  end

  it "renders custom response" do
    get :custom_action
    expect(response.body).to eq("Custom response")
  end
end

# Testing with request headers
RSpec.describe ApiController, type: :controller do
  controller do
    def index
      if request.headers["Authorization"].present?
        render plain: "Authenticated"
      else
        render plain: "Not authenticated", status: :unauthorized
      end
    end
  end

  describe "GET #index" do
    context "with authorization header" do
      before { request.headers["Authorization"] = "Bearer token123" }

      it "returns success" do
        get :index
        expect(response).to have_http_status(:ok)
      end
    end

    context "without authorization header" do
      it "returns unauthorized" do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

# Inherited controller specs
RSpec.describe FoosController, type: :controller do
  # When controller inherits from another controller
  controller FoosController do
    def index
      @name = self.class.name
      @controller_name = controller_name
      render plain: "Hello"
    end
  end

  describe "GET #index" do
    before { get :index }

    it "gets the class name as described" do
      expect(assigns(:name)).to eq("FoosController")
    end

    it "gets the controller_name as described" do
      expect(assigns(:controller_name)).to eq("foos")
    end
  end
end

# Testing before_action filters
RSpec.describe ProtectedController, type: :controller do
  controller do
    before_action :require_login

    def index
      render plain: "Protected content"
    end

    private

    def require_login
      redirect_to login_path unless session[:user_id]
    end
  end

  describe "before_action :require_login" do
    context "when not logged in" do
      it "redirects to login" do
        get :index
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in" do
      before { session[:user_id] = 1 }

      it "allows access" do
        get :index
        expect(response).to have_http_status(:ok)
      end
    end
  end
end

# Testing flash messages
RSpec.describe WidgetsController, type: :controller do
  describe "POST #create" do
    context "with valid params" do
      it "sets a success flash message" do
        post :create, params: { widget: attributes_for(:widget) }
        expect(flash[:notice]).to eq("Widget was successfully created.")
      end
    end

    context "with invalid params" do
      it "sets an error flash message" do
        post :create, params: { widget: { name: "" } }
        expect(flash[:alert]).to be_present
      end
    end
  end
end

# Testing session modifications
RSpec.describe SessionsController, type: :controller do
  describe "POST #create" do
    let(:user) { create(:user, password: "secret") }

    it "sets user_id in session" do
      post :create, params: { email: user.email, password: "secret" }
      expect(session[:user_id]).to eq(user.id)
    end
  end

  describe "DELETE #destroy" do
    before { session[:user_id] = 1 }

    it "clears user_id from session" do
      delete :destroy
      expect(session[:user_id]).to be_nil
    end
  end
end
