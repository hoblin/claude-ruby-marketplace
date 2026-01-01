# FactoryBot: Associations Examples
# Source: factory_bot gem spec/acceptance/associations_spec.rb

# Associations create related records automatically.
# Strategy propagates: build creates built associations,
# create creates persisted associations.

# Implicit belongs_to
FactoryBot.define do
  factory :user do
    name { "John" }
  end

  factory :post do
    title { "My Post" }
    user  # Implicit - looks for :user factory
  end
end

RSpec.describe "Implicit associations" do
  describe "belongs_to" do
    let(:post) { build(:post) }

    it "creates associated record" do
      expect(post.user).to be_present
      expect(post.user.name).to eq("John")
    end
  end
end

# Explicit association syntax
FactoryBot.define do
  factory :comment do
    body { "Comment text" }
    association :author, factory: :user
  end

  factory :review do
    content { "Review content" }
    association :reviewer, factory: :user, name: "Reviewer"
  end
end

RSpec.describe "Explicit associations" do
  describe "with factory option" do
    let(:comment) { build(:comment) }

    it "uses specified factory" do
      expect(comment.author).to be_a(User)
    end
  end

  describe "with attribute overrides" do
    let(:review) { build(:review) }

    it "applies overrides to association" do
      expect(review.reviewer.name).to eq("Reviewer")
    end
  end
end

# Association with traits
FactoryBot.define do
  factory :admin_post, class: "Post" do
    title { "Admin Post" }
    association :author, factory: [:user, :admin]
  end

  factory :featured_article, class: "Article" do
    title { "Featured" }
    association :author, :verified, factory: :user
  end
end

RSpec.describe "Association with traits" do
  describe "array syntax for factory with traits" do
    let(:post) { build(:admin_post) }

    it "applies traits to associated record" do
      expect(post.author).to be_admin
    end
  end

  describe "inline trait syntax" do
    let(:article) { build(:featured_article) }

    it "applies trait to association" do
      expect(article.author).to be_verified
    end
  end
end

# Strategy inheritance
RSpec.describe "Strategy inheritance" do
  FactoryBot.define do
    factory :post do
      title { "Post" }
      user
    end
  end

  describe "build inherits to associations" do
    let(:post) { build(:post) }

    it "builds association (not persisted)" do
      expect(post).to be_new_record
      expect(post.user).to be_new_record
    end
  end

  describe "create inherits to associations" do
    let(:post) { create(:post) }

    it "creates association (persisted)" do
      expect(post).to be_persisted
      expect(post.user).to be_persisted
    end
  end

  describe "build_stubbed inherits to associations" do
    let(:post) { build_stubbed(:post) }

    it "stubs association" do
      expect(post).to be_persisted
      expect(post.user).to be_persisted
    end
  end
end

# Override strategy for association
FactoryBot.define do
  factory :post do
    title { "Post" }
    association :user, strategy: :create  # Always create user
  end
end

RSpec.describe "Strategy override" do
  describe "explicit strategy on association" do
    let(:post) { build(:post) }

    it "uses specified strategy regardless of parent" do
      expect(post).to be_new_record
      expect(post.user).to be_persisted  # Created due to strategy: :create
    end
  end
end

# has_many associations
FactoryBot.define do
  factory :blog do
    name { "My Blog" }
    posts { [association(:post)] }
  end

  factory :author do
    name { "Author" }
    articles { Array.new(3) { association(:article) } }
  end
end

RSpec.describe "has_many associations" do
  describe "inline collection" do
    let(:blog) { build(:blog) }

    it "creates collection with one item" do
      expect(blog.posts.length).to eq(1)
    end
  end

  describe "multiple items" do
    let(:author) { build(:author) }

    it "creates specified number of items" do
      expect(author.articles.length).to eq(3)
    end
  end
end

# has_many with transient attributes
FactoryBot.define do
  factory :user do
    name { "User" }

    transient do
      posts_count { 0 }
    end

    after(:create) do |user, evaluator|
      create_list(:post, evaluator.posts_count, author: user)
      user.reload
    end
  end
end

RSpec.describe "has_many with transient" do
  describe "configurable collection size" do
    let(:user) { create(:user, posts_count: 5) }

    it "creates specified number of associations" do
      expect(user.posts.count).to eq(5)
    end
  end
end

# Polymorphic associations
FactoryBot.define do
  factory :comment do
    body { "Comment" }

    for_post  # Default trait

    trait :for_post do
      association :commentable, factory: :post
    end

    trait :for_article do
      association :commentable, factory: :article
    end

    trait :for_video do
      association :commentable, factory: :video
    end
  end
end

RSpec.describe "Polymorphic associations" do
  describe "default polymorphic type" do
    let(:comment) { create(:comment) }

    it "uses default trait" do
      expect(comment.commentable).to be_a(Post)
    end
  end

  describe "alternate polymorphic types" do
    let(:article_comment) { create(:comment, :for_article) }
    let(:video_comment) { create(:comment, :for_video) }

    it "uses trait-specified type" do
      expect(article_comment.commentable).to be_a(Article)
      expect(video_comment.commentable).to be_a(Video)
    end
  end
end

# Interconnected associations
FactoryBot.define do
  factory :account do
    name { "Account" }
    supplier { association(:supplier, account: instance) }
  end

  factory :supplier do
    name { "Supplier" }
    account { association(:account, supplier: instance) }
  end
end

RSpec.describe "Interconnected associations" do
  describe "bidirectional references" do
    let(:account) { build(:account) }

    it "creates circular reference" do
      expect(account.supplier.account).to eq(account)
    end
  end
end

# Complex interconnected models
FactoryBot.define do
  factory :student do
    name { "Student" }
    school
    profile { association(:profile, student: instance, school:) }
  end

  factory :profile do
    bio { "Bio" }
    school
    student { association(:student, profile: instance, school:) }
  end
end

RSpec.describe "Complex interconnected models" do
  describe "shared associations" do
    let(:student) { build(:student) }

    it "shares the same school across related records" do
      expect(student.profile.school).to eq(student.school)
    end
  end
end

# Overriding associations at call time
RSpec.describe "Overriding associations" do
  describe "passing existing record" do
    let(:author) { create(:user, name: "Specific Author") }
    let(:post) { create(:post, user: author) }

    it "uses provided association" do
      expect(post.user).to eq(author)
      expect(post.user.name).to eq("Specific Author")
    end
  end

  describe "nil association" do
    let(:post) { build(:post, user: nil) }

    it "allows nil" do
      expect(post.user).to be_nil
    end
  end
end
