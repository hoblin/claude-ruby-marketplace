# Basic Association Examples
# Demonstrates belongs_to, has_one, has_many relationships

# ============================================
# belongs_to - Child side (has foreign key)
# ============================================

class Book < ApplicationRecord
  # Required by default (Rails 5+)
  belongs_to :author

  # Optional - allows NULL foreign key
  belongs_to :publisher, optional: true

  # Custom naming
  belongs_to :category,
             class_name: "Genre",
             foreign_key: "genre_id",
             inverse_of: :books  # Required with custom FK

  # With counter cache on parent
  belongs_to :series, counter_cache: true

  # Touch parent on save
  belongs_to :library, touch: true
end

# Migration for books
# create_table :books do |t|
#   t.belongs_to :author, null: false, foreign_key: true
#   t.belongs_to :publisher, foreign_key: true
#   t.belongs_to :genre, foreign_key: { to_table: :genres }
#   t.belongs_to :series, foreign_key: true
#   t.belongs_to :library, foreign_key: true
#   t.string :title
#   t.timestamps
# end

# ============================================
# has_one - Parent side one-to-one
# ============================================

class Supplier < ApplicationRecord
  has_one :account, dependent: :destroy

  # Optional association
  has_one :profile

  # Custom naming
  has_one :representative,
          class_name: "Person",
          foreign_key: "company_id",
          inverse_of: :employer
end

# Migration - enforce true 1:1 at database level
# create_table :accounts do |t|
#   t.belongs_to :supplier, null: false, index: { unique: true }, foreign_key: true
#   t.decimal :balance
#   t.timestamps
# end

# ============================================
# has_many - One-to-many
# ============================================

class Author < ApplicationRecord
  has_many :books, dependent: :destroy

  # Scoped association
  has_many :published_books,
           -> { where(published: true) },
           class_name: "Book"

  has_many :recent_books,
           -> { order(created_at: :desc).limit(5) },
           class_name: "Book"

  # Through association
  has_many :publishers, -> { distinct }, through: :books
end

# ============================================
# Usage Examples
# ============================================

# Creating with associations
author = Author.create!(name: "Jane Austen")
book = author.books.create!(title: "Pride and Prejudice")

# Building without saving
draft = author.books.build(title: "Work in Progress")
draft.save

# Adding existing record
existing_book = Book.find(123)
author.books << existing_book  # Saves immediately!

# Association queries
author.books.count           # COUNT query
author.books.size            # Uses counter_cache if present
author.books.empty?          # Boolean check
author.book_ids              # Array of IDs

# Scoped queries on association
author.books.where(published: true)
author.books.order(created_at: :desc)
author.published_books.first

# has_one building
supplier = Supplier.create!(name: "ACME Corp")
supplier.create_account!(balance: 1000)
# or
supplier.build_account(balance: 500)
supplier.save

# has_one replacement
supplier.account = Account.new(balance: 2000)  # Old account nullified/destroyed
