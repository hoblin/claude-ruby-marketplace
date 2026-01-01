# ActiveRecord Migration Examples: Reversible Patterns
# Techniques for writing migrations that can be rolled back safely

# =============================================================================
# AUTO-REVERSIBLE OPERATIONS
# =============================================================================

# These work with `change` method - Rails handles reversal automatically

class AutoReversibleOperations < ActiveRecord::Migration[7.2]
  def change
    # Table operations
    create_table :products do |t|
      t.string :name
      t.timestamps
    end

    create_join_table :products, :categories

    # Column operations
    add_column :users, :phone, :string
    add_timestamps :legacy_table

    # Reference operations
    add_reference :orders, :user, foreign_key: true

    # Index operations
    add_index :users, :email, unique: true

    # Constraint operations
    add_foreign_key :orders, :users
    add_check_constraint :products, "price > 0", name: "price_positive"

    # Rename operations
    rename_table :old_name, :new_name
    rename_column :users, :name, :full_name
    rename_index :users, :old_index, :new_index

    # Extension operations (PostgreSQL)
    enable_extension "pgcrypto"
  end
end

# =============================================================================
# REVERSIBLE WITH from/to
# =============================================================================

# These operations need explicit from/to values

class ReversibleWithFromTo < ActiveRecord::Migration[7.2]
  def change
    # Default changes
    change_column_default :users, :status, from: nil, to: "active"
    change_column_default :products, :quantity, from: 0, to: 1

    # Comment changes
    change_column_comment :users, :email, from: nil, to: "Primary contact email"
    change_table_comment :users, from: nil, to: "Application users"
  end
end

# =============================================================================
# REVERSIBLE WITH COLUMN TYPE
# =============================================================================

# Remove operations need type info for recreation on rollback

class ReversibleRemoveOperations < ActiveRecord::Migration[7.2]
  def change
    # Single column - must include type
    remove_column :users, :legacy_token, :string

    # Multiple columns - must include type option
    remove_columns :users, :temp1, :temp2, type: :string

    # With all options for exact recreation
    remove_column :products, :discount, :decimal,
                  precision: 5, scale: 2, default: 0.0
  end
end

# =============================================================================
# REVERSIBLE DROP TABLE
# =============================================================================

# drop_table must include full schema for reversibility

class ReversibleDropTable < ActiveRecord::Migration[7.2]
  def change
    drop_table :legacy_reports do |t|
      t.string :name, null: false
      t.text :content
      t.references :user, foreign_key: true
      t.timestamps
    end

    # With table options
    drop_table :archived_data, id: :uuid do |t|
      t.jsonb :data
      t.timestamps
    end
  end
end

# =============================================================================
# REVERSIBLE REMOVE INDEX
# =============================================================================

class ReversibleRemoveIndex < ActiveRecord::Migration[7.2]
  def change
    # By column (reversible)
    remove_index :users, :email

    # Composite index
    remove_index :orders, [:user_id, :status]

    # With all options for exact recreation
    remove_index :users, :username, unique: true, name: "idx_users_username"
  end
end

# =============================================================================
# REVERSIBLE REMOVE FOREIGN KEY
# =============================================================================

class ReversibleRemoveForeignKey < ActiveRecord::Migration[7.2]
  def change
    # By table (reversible)
    remove_foreign_key :orders, :users

    # By column - must include to_table
    remove_foreign_key :orders, column: :buyer_id, to_table: :users

    # With options
    remove_foreign_key :order_items, :products,
                       on_delete: :cascade, on_update: :cascade
  end
end

# =============================================================================
# USING reversible BLOCK
# =============================================================================

# For custom SQL or complex operations

class UsingReversibleBlock < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :name
      t.decimal :price
      t.timestamps
    end

    # Custom constraint with reversible
    reversible do |dir|
      dir.up do
        execute <<~SQL
          ALTER TABLE products
          ADD CONSTRAINT price_range
          CHECK (price BETWEEN 0 AND 1000000)
        SQL
      end

      dir.down do
        execute <<~SQL
          ALTER TABLE products
          DROP CONSTRAINT price_range
        SQL
      end
    end
  end
end

# Multiple reversible blocks
class ComplexReversibleMigration < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :status, :string

    reversible do |dir|
      dir.up do
        execute "UPDATE orders SET status = 'pending' WHERE status IS NULL"
      end
      # No down - data would be lost anyway
    end

    change_column_null :orders, :status, false

    reversible do |dir|
      dir.up do
        execute "CREATE INDEX CONCURRENTLY idx_orders_status ON orders(status)"
      end
      dir.down do
        execute "DROP INDEX CONCURRENTLY idx_orders_status"
      end
    end
  end
end

# =============================================================================
# EXPLICIT up/down METHODS
# =============================================================================

# Use when operation is truly irreversible or complex

class ExplicitUpDown < ActiveRecord::Migration[7.2]
  def up
    # Change column type (irreversible without explicit down)
    change_column :products, :price, :decimal, precision: 12, scale: 2

    # Data transformation
    execute <<~SQL
      UPDATE products
      SET price = price * 100
      WHERE price_type = 'dollars'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE products
      SET price = price / 100
      WHERE price_type = 'dollars'
    SQL

    change_column :products, :price, :decimal, precision: 10, scale: 2
  end
end

# =============================================================================
# IRREVERSIBLE MIGRATIONS
# =============================================================================

# Explicitly mark migrations that cannot be reversed

class IrreversibleMigration < ActiveRecord::Migration[7.2]
  def up
    # Data destruction - cannot be reversed
    execute "DELETE FROM audit_logs WHERE created_at < '2020-01-01'"

    # Remove column without saving type info
    remove_column :users, :legacy_data
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "Cannot restore deleted audit logs or legacy_data column contents"
  end
end

# Partial irreversibility
class PartiallyReversible < ActiveRecord::Migration[7.2]
  def up
    add_column :users, :full_name, :string

    # Combine first_name + last_name into full_name
    execute <<~SQL
      UPDATE users SET full_name = first_name || ' ' || last_name
    SQL

    remove_column :users, :first_name
    remove_column :users, :last_name
  end

  def down
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string

    # Best effort - split on space (may not match original)
    execute <<~SQL
      UPDATE users SET
        first_name = split_part(full_name, ' ', 1),
        last_name = substring(full_name from position(' ' in full_name) + 1)
    SQL

    remove_column :users, :full_name
  end
end

# =============================================================================
# CONDITIONAL REVERSIBILITY
# =============================================================================

# Different behavior in up vs down

class ConditionalMigration < ActiveRecord::Migration[7.2]
  def change
    # These are always reversible
    add_column :users, :verified_at, :datetime
    add_column :users, :verified_by_id, :bigint

    # Data population only on up
    reversible do |dir|
      dir.up do
        # Set verified_at for users who completed verification
        execute <<~SQL
          UPDATE users
          SET verified_at = completed_at
          WHERE verification_status = 'completed'
        SQL
      end
      # No down - we'd lose when they were actually verified
    end

    add_index :users, :verified_at
  end
end

# =============================================================================
# TESTING REVERSIBILITY
# =============================================================================

# Always test migrations in both directions

# From command line:
# rails db:migrate VERSION=20240101000000
# rails db:rollback STEP=1
# rails db:migrate

# Or use the migrate alias (recommended):
# rails db:migrate db:rollback && rails db:migrate

# In RSpec (if you have migration tests):
# describe Migration do
#   it "migrates up and down" do
#     migrate_up
#     expect(User.column_names).to include("full_name")
#
#     migrate_down
#     expect(User.column_names).not_to include("full_name")
#   end
# end

# =============================================================================
# PRACTICAL PATTERNS
# =============================================================================

# Reversible enum creation (PostgreSQL)
class CreateStatusEnum < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE TYPE order_status AS ENUM ('pending', 'processing', 'shipped', 'delivered')
        SQL
      end

      dir.down do
        execute "DROP TYPE order_status"
      end
    end

    add_column :orders, :status, :order_status, default: "pending"
  end
end

# Reversible trigger creation
class CreateAuditTrigger < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE OR REPLACE FUNCTION audit_changes() RETURNS TRIGGER AS $$
          BEGIN
            INSERT INTO audit_logs (table_name, record_id, action, created_at)
            VALUES (TG_TABLE_NAME, NEW.id, TG_OP, NOW());
            RETURN NEW;
          END;
          $$ LANGUAGE plpgsql;

          CREATE TRIGGER users_audit
          AFTER INSERT OR UPDATE ON users
          FOR EACH ROW EXECUTE FUNCTION audit_changes();
        SQL
      end

      dir.down do
        execute <<~SQL
          DROP TRIGGER IF EXISTS users_audit ON users;
          DROP FUNCTION IF EXISTS audit_changes();
        SQL
      end
    end
  end
end

# Reversible view creation
class CreateActiveUsersView < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE VIEW active_users AS
          SELECT * FROM users
          WHERE active = true AND deleted_at IS NULL
        SQL
      end

      dir.down do
        execute "DROP VIEW active_users"
      end
    end
  end
end
