# ActiveRecord Custom Validators Examples

# =============================================================================
# INLINE VALIDATION METHODS
# =============================================================================

class Invoice < ApplicationRecord
  validate :total_matches_line_items
  validate :due_date_in_future, on: :create
  validate :cannot_exceed_credit_limit

  private

  def total_matches_line_items
    return if line_items.empty?

    calculated = line_items.sum(&:amount)
    return if total == calculated

    errors.add(:total, "doesn't match line items sum (expected #{calculated})")
  end

  def due_date_in_future
    return if due_date.blank?
    return if due_date > Date.current

    errors.add(:due_date, "must be in the future")
  end

  def cannot_exceed_credit_limit
    return if customer.nil?
    return if total <= customer.available_credit

    errors.add(:total, "exceeds customer's available credit of #{customer.available_credit}")
  end
end

# =============================================================================
# EachValidator - ATTRIBUTE-LEVEL REUSABLE VALIDATOR
# =============================================================================

# app/validators/email_validator.rb
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank? && options[:allow_blank]

    unless URI::MailTo::EMAIL_REGEXP.match?(value)
      record.errors.add(attribute, options[:message] || "is not a valid email address")
    end
  end
end

# app/validators/phone_validator.rb
class PhoneValidator < ActiveModel::EachValidator
  PHONE_REGEX = /\A\+?[\d\s\-()]{10,}\z/

  def validate_each(record, attribute, value)
    return if value.blank? && options[:allow_blank]

    unless PHONE_REGEX.match?(value)
      record.errors.add(attribute, options[:message] || "is not a valid phone number")
    end

    # Additional format check for specific country
    if options[:country] == :us && value.present?
      unless value.gsub(/\D/, "").length == 10
        record.errors.add(attribute, "must be a 10-digit US phone number")
      end
    end
  end
end

# app/validators/url_validator.rb
class UrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank? && options[:allow_blank]

    begin
      uri = URI.parse(value)
      valid = uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      valid &&= uri.host.present?

      # Optional: require HTTPS
      if options[:https_only] && !uri.is_a?(URI::HTTPS)
        record.errors.add(attribute, "must use HTTPS")
        return
      end

      record.errors.add(attribute, options[:message] || "is not a valid URL") unless valid
    rescue URI::InvalidURIError
      record.errors.add(attribute, options[:message] || "is not a valid URL")
    end
  end
end

# Usage in models:
class User < ApplicationRecord
  validates :email, email: true
  validates :backup_email, email: { allow_blank: true }
  validates :phone, phone: { allow_blank: true }
  validates :mobile, phone: { country: :us }
  validates :website, url: { allow_blank: true }
  validates :api_endpoint, url: { https_only: true }
end

# =============================================================================
# VALIDATOR CLASS - RECORD-LEVEL VALIDATION
# =============================================================================

# app/validators/date_range_validator.rb
class DateRangeValidator < ActiveModel::Validator
  def validate(record)
    start_attr = options[:start] || :start_date
    end_attr = options[:end] || :end_date

    start_date = record.send(start_attr)
    end_date = record.send(end_attr)

    return if start_date.blank? || end_date.blank?

    if end_date <= start_date
      record.errors.add(end_attr, "must be after #{start_attr.to_s.humanize.downcase}")
    end

    # Optional: check maximum duration
    if options[:max_duration] && (end_date - start_date) > options[:max_duration]
      record.errors.add(end_attr, "cannot be more than #{options[:max_duration].inspect} after start")
    end
  end
end

# Usage:
class Event < ApplicationRecord
  validates_with DateRangeValidator
end

class Reservation < ApplicationRecord
  validates_with DateRangeValidator,
    start: :check_in,
    end: :check_out,
    max_duration: 30.days
end

# =============================================================================
# COMPLEX VALIDATOR WITH EXTERNAL DATA
# =============================================================================

# app/validators/profanity_validator.rb
class ProfanityValidator < ActiveModel::EachValidator
  PROFANITY_LIST_PATH = Rails.root.join("config", "profanity_list.txt")

  def validate_each(record, attribute, value)
    return if value.blank?

    profane_words = value.downcase.split(/\W+/) & profanity_list

    if profane_words.any?
      record.errors.add(attribute, options[:message] || "contains inappropriate language")
    end
  end

  private

  def profanity_list
    @profanity_list ||= File.read(PROFANITY_LIST_PATH).split("\n").map(&:strip).map(&:downcase)
  rescue Errno::ENOENT
    Rails.logger.warn("Profanity list not found at #{PROFANITY_LIST_PATH}")
    []
  end
end

# Usage:
class Comment < ApplicationRecord
  validates :body, profanity: true
  validates :title, profanity: { message: "must not contain bad words" }
end

# =============================================================================
# VALIDATOR WITH DATABASE LOOKUP
# =============================================================================

# app/validators/reserved_word_validator.rb
class ReservedWordValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    # Check against database table of reserved words
    if ReservedWord.exists?(word: value.downcase)
      record.errors.add(attribute, options[:message] || "is reserved and cannot be used")
    end

    # Also check hardcoded list
    if hardcoded_reserved.include?(value.downcase)
      record.errors.add(attribute, options[:message] || "is a system reserved word")
    end
  end

  private

  def hardcoded_reserved
    %w[admin root system api www mail ftp]
  end
end

# Usage:
class Organization < ApplicationRecord
  validates :subdomain, reserved_word: true
end

# =============================================================================
# VALIDATOR WITH COMPLEX BUSINESS LOGIC
# =============================================================================

# app/validators/business_hours_validator.rb
class BusinessHoursValidator < ActiveModel::Validator
  def validate(record)
    validate_no_overlaps(record)
    validate_within_business_hours(record)
    validate_minimum_duration(record)
  end

  private

  def validate_no_overlaps(record)
    return unless record.start_time && record.end_time

    overlapping = record.class.where.not(id: record.id)
      .where(resource_id: record.resource_id)
      .where(date: record.date)
      .where("start_time < ? AND end_time > ?", record.end_time, record.start_time)

    if overlapping.exists?
      record.errors.add(:base, "Booking overlaps with an existing reservation")
    end
  end

  def validate_within_business_hours(record)
    return unless record.start_time && record.end_time

    business_start = Time.zone.parse("09:00")
    business_end = Time.zone.parse("17:00")

    if record.start_time.seconds_since_midnight < business_start.seconds_since_midnight ||
       record.end_time.seconds_since_midnight > business_end.seconds_since_midnight
      record.errors.add(:base, "Booking must be within business hours (9 AM - 5 PM)")
    end
  end

  def validate_minimum_duration(record)
    return unless record.start_time && record.end_time

    min_duration = 30.minutes

    if (record.end_time - record.start_time) < min_duration
      record.errors.add(:base, "Booking must be at least 30 minutes")
    end
  end
end

# Usage:
class Booking < ApplicationRecord
  validates_with BusinessHoursValidator
end

# =============================================================================
# COMPOSITION - COMBINING VALIDATORS
# =============================================================================

# app/validators/strong_password_validator.rb
class StrongPasswordValidator < ActiveModel::EachValidator
  MIN_LENGTH = 8
  MAX_LENGTH = 72

  REQUIREMENTS = {
    lowercase: /[a-z]/,
    uppercase: /[A-Z]/,
    digit: /\d/,
    special: /[!@#$%^&*(),.?":{}|<>]/
  }.freeze

  def validate_each(record, attribute, value)
    return if value.blank? && options[:allow_blank]

    validate_length(record, attribute, value)
    validate_complexity(record, attribute, value)
    validate_not_common(record, attribute, value)
    validate_not_user_data(record, attribute, value)
  end

  private

  def validate_length(record, attribute, value)
    if value.length < MIN_LENGTH
      record.errors.add(attribute, "must be at least #{MIN_LENGTH} characters")
    end

    if value.length > MAX_LENGTH
      record.errors.add(attribute, "must be at most #{MAX_LENGTH} characters")
    end
  end

  def validate_complexity(record, attribute, value)
    required = options[:require] || REQUIREMENTS.keys

    required.each do |requirement|
      regex = REQUIREMENTS[requirement]
      unless value.match?(regex)
        record.errors.add(attribute, "must contain at least one #{requirement.to_s.humanize.downcase}")
      end
    end
  end

  def validate_not_common(record, attribute, value)
    common_passwords = %w[password 123456 qwerty letmein]

    if common_passwords.include?(value.downcase)
      record.errors.add(attribute, "is too common")
    end
  end

  def validate_not_user_data(record, attribute, value)
    user_data = [
      record.try(:email)&.split("@")&.first,
      record.try(:username),
      record.try(:name)&.downcase
    ].compact

    if user_data.any? { |data| value.downcase.include?(data.to_s.downcase) }
      record.errors.add(attribute, "cannot contain your personal information")
    end
  end
end

# Usage:
class User < ApplicationRecord
  validates :password, strong_password: true, on: :create
  validates :password, strong_password: { allow_blank: true }, on: :update

  # Or with custom requirements
  validates :admin_password, strong_password: {
    require: [:lowercase, :uppercase, :digit, :special]
  }
end

# =============================================================================
# PRIVATE VALIDATION METHODS (BEST PRACTICE)
# =============================================================================

class Transaction < ApplicationRecord
  validate :validate_amount
  validate :validate_balance
  validate :validate_daily_limit

  private  # All custom validation methods should be private

  def validate_amount
    return if amount.blank?

    errors.add(:amount, "must be positive") if amount <= 0
    errors.add(:amount, "exceeds maximum single transaction") if amount > 10_000
  end

  def validate_balance
    return if account.nil? || amount.nil?

    if amount > account.balance
      errors.add(:amount, "exceeds available balance of #{account.balance}")
    end
  end

  def validate_daily_limit
    return if account.nil? || amount.nil?

    daily_total = account.transactions.where(created_at: Date.current.all_day).sum(:amount)

    if (daily_total + amount) > account.daily_limit
      remaining = account.daily_limit - daily_total
      errors.add(:amount, "would exceed daily limit. Remaining: #{remaining}")
    end
  end
end
