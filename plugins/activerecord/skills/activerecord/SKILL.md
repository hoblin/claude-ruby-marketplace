---
name: ActiveRecord
description: This skill should be used when the user asks to "write a migration", "add a column", "add column to table", "create an index", "add a foreign key", "set up associations", "fix N+1 queries", "optimize queries", "add validations", "create callbacks", "use eager loading", or mentions ActiveRecord, belongs_to, has_many, has_one, :through associations, polymorphic associations, inverse_of, touch: true, counter_cache, dependent: destroy, where clauses, scopes, includes, preload, eager_load, joins, find_each, batch processing, counter caches, foreign key constraints, or database constraints. Should also be used when editing *_model.rb files, working in app/models/ directory, db/migrate/, discussing query performance, N+1 prevention, validation vs constraint decisions, or reviewing database schema design.
version: 1.0.0
---

# ActiveRecord

This skill provides comprehensive guidance for working with ActiveRecord in Rails applications. Use for writing migrations, defining associations, optimizing queries, preventing N+1 issues, implementing validations, and following database best practices.

## Quick Reference

### CRUD Operations

```ruby
# Create
user = User.create(name: "Alice", email: "alice@example.com")
user = User.create!(...)  # Raises on failure

# Read
User.find(1)              # Raises RecordNotFound
User.find_by(email: "x")  # Returns nil if not found
User.where(active: true)  # Returns Relation

# Update
user.update(name: "Bob")
user.update!(...)         # Raises on failure

# Delete (callbacks run)
user.destroy

# Delete (no callbacks)
user.delete
```

### Key Concepts

| Concept | Purpose |
|---------|---------|
| `belongs_to` | Child side of association (has foreign key) |
| `has_many` / `has_one` | Parent side of association |
| `has_many :through` | Many-to-many via join model |
| `includes` / `preload` | Eager loading (prevent N+1) |
| `scope` | Named query builder |
| `validates` | Model-level data validation |
| `before_save` / `after_commit` | Lifecycle callbacks |

## Eager Loading Decision Tree

```
Need to access associated data?
├── NO → Use `joins` (filtering only)
└── YES → Need to filter/sort by association?
          ├── NO → Use `preload` (separate queries)
          └── YES → Large dataset with many associations?
                    ├── YES → Use `includes` with `references`
                    └── NO → Use `eager_load` (single JOIN)
```

### Quick Comparison

| Method | Strategy | Best For |
|--------|----------|----------|
| `includes` | Auto-choose | Default choice |
| `preload` | Separate queries | Large datasets, no filtering |
| `eager_load` | LEFT OUTER JOIN | Filtering by association |
| `joins` | INNER JOIN | Filtering only, not accessing data |

```ruby
# N+1 problem
Post.all.each { |p| p.author.name }  # 1 + N queries

# Solution
Post.includes(:author).each { |p| p.author.name }  # 2 queries
```

## Validation vs Constraint Decision

```
Does the rule ALWAYS apply, regardless of business logic?
├── Yes → Database constraint
│   └── Examples: NOT NULL, foreign keys, unique emails
└── No → Model validation
    └── Examples: Format rules that change, conditional requirements

Need helpful user-facing error messages?
├── Yes → Model validation (possibly WITH constraint)
└── No → Constraint alone is fine
```

**Best Practice**: Use both for critical fields:

```ruby
# Migration (data integrity)
add_index :users, :email, unique: true

# Model (user feedback)
validates :email, presence: true, uniqueness: true
```

## Associations Quick Reference

### Basic Types

```ruby
class Author < ApplicationRecord
  has_many :books, dependent: :destroy
  has_one :profile
end

class Book < ApplicationRecord
  belongs_to :author                    # Required by default
  belongs_to :publisher, optional: true # Allow NULL
end
```

### Through Associations

```ruby
class Physician < ApplicationRecord
  has_many :appointments
  has_many :patients, through: :appointments
end

class Appointment < ApplicationRecord
  belongs_to :physician
  belongs_to :patient
  # Join model can have attributes
  validates :scheduled_at, presence: true
end
```

### Critical Options

| Option | Purpose |
|--------|---------|
| `inverse_of` | Required with custom foreign_key |
| `dependent: :destroy` | Cascade delete with callbacks |
| `counter_cache: true` | Cache association count |
| `touch: true` | Update parent's updated_at |

## Migrations Quick Reference

### Safe Patterns

```ruby
# Always reversible
add_column :users, :name, :string
add_index :users, :email, unique: true
add_reference :orders, :user, foreign_key: true

# Concurrent index (no table lock)
disable_ddl_transaction!
add_index :users, :email, algorithm: :concurrently
```

### Must Include Type for Reversibility

```ruby
remove_column :users, :legacy_field, :string  # Include type!
change_column_default :users, :status, from: nil, to: "active"
```

## Callbacks Quick Reference

### Order of Execution

```
before_validation → after_validation →
before_save → around_save → before_create →
around_create → [INSERT] → after_create →
after_save → [COMMIT] → after_commit
```

### Critical Rule: Use after_commit for External Systems

```ruby
# WRONG - Race condition!
after_save :enqueue_processing

# CORRECT - Runs after COMMIT
after_commit :enqueue_processing, on: :create
```

## Batch Processing

```ruby
# BAD - loads all records
User.all.each { |u| process(u) }

# GOOD - processes in batches
User.find_each { |u| process(u) }

# Bulk operations
User.where(old: true).in_batches.update_all(archived: true)
```

## Best Practices

### Do

- Add database index for columns used in WHERE, ORDER BY, JOIN
- Use `includes` to prevent N+1 queries
- Pair uniqueness validations with unique database indexes
- Use `find_each` for processing large datasets
- Use `pluck(:column)` instead of `all.map(&:column)`
- Define `inverse_of` when using custom `foreign_key`
- Use `after_commit` for background jobs and external APIs
- Prefer `has_many :through` over `has_and_belongs_to_many`

### Don't

- Don't use `default_scope` (causes subtle issues)
- Don't use `delete` when you need callbacks
- Don't skip database constraints for critical uniqueness
- Don't use `update_column` to bypass validations casually
- Don't reference models in migrations (use raw SQL)
- Don't edit already-deployed migrations
- Don't use `after_save` for external system interactions

## Anti-Patterns Quick List

| Anti-Pattern | Solution |
|--------------|----------|
| N+1 queries | Use `includes`, `preload`, or `eager_load` |
| `User.all.map(&:email)` | Use `User.pluck(:email)` |
| Uniqueness without index | Add unique database index |
| `validates :active, presence: true` | Use `inclusion: { in: [true, false] }` for booleans |
| `after_save` for jobs | Use `after_commit` |
| Callback hell | Extract to service objects |
| `default_scope` | Use explicit scopes |
| `has_and_belongs_to_many` | Use `has_many :through` |

## Additional Resources

### Reference Files

For detailed patterns and complete API references, consult:

- **`references/basics.md`** - Conventions, CRUD, dirty tracking, STI, type casting
- **`references/migrations.md`** - Schema changes, indexes, constraints, safe patterns
- **`references/validations.md`** - Built-in validators, custom validators, contexts
- **`references/callbacks.md`** - Lifecycle hooks, transaction callbacks, alternatives
- **`references/associations.md`** - All association types, inverse_of, dependent options
- **`references/querying.md`** - Finders, eager loading, scopes, batch processing

### Example Files

Ready-to-use code patterns in `examples/`:

- **`examples/basics/`** - CRUD, dirty tracking, type casting, inheritance
- **`examples/migrations/`** - Schema changes, indexes, safe patterns, reversibility
- **`examples/validations/`** - Built-in, conditional, custom, contexts, constraints
- **`examples/callbacks/`** - Lifecycle, transaction callbacks, conditional, alternatives
- **`examples/associations/`** - Basic, through, polymorphic, self-referential, extensions
- **`examples/querying/`** - Finders, eager loading, scopes, batch processing, optimization
