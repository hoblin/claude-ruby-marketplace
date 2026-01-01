# ActiveRecord Dirty Tracking Examples

# =============================================================================
# BEFORE SAVE - Pending Changes
# =============================================================================

user = User.find(1)
user.name  # => "Alice"

# Make a change
user.name = "Bob"

# Check if anything changed
user.changed?                    # => true
user.changes                     # => {"name" => ["Alice", "Bob"]}

# Check specific attribute
user.name_changed?               # => true
user.name_was                    # => "Alice" (original value)
user.name_change                 # => ["Alice", "Bob"]

# Check what will be saved
user.will_save_change_to_name?   # => true
user.changes_to_save             # => {"name" => ["Alice", "Bob"]}
user.name_in_database            # => "Alice"

# Check with options
user.name_changed?(from: "Alice")           # => true
user.name_changed?(to: "Bob")               # => true
user.name_changed?(from: "Alice", to: "Bob") # => true

# =============================================================================
# AFTER SAVE - Previous Changes
# =============================================================================

user.save

# Now check previous changes (what just happened)
user.saved_change_to_name?       # => true
user.saved_change_to_name        # => ["Alice", "Bob"]
user.name_before_last_save       # => "Alice"
user.name_previously_was         # => "Alice"
user.previous_changes            # => {"name" => ["Alice", "Bob"], "updated_at" => [...]}

# Pending changes are now empty
user.changed?                    # => false
user.changes                     # => {}

# =============================================================================
# REVERTING CHANGES
# =============================================================================

user.name = "Changed"
user.email = "changed@example.com"

# Revert single attribute
user.restore_name!
user.name  # => "Bob" (restored)

# Revert all changes
user.restore_attributes
user.email  # => original value

# Reload from database (clears all dirty state)
user.name = "Something"
user.reload
user.changed?  # => false

# =============================================================================
# USING IN CALLBACKS
# =============================================================================

class User < ApplicationRecord
  after_save :notify_if_email_changed
  after_save :log_role_change
  before_save :set_confirmation_token, if: :will_save_change_to_email?

  private

  def notify_if_email_changed
    if saved_change_to_email?
      old_email, new_email = saved_change_to_email
      UserMailer.email_changed(self, old_email).deliver_later
    end
  end

  def log_role_change
    if saved_change_to_role?
      AuditLog.create!(
        user: self,
        action: "role_changed",
        old_value: role_before_last_save,
        new_value: role
      )
    end
  end

  def set_confirmation_token
    self.confirmation_token = SecureRandom.urlsafe_base64
    self.confirmed_at = nil
  end
end

# =============================================================================
# CONDITIONAL UPDATES
# =============================================================================

class Order < ApplicationRecord
  after_save :recalculate_if_items_changed

  private

  def recalculate_if_items_changed
    # Only recalculate if total-affecting fields changed
    if saved_change_to_discount? || saved_change_to_shipping?
      recalculate_total!
    end
  end
end

# =============================================================================
# TRACKING SPECIFIC CHANGES
# =============================================================================

class Profile < ApplicationRecord
  SENSITIVE_FIELDS = %w[email phone_number ssn].freeze

  after_save :audit_sensitive_changes

  private

  def audit_sensitive_changes
    changed_sensitive = previous_changes.keys & SENSITIVE_FIELDS

    changed_sensitive.each do |field|
      old_val, new_val = previous_changes[field]
      SecurityAudit.log(
        user: self,
        field:,
        changed_from: mask_value(old_val),
        changed_to: mask_value(new_val)
      )
    end
  end

  def mask_value(value)
    return nil if value.nil?
    "***#{value.to_s.last(4)}"
  end
end

# =============================================================================
# CHANGED_ATTRIBUTES VS CHANGES
# =============================================================================

user.name = "New"
user.email = "new@example.com"

# changed_attribute_names_to_save - just the names
user.changed_attribute_names_to_save  # => ["name", "email"]

# attributes_in_database - original values hash
user.attributes_in_database  # => {"name" => "Old", "email" => "old@example.com", ...}

# =============================================================================
# ASSOCIATION CHANGES
# =============================================================================

# Foreign key changes are tracked
post = Post.find(1)
post.author_id = 5
post.author_id_changed?  # => true
post.author_id_was       # => previous author_id

# =============================================================================
# IN-PLACE MODIFICATION (Rails 7+)
# =============================================================================

# Rails 7+ automatically detects in-place changes
user.tags = ["ruby"]
user.tags << "rails"
user.tags_changed?  # => true (automatic detection)

# Previously required:
# user.tags_will_change!  # No longer needed in Rails 7+
# user.tags << "rails"

# =============================================================================
# SKIPPING DIRTY TRACKING
# =============================================================================

# These methods bypass dirty tracking entirely
user.update_column(:login_count, 5)   # No callbacks, no dirty tracking
user.update_columns(login_count: 5)   # No callbacks, no dirty tracking

# Check changes BEFORE using these if needed
if user.login_count_changed?
  # ... do something
end
user.update_column(:login_count, user.login_count)

# =============================================================================
# PERFORMANCE CONSIDERATIONS
# =============================================================================

# Dirty tracking adds memory overhead
# For bulk operations, use update_all to bypass

# BAD - instantiates models with dirty tracking
User.where(status: :pending).each do |user|
  user.update(status: :active)
end

# GOOD - direct SQL, no instantiation
User.where(status: :pending).update_all(status: :active)

# For read-only operations, use pluck
emails = User.pluck(:email)  # No model instantiation
