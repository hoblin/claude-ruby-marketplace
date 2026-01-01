# RSpec Rails: View Specs Examples
# Source: rspec-rails gem features/view_specs/

# View specs test templates in isolation.
# Three-step pattern: assign, render, assert.
# Location: spec/views/

# Basic view spec
RSpec.describe "widgets/index", type: :view do
  let(:widgets) { create_list(:widget, 2, :with_names) }

  before { assign(:widgets, widgets) }

  it "displays all widgets" do
    render

    widgets.each do |widget|
      expect(rendered).to include(widget.name)
    end
  end
end

# Testing specific elements
RSpec.describe "widgets/show", type: :view do
  let(:widget) { create(:widget, name: "Slicer", price: 99) }

  before { assign(:widget, widget) }

  it "displays the widget name" do
    render
    expect(rendered).to match(/Slicer/)
  end

  it "displays the widget price" do
    render
    expect(rendered).to include("$99")
  end
end

# Explicit template rendering
RSpec.describe "rendering the widget template", type: :view do
  let(:widget) { create(:widget, name: "Dicer") }

  before { assign(:widget, widget) }

  it "renders with explicit template path" do
    render template: "widgets/widget"
    expect(rendered).to include("Dicer")
  end
end

# Rendering with layouts
RSpec.describe "widgets/widget", type: :view do
  let(:widget) { create(:widget, name: "Blender") }

  before { assign(:widget, widget) }

  context "with application layout" do
    it "includes header from layout" do
      render template: "widgets/widget", layout: "layouts/application"

      expect(rendered).to include("Application Header")
      expect(rendered).to include("Blender")
    end
  end

  context "with admin layout" do
    it "includes admin navigation" do
      render template: "widgets/widget", layout: "layouts/admin"

      expect(rendered).to include("Admin Navigation")
    end
  end
end

# Testing partials
RSpec.describe "widgets/_widget", type: :view do
  let(:widget) { create(:widget, name: "Grinder") }

  it "renders the widget partial with locals" do
    render partial: "widgets/widget", locals: { widget: }

    expect(rendered).to include("Grinder")
  end
end

# Testing collection rendering
RSpec.describe "widgets/_widget", type: :view do
  let(:widgets) { build_list(:widget, 3) }

  it "renders each widget in collection" do
    render partial: "widgets/widget", collection: widgets

    widgets.each do |widget|
      expect(rendered).to include(widget.name)
    end
  end
end

# Stubbing view helpers
RSpec.describe "secrets/index", type: :view do
  context "when user is admin" do
    before { allow(view).to receive(:admin?).and_return(true) }

    it "displays admin section" do
      render
      expect(rendered).to include("Secret admin area")
    end
  end

  context "when user is not admin" do
    before { allow(view).to receive(:admin?).and_return(false) }

    it "hides admin section" do
      render
      expect(rendered).not_to include("Secret admin area")
    end
  end
end

# Stubbing current_user
RSpec.describe "dashboard/index", type: :view do
  let(:user) { build(:user, name: "John") }

  before { allow(view).to receive(:current_user).and_return(user) }

  it "greets the current user" do
    render
    expect(rendered).to include("Welcome, John")
  end
end

# Testing forms
RSpec.describe "widgets/new", type: :view do
  before { assign(:widget, Widget.new) }

  it "renders the new widget form" do
    render

    expect(rendered).to have_selector("form[action='/widgets'][method='post']")
    expect(rendered).to have_selector("input[name='widget[name]']")
    expect(rendered).to have_selector("input[type='submit']")
  end
end

# Testing edit forms with existing record
RSpec.describe "widgets/edit", type: :view do
  let(:widget) { create(:widget, name: "Existing Widget") }

  before { assign(:widget, widget) }

  it "populates form with widget values" do
    render

    expect(rendered).to have_selector("form[action='/widgets/#{widget.id}']")
    expect(rendered).to have_selector("input[name='widget[name]'][value='Existing Widget']")
  end
end

# Testing conditional content
RSpec.describe "widgets/show", type: :view do
  let(:widget) { create(:widget, :published) }

  before { assign(:widget, widget) }

  context "when widget is published" do
    it "shows published badge" do
      render
      expect(rendered).to include("Published")
    end
  end

  context "when widget is draft" do
    let(:widget) { create(:widget, :draft) }

    it "shows draft badge" do
      render
      expect(rendered).to include("Draft")
    end
  end
end

# Testing links
RSpec.describe "widgets/index", type: :view do
  let(:widgets) { create_list(:widget, 2) }

  before { assign(:widgets, widgets) }

  it "links to each widget" do
    render

    widgets.each do |widget|
      expect(rendered).to have_link(widget.name, href: widget_path(widget))
    end
  end

  it "links to new widget" do
    render
    expect(rendered).to have_link("New Widget", href: new_widget_path)
  end
end

# Using Capybara matchers in view specs
RSpec.describe "widgets/show", type: :view do
  let(:widget) { create(:widget, name: "Test Widget", description: "A great widget") }

  before { assign(:widget, widget) }

  it "renders widget details" do
    render

    expect(rendered).to have_css("h1", text: "Test Widget")
    expect(rendered).to have_css("p.description", text: "A great widget")
  end
end

# Testing empty states
RSpec.describe "widgets/index", type: :view do
  context "with no widgets" do
    before { assign(:widgets, []) }

    it "shows empty state message" do
      render
      expect(rendered).to include("No widgets found")
    end
  end
end

# Testing content_for blocks
RSpec.describe "widgets/show", type: :view do
  let(:widget) { create(:widget, name: "Widget") }

  before { assign(:widget, widget) }

  it "sets page title via content_for" do
    render

    expect(view.content_for(:title)).to eq("Widget")
  end
end

# Access view helpers defined in the application
RSpec.describe "widgets/show", type: :view do
  let(:widget) { create(:widget, price: 1000) }

  before { assign(:widget, widget) }

  it "formats currency using helper" do
    render
    expect(rendered).to include("$1,000.00")
  end
end
