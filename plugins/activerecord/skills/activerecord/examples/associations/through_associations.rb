# Through Association Examples
# Many-to-many relationships with join models

# ============================================
# has_many :through - Standard Pattern
# ============================================

# Physician <-> Appointment <-> Patient
#
# ┌──────────────┐       ┌──────────────┐       ┌──────────────┐
# │   Physician  │       │  Appointment │       │   Patient    │
# ├──────────────┤       ├──────────────┤       ├──────────────┤
# │ id           │◄──────│ physician_id │       │ id           │
# │ name         │       │ patient_id   │──────►│ name         │
# │              │       │ scheduled_at │       │              │
# └──────────────┘       └──────────────┘       └──────────────┘

class Physician < ApplicationRecord
  has_many :appointments, dependent: :destroy
  has_many :patients, through: :appointments
end

class Appointment < ApplicationRecord
  belongs_to :physician
  belongs_to :patient

  # Join model can have attributes
  validates :scheduled_at, presence: true
  validate :no_double_booking

  scope :upcoming, -> { where("scheduled_at > ?", Time.current) }
  scope :past, -> { where("scheduled_at <= ?", Time.current) }

  private

  def no_double_booking
    return unless scheduled_at

    conflict = Appointment.where(physician:, scheduled_at:).where.not(id:)
    errors.add(:scheduled_at, "physician already has appointment") if conflict.exists?
  end
end

class Patient < ApplicationRecord
  has_many :appointments, dependent: :destroy
  has_many :physicians, through: :appointments
end

# Migrations
# create_table :appointments do |t|
#   t.belongs_to :physician, null: false, foreign_key: true
#   t.belongs_to :patient, null: false, foreign_key: true
#   t.datetime :scheduled_at, null: false
#   t.text :notes
#   t.timestamps
# end
# add_index :appointments, [:physician_id, :scheduled_at], unique: true

# ============================================
# Usage Examples
# ============================================

# Creating through association
physician = Physician.find(1)
patient = Patient.find(1)

# Via join model
appointment = Appointment.create!(
  physician:,
  patient:,
  scheduled_at: 1.day.from_now
)

# Shortcut - creates join record automatically
physician.patients << patient  # Creates Appointment

# With join model attributes
physician.appointments.create!(
  patient:,
  scheduled_at: 2.days.from_now,
  notes: "Follow-up visit"
)

# Querying through
physician.patients.where(name: "John")
physician.appointments.upcoming

# ============================================
# has_one :through
# ============================================

# Supplier -> Account -> AccountHistory

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

# Usage
supplier = Supplier.first
supplier.account_history  # One query through Account

# ============================================
# Nested has_many :through
# ============================================

# Document -> Section -> Paragraph

class Document < ApplicationRecord
  has_many :sections
  has_many :paragraphs, through: :sections
end

class Section < ApplicationRecord
  belongs_to :document
  has_many :paragraphs
end

class Paragraph < ApplicationRecord
  belongs_to :section
end

# Access all paragraphs in document
document.paragraphs

# ============================================
# Inverse Of - Critical for Nested Attributes
# ============================================

class Invoice < ApplicationRecord
  has_many :line_items, inverse_of: :invoice  # REQUIRED!
  accepts_nested_attributes_for :line_items

  validates :total, presence: true
end

class LineItem < ApplicationRecord
  belongs_to :invoice
  validates :invoice, presence: true  # Fails without inverse_of!
end

# Without inverse_of:
# Invoice.create!(line_items_attributes: [{...}])
# => ValidationFailed: Invoice can't be blank

# With inverse_of:
# Invoice.create!(line_items_attributes: [{...}])
# => Success! Rails knows line_item.invoice is the parent

# ============================================
# Source Option - When Names Don't Match
# ============================================

class Person < ApplicationRecord
  has_many :readings
  has_many :articles, through: :readings, source: :post  # post, not article
end

class Reading < ApplicationRecord
  belongs_to :person
  belongs_to :post  # Not called "article"
end

# ============================================
# HABTM vs Through Comparison
# ============================================

# HABTM - Simple but limited
class Assembly < ApplicationRecord
  has_and_belongs_to_many :parts
end

class Part < ApplicationRecord
  has_and_belongs_to_many :assemblies
end

# has_many :through - Flexible (PREFERRED)
class Assembly < ApplicationRecord
  has_many :assembly_parts
  has_many :parts, through: :assembly_parts
end

class AssemblyPart < ApplicationRecord
  belongs_to :assembly
  belongs_to :part

  # Can add attributes later!
  # quantity, position, notes, etc.
end

class Part < ApplicationRecord
  has_many :assembly_parts
  has_many :assemblies, through: :assembly_parts
end
