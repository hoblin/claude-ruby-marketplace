# ActiveRecord Migration Examples: Schema Changes
# Run migrations: rails db:migrate
# Rollback: rails db:rollback

# =============================================================================
# CREATING TABLES
# =============================================================================

# Basic table creation
class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :sku, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :quantity, default: 0
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :products, :sku, unique: true
  end
end

# Table with foreign key reference
class CreateOrderItems < ActiveRecord::Migration[7.2]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.timestamps
    end
  end
end

# Join table (no primary key)
class CreateProductsCategories < ActiveRecord::Migration[7.2]
  def change
    create_join_table :products, :categories do |t|
      t.index [:product_id, :category_id], unique: true
      t.index :category_id
    end
  end
end

# Table with UUID primary key
class CreateApiKeys < ActiveRecord::Migration[7.2]
  def change
    create_table :api_keys, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :key_digest, null: false
      t.datetime :expires_at
      t.datetime :last_used_at
      t.timestamps
    end

    add_index :api_keys, :key_digest, unique: true
  end
end

# Table with composite primary key
class CreateTenantUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :tenant_users, primary_key: [:tenant_id, :user_id] do |t|
      t.bigint :tenant_id, null: false
      t.bigint :user_id, null: false
      t.string :role, null: false, default: "member"
      t.timestamps
    end
  end
end

# Polymorphic association table
class CreateComments < ActiveRecord::Migration[7.2]
  def change
    create_table :comments do |t|
      t.references :commentable, polymorphic: true, null: false
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.timestamps
    end

    add_index :comments, [:commentable_type, :commentable_id]
  end
end

# =============================================================================
# ADDING COLUMNS
# =============================================================================

class AddFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    # Simple columns
    add_column :users, :phone, :string
    add_column :users, :verified_at, :datetime

    # Column with default
    add_column :users, :locale, :string, default: "en", null: false

    # JSON/JSONB column (PostgreSQL)
    add_column :users, :preferences, :jsonb, default: {}
    add_column :users, :metadata, :jsonb, default: {}

    # Add index on JSON field (PostgreSQL GIN index)
    add_index :users, :preferences, using: :gin
  end
end

# Adding reference column
class AddOrganizationToUsers < ActiveRecord::Migration[7.2]
  def change
    # Creates user_id column with index and foreign key
    add_reference :users, :organization, foreign_key: true

    # Without index
    add_reference :users, :invited_by, foreign_key: { to_table: :users }, index: false

    # Polymorphic reference (no foreign key possible)
    add_reference :attachments, :attachable, polymorphic: true, index: true
  end
end

# =============================================================================
# MODIFYING COLUMNS
# =============================================================================

# Renaming columns (reversible)
class RenameUserFields < ActiveRecord::Migration[7.2]
  def change
    rename_column :users, :name, :full_name
    rename_column :users, :type, :account_type  # Avoid STI conflict
  end
end

# Changing defaults (reversible with from/to)
class ChangeUserDefaults < ActiveRecord::Migration[7.2]
  def change
    change_column_default :users, :status, from: nil, to: "pending"
    change_column_default :users, :role, from: "user", to: "member"
  end
end

# Changing null constraint
class AddNotNullToEmail < ActiveRecord::Migration[7.2]
  def change
    # Backfill NULLs first with default value
    change_column_null :users, :email, false, "unknown@example.com"
  end
end

# Changing column type (IRREVERSIBLE - requires up/down)
class ChangeDescriptionToText < ActiveRecord::Migration[7.2]
  def up
    change_column :products, :description, :text
  end

  def down
    change_column :products, :description, :string
  end
end

# Changing precision/scale
class IncreasePricePrecision < ActiveRecord::Migration[7.2]
  def up
    change_column :products, :price, :decimal, precision: 12, scale: 2
  end

  def down
    change_column :products, :price, :decimal, precision: 10, scale: 2
  end
end

# =============================================================================
# REMOVING COLUMNS
# =============================================================================

# Removing single column (must include type for reversibility)
class RemoveLegacyField < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :legacy_token, :string
  end
end

# Removing multiple columns
class RemoveDeprecatedFields < ActiveRecord::Migration[7.2]
  def change
    remove_columns :users, :old_field1, :old_field2, type: :string
  end
end

# Removing reference
class RemoveOrganizationFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_reference :users, :organization, foreign_key: true
  end
end

# =============================================================================
# RENAMING TABLES
# =============================================================================

class RenameUsersToAccounts < ActiveRecord::Migration[7.2]
  def change
    rename_table :users, :accounts
  end
end

# =============================================================================
# DROPPING TABLES
# =============================================================================

# Must include full schema for reversibility
class DropLegacyReports < ActiveRecord::Migration[7.2]
  def change
    drop_table :legacy_reports do |t|
      t.string :name
      t.text :data
      t.references :user
      t.timestamps
    end
  end
end

# Irreversible drop (when you don't need rollback)
class DropTemporaryTable < ActiveRecord::Migration[7.2]
  def up
    drop_table :temp_imports
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

# =============================================================================
# PRACTICAL PATTERNS
# =============================================================================

# Adding column with index in one migration
class AddStatusToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :status, :string, default: "pending", null: false
    add_index :orders, :status
  end
end

# Adding timestamps to existing table
class AddTimestampsToProducts < ActiveRecord::Migration[7.2]
  def change
    # Adds created_at and updated_at with null: false, precision: 6
    add_timestamps :products, default: -> { "CURRENT_TIMESTAMP" }
  end
end

# Converting column with data preservation
class ConvertPriceToInteger < ActiveRecord::Migration[7.2]
  def up
    # Add new column
    add_column :products, :price_cents, :integer

    # Migrate data (for small tables)
    execute "UPDATE products SET price_cents = (price * 100)::integer"

    # Remove old column
    remove_column :products, :price
  end

  def down
    add_column :products, :price, :decimal, precision: 10, scale: 2
    execute "UPDATE products SET price = price_cents / 100.0"
    remove_column :products, :price_cents
  end
end
