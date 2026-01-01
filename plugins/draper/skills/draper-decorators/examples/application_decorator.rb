# app/decorators/application_decorator.rb
#
# Base decorator with shared presentation methods.
# All decorators should inherit from this class.
#
class ApplicationDecorator < Draper::Decorator
  # Common date formatting
  #
  # @param date [Time, Date, nil] the date to format
  # @param format [Symbol] the I18n format key
  # @return [String] formatted date or "N/A"
  def formatted_date(date = created_at, format: :long)
    return "N/A" if date.blank?

    h.l(date, format:)
  end

  # Relative time (e.g., "2 hours ago")
  #
  # @param time [Time] the time to format
  # @return [String] relative time string
  def time_ago(time = created_at)
    "#{h.time_ago_in_words(time)} ago"
  end

  # Currency formatting
  #
  # @param amount [Numeric, nil] the amount to format
  # @return [String] formatted currency
  def formatted_currency(amount)
    return "$0.00" if amount.blank?

    h.number_to_currency(amount)
  end

  # Truncate text with word boundary
  #
  # @param text [String] text to truncate
  # @param length [Integer] maximum length
  # @return [String] truncated text
  def truncated_text(text, length: 100)
    h.truncate(text.to_s, length:, separator: " ")
  end

  # Safe boolean display
  #
  # @param value [Boolean] the boolean to display
  # @return [String] "Yes" or "No"
  def boolean_display(value)
    value ? "Yes" : "No"
  end

  # Status badge helper
  #
  # @param text [String] badge text
  # @param type [Symbol] badge type (:success, :warning, :danger, :info, :secondary)
  # @return [String] HTML span element
  def badge(text, type: :secondary)
    h.content_tag(:span, text, class: "badge badge-#{type}")
  end
end
