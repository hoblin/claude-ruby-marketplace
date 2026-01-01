# RSpec Rails: System Specs Examples
# Source: rspec-rails gem features/system_specs/

# System specs are browser-based tests using Capybara.
# They run within database transactions by default.
# Location: spec/system/

# Basic system spec with rack_test driver
RSpec.describe "Widget management", type: :system do
  before { driven_by(:rack_test) }

  describe "creating a widget" do
    it "creates a new widget" do
      visit "/widgets/new"

      fill_in "Name", with: "My Widget"
      fill_in "Description", with: "A useful widget"
      click_button "Create Widget"

      expect(page).to have_text("Widget was successfully created")
      expect(page).to have_text("My Widget")
    end
  end
end

# Using headless Chrome for JavaScript testing
RSpec.describe "JavaScript features", type: :system do
  before { driven_by(:selenium_chrome_headless) }

  describe "dynamic form" do
    it "shows validation errors without page reload" do
      visit "/widgets/new"
      click_button "Create Widget"

      expect(page).to have_text("Name can't be blank")
    end
  end

  describe "modal dialog" do
    let!(:widget) { create(:widget) }

    it "confirms deletion in modal" do
      visit "/widgets/#{widget.id}"

      click_button "Delete"
      within(".modal") do
        click_button "Confirm"
      end

      expect(page).to have_text("Widget was deleted")
    end
  end
end

# Testing user flows
RSpec.describe "User registration flow", type: :system do
  before { driven_by(:rack_test) }

  it "allows new user to sign up" do
    visit "/"

    click_link "Sign Up"
    fill_in "Email", with: "new@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    click_button "Create Account"

    expect(page).to have_text("Welcome! You have signed up successfully")
    expect(page).to have_link("Sign Out")
  end
end

# Testing authentication
RSpec.describe "User sessions", type: :system do
  before { driven_by(:rack_test) }

  let(:user) { create(:user, email: "test@example.com", password: "password") }

  describe "logging in" do
    it "logs in with valid credentials" do
      visit "/login"

      fill_in "Email", with: "test@example.com"
      fill_in "Password", with: "password"
      click_button "Log In"

      expect(page).to have_text("Logged in successfully")
      expect(page).to have_link("Sign Out")
    end

    it "shows error with invalid credentials" do
      visit "/login"

      fill_in "Email", with: "test@example.com"
      fill_in "Password", with: "wrong"
      click_button "Log In"

      expect(page).to have_text("Invalid email or password")
    end
  end

  describe "logging out" do
    before do
      visit "/login"
      fill_in "Email", with: "test@example.com"
      fill_in "Password", with: "password"
      click_button "Log In"
    end

    it "logs out the user" do
      click_link "Sign Out"
      expect(page).to have_text("You have been logged out")
    end
  end
end

# Testing CRUD operations
RSpec.describe "Widget CRUD", type: :system do
  before { driven_by(:rack_test) }

  let(:user) { create(:user) }

  before do
    # Login helper
    visit "/login"
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_button "Log In"
  end

  describe "listing widgets" do
    let!(:widgets) { create_list(:widget, 3, user:) }

    it "displays all user widgets" do
      visit "/widgets"

      widgets.each do |widget|
        expect(page).to have_text(widget.name)
      end
    end
  end

  describe "creating a widget" do
    it "creates with valid data" do
      visit "/widgets/new"

      fill_in "Name", with: "New Widget"
      click_button "Create Widget"

      expect(page).to have_text("Widget was successfully created")
    end
  end

  describe "editing a widget" do
    let!(:widget) { create(:widget, name: "Old Name", user:) }

    it "updates the widget" do
      visit "/widgets/#{widget.id}/edit"

      fill_in "Name", with: "Updated Name"
      click_button "Update Widget"

      expect(page).to have_text("Widget was successfully updated")
      expect(page).to have_text("Updated Name")
    end
  end

  describe "deleting a widget" do
    let!(:widget) { create(:widget, user:) }

    it "removes the widget" do
      visit "/widgets/#{widget.id}"

      click_button "Delete"

      expect(page).to have_text("Widget was deleted")
      expect(page).not_to have_text(widget.name)
    end
  end
end

# Testing navigation
RSpec.describe "Navigation", type: :system do
  before { driven_by(:rack_test) }

  it "navigates between pages" do
    visit "/"

    click_link "Widgets"
    expect(page).to have_current_path("/widgets")

    click_link "About"
    expect(page).to have_current_path("/about")
  end
end

# Testing flash messages
RSpec.describe "Flash messages", type: :system do
  before { driven_by(:rack_test) }

  it "shows success message" do
    visit "/widgets/new"
    fill_in "Name", with: "Test"
    click_button "Create Widget"

    expect(page).to have_css(".flash.notice", text: "successfully created")
  end

  it "shows error message" do
    visit "/widgets/new"
    click_button "Create Widget"

    expect(page).to have_css(".flash.alert")
  end
end

# Testing with JavaScript (Turbo)
RSpec.describe "Turbo interactions", type: :system do
  before { driven_by(:selenium_chrome_headless) }

  let!(:widget) { create(:widget) }

  describe "inline editing" do
    it "updates without full page reload" do
      visit "/widgets/#{widget.id}"

      click_link "Edit"
      fill_in "Name", with: "Updated via Turbo"
      click_button "Save"

      expect(page).to have_text("Updated via Turbo")
      # Page was not fully reloaded
    end
  end
end

# Testing file uploads
RSpec.describe "File uploads", type: :system do
  before { driven_by(:rack_test) }

  it "uploads an image" do
    visit "/widgets/new"

    fill_in "Name", with: "Widget with Image"
    attach_file "Image", Rails.root.join("spec/fixtures/files/image.png")
    click_button "Create Widget"

    expect(page).to have_css("img.widget-image")
  end
end

# Testing pagination
RSpec.describe "Pagination", type: :system do
  before { driven_by(:rack_test) }

  let!(:widgets) { create_list(:widget, 30) }

  it "paginates results" do
    visit "/widgets"

    expect(page).to have_css(".widget", count: 10)
    expect(page).to have_link("Next")

    click_link "Next"

    expect(page).to have_css(".widget", count: 10)
    expect(page).to have_link("Previous")
  end
end

# Testing search
RSpec.describe "Search", type: :system do
  before { driven_by(:rack_test) }

  let!(:matching_widget) { create(:widget, name: "Super Widget") }
  let!(:other_widget) { create(:widget, name: "Regular Item") }

  it "filters results by search term" do
    visit "/widgets"

    fill_in "Search", with: "Super"
    click_button "Search"

    expect(page).to have_text("Super Widget")
    expect(page).not_to have_text("Regular Item")
  end
end

# Configuration in rails_helper.rb
# RSpec.configure do |config|
#   config.before(type: :system) do
#     driven_by :selenium_chrome_headless
#   end
# end
