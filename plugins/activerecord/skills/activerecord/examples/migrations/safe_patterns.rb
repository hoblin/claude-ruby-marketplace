# ActiveRecord Migration Examples: Safe Production Patterns
# Patterns for zero-downtime deployments and large table migrations

# =============================================================================
# SAFE COLUMN REMOVAL (3-Release Process)
# =============================================================================

# RELEASE 1: Add to ignored_columns in model
# app/models/user.rb
class User < ApplicationRecord
  # Step 1: Tell ActiveRecord to ignore this column
  # This prevents errors when old code still references it
  self.ignored_columns += ["legacy_field"]
end

# RELEASE 2: Drop the column
class RemoveLegacyField < ActiveRecord::Migration[7.2]
  def change
    # Safe to remove now - code doesn't reference it
    remove_column :users, :legacy_field, :string
  end
end

# RELEASE 3: Remove ignored_columns line from model

# =============================================================================
# SAFE NOT NULL ADDITION (PostgreSQL)
# =============================================================================

# Adding NOT NULL to existing column can lock table while validating all rows
# Split into multiple steps for large tables

# Step 1: Add check constraint without validation
class AddNotNullConstraintStep1 < ActiveRecord::Migration[7.2]
  def change
    add_check_constraint :users, "email IS NOT NULL",
                         name: "users_email_not_null",
                         validate: false
  end
end

# Step 2: Validate constraint (separate deployment)
class AddNotNullConstraintStep2 < ActiveRecord::Migration[7.2]
  def change
    validate_check_constraint :users, name: "users_email_not_null"
  end
end

# Step 3: Add actual NOT NULL and remove constraint
class AddNotNullConstraintStep3 < ActiveRecord::Migration[7.2]
  def change
    change_column_null :users, :email, false
    remove_check_constraint :users, name: "users_email_not_null"
  end
end

# =============================================================================
# SAFE COLUMN ADDITION WITH DEFAULT
# =============================================================================

# Modern Rails (5.2+) handles this efficiently, but for very large tables:

# Option 1: Add column, backfill, then set default
class AddStatusSafely < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    # Step 1: Add column without default
    add_column :orders, :priority, :string

    # Step 2: Backfill in batches
    Order.unscoped.in_batches(of: 10_000) do |batch|
      batch.update_all(priority: "normal")
      sleep(0.1)  # Throttle
    end

    # Step 3: Set default for new records
    change_column_default :orders, :priority, "normal"

    # Step 4: Add NOT NULL if needed
    change_column_null :orders, :priority, false
  end

  def down
    remove_column :orders, :priority
  end
end

# =============================================================================
# SAFE COLUMN RENAME (Dual-Write Pattern)
# =============================================================================

# Renaming columns breaks running code that references old name
# Use alias_attribute + phased deployment

# RELEASE 1: Add new column, dual-write
class RenameNameToFullNameStep1 < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :full_name, :string
  end
end

# app/models/user.rb (Release 1)
class User < ApplicationRecord
  # Dual-write to both columns
  before_save :sync_name_columns

  # Read from new column, fall back to old
  def full_name
    super || name
  end

  private

  def sync_name_columns
    self.full_name = name if name_changed?
    self.name = full_name if full_name_changed?
  end
end

# RELEASE 2: Backfill existing data
class RenameNameToFullNameStep2 < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    User.unscoped.where(full_name: nil).in_batches(of: 10_000) do |batch|
      batch.update_all("full_name = name")
      sleep(0.1)
    end
  end
end

# RELEASE 3: Switch to new column, stop dual-write
# Update all code to use full_name, remove sync callback

# RELEASE 4: Remove old column (use safe removal pattern)
class RenameNameToFullNameStep4 < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :name, :string
  end
end

# =============================================================================
# SAFE TYPE CHANGE
# =============================================================================

# Changing column type often rewrites entire table
# Use new column + migration instead

class ChangeIdToUuid < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    # Add new UUID column
    add_column :products, :uuid, :uuid, default: "gen_random_uuid()"

    # Backfill existing records
    Product.unscoped.in_batches(of: 10_000) do |batch|
      batch.update_all("uuid = gen_random_uuid()")
      sleep(0.1)
    end

    # Add unique index
    add_index :products, :uuid, unique: true, algorithm: :concurrently

    # Now update foreign keys and code to use uuid
    # Then in later migration, remove old id column
  end

  def down
    remove_column :products, :uuid
  end
end

# =============================================================================
# SAFE INDEX CREATION
# =============================================================================

class AddIndexSafely < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!  # Required for concurrent

  def change
    add_index :users, :email,
              unique: true,
              algorithm: :concurrently,
              name: "index_users_on_email_unique"
  end
end

# With if_not_exists for idempotency
class AddIndexIdempotent < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :users, :email, algorithm: :concurrently, if_not_exists: true
  end
end

# =============================================================================
# SAFE FOREIGN KEY ADDITION
# =============================================================================

# Foreign keys validate all rows on creation, which can lock tables

# Step 1: Add without validation
class AddForeignKeySafely1 < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :orders, :users, validate: false
  end
end

# Step 2: Validate in separate migration
class AddForeignKeySafely2 < ActiveRecord::Migration[7.2]
  def change
    validate_foreign_key :orders, :users
  end
end

# =============================================================================
# SAFE DATA BACKFILL
# =============================================================================

class BackfillUserStatus < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    # Process in batches to avoid memory issues and long locks
    loop do
      # Find batch of records to update
      count = User.unscoped
                  .where(status: nil)
                  .limit(10_000)
                  .update_all(status: "active")

      break if count.zero?

      sleep(0.1)  # Throttle to reduce database load
    end
  end
end

# Using find_each for complex logic
class BackfillCalculatedField < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  # Define local model to avoid depending on app code
  class Order < ApplicationRecord
    self.table_name = "orders"
  end

  def up
    Order.unscoped.where(total_cents: nil).find_each(batch_size: 1000) do |order|
      total = order.subtotal_cents.to_i + order.tax_cents.to_i
      order.update_columns(total_cents: total)
    end
  end
end

# =============================================================================
# MIGRATION WITH LOCK TIMEOUT
# =============================================================================

class MigrationWithTimeout < ActiveRecord::Migration[7.2]
  def change
    # Set lock timeout to avoid blocking for too long
    execute "SET lock_timeout = '5s'"

    begin
      add_column :users, :verified, :boolean, default: false
    ensure
      execute "SET lock_timeout = DEFAULT"
    end
  end
end

# =============================================================================
# SAFE TABLE COPY PATTERN
# =============================================================================

# For massive schema changes, copy to new table

class RestructureProductsTable < ActiveRecord::Migration[7.2]
  def up
    # Create new table with desired schema
    create_table :products_v2 do |t|
      t.string :name, null: false
      t.decimal :price_cents, precision: 12, scale: 0, null: false
      # ... new schema
      t.timestamps
    end

    # Copy data (in production, do this in background job)
    execute <<~SQL
      INSERT INTO products_v2 (id, name, price_cents, created_at, updated_at)
      SELECT id, name, (price * 100)::bigint, created_at, updated_at
      FROM products
    SQL

    # Rename tables
    rename_table :products, :products_legacy
    rename_table :products_v2, :products

    # Later: drop legacy table after verification
  end

  def down
    rename_table :products, :products_v2
    rename_table :products_legacy, :products
    drop_table :products_v2
  end
end

# =============================================================================
# ENUM CHANGES (PostgreSQL)
# =============================================================================

# Adding enum values requires disable_ddl_transaction
class AddEnumValue < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    execute "ALTER TYPE order_status ADD VALUE 'refunded'"
  end

  def down
    # Cannot remove enum values easily in PostgreSQL
    # Would need to recreate enum type
    raise ActiveRecord::IrreversibleMigration
  end
end

# =============================================================================
# IDEMPOTENT MIGRATIONS
# =============================================================================

# Make migrations safe to run multiple times (useful for retry scenarios)

class IdempotentMigration < ActiveRecord::Migration[7.2]
  def change
    # Check before creating
    unless table_exists?(:audits)
      create_table :audits do |t|
        t.string :action
        t.timestamps
      end
    end

    # Check before adding column
    unless column_exists?(:users, :audit_count)
      add_column :users, :audit_count, :integer, default: 0
    end

    # Check before adding index
    unless index_exists?(:users, :audit_count)
      add_index :users, :audit_count
    end
  end
end

# =============================================================================
# POST-DEPLOYMENT MIGRATIONS
# =============================================================================

# For non-critical operations that can run after deployment
# These don't block the deploy and can take longer

# Place in db/post_migrate/ if using GitLab-style setup
# Or run via separate rake task

class PostDeploymentCleanup < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    # Remove unused indexes (non-blocking)
    remove_index :orders, :legacy_column, algorithm: :concurrently, if_exists: true

    # Clean up orphaned data
    execute "DELETE FROM order_items WHERE order_id NOT IN (SELECT id FROM orders)"

    # Add new index (non-blocking)
    add_index :orders, :new_column, algorithm: :concurrently, if_not_exists: true
  end
end

# =============================================================================
# USING strong_migrations GEM
# =============================================================================

# With strong_migrations installed, dangerous operations are blocked
# Use safety_assured only after careful review

class MigrationWithStrongMigrations < ActiveRecord::Migration[7.2]
  def change
    # This would normally be blocked
    safety_assured do
      add_column :users, :settings, :jsonb, default: {}
    end
  end
end

# Better: Follow recommended pattern
class SafeAddColumnWithDefault < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    # Add column without default first
    add_column :users, :settings, :jsonb

    # Backfill (for existing records)
    User.unscoped.in_batches do |batch|
      batch.update_all(settings: {})
    end

    # Set default for new records
    change_column_default :users, :settings, {}

    # Add NOT NULL if needed
    change_column_null :users, :settings, false
  end
end
