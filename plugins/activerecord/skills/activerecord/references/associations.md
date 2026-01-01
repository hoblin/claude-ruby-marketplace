# ActiveRecord Associations Reference

## Association Types Overview

### belongs_to - Child Side

The declaring model contains the foreign key. Use singular form.

```ruby
class Book < ApplicationRecord
  belongs_to :author                      # Required by default (Rails 5+)
  belongs_to :publisher, optional: true   # Allow NULL foreign key
  belongs_to :category, class_name: "Genre", foreign_key: "genre_id"
end
```

**Key Options:**
- `optional: true` - Allow NULL foreign key
- `counter_cache: true` - Maintain count on parent (column goes on parent)
- `touch: true` - Update parent's `updated_at` on save
- `inverse_of: :association` - Bi-directional reference (required with custom FK)
- `polymorphic: true` - Belong to multiple model types

**Migration:**
```ruby
create_table :books do |t|
  t.belongs_to :author, null: false, foreign_key: true
end
```

---

### has_one - Parent Side One-to-One

Another model has a reference to this model. Foreign key is on the other table.

```ruby
class Supplier < ApplicationRecord
  has_one :account, dependent: :destroy
  has_one :representative, class_name: "Person"
end
```

**Critical Warning:** Rails does NOT enforce 1:1 at database level. Add unique index:

```ruby
# Migration - enforce true 1:1
add_index :accounts, :supplier_id, unique: true
```

**Key Options:**
- `dependent: :destroy` - Destroy associated when parent destroyed
- `as: :attachable` - Polymorphic target
- `through: :other_association` - Through another association

---

### has_many - One-to-Many

This model has multiple instances of another model.

```ruby
class Author < ApplicationRecord
  has_many :books, dependent: :destroy
  has_many :published_books, -> { where(published: true) }, class_name: "Book"
  has_many :chapters, through: :books
end
```

**Key Options:**
- `dependent:` - Cascade behavior (see Dependent Options below)
- `counter_cache:` - Custom column name for count
- `inverse_of:` - Bi-directional reference
- `through:` - Many-to-many via join model

**Collection Methods:**
```ruby
author.books              # Returns Relation
author.books.build        # Create unsaved
author.books.create       # Create and save
author.books << book      # Add (saves immediately!)
author.book_ids           # Array of IDs
```

---

### has_and_belongs_to_many - Direct Many-to-Many

Simple many-to-many without join model. **Prefer `has_many :through` instead.**

```ruby
class Assembly < ApplicationRecord
  has_and_belongs_to_many :parts
end

class Part < ApplicationRecord
  has_and_belongs_to_many :assemblies
end
```

**Migration (no primary key):**
```ruby
create_table :assemblies_parts, id: false do |t|
  t.belongs_to :assembly, foreign_key: true
  t.belongs_to :part, foreign_key: true
end
add_index :assemblies_parts, [:assembly_id, :part_id], unique: true
```

**Join Table Naming:** Lexically ordered - `papers_paper_boxes` not `paper_boxes_papers`. Use explicit `:join_table` to avoid surprises.

**Critical:** Declare `has_and_belongs_to_many` BEFORE `self.table_name =` in model.

---

## Through Associations

### has_many :through

Many-to-many with join model. **Always prefer over HABTM.**

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│   Physician  │       │  Appointment │       │   Patient    │
├──────────────┤       ├──────────────┤       ├──────────────┤
│ id           │◄──────│ physician_id │       │ id           │
│ name         │       │ patient_id   │──────►│ name         │
│              │       │ scheduled_at │       │              │
└──────────────┘       └──────────────┘       └──────────────┘
        │                     ▲                     │
        │     has_many        │      has_many       │
        └─────:through────────┴──────:through───────┘
```

```ruby
class Physician < ApplicationRecord
  has_many :appointments
  has_many :patients, through: :appointments
end

class Appointment < ApplicationRecord
  belongs_to :physician
  belongs_to :patient

  # Join model can have attributes and validations
  validates :scheduled_at, presence: true
end

class Patient < ApplicationRecord
  has_many :appointments
  has_many :physicians, through: :appointments
end
```

**Advantages over HABTM:**
- Add attributes/validations to join model
- Store metadata (timestamps, status)
- Add callbacks to relationship changes
- Easier to extend later

---

### has_one :through

Access single record through intermediate association.

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│   Supplier   │       │   Account    │       │ AccountHistory│
├──────────────┤       ├──────────────┤       ├──────────────┤
│ id           │◄──────│ supplier_id  │       │ id           │
│ name         │       │ id           │◄──────│ account_id   │
│              │       │              │       │ credit_rating│
└──────────────┘       └──────────────┘       └──────────────┘
        │                     │
        │ has_one :through    │
        └─────────────────────┘
```

```ruby
class Supplier < ApplicationRecord
  has_one :account
  has_one :account_history, through: :account
end

class Account < ApplicationRecord
  belongs_to :supplier
  has_one :account_history
end

class AccountHistory < ApplicationRecord
  belongs_to :account
end
```

---

### Through Association Writability

**Critical Rule:** `:through` associations are only writable when join model uses `belongs_to`.

```ruby
# WORKS - join model has belongs_to
class Tagging < ApplicationRecord
  belongs_to :post
  belongs_to :tag
end
post.tags << tag  # Creates Tagging record

# READ-ONLY - join model has has_one/has_many
class Group < ApplicationRecord
  has_many :users
  has_many :avatars, through: :users  # Read-only!
end
group.avatars << avatar  # WON'T WORK
```

**Solution:** Manipulate the `:through` association directly.

---

## Polymorphic Associations

Single association points to multiple model types.

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│   Employee   │       │   Picture    │       │   Product    │
├──────────────┤       ├──────────────┤       ├──────────────┤
│ id           │◄──┐   │ id           │   ┌──►│ id           │
│ name         │   │   │ imageable_type│   │   │ name         │
│              │   └───│ imageable_id │───┘   │              │
└──────────────┘       │ name         │       └──────────────┘
                       └──────────────┘
```

```ruby
class Picture < ApplicationRecord
  belongs_to :imageable, polymorphic: true
end

class Employee < ApplicationRecord
  has_many :pictures, as: :imageable
end

class Product < ApplicationRecord
  has_many :pictures, as: :imageable
end
```

**Migration:**
```ruby
create_table :pictures do |t|
  t.string :name
  t.belongs_to :imageable, polymorphic: true
  t.timestamps
end
# Creates: imageable_type (string), imageable_id (integer)
```

**Naming Convention:**
- Use `-able` suffix when association is recipient: `imageable`, `attachable`, `commentable`
- Use subject form when acting: `author` not `authorable`

**STI Compatibility Warning:**
When using polymorphic with STI, store base class in type column:

```ruby
class Asset < ApplicationRecord
  belongs_to :attachable, polymorphic: true

  def attachable_type=(class_name)
    super(class_name.constantize.base_class.to_s)
  end
end
```

**Limitations:**
- Cannot use database foreign key constraints
- Cannot use `joins`, only `includes` for eager loading
- When renaming models, must update `*_type` column values

---

## Self-Referential Associations

Model relates to itself (hierarchies, trees, graphs).

```ruby
class Employee < ApplicationRecord
  # Employee has one manager (who is also an Employee)
  belongs_to :manager, class_name: "Employee", optional: true

  # Employee has many subordinates (who are also Employees)
  has_many :subordinates, class_name: "Employee", foreign_key: "manager_id"
end

# Usage
employee.manager        # Returns manager Employee
employee.subordinates   # Returns Employee collection
```

**Migration:**
```ruby
create_table :employees do |t|
  t.string :name
  t.belongs_to :manager, foreign_key: { to_table: :employees }
  t.timestamps
end
```

**Friendship Example (Many-to-Many Self-Join):**
```ruby
class User < ApplicationRecord
  has_many :friendships
  has_many :friends, through: :friendships
end

class Friendship < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: "User"
end
```

---

## Critical Association Options

### inverse_of - Bi-directional References

Tells Rails two associations represent same relationship from different sides.

**When Required:**
1. With custom `:foreign_key`
2. On `:through` join model associations
3. With `accepts_nested_attributes_for`

```ruby
class Author < ApplicationRecord
  has_many :books, inverse_of: :author
end

class Book < ApplicationRecord
  belongs_to :author, inverse_of: :books
end
```

**Why It Matters:**

```ruby
# WITHOUT inverse_of - extra query
author = Author.first
book = author.books.first
book.author.name         # Queries DB again!

# WITH inverse_of - no extra query
book.author.object_id == author.object_id  # Same object
```

**accepts_nested_attributes_for Requirement:**

```ruby
class Notice < ApplicationRecord
  has_many :entity_roles, inverse_of: :notice  # REQUIRED!
  accepts_nested_attributes_for :entity_roles
end

class EntityRole < ApplicationRecord
  belongs_to :notice
  validates :notice, presence: true  # Fails without inverse_of
end
```

Without `inverse_of`, Rails can't assign parent before validation, causing "can't be blank" errors.

**Automatic Detection Limitations:**
Rails auto-detects `:inverse_of` for simple associations but NOT when using:
- `:foreign_key` option
- `:through` option
- Custom scopes
- Non-standard naming

**Best Practice:** Always set `inverse_of` when using custom `:foreign_key`.

---

### dependent - Cascade Deletion

Controls what happens to associated records when parent is destroyed.

| Option | Behavior | Callbacks | Speed |
|--------|----------|-----------|-------|
| `:destroy` | Destroy each record | Yes | Slow |
| `:delete_all` | SQL DELETE (no load) | No | Fast |
| `:nullify` | Set FK to NULL | No | Fast |
| `:restrict_with_exception` | Raise if any exist | N/A | N/A |
| `:restrict_with_error` | Add error if any exist | N/A | N/A |
| `:destroy_async` | Background job destroy | Yes | Async |

**Decision Matrix:**

| Use Case | Option |
|----------|--------|
| Standard cascade | `:destroy` |
| No child callbacks needed | `:delete_all` |
| Keep orphan records | `:nullify` |
| Prevent accidental deletion | `:restrict_with_exception` |
| Large-scale deletions | `:destroy_async` |

**Warning - delete_all Breaks Grandchildren:**

```ruby
class Parent < ApplicationRecord
  has_many :children, dependent: :delete_all
end

class Child < ApplicationRecord
  has_many :grandchildren, dependent: :destroy
end

parent.destroy  # Deletes children, ORPHANS grandchildren!
```

**Warning - destroy_async + FK Constraints:**
Do NOT use `:destroy_async` with database foreign key constraints. FK actions occur in same transaction, but async job runs later causing violations.

**Orphan-Then-Purge Pattern (Large Datasets):**

```ruby
class Blog < ApplicationRecord
  has_many :posts, dependent: :nullify  # Fast orphaning
end

# Background job cleans up
Post.where(blog_id: nil).find_each(&:destroy)  # Proper callbacks
```

**Scoped Association Warning:**

```ruby
has_many :comments, -> { where(published: true) }, dependent: :destroy
```
Only published comments destroyed - unpublished become orphans!

---

### counter_cache - Count Optimization

Caches association count to eliminate COUNT queries.

```ruby
class Comment < ApplicationRecord
  belongs_to :post, counter_cache: true
end

class Post < ApplicationRecord
  has_many :comments
  attr_readonly :comments_count  # Prevent manual updates
end
```

**Migration:**
```ruby
add_column :posts, :comments_count, :integer, default: 0, null: false
```

**Backfilling Existing Data:**

```ruby
# Option 1: Simple reset
Post.find_each { |post| Post.reset_counters(post.id, :comments) }

# Option 2: For large tables, disable during backfill
belongs_to :post, counter_cache: { active: false }
# After backfill complete, change to:
belongs_to :post, counter_cache: true
```

**Custom Column Name:**
```ruby
belongs_to :post, counter_cache: :my_comments_count
```

**Gotchas:**
- Only updates via callbacks (`.delete` bypasses)
- Doesn't support scoped counts (use `counter_culture` gem)
- Consider database triggers for high-write scenarios

---

### autosave - Automatic Associated Saving

Controls when associated records are saved with parent.

| Setting | Behavior |
|---------|----------|
| Not specified | Save new records only |
| `true` | Save new AND updated records |
| `false` | Never auto-save |

```ruby
class Author < ApplicationRecord
  has_one :profile, autosave: true
end

author = Author.new(name: "Jane")
author.build_profile(bio: "Writer")
author.save  # Saves both author AND profile
```

**accepts_nested_attributes_for Auto-Enables:**
```ruby
accepts_nested_attributes_for :books  # Sets autosave: true automatically
```

**Callback Order Warning:**
Autosave defines callbacks. Define associations BEFORE custom callbacks:

```ruby
class Author < ApplicationRecord
  has_many :books, autosave: true     # First
  before_save :do_something           # Second - runs after autosave setup
end
```

---

## Association Extensions

Add custom methods to association proxies.

```ruby
class Project < ApplicationRecord
  has_many :tasks do
    def active
      where(status: 'active')
    end

    def by_priority
      order(priority: :desc)
    end

    def total_hours
      sum(:estimated_hours)
    end
  end
end

# Usage
project.tasks.active.by_priority
project.tasks.total_hours
```

**Shared Extensions via Module:**

```ruby
module StatusFilter
  def active
    where(status: 'active')
  end

  def completed
    where(status: 'completed')
  end
end

class Project < ApplicationRecord
  has_many :tasks, -> { extending StatusFilter }
  has_many :milestones, -> { extending StatusFilter }
end
```

**Accessing Parent Object:**
```ruby
has_many :tasks do
  def recent_for_owner
    where("created_at > ?", proxy_association.owner.created_at)
  end
end
```

---

## N+1 Query Prevention

### Eager Loading Methods

| Method | Strategy | Use When |
|--------|----------|----------|
| `includes` | Auto-choose | Default choice |
| `preload` | Separate queries | Large datasets, no filtering |
| `eager_load` | LEFT OUTER JOIN | Filtering/sorting by association |
| `joins` | INNER JOIN | Filtering only, not accessing data |

**Examples:**

```ruby
# includes - smart default (Rails decides preload vs eager_load)
Author.includes(:books).each { |a| a.books.size }

# preload - always separate queries
Author.preload(:books).limit(10)  # 2 queries total

# eager_load - always single JOIN
Author.eager_load(:books).where(books: { published: true })

# joins - filtering only (doesn't load association)
Author.joins(:books).where(books: { published: true }).distinct
```

**Strict Loading (Rails 6.1+):**
```ruby
Author.strict_loading.first
author.books  # Raises StrictLoadingViolationError!

# Per-association
has_many :books, strict_loading: true
```

**Nested Eager Loading:**
```ruby
Author.includes(books: :publisher)
Author.includes(books: [:publisher, :reviews])
Author.includes(books: { publisher: :address })
```

---

## Anti-Patterns

### 1. Naming After AR Methods
```ruby
# BAD - conflicts with AR::Base methods
has_many :attributes
has_one :connection
```

### 2. Relying on Validations for Uniqueness
```ruby
# BAD - race condition
validates :supplier, uniqueness: true

# GOOD - database constraint
add_index :accounts, :supplier_id, unique: true
```

### 3. Callbacks for Business Logic
```ruby
# BAD - hidden side effects
after_create :send_email
after_update :sync_to_api

# GOOD - explicit service object
class ProjectCreator
  def call(params)
    project = Project.create!(params)
    ProjectMailer.created(project).deliver_later
    ExternalApi.sync(project)
    project
  end
end
```

### 4. HABTM Without Future Consideration
```ruby
# BAD - hard to extend later
has_and_belongs_to_many :tags

# GOOD - flexible from start
has_many :taggings
has_many :tags, through: :taggings
```

### 5. Missing inverse_of with Custom FK
```ruby
# BAD - causes extra queries, validation failures
belongs_to :author, foreign_key: "writer_id"

# GOOD
belongs_to :author, foreign_key: "writer_id", inverse_of: :books
```

### 6. Eager Loading with Limit
```ruby
# WARNING - limit ignored with includes!
has_many :recent_comments, -> { order(created_at: :desc).limit(5) }
Post.includes(:recent_comments).first.recent_comments  # Returns ALL comments!
```

---

## Naming Conventions

Follow GitLab style guide for scope naming:

| Pattern | Purpose | Example |
|---------|---------|---------|
| `for_*` | Filter by belongs_to | `scope :for_user, ->(u) { where(user: u) }` |
| `with_*` | Joins/eager load or filter has_* | `scope :with_comments, -> { joins(:comments) }` |
| `order_by_*` | Ordering | `scope :order_by_recent, -> { order(created_at: :desc) }` |

---

## See Also

- `examples/associations/` - Working code examples
- `references/querying.md` - Eager loading details
- `references/callbacks.md` - Callback alternatives
- `references/migrations.md` - Foreign key constraints
