# RSpec Rails: Model Specs Examples
# Source: rspec-rails gem features/model_specs/

# Model specs test ActiveRecord models, validations, associations,
# scopes, callbacks, and instance methods.
# Location: spec/models/

# Basic model testing
RSpec.describe Post, type: :model do
  describe "validations" do
    subject(:post) { build(:post) }

    it "is valid with valid attributes" do
      expect(post).to be_valid
    end

    it "is invalid without a title" do
      post.title = nil
      expect(post).not_to be_valid
      expect(post.errors[:title]).to include("can't be blank")
    end

    # Validation context
    it "validates uniqueness on create" do
      expect(post).to be_valid(:create)
    end
  end

  describe "associations" do
    subject(:post) { create(:post) }

    it "has many comments" do
      comments = create_list(:comment, 3, post:)
      expect(post.comments).to match_array(comments)
    end

    it "belongs to an author" do
      expect(post.author).to be_a(User)
    end

    it "destroys dependent comments" do
      create_list(:comment, 2, post:)
      expect { post.destroy }.to change(Comment, :count).by(-2)
    end
  end

  describe "scopes" do
    describe ".published" do
      let!(:published_post) { create(:post, :published) }
      let!(:draft_post) { create(:post, :draft) }

      it "returns only published posts" do
        expect(Post.published).to contain_exactly(published_post)
      end
    end

    describe ".recent" do
      let!(:old_post) { create(:post, created_at: 1.month.ago) }
      let!(:new_post) { create(:post, created_at: 1.day.ago) }

      it "returns posts in reverse chronological order" do
        expect(Post.recent).to eq([new_post, old_post])
      end
    end

    # Testing scope combinations with match_array
    describe ".featured" do
      let!(:featured_posts) { create_list(:post, 3, :featured) }
      let!(:regular_posts) { create_list(:post, 2) }

      subject { Post.featured }

      it "returns featured posts in any order" do
        expect(subject).to match_array(featured_posts)
      end
    end
  end

  describe "callbacks" do
    describe "before_save" do
      subject(:post) { build(:post, title: "  hello world  ") }

      it "strips whitespace from title" do
        post.save
        expect(post.title).to eq("hello world")
      end
    end

    describe "after_create" do
      subject(:post) { build(:post) }

      it "schedules notification job" do
        expect { post.save }
          .to have_enqueued_job(NotifySubscribersJob)
          .with(post)
      end
    end
  end

  describe "instance methods" do
    describe "#published?" do
      context "when published_at is set" do
        subject(:post) { build(:post, published_at: Time.current) }

        it "returns true" do
          expect(post).to be_published
        end
      end

      context "when published_at is nil" do
        subject(:post) { build(:post, published_at: nil) }

        it "returns false" do
          expect(post).not_to be_published
        end
      end
    end

    describe "#reading_time" do
      subject(:post) { build(:post, body: "word " * 500) }

      it "calculates based on word count" do
        expect(post.reading_time).to eq(2) # 500 words / 250 wpm
      end
    end
  end
end

# be_a_new matcher - testing new record state
RSpec.describe Widget, type: :model do
  describe "persistence state" do
    context "when initialized" do
      subject(:widget) { Widget.new }

      it "is a new widget" do
        expect(widget).to be_a_new(Widget)
      end
    end

    context "when saved" do
      subject(:widget) { create(:widget) }

      it "is not a new widget" do
        expect(widget).not_to be_a_new(Widget)
      end
    end
  end
end

# Testing class methods
RSpec.describe Order, type: :model do
  describe ".total_revenue" do
    let!(:orders) { create_list(:order, 3, amount: 100) }

    it "sums all order amounts" do
      expect(Order.total_revenue).to eq(300)
    end
  end

  describe ".find_by_reference" do
    let!(:order) { create(:order, reference: "ORD-123") }

    it "finds order by reference" do
      expect(Order.find_by_reference("ORD-123")).to eq(order)
    end

    it "returns nil for unknown reference" do
      expect(Order.find_by_reference("UNKNOWN")).to be_nil
    end
  end
end

# Testing concerns/modules
RSpec.describe Publishable, type: :model do
  # Use a concrete class that includes the concern
  let(:publishable_class) do
    Class.new(ApplicationRecord) do
      self.table_name = "articles"
      include Publishable
    end
  end

  subject(:record) { publishable_class.new }

  describe "#publish!" do
    it "sets published_at to current time" do
      freeze_time do
        record.publish!
        expect(record.published_at).to eq(Time.current)
      end
    end
  end
end
