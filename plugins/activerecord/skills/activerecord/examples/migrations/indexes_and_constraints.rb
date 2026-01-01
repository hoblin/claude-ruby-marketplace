# ActiveRecord Migration Examples: Indexes and Constraints

# =============================================================================
# BASIC INDEXES
# =============================================================================

class AddBasicIndexes < ActiveRecord::Migration[7.2]
  def change
    # Single column index
    add_index :users, :email

    # Unique index
    add_index :users, :username, unique: true

    # Named index
    add_index :users, :created_at, name: "idx_users_created"
  end
end

# =============================================================================
# COMPOSITE INDEXES
# =============================================================================

# Column order matters! Most selective column first
class AddCompositeIndexes < ActiveRecord::Migration[7.2]
  def change
    # Good for: WHERE last_name = 'X' AND first_name = 'Y'
    # Good for: WHERE last_name = 'X'
    # NOT useful for: WHERE first_name = 'Y' alone
    add_index :users, [:last_name, :first_name]

    # Foreign key + status (common lookup pattern)
    add_index :orders, [:user_id, :status]

    # Polymorphic association (always add this!)
    add_index :comments, [:commentable_type, :commentable_id]

    # Unique composite
    add_index :memberships, [:user_id, :organization_id], unique: true
  end
end

# =============================================================================
# PARTIAL INDEXES (PostgreSQL, SQLite)
# =============================================================================

class AddPartialIndexes < ActiveRecord::Migration[7.2]
  def change
    # Index only active records (smaller, faster)
    add_index :users, :email, where: "active = true", name: "idx_users_email_active"

    # Index only non-null values
    add_index :sessions, :user_id, where: "user_id IS NOT NULL"

    # Index only pending orders
    add_index :orders, :created_at, where: "status = 'pending'"

    # Unique email only for non-deleted users (soft delete pattern)
    add_index :users, :email, unique: true, where: "deleted_at IS NULL"

    # Index only recent records
    add_index :events, :created_at, where: "created_at > '2024-01-01'"
  end
end

# =============================================================================
# EXPRESSION INDEXES (PostgreSQL)
# =============================================================================

class AddExpressionIndexes < ActiveRecord::Migration[7.2]
  def change
    # Case-insensitive email lookup
    add_index :users, "lower(email)", unique: true, name: "idx_users_email_lower"

    # Date extraction
    add_index :events, "date(created_at)", name: "idx_events_created_date"

    # JSON field indexing
    add_index :users, "(preferences->>'theme')", name: "idx_users_theme"
  end
end

# =============================================================================
# COVERING INDEXES (PostgreSQL)
# =============================================================================

class AddCoveringIndexes < ActiveRecord::Migration[7.2]
  def change
    # Include additional columns to avoid table lookups
    # Useful when you always SELECT these columns with the WHERE clause
    add_index :orders, :user_id, include: [:status, :total]

    # SELECT status, total FROM orders WHERE user_id = ?
    # Can be answered entirely from index!
  end
end

# =============================================================================
# CONCURRENT INDEXES (PostgreSQL)
# =============================================================================

class AddConcurrentIndex < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!  # REQUIRED for concurrent operations

  def change
    # Won't lock the table during creation
    add_index :users, :email, algorithm: :concurrently

    # Remove index concurrently
    remove_index :users, :old_column, algorithm: :concurrently
  end
end

# Adding concurrent index with safety check
class AddEmailIndexSafely < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    # Check if index exists before creating
    unless index_exists?(:users, :email, name: "index_users_on_email")
      add_index :users, :email, algorithm: :concurrently
    end
  end
end

# =============================================================================
# SPECIAL INDEX TYPES
# =============================================================================

class AddSpecialIndexes < ActiveRecord::Migration[7.2]
  def change
    # GIN index for JSONB (PostgreSQL)
    add_index :products, :metadata, using: :gin

    # GiST index for geometric/range types (PostgreSQL)
    add_index :locations, :coordinates, using: :gist

    # Full-text search index (PostgreSQL)
    add_index :articles, "to_tsvector('english', title || ' ' || body)",
              using: :gin, name: "idx_articles_fulltext"

    # Trigram index for LIKE queries (PostgreSQL, requires pg_trgm)
    add_index :products, :name, using: :gin, opclass: :gin_trgm_ops

    # FULLTEXT index (MySQL)
    # add_index :articles, [:title, :body], type: :fulltext
  end
end

# =============================================================================
# INDEX WITH ORDERING
# =============================================================================

class AddOrderedIndexes < ActiveRecord::Migration[7.2]
  def change
    # Descending order (useful for ORDER BY col DESC queries)
    add_index :events, :created_at, order: :desc

    # Mixed ordering
    add_index :leaderboards, [:game_id, :score], order: { game_id: :asc, score: :desc }

    # NULLS positioning (PostgreSQL)
    add_index :tasks, :due_date, order: { due_date: "ASC NULLS LAST" }
  end
end

# =============================================================================
# FOREIGN KEY CONSTRAINTS
# =============================================================================

class AddForeignKeys < ActiveRecord::Migration[7.2]
  def change
    # Basic foreign key
    add_foreign_key :orders, :users

    # With custom column name
    add_foreign_key :orders, :users, column: :customer_id

    # With ON DELETE behavior
    add_foreign_key :comments, :posts, on_delete: :cascade

    # With ON UPDATE behavior
    add_foreign_key :order_items, :products, on_update: :cascade

    # Referencing non-id primary key
    add_foreign_key :profiles, :users, primary_key: :uuid, column: :user_uuid

    # Self-referential
    add_foreign_key :employees, :employees, column: :manager_id
  end
end

# Foreign key with custom name
class AddNamedForeignKey < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :orders, :users,
                    column: :placed_by_id,
                    name: "fk_orders_placed_by_user"
  end
end

# =============================================================================
# CHECK CONSTRAINTS
# =============================================================================

class AddCheckConstraints < ActiveRecord::Migration[7.2]
  def change
    # Positive price
    add_check_constraint :products, "price > 0", name: "products_price_positive"

    # Valid quantity
    add_check_constraint :order_items, "quantity >= 1", name: "order_items_quantity_min"

    # Status validation
    add_check_constraint :orders, "status IN ('pending', 'processing', 'shipped', 'delivered')",
                         name: "orders_valid_status"

    # Date range
    add_check_constraint :events, "end_date >= start_date", name: "events_valid_dates"

    # Email format (basic)
    add_check_constraint :users, "email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'",
                         name: "users_valid_email"

    # Percentage range
    add_check_constraint :discounts, "percentage BETWEEN 0 AND 100",
                         name: "discounts_valid_percentage"
  end
end

# PostgreSQL: Add constraint without validation (for large tables)
class AddConstraintSafely < ActiveRecord::Migration[7.2]
  def change
    # Step 1: Add without validation
    add_check_constraint :products, "price > 0",
                         name: "products_price_positive",
                         validate: false
  end
end

class ValidateConstraint < ActiveRecord::Migration[7.2]
  def change
    # Step 2: Validate in separate migration/deployment
    validate_check_constraint :products, name: "products_price_positive"
  end
end

# =============================================================================
# UNIQUE CONSTRAINTS
# =============================================================================

class AddUniqueConstraints < ActiveRecord::Migration[7.2]
  def change
    # Simple unique
    add_index :users, :email, unique: true

    # Composite unique
    add_index :subscriptions, [:user_id, :plan_id], unique: true

    # Unique with condition (soft delete)
    add_index :users, :email, unique: true, where: "deleted_at IS NULL"

    # Case-insensitive unique (PostgreSQL)
    add_index :users, "lower(email)", unique: true, name: "idx_users_email_unique_lower"
  end
end

# =============================================================================
# REMOVING INDEXES AND CONSTRAINTS
# =============================================================================

class RemoveIndexesAndConstraints < ActiveRecord::Migration[7.2]
  def change
    # Remove index by column (must specify column for reversibility)
    remove_index :users, :email

    # Remove index by name
    remove_index :users, name: "idx_users_email_lower"

    # Remove composite index
    remove_index :orders, [:user_id, :status]

    # Remove foreign key
    remove_foreign_key :orders, :users

    # Remove foreign key by column
    remove_foreign_key :orders, column: :customer_id, to_table: :users

    # Remove check constraint
    remove_check_constraint :products, name: "products_price_positive"
  end
end

# =============================================================================
# PRACTICAL PATTERNS
# =============================================================================

# Complete reference setup with all constraints
class CreateOrdersWithConstraints < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.references :user, null: false
      t.references :shipping_address, null: false
      t.string :status, null: false, default: "pending"
      t.decimal :subtotal, precision: 10, scale: 2, null: false
      t.decimal :tax, precision: 10, scale: 2, null: false
      t.decimal :total, precision: 10, scale: 2, null: false
      t.timestamps
    end

    # Foreign keys
    add_foreign_key :orders, :users, on_delete: :restrict
    add_foreign_key :orders, :addresses, column: :shipping_address_id

    # Check constraints
    add_check_constraint :orders, "subtotal >= 0", name: "orders_subtotal_non_negative"
    add_check_constraint :orders, "tax >= 0", name: "orders_tax_non_negative"
    add_check_constraint :orders, "total = subtotal + tax", name: "orders_total_calculation"
    add_check_constraint :orders, "status IN ('pending', 'paid', 'shipped', 'delivered', 'cancelled')",
                         name: "orders_valid_status"

    # Indexes for common queries
    add_index :orders, [:user_id, :status]
    add_index :orders, [:status, :created_at]
  end
end

# Index strategy for polymorphic association
class SetupPolymorphicIndexes < ActiveRecord::Migration[7.2]
  def change
    # Always create composite index for polymorphic associations
    add_index :taggings, [:taggable_type, :taggable_id]

    # If you query by tag_id within a type
    add_index :taggings, [:taggable_type, :tag_id]
  end
end
