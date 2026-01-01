# spec/decorators/post_decorator_spec.rb
#
# Complete decorator spec template demonstrating best practices.
#
require "rails_helper"

RSpec.describe PostDecorator do
  subject(:decorator) { described_class.new(post, context:) }

  let(:post) { build_stubbed(:post, attributes) }
  let(:attributes) { {} }
  let(:context) { {} }

  describe "#formatted_title" do
    subject(:formatted_title) { decorator.formatted_title }

    let(:attributes) { { title: "my post title" } }

    it "titleizes the title" do
      expect(formatted_title).to eq("My Post Title")
    end

    context "with max_length" do
      subject(:formatted_title) { decorator.formatted_title(max_length: 10) }

      let(:attributes) { { title: "a very long post title" } }

      it "truncates to specified length" do
        expect(formatted_title.length).to be <= 13 # includes "..."
      end
    end
  end

  describe "#status_badge" do
    subject(:badge) { decorator.status_badge }

    context "when published" do
      let(:post) { build_stubbed(:post, :published) }

      it "renders success badge" do
        markup = Capybara.string(badge)

        expect(markup).to have_css("span.badge.badge-success", text: "Published")
      end
    end

    context "when draft" do
      let(:post) { build_stubbed(:post, :draft) }

      it "renders warning badge" do
        markup = Capybara.string(badge)

        expect(markup).to have_css("span.badge.badge-warning", text: "Draft")
      end
    end
  end

  describe "#publication_date" do
    subject(:publication_date) { decorator.publication_date }

    context "when published" do
      let(:attributes) { { published_at: Time.zone.parse("2024-03-15") } }

      it "formats the date" do
        expect(publication_date).to eq("March 15, 2024")
      end
    end

    context "when not published" do
      let(:attributes) { { published_at: nil } }

      it "returns not published message" do
        expect(publication_date).to eq("Not published")
      end
    end
  end

  describe "#reading_time" do
    subject(:reading_time) { decorator.reading_time }

    let(:attributes) { { body: "word " * 400 } }

    it "calculates reading time" do
      expect(reading_time).to eq("2 min read")
    end
  end

  describe "#excerpt" do
    subject(:excerpt) { decorator.excerpt }

    let(:attributes) { { body: "a " * 150 } }

    it "truncates body" do
      expect(excerpt.length).to be <= 203 # 200 + "..."
    end

    it "truncates at word boundary" do
      expect(excerpt).not_to end_with("a...")
    end
  end

  describe "#edit_link" do
    subject(:link) { decorator.edit_link }

    context "without current_user" do
      let(:context) { {} }

      it "returns nil" do
        expect(link).to be_nil
      end
    end

    context "with user who cannot edit" do
      let(:context) { { current_user: build_stubbed(:user) } }

      before do
        allow(context[:current_user]).to receive(:can?).with(:edit, post).and_return(false)
      end

      it "returns nil" do
        expect(link).to be_nil
      end
    end

    context "with user who can edit" do
      let(:post) { create(:post) }
      let(:context) { { current_user: build_stubbed(:user) } }

      before do
        allow(context[:current_user]).to receive(:can?).with(:edit, post).and_return(true)
      end

      it "renders edit link" do
        markup = Capybara.string(link)

        expect(markup).to have_link("Edit", href: "/posts/#{post.id}/edit")
      end

      it "has button classes" do
        markup = Capybara.string(link)

        expect(markup).to have_css("a.btn.btn-sm.btn-secondary")
      end
    end
  end

  describe "#delete_link" do
    subject(:link) { decorator.delete_link }

    context "with user who can delete" do
      let(:post) { create(:post) }
      let(:context) { { current_user: build_stubbed(:user) } }

      before do
        allow(context[:current_user]).to receive(:can?).with(:delete, post).and_return(true)
      end

      it "renders delete link with confirmation" do
        markup = Capybara.string(link)

        expect(markup).to have_css("a[data-confirm='Are you sure?']", text: "Delete")
      end
    end
  end

  describe "#action_buttons" do
    subject(:buttons) { decorator.action_buttons }

    context "with no permissions" do
      let(:context) { {} }

      it "returns nil" do
        expect(buttons).to be_nil
      end
    end

    context "with edit permission" do
      let(:post) { create(:post) }
      let(:context) { { current_user: build_stubbed(:user) } }

      before do
        allow(context[:current_user]).to receive(:can?).with(:edit, post).and_return(true)
        allow(context[:current_user]).to receive(:can?).with(:delete, post).and_return(false)
      end

      it "renders button group" do
        markup = Capybara.string(buttons)

        expect(markup).to have_css("div.btn-group")
        expect(markup).to have_link("Edit")
        expect(markup).not_to have_link("Delete")
      end
    end
  end

  describe "associations" do
    describe "#author" do
      subject(:author) { decorator.author }

      let(:post) { create(:post) }

      it "returns decorated author" do
        expect(author).to be_decorated_with(AuthorDecorator)
      end
    end

    describe "#comments" do
      subject(:comments) { decorator.comments }

      let(:post) { create(:post) }

      before { create_list(:comment, 3, post:) }

      it "returns decorated comments" do
        expect(comments).to all(be_decorated_with(CommentDecorator))
      end

      it "includes all comments" do
        expect(comments.size).to eq(3)
      end
    end
  end

  describe "#author_info" do
    subject(:info) { decorator.author_info }

    let(:post) { create(:post) }

    it "renders author info block" do
      markup = Capybara.string(info)

      expect(markup).to have_css("div.author-info")
      expect(markup).to have_css("span.author-name")
      expect(markup).to have_css("span.post-date")
    end
  end

  describe "#meta_info" do
    subject(:meta) { decorator.meta_info }

    let(:post) { create(:post, :with_category) }

    before { create_list(:comment, 2, post:) }

    it "renders meta information" do
      markup = Capybara.string(meta)

      expect(markup).to have_css("div.post-meta")
      expect(markup).to have_link(post.category.name)
      expect(markup.text).to include("2 comments")
    end
  end
end
