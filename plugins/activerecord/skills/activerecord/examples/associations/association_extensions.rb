# Association Extension Examples
# Adding custom methods to association proxies

# ============================================
# Inline Extension
# ============================================

class Project < ApplicationRecord
  has_many :tasks do
    # Filter methods
    def active
      where(status: "active")
    end

    def completed
      where(status: "completed")
    end

    def overdue
      active.where("due_date < ?", Date.current)
    end

    # Calculation methods
    def total_hours
      sum(:estimated_hours)
    end

    def completion_percentage
      return 0 if empty?

      (completed.count.to_f / count * 100).round(2)
    end

    # Creation helpers
    def create_milestone!(name, due_date)
      create!(name:, due_date:, priority: :high, milestone: true)
    end

    # Access owner via proxy_association
    def recent_for_owner
      where("created_at > ?", proxy_association.owner.created_at)
    end
  end
end

# Usage
project = Project.find(1)
project.tasks.active
project.tasks.overdue.count
project.tasks.total_hours
project.tasks.completion_percentage
project.tasks.create_milestone!("Launch", 1.month.from_now)

# ============================================
# Shared Extension Module
# ============================================

module StatusFilter
  def active
    where(status: "active")
  end

  def completed
    where(status: "completed")
  end

  def pending
    where(status: "pending")
  end

  def by_status(status)
    where(status:)
  end
end

module Orderable
  def by_priority
    order(priority: :desc)
  end

  def by_recent
    order(created_at: :desc)
  end

  def by_due_date
    order(due_date: :asc)
  end
end

class Project < ApplicationRecord
  has_many :tasks, -> { extending StatusFilter, Orderable }
  has_many :issues, -> { extending StatusFilter, Orderable }
end

class Team < ApplicationRecord
  has_many :members, -> { extending StatusFilter }
end

# Usage
project.tasks.active.by_priority
project.issues.pending.by_due_date
team.members.active

# ============================================
# Extension with Scopes
# ============================================

class Author < ApplicationRecord
  has_many :books, -> { order(published_at: :desc) } do
    def fiction
      where(genre: "fiction")
    end

    def nonfiction
      where(genre: "nonfiction")
    end

    def bestsellers
      where(bestseller: true)
    end

    def published_in(year)
      where("EXTRACT(YEAR FROM published_at) = ?", year)
    end

    def search(query)
      where("title ILIKE ?", "%#{query}%")
    end
  end
end

# Chain extensions with other query methods
author.books.fiction.bestsellers
author.books.nonfiction.published_in(2024)
author.books.search("ruby").limit(10)

# ============================================
# Extension Accessing Owner
# ============================================

class User < ApplicationRecord
  has_many :notifications do
    def unread
      where(read_at: nil)
    end

    def mark_all_read!
      update_all(read_at: Time.current)
    end

    def for_past_week
      where("created_at > ?", 1.week.ago)
    end

    # Access the user via proxy_association.owner
    def summary
      owner = proxy_association.owner
      {
        total: count,
        unread: unread.count,
        user_name: owner.name
      }
    end
  end
end

# Usage
user.notifications.unread.count
user.notifications.mark_all_read!
user.notifications.summary
# => { total: 42, unread: 5, user_name: "Alice" }

# ============================================
# Extension for Through Associations
# ============================================

class Doctor < ApplicationRecord
  has_many :appointments
  has_many :patients, through: :appointments do
    def with_recent_visit
      where("appointments.scheduled_at > ?", 6.months.ago)
    end

    def needing_followup
      joins(:appointments)
        .where(appointments: { followup_needed: true })
        .distinct
    end
  end
end

# Usage
doctor.patients.with_recent_visit
doctor.patients.needing_followup.count

# ============================================
# Real-World Example: Versioned Documents
# ============================================

class Document < ApplicationRecord
  has_many :versions, -> { order(version_number: :desc) } do
    def latest
      first
    end

    def published
      where(published: true)
    end

    def latest_published
      published.first
    end

    def diff(v1, v2)
      # Return diff between two versions
      version1 = find_by(version_number: v1)
      version2 = find_by(version_number: v2)
      # Implementation...
    end

    def create_new_version!(content, author:)
      last_number = maximum(:version_number) || 0
      create!(
        content:,
        author:,
        version_number: last_number + 1,
        created_at: Time.current
      )
    end
  end
end

# Usage
doc.versions.latest
doc.versions.published.count
doc.versions.create_new_version!("Updated content", author: current_user)

# ============================================
# Extension vs Scope Decision
# ============================================

# Use SCOPE when:
# - Query is useful globally (not just via association)
# - Simple filtering/ordering
# - Used in multiple associations

class Task < ApplicationRecord
  scope :active, -> { where(status: "active") }
  scope :by_priority, -> { order(priority: :desc) }
end

# Use EXTENSION when:
# - Query only makes sense in association context
# - Need access to owner (proxy_association.owner)
# - Doing mutations (mark_all_read!, etc.)
# - Complex business logic specific to relationship

class Project < ApplicationRecord
  has_many :tasks do
    # Makes sense only in project context
    def critical_path
      # Complex calculation involving project data
      owner = proxy_association.owner
      active.where("due_date <= ?", owner.deadline)
            .order(priority: :desc)
    end
  end
end

# ============================================
# Testing Extensions
# ============================================

# spec/models/project_spec.rb
RSpec.describe Project do
  describe "tasks extension" do
    let(:project) { create(:project) }
    let!(:active_task) { create(:task, project:, status: "active") }
    let!(:completed_task) { create(:task, project:, status: "completed") }

    describe "#active" do
      it "returns only active tasks" do
        expect(project.tasks.active).to contain_exactly(active_task)
      end
    end

    describe "#completion_percentage" do
      it "calculates correct percentage" do
        expect(project.tasks.completion_percentage).to eq(50.0)
      end

      it "returns 0 for empty association" do
        empty_project = create(:project)
        expect(empty_project.tasks.completion_percentage).to eq(0)
      end
    end
  end
end
