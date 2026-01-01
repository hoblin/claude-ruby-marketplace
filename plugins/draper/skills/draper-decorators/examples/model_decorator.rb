# app/decorators/post_decorator.rb
#
# Decorator for Post model presentation logic.
#
# @example Basic usage
#   @post = Post.find(params[:id]).decorate
#   @post.formatted_title  # => "My Post Title"
#
# @example With context
#   @post = Post.find(params[:id]).decorate(context: { current_user: current_user })
#   @post.edit_link  # => renders link only if user can edit
#
class PostDecorator < ApplicationDecorator
  delegate_all

  # Auto-decorate associations
  decorates_association :author
  decorates_association :comments
  decorates_association :category

  # Delegate specific methods from associated decorators
  delegate :full_name, to: :author, prefix: true

  # Formatted title with optional truncation
  #
  # @param max_length [Integer, nil] optional max length
  # @return [String] formatted title
  def formatted_title(max_length: nil)
    result = title.titleize
    max_length ? truncated_text(result, length: max_length) : result
  end

  # Publication status badge
  #
  # @return [String] HTML badge element
  def status_badge
    if published?
      badge("Published", type: :success)
    else
      badge("Draft", type: :warning)
    end
  end

  # Formatted publication date
  #
  # @return [String] date string or "Not published"
  def publication_date
    return "Not published" unless published_at

    formatted_date(published_at)
  end

  # Reading time estimate
  #
  # @return [String] reading time
  def reading_time
    words_per_minute = 200
    words = body.to_s.split.size
    minutes = (words / words_per_minute.to_f).ceil

    "#{minutes} min read"
  end

  # Post excerpt for listings
  #
  # @param length [Integer] excerpt length
  # @return [String] truncated body
  def excerpt(length: 200)
    truncated_text(body, length:)
  end

  # Edit link (context-aware)
  #
  # @return [String, nil] edit link HTML or nil
  def edit_link
    return unless can_edit?

    h.link_to("Edit", h.edit_post_path(object), class: "btn btn-sm btn-secondary")
  end

  # Delete link with confirmation
  #
  # @return [String, nil] delete link HTML or nil
  def delete_link
    return unless can_delete?

    h.link_to(
      "Delete",
      h.post_path(object),
      method: :delete,
      data: { confirm: "Are you sure?" },
      class: "btn btn-sm btn-danger"
    )
  end

  # Action buttons group
  #
  # @return [String] HTML with action buttons
  def action_buttons
    buttons = [edit_link, delete_link].compact
    return if buttons.empty?

    h.content_tag(:div, class: "btn-group") do
      h.safe_join(buttons)
    end
  end

  # Author info line
  #
  # @return [String] HTML with author avatar and name
  def author_info
    h.content_tag(:div, class: "author-info") do
      h.safe_join([
        author.avatar_tag(size: :small),
        h.content_tag(:span, author_full_name, class: "author-name"),
        h.content_tag(:span, " · ", class: "separator"),
        h.content_tag(:span, time_ago(created_at), class: "post-date")
      ])
    end
  end

  # Meta information (category, comments count)
  #
  # @return [String] HTML meta line
  def meta_info
    parts = []
    parts << h.link_to(category.name, h.category_path(category)) if category
    parts << "#{comments.size} comments"

    h.content_tag(:div, h.safe_join(parts, " · "), class: "post-meta")
  end

  private

  # Check if current user can edit
  #
  # @return [Boolean]
  def can_edit?
    return false unless context[:current_user]

    context[:current_user].can?(:edit, object)
  end

  # Check if current user can delete
  #
  # @return [Boolean]
  def can_delete?
    return false unless context[:current_user]

    context[:current_user].can?(:delete, object)
  end
end
