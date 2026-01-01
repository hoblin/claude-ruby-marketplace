# ActiveRecord Migrations Reference

Comprehensive reference for database migrations: methods, reversibility, constraints, indexes, and safe patterns for production deployments.

## Core Migration Methods

### Creating Tables

```ruby
class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 8, scale: 2
      t.references :category, foreign_key: true
      t.timestamps
    end
  end
end
```

| Option | Purpose | Example |
|--------|---------|---------|
| `id: false` | No auto-incrementing primary key | Join tables |
| `id: :uuid` | UUID primary key | Distributed systems |
| `primary_key: :custom_id` | Custom PK column name | Legacy schemas |
| `if_not_exists: true` | Skip if table exists | Idempotent migrations |
| `force: true` | Drop table first | **Never in production** |

### Column Types

| Type | PostgreSQL | MySQL | SQLite | Notes |
|------|------------|-------|--------|-------|
| `:string` | varchar(255) | varchar(255) | varchar | Use for short text |
| `:text` | text | text | text | Use for long text |
| `:integer` | integer | int(11) | integer | 4 bytes |
| `:bigint` | bigint | bigint | integer | 8 bytes (default for PKs) |
| `:decimal` | decimal | decimal | decimal | Specify precision/scale |
| `:float` | float | float | float | Inexact, use decimal for money |
| `:boolean` | boolean | tinyint(1) | boolean | |
| `:date` | date | date | date | |
| `:datetime` | timestamp | datetime | datetime | Rails adds precision: 6 |
| `:time` | time | time | time | |
| `:binary` | bytea | blob | blob | |
| `:json` | json | json | text | Use `:jsonb` for PostgreSQL |
| `:jsonb` | jsonb | - | - | PostgreSQL only, indexed |
| `:uuid` | uuid | - | - | PostgreSQL/MySQL 8+ |

### Adding Columns

```ruby
add_column :users, :role, :string, default: "member", null: false
add_column :products, :metadata, :jsonb, default: {}

# Reference columns (with index by default)
add_reference :products, :supplier, foreign_key: true
add_reference :comments, :commentable, polymorphic: true, index: true
```

### Modifying Columns

```ruby
# Change type (IRREVERSIBLE without up/down)
change_column :products, :price, :decimal, precision: 10, scale: 2

# Change null constraint (REVERSIBLE)
change_column_null :users, :email, false

# Change default (REVERSIBLE with from/to)
change_column_default :users, :status, from: nil, to: "active"

# Rename column (REVERSIBLE)
rename_column :users, :name, :full_name
```

### Removing Columns

```ruby
# Must include type for reversibility
remove_column :users, :legacy_field, :string

# Multiple columns (must include type option)
remove_columns :users, :temp1, :temp2, type: :string
```

## Reversibility

### Auto-Reversible Operations

These operations can use `change` - Rails knows how to reverse them:

| Operation | Reverse |
|-----------|---------|
| `add_column` | `remove_column` |
| `add_index` | `remove_index` |
| `add_reference` | `remove_reference` |
| `add_foreign_key` | `remove_foreign_key` |
| `add_timestamps` | `remove_timestamps` |
| `add_check_constraint` | `remove_check_constraint` |
| `create_table` | `drop_table` |
| `create_join_table` | `drop_join_table` |
| `rename_column` | Reverse rename |
| `rename_table` | Reverse rename |
| `rename_index` | Reverse rename |
| `enable_extension` | `disable_extension` |

### Operations Requiring Extra Info

```ruby
# change_column_default - MUST have from/to
change_column_default :posts, :status, from: nil, to: "draft"

# remove_column - MUST include type
remove_column :users, :age, :integer

# remove_index - MUST include column
remove_index :users, :email
remove_index :users, column: [:first_name, :last_name]

# remove_foreign_key - MUST include to_table
remove_foreign_key :orders, :customers
remove_foreign_key :orders, column: :buyer_id, to_table: :users

# drop_table - MUST include block for schema
drop_table :users do |t|
  t.string :email
  t.timestamps
end
```

### Irreversible Operations (Use up/down)

```ruby
class ChangeColumnType < ActiveRecord::Migration[7.2]
  def up
    change_column :products, :price, :decimal, precision: 10, scale: 2
  end

  def down
    change_column :products, :price, :decimal, precision: 8, scale: 2
  end
end
```

### Using reversible Block

```ruby
class AddConstraint < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.decimal :price
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        execute "ALTER TABLE products ADD CONSTRAINT price_positive CHECK (price > 0)"
      end
      dir.down do
        execute "ALTER TABLE products DROP CONSTRAINT price_positive"
      end
    end
  end
end
```

### Testing Reversibility

Always test both directions:

```bash
rails db:migrate && rails db:rollback && rails db:migrate
```

Mark truly irreversible migrations explicitly:

```ruby
def down
  raise ActiveRecord::IrreversibleMigration
end
```

## Database Constraints

### NOT NULL

```ruby
# On new column
add_column :users, :email, :string, null: false

# On existing column (validates all rows - can lock table!)
change_column_null :users, :email, false

# With default for existing NULLs
change_column_null :users, :email, false, "unknown@example.com"
```

### Foreign Keys

```ruby
# With reference (most common)
add_reference :orders, :customer, foreign_key: true

# Standalone foreign key
add_foreign_key :orders, :customers

# With options
add_foreign_key :orders, :customers,
  column: :buyer_id,
  on_delete: :cascade,
  on_update: :cascade

# Composite foreign key (PostgreSQL)
add_foreign_key :line_items, :orders, primary_key: [:shop_id, :order_id]
```

| on_delete/on_update | Behavior |
|---------------------|----------|
| `:nullify` | Set FK column to NULL |
| `:cascade` | Delete/update child rows |
| `:restrict` | Prevent if children exist |
| `:no_action` | Defer check to transaction end |

### Check Constraints

```ruby
add_check_constraint :products, "price > 0", name: "products_price_positive"
add_check_constraint :orders, "quantity >= 1", name: "orders_quantity_min"

# PostgreSQL: validate separately for large tables
add_check_constraint :users, "email IS NOT NULL",
  name: "users_email_not_null",
  validate: false
```

### Unique Constraints

```ruby
# Via index (most common)
add_index :users, :email, unique: true

# Composite unique
add_index :memberships, [:user_id, :organization_id], unique: true

# Partial unique (PostgreSQL)
add_index :users, :email, unique: true, where: "deleted_at IS NULL"
```

## Index Strategies

### When to Add Indexes

Add indexes for columns used in:
- `WHERE` clauses
- `ORDER BY` clauses
- `JOIN` conditions
- Foreign key columns

Skip indexes for:
- Tables with < 1,000 rows (unless expecting growth)
- Columns with low cardinality (few unique values)
- Write-heavy tables with infrequent reads

### Basic Indexes

```ruby
add_index :users, :email
add_index :users, :email, unique: true
add_index :users, :email, name: "idx_users_email"
```

### Composite Indexes

Column order matters - leftmost column is most important:

```ruby
# Good for: WHERE last_name = 'X' AND first_name = 'Y'
# Good for: WHERE last_name = 'X'
# NOT useful for: WHERE first_name = 'Y'
add_index :users, [:last_name, :first_name]
```

Put most selective column first.

### Partial Indexes (PostgreSQL, SQLite)

Index only subset of rows:

```ruby
# Index only active users
add_index :users, :email, where: "active = true"

# Index only non-null values
add_index :sessions, :user_id, where: "user_id IS NOT NULL"

# Index only specific status
add_index :orders, :created_at, where: "status = 'pending'"
```

### Index Options

| Option | Purpose | Database |
|--------|---------|----------|
| `unique: true` | Enforce uniqueness | All |
| `where: "..."` | Partial index | PostgreSQL, SQLite |
| `include: [:col]` | Cover additional columns | PostgreSQL |
| `using: :gist` | Different index type | PostgreSQL |
| `order: { col: :desc }` | Index ordering | PostgreSQL, MySQL 8+ |
| `algorithm: :concurrently` | No table lock | PostgreSQL |
| `type: :fulltext` | Full-text search | MySQL |

### Concurrent Index Creation (PostgreSQL)

```ruby
class AddIndexConcurrently < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :users, :email, algorithm: :concurrently
  end
end
```

**Required** for large production tables to avoid blocking reads/writes.

## Safe Migration Patterns

### Zero-Downtime Deployment

For production applications, migrations must not block normal operation:

| Operation | Risk | Safe Alternative |
|-----------|------|------------------|
| Add column with default | Table rewrite (older Rails) | Add column, then set default |
| Add NOT NULL | Validates all rows | Check constraint first |
| Remove column | AR caches columns | Add `ignored_columns` first |
| Rename column | Code references old name | Dual-write pattern |
| Change column type | Table rewrite | Create new column, migrate data |
| Add index | Locks table | `algorithm: :concurrently` |

### Safe Column Removal (3-Release Process)

**Release 1**: Add to ignored_columns
```ruby
class User < ApplicationRecord
  self.ignored_columns += ["legacy_column"]
end
```

**Release 2**: Drop column in post-deployment migration
```ruby
class RemoveLegacyColumn < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :legacy_column, :string
  end
end
```

**Release 3**: Remove ignored_columns line

### Safe NOT NULL Addition (PostgreSQL)

```ruby
class SafeAddNotNull < ActiveRecord::Migration[7.2]
  def up
    # Step 1: Add check constraint without validation
    add_check_constraint :users, "email IS NOT NULL",
      name: "users_email_not_null",
      validate: false

    # Step 2: Validate constraint (doesn't lock)
    validate_check_constraint :users, name: "users_email_not_null"

    # Step 3: Add actual NOT NULL (instant, uses constraint)
    change_column_null :users, :email, false

    # Step 4: Remove redundant constraint
    remove_check_constraint :users, name: "users_email_not_null"
  end

  def down
    change_column_null :users, :email, true
  end
end
```

### Backfilling Data Safely

```ruby
class BackfillStatus < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    User.unscoped.in_batches(of: 10_000) do |batch|
      batch.update_all(status: "active")
      sleep(0.1)  # Throttle to reduce load
    end
  end
end
```

### Using strong_migrations Gem

```ruby
# Gemfile
gem "strong_migrations"

# config/initializers/strong_migrations.rb
StrongMigrations.start_after = 20240101000000

# Migration with safety override
class AddColumn < ActiveRecord::Migration[7.2]
  def change
    safety_assured { add_column :users, :data, :jsonb, default: {} }
  end
end
```

## Data vs Schema Migrations

### Keep Them Separate

Schema migrations change database structure. Data migrations transform content.

**Problems with mixing**:
- Transaction rollback undoes both schema and data changes
- Data migrations can take much longer
- Different failure modes and recovery strategies

### Recommended Approaches

**1. maintenance_tasks gem** (Rails recommended):
```ruby
# lib/maintenance_tasks/tasks/backfill_user_status.rb
class BackfillUserStatus < MaintenanceTasks::Task
  def collection
    User.where(status: nil)
  end

  def process(user)
    user.update!(status: "active")
  end
end
```

**2. Separate data migration with data_migrate gem**:
```bash
rails g data_migration backfill_user_status
```

**3. Rake task / runner script**:
```ruby
# db/scripts/backfill_status.rb
User.where(status: nil).find_each do |user|
  user.update!(status: "active")
end
```

## Anti-Patterns

### Never Edit Committed Migrations

```ruby
# BAD - changing a deployed migration
class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email  # Added later - breaks other environments!
    end
  end
end

# GOOD - create new migration
class AddEmailToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :email, :string
  end
end
```

### Never Reference Models in Migrations

```ruby
# BAD - model may change, breaking old migrations
class BackfillUserNames < ActiveRecord::Migration[7.2]
  def up
    User.find_each do |user|
      user.update!(display_name: user.generate_display_name)
    end
  end
end

# GOOD - define migration-local model
class BackfillUserNames < ActiveRecord::Migration[7.2]
  class User < ApplicationRecord
    self.table_name = "users"
  end

  def up
    User.find_each do |user|
      user.update_columns(display_name: "#{user.first_name} #{user.last_name}")
    end
  end
end

# BEST - use raw SQL for simple transformations
class BackfillUserNames < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL
      UPDATE users SET display_name = first_name || ' ' || last_name
    SQL
  end
end
```

### Reset Column Information When Using Models

```ruby
class AddAndBackfillRole < ActiveRecord::Migration[7.2]
  def up
    add_column :users, :role, :string

    # REQUIRED - AR caches column info
    User.reset_column_information

    User.find_each do |user|
      user.update_columns(role: "member")
    end
  end
end
```

### Never Use force: true in Production Migrations

```ruby
# BAD - drops and recreates table, losing all data
create_table :users, force: true do |t|
  t.string :email
end

# OK - only in development/test for fixture setup
if Rails.env.development? || Rails.env.test?
  create_table :users, force: true do |t|
    t.string :email
  end
end
```

### Avoid change_column When Possible

```ruby
# BAD - irreversible, unclear intent
change_column :users, :status, :string, default: "active"

# GOOD - specific, reversible
change_column_default :users, :status, from: nil, to: "active"
```

## Decision Tree: Validation vs Constraint

```
Does the rule ALWAYS apply, regardless of business logic?
├── Yes → Database constraint
│   └── Examples: NOT NULL, foreign keys, unique emails, positive prices
│
└── No → Model validation
    └── Examples: Format rules that change, conditional requirements

Is data integrity critical even with direct SQL?
├── Yes → Database constraint
│
└── No → Model validation is sufficient

Need helpful user-facing error messages?
├── Yes → Model validation (possibly WITH constraint)
│
└── No → Constraint alone is fine

Production constraint addition acceptable?
├── No → Model validation only (can't lock table)
│
└── Yes → Database constraint
```

**Best Practice**: Use both for critical rules:
```ruby
# Database constraint (data integrity)
add_check_constraint :products, "price > 0"

# Model validation (user feedback)
validates :price, numericality: { greater_than: 0 }
```

## Transactional Migrations

### Default Behavior

DDL operations are wrapped in transactions (if adapter supports):
- Success: All changes committed
- Failure: All changes rolled back

### When to Disable Transactions

```ruby
class AddEnumValue < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!  # Required

  def up
    execute "ALTER TYPE status_type ADD VALUE 'archived'"
  end
end
```

Required for:
- PostgreSQL enum modifications
- Concurrent index creation/removal
- Long-running data backfills
- Any operation incompatible with transactions

## PostgreSQL-Specific Features

```ruby
# Enable extension
enable_extension "pgcrypto"
enable_extension "citext"

# Create enum type
create_enum :status, ["draft", "published", "archived"]

# Use enum in table
add_column :posts, :status, :status, default: "draft"

# JSONB with GIN index
add_column :products, :metadata, :jsonb, default: {}
add_index :products, :metadata, using: :gin

# Partial unique index
add_index :users, :email, unique: true, where: "deleted_at IS NULL"

# Expression index
add_index :users, "lower(email)", unique: true

# Include columns in index
add_index :orders, :user_id, include: [:status, :total]
```

## Migration Timing Guidelines

| Migration Type | Max Duration | Use Case |
|----------------|--------------|----------|
| Regular | < 3 min | Critical schema changes before deploy |
| Post-deployment | < 10 min | Cleanup, non-critical indexes |
| Background job | > 10 min | Large data transformations |

Test migration duration against production-scale data in staging.
