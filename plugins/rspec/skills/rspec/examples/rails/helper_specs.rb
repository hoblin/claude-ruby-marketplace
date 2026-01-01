# RSpec Rails: Helper Specs Examples
# Source: rspec-rails gem features/helper_specs/

# Helper specs test view helper methods in isolation.
# Access the helper module via `helper`.
# Location: spec/helpers/

# Basic helper spec
RSpec.describe ApplicationHelper, type: :helper do
  describe "#page_title" do
    context "when @title is not set" do
      it "returns the default title" do
        expect(helper.page_title).to eq("RSpec is your friend")
      end
    end

    context "when @title is set" do
      before { assign(:title, "Custom Title") }

      it "returns the custom title" do
        expect(helper.page_title).to eq("Custom Title")
      end
    end
  end
end

# Testing formatting helpers
RSpec.describe FormattingHelper, type: :helper do
  describe "#format_date" do
    it "formats date in user-friendly format" do
      date = Date.new(2024, 1, 15)
      expect(helper.format_date(date)).to eq("January 15, 2024")
    end

    it "returns empty string for nil" do
      expect(helper.format_date(nil)).to eq("")
    end
  end

  describe "#format_currency" do
    it "formats amount as currency" do
      expect(helper.format_currency(1234.56)).to eq("$1,234.56")
    end

    it "handles zero" do
      expect(helper.format_currency(0)).to eq("$0.00")
    end

    it "handles negative amounts" do
      expect(helper.format_currency(-50)).to eq("-$50.00")
    end
  end
end

# Using URL helpers in helper specs
RSpec.describe WidgetsHelper, type: :helper do
  describe "#link_to_widget" do
    let(:widget) { create(:widget, name: "Super Widget") }

    it "creates link to widget" do
      result = helper.link_to_widget(widget)

      expect(result).to include("Super Widget")
      expect(result).to include(widget_path(widget))
    end
  end

  describe "#widget_status_badge" do
    let(:widget) { build(:widget) }

    context "when widget is active" do
      let(:widget) { build(:widget, :active) }

      it "returns success badge" do
        result = helper.widget_status_badge(widget)
        expect(result).to include("badge-success")
        expect(result).to include("Active")
      end
    end

    context "when widget is inactive" do
      let(:widget) { build(:widget, :inactive) }

      it "returns warning badge" do
        result = helper.widget_status_badge(widget)
        expect(result).to include("badge-warning")
        expect(result).to include("Inactive")
      end
    end
  end
end

# Testing helpers that use Rails helpers
RSpec.describe TextHelper, type: :helper do
  describe "#truncated_summary" do
    it "truncates long text" do
      text = "This is a very long text that should be truncated"
      result = helper.truncated_summary(text, length: 20)

      expect(result.length).to be <= 23 # 20 + "..."
      expect(result).to end_with("...")
    end

    it "leaves short text unchanged" do
      text = "Short text"
      result = helper.truncated_summary(text, length: 50)

      expect(result).to eq("Short text")
    end
  end

  describe "#pluralized_count" do
    it "pluralizes with count" do
      expect(helper.pluralized_count(1, "item")).to eq("1 item")
      expect(helper.pluralized_count(5, "item")).to eq("5 items")
      expect(helper.pluralized_count(0, "item")).to eq("0 items")
    end
  end
end

# Testing helpers with HTML output
RSpec.describe IconHelper, type: :helper do
  describe "#icon" do
    it "generates icon element" do
      result = helper.icon("check")
      expect(result).to be_html_safe
      expect(result).to include('<i class="icon icon-check">')
    end

    it "accepts additional classes" do
      result = helper.icon("warning", class: "text-danger")
      expect(result).to include("icon-warning")
      expect(result).to include("text-danger")
    end
  end
end

# Testing helpers that use controller context
RSpec.describe NavigationHelper, type: :helper do
  describe "#active_nav_class" do
    before { allow(helper).to receive(:controller_name).and_return("widgets") }

    context "when on matching controller" do
      it "returns active class" do
        expect(helper.active_nav_class("widgets")).to eq("active")
      end
    end

    context "when on different controller" do
      it "returns empty string" do
        expect(helper.active_nav_class("users")).to eq("")
      end
    end
  end
end

# Testing helpers that depend on current_user
RSpec.describe AuthorizationHelper, type: :helper do
  let(:admin_user) { build(:user, :admin) }
  let(:regular_user) { build(:user) }

  describe "#can_edit?" do
    let(:widget) { build(:widget, user: regular_user) }

    context "when user is admin" do
      before { allow(helper).to receive(:current_user).and_return(admin_user) }

      it "returns true" do
        expect(helper.can_edit?(widget)).to be(true)
      end
    end

    context "when user is the owner" do
      before { allow(helper).to receive(:current_user).and_return(regular_user) }

      it "returns true" do
        expect(helper.can_edit?(widget)).to be(true)
      end
    end

    context "when user is neither admin nor owner" do
      let(:other_user) { build(:user) }

      before { allow(helper).to receive(:current_user).and_return(other_user) }

      it "returns false" do
        expect(helper.can_edit?(widget)).to be(false)
      end
    end
  end
end

# Testing helpers that build complex structures
RSpec.describe BreadcrumbHelper, type: :helper do
  describe "#breadcrumbs" do
    it "builds breadcrumb trail" do
      result = helper.breadcrumbs do |b|
        b.add "Home", root_path
        b.add "Widgets", widgets_path
        b.add "Edit"
      end

      expect(result).to include(root_path)
      expect(result).to include(widgets_path)
      expect(result).to include("Edit")
    end
  end
end

# Testing helpers with flash messages
RSpec.describe FlashHelper, type: :helper do
  describe "#flash_class" do
    it "maps notice to success" do
      expect(helper.flash_class(:notice)).to eq("alert-success")
    end

    it "maps alert to danger" do
      expect(helper.flash_class(:alert)).to eq("alert-danger")
    end

    it "maps unknown to info" do
      expect(helper.flash_class(:custom)).to eq("alert-info")
    end
  end
end

# Testing time-dependent helpers
RSpec.describe TimeHelper, type: :helper do
  describe "#time_ago_in_words_short" do
    it "returns minutes ago" do
      time = 5.minutes.ago
      expect(helper.time_ago_in_words_short(time)).to eq("5m ago")
    end

    it "returns hours ago" do
      time = 3.hours.ago
      expect(helper.time_ago_in_words_short(time)).to eq("3h ago")
    end

    it "returns days ago" do
      time = 2.days.ago
      expect(helper.time_ago_in_words_short(time)).to eq("2d ago")
    end
  end
end
