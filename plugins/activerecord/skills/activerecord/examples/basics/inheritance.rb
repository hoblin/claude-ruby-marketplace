# ActiveRecord Single Table Inheritance (STI) Examples

# =============================================================================
# BASIC STI SETUP
# =============================================================================

# Migration
class CreateVehicles < ActiveRecord::Migration[7.2]
  def change
    create_table :vehicles do |t|
      t.string :type, null: false  # Required for STI
      t.string :make
      t.string :model
      t.integer :year
      t.integer :wheels
      t.float :cargo_capacity
      t.timestamps

      t.index :type
    end
  end
end

# Models
class Vehicle < ApplicationRecord
  validates :make, :model, presence: true

  def description
    "#{year} #{make} #{model}"
  end
end

class Car < Vehicle
  validates :wheels, inclusion: { in: [4] }

  def vehicle_type
    "Automobile"
  end
end

class Truck < Vehicle
  validates :wheels, inclusion: { in: [4, 6, 8, 10, 18] }
  validates :cargo_capacity, presence: true

  def vehicle_type
    "Commercial Vehicle"
  end
end

class Motorcycle < Vehicle
  validates :wheels, inclusion: { in: [2, 3] }

  def vehicle_type
    "Two-wheeler"
  end
end

# =============================================================================
# STI USAGE
# =============================================================================

# Creating records
car = Car.create!(make: "Toyota", model: "Camry", year: 2024, wheels: 4)
car.type  # => "Car"

truck = Truck.create!(
  make: "Ford",
  model: "F-150",
  year: 2024,
  wheels: 4,
  cargo_capacity: 1500
)

# Queries automatically filter by type
Car.all
# SELECT * FROM vehicles WHERE type = 'Car'

Truck.count
# SELECT COUNT(*) FROM vehicles WHERE type = 'Truck'

# Base class queries all types
Vehicle.all
# SELECT * FROM vehicles

# Type-based queries
Vehicle.where(type: "Car")
Vehicle.where(type: ["Car", "Truck"])

# =============================================================================
# STI WITH NAMESPACED MODELS
# =============================================================================

module Inventory
  class Item < ApplicationRecord
    self.table_name = "inventory_items"
  end

  class PhysicalItem < Item
    # type = "Inventory::PhysicalItem" (full class name by default)
  end

  class DigitalItem < Item
    # type = "Inventory::DigitalItem"
  end
end

# To store short type names
class ApplicationRecord < ActiveRecord::Base
  self.store_full_class_name = false
  # Now type = "PhysicalItem" instead of "Inventory::PhysicalItem"
end

# =============================================================================
# STI WITH SHARED SCOPES
# =============================================================================

class Vehicle < ApplicationRecord
  scope :recent, -> { where("created_at > ?", 1.year.ago) }
  scope :by_make, ->(make) { where(make:) }
  scope :vintage, -> { where("year < ?", 1990) }
end

# Scopes work on subclasses
Car.recent.by_make("Honda")
# SELECT * FROM vehicles WHERE type = 'Car' AND created_at > ... AND make = 'Honda'

# =============================================================================
# STI WITH CALLBACKS
# =============================================================================

class Vehicle < ApplicationRecord
  before_save :normalize_make

  private

  def normalize_make
    self.make = make.titleize if make.present?
  end
end

class Car < Vehicle
  before_create :set_default_wheels

  private

  def set_default_wheels
    self.wheels ||= 4
  end
end

class Truck < Vehicle
  after_create :notify_fleet_manager

  private

  def notify_fleet_manager
    FleetManager.new_truck_added(self)
  end
end

# =============================================================================
# STI ANTI-PATTERN: SPARSE TABLES
# =============================================================================

# BAD - Too many type-specific columns
class Vehicle < ApplicationRecord
  # columns: type, make, model, wheels,
  #          wing_span, max_altitude,     # Airplane only
  #          displacement, fuel_type,     # Motorcycle only
  #          towing_capacity, bed_length  # Truck only
  # Results in lots of NULL values
end

# GOOD - Use delegated types or separate tables
# See delegated_types.rb for alternative

# =============================================================================
# ALTERNATIVE: DELEGATED TYPES (Rails 6.1+)
# =============================================================================

# Migration
class CreateEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :entries do |t|
      t.string :entryable_type, null: false
      t.bigint :entryable_id, null: false
      t.string :title
      t.datetime :published_at
      t.timestamps

      t.index [:entryable_type, :entryable_id]
    end

    create_table :messages do |t|
      t.text :body
      t.timestamps
    end

    create_table :comments do |t|
      t.text :content
      t.bigint :parent_id
      t.timestamps
    end
  end
end

# Models
class Entry < ApplicationRecord
  delegated_type :entryable, types: %w[Message Comment], dependent: :destroy
  delegate :body, to: :entryable, allow_nil: true
end

class Message < ApplicationRecord
  has_one :entry, as: :entryable, touch: true
  validates :body, presence: true
end

class Comment < ApplicationRecord
  has_one :entry, as: :entryable, touch: true
  belongs_to :parent, class_name: "Comment", optional: true
  validates :content, presence: true
end

# Usage
message = Message.create!(body: "Hello world")
entry = Entry.create!(title: "First Post", entryable: message)

entry.message?    # => true
entry.comment?    # => false
entry.entryable   # => Message instance

Entry.messages    # Scope for message entries
Entry.comments    # Scope for comment entries

# =============================================================================
# ALTERNATIVE: SEPARATE TABLES WITH CONCERNS
# =============================================================================

module Vehicular
  extend ActiveSupport::Concern

  included do
    validates :make, :model, :year, presence: true
    scope :recent, -> { where("year >= ?", 5.years.ago.year) }
  end

  def description
    "#{year} #{make} #{model}"
  end

  def age
    Time.current.year - year
  end
end

class Car < ApplicationRecord
  include Vehicular
  validates :doors, inclusion: { in: 2..5 }
end

class Motorcycle < ApplicationRecord
  include Vehicular
  validates :engine_cc, presence: true
end

class Boat < ApplicationRecord
  include Vehicular
  validates :length_feet, presence: true
end

# =============================================================================
# STI FACTORY PATTERN
# =============================================================================

class Vehicle < ApplicationRecord
  def self.build_by_type(type, **attributes)
    case type.to_s.downcase
    when "car" then Car.new(attributes)
    when "truck" then Truck.new(attributes)
    when "motorcycle" then Motorcycle.new(attributes)
    else raise ArgumentError, "Unknown vehicle type: #{type}"
    end
  end
end

# Usage
vehicle = Vehicle.build_by_type("car", make: "Honda", model: "Civic")
vehicle.class  # => Car

# =============================================================================
# QUERYING ACROSS STI HIERARCHY
# =============================================================================

# All vehicles of specific types
Vehicle.where(type: [Car.name, Truck.name])

# Using subclasses
Vehicle.where(type: Vehicle.subclasses.map(&:name))

# Exclude specific type
Vehicle.where.not(type: "Motorcycle")

# Polymorphic queries (if vehicle is used polymorphically elsewhere)
class Insurance < ApplicationRecord
  belongs_to :insurable, polymorphic: true
end

# Note: This saves "Vehicle" as insurable_type, not "Car"
# Be careful with STI + polymorphic associations
car = Car.find(1)
Insurance.create!(insurable: car)
# insurable_type = "Vehicle" (base class) - may cause issues

# Workaround: store full type
class Insurance < ApplicationRecord
  belongs_to :insurable, polymorphic: true

  before_save :store_actual_type

  private

  def store_actual_type
    self.insurable_type = insurable.class.name
  end
end

# =============================================================================
# TESTING STI MODELS
# =============================================================================

# FactoryBot
FactoryBot.define do
  factory :vehicle do
    make { "Generic" }
    model { "Model" }
    year { 2024 }

    factory :car, class: "Car" do
      make { "Toyota" }
      model { "Camry" }
      wheels { 4 }
    end

    factory :truck, class: "Truck" do
      make { "Ford" }
      model { "F-150" }
      wheels { 4 }
      cargo_capacity { 1500 }
    end

    factory :motorcycle, class: "Motorcycle" do
      make { "Harley-Davidson" }
      model { "Sportster" }
      wheels { 2 }
    end
  end
end

# RSpec
RSpec.describe Car do
  it "inherits from Vehicle" do
    expect(Car.superclass).to eq(Vehicle)
  end

  it "has correct type" do
    car = create(:car)
    expect(car.type).to eq("Car")
  end

  it "queries only cars" do
    create(:car)
    create(:truck)

    expect(Car.count).to eq(1)
    expect(Vehicle.count).to eq(2)
  end
end
