# RSpec Rails: Routing Specs Examples
# Source: rspec-rails gem features/routing_specs/

# Routing specs test Rails routes in isolation.
# Location: spec/routing/

# Basic route_to matching
RSpec.describe "Widget routes", type: :routing do
  describe "GET /widgets" do
    it "routes to widgets#index" do
      expect(get: "/widgets").to route_to("widgets#index")
    end
  end

  describe "GET /widgets/:id" do
    it "routes to widgets#show" do
      expect(get: "/widgets/1").to route_to(
        controller: "widgets",
        action: "show",
        id: "1"
      )
    end
  end

  describe "POST /widgets" do
    it "routes to widgets#create" do
      expect(post: "/widgets").to route_to("widgets#create")
    end
  end

  describe "PATCH /widgets/:id" do
    it "routes to widgets#update" do
      expect(patch: "/widgets/1").to route_to(
        controller: "widgets",
        action: "update",
        id: "1"
      )
    end
  end

  describe "DELETE /widgets/:id" do
    it "routes to widgets#destroy" do
      expect(delete: "/widgets/1").to route_to(
        controller: "widgets",
        action: "destroy",
        id: "1"
      )
    end
  end
end

# Testing nested routes
RSpec.describe "Comment routes", type: :routing do
  describe "GET /posts/:post_id/comments" do
    it "routes to comments#index" do
      expect(get: "/posts/5/comments").to route_to(
        controller: "comments",
        action: "index",
        post_id: "5"
      )
    end
  end

  describe "POST /posts/:post_id/comments" do
    it "routes to comments#create" do
      expect(post: "/posts/5/comments").to route_to(
        controller: "comments",
        action: "create",
        post_id: "5"
      )
    end
  end
end

# Testing namespaced routes
RSpec.describe "Admin routes", type: :routing do
  describe "GET /admin/users" do
    it "routes to admin/users#index" do
      expect(get: "/admin/users").to route_to("admin/users#index")
    end
  end

  describe "GET /admin/dashboard" do
    it "routes to admin/dashboard#show" do
      expect(get: "/admin/dashboard").to route_to("admin/dashboard#show")
    end
  end
end

# Testing API versioned routes
RSpec.describe "API v1 routes", type: :routing do
  describe "GET /api/v1/widgets" do
    it "routes to api/v1/widgets#index" do
      expect(get: "/api/v1/widgets").to route_to(
        controller: "api/v1/widgets",
        action: "index"
      )
    end
  end
end

# Testing custom member routes
RSpec.describe "Custom routes", type: :routing do
  describe "POST /widgets/:id/publish" do
    it "routes to widgets#publish" do
      expect(post: "/widgets/1/publish").to route_to(
        controller: "widgets",
        action: "publish",
        id: "1"
      )
    end
  end

  describe "POST /widgets/:id/archive" do
    it "routes to widgets#archive" do
      expect(post: "/widgets/1/archive").to route_to(
        controller: "widgets",
        action: "archive",
        id: "1"
      )
    end
  end
end

# Testing collection routes
RSpec.describe "Collection routes", type: :routing do
  describe "GET /widgets/search" do
    it "routes to widgets#search" do
      expect(get: "/widgets/search").to route_to("widgets#search")
    end
  end

  describe "POST /widgets/import" do
    it "routes to widgets#import" do
      expect(post: "/widgets/import").to route_to("widgets#import")
    end
  end
end

# be_routable matcher
RSpec.describe "Route existence", type: :routing do
  describe "existing routes" do
    it "is routable to GET /widgets" do
      expect(get: "/widgets").to be_routable
    end

    it "is routable to POST /widgets" do
      expect(post: "/widgets").to be_routable
    end
  end

  describe "non-existing routes" do
    it "is not routable to PUT /widgets" do
      expect(put: "/widgets").not_to be_routable
    end

    it "is not routable to DELETE /admin" do
      expect(delete: "/admin").not_to be_routable
    end
  end
end

# Testing routes with constraints
RSpec.describe "Constrained routes", type: :routing do
  describe "routes with format constraint" do
    it "routes /widgets.json to widgets#index" do
      expect(get: "/widgets.json").to route_to(
        controller: "widgets",
        action: "index",
        format: "json"
      )
    end
  end

  describe "routes with ID constraint" do
    it "routes numeric ID" do
      expect(get: "/widgets/123").to be_routable
    end

    # Depending on route constraints, this might not be routable
    # it "does not route non-numeric ID" do
    #   expect(get: "/widgets/abc").not_to be_routable
    # end
  end
end

# Testing subdomain routes
RSpec.describe "Subdomain routes", type: :routing do
  describe "api subdomain" do
    before { host! "api.example.com" }

    it "routes to API controller" do
      expect(get: "/widgets").to route_to("api/widgets#index")
    end
  end

  describe "admin subdomain" do
    before { host! "admin.example.com" }

    it "routes to admin controller" do
      expect(get: "/dashboard").to route_to("admin/dashboard#show")
    end
  end
end

# Testing route helpers
RSpec.describe "Route helpers", type: :routing do
  it "generates widget_path" do
    expect(widget_path(1)).to eq("/widgets/1")
  end

  it "generates widgets_path" do
    expect(widgets_path).to eq("/widgets")
  end

  it "generates new_widget_path" do
    expect(new_widget_path).to eq("/widgets/new")
  end

  it "generates edit_widget_path" do
    expect(edit_widget_path(1)).to eq("/widgets/1/edit")
  end
end

# Testing shallow nested routes
RSpec.describe "Shallow routes", type: :routing do
  describe "nested under parent" do
    it "routes comments#create under posts" do
      expect(post: "/posts/1/comments").to route_to(
        controller: "comments",
        action: "create",
        post_id: "1"
      )
    end
  end

  describe "shallow (non-nested)" do
    it "routes comments#show without parent" do
      expect(get: "/comments/5").to route_to(
        controller: "comments",
        action: "show",
        id: "5"
      )
    end
  end
end

# Testing root route
RSpec.describe "Root route", type: :routing do
  it "routes / to pages#home" do
    expect(get: "/").to route_to("pages#home")
  end
end

# Testing optional format
RSpec.describe "Format routing", type: :routing do
  describe "with format" do
    it "routes with JSON format" do
      expect(get: "/widgets/1.json").to route_to(
        controller: "widgets",
        action: "show",
        id: "1",
        format: "json"
      )
    end

    it "routes with XML format" do
      expect(get: "/widgets/1.xml").to route_to(
        controller: "widgets",
        action: "show",
        id: "1",
        format: "xml"
      )
    end
  end
end
