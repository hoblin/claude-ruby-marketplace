# frozen_string_literal: true

# Rails MCP Integration
# Demonstrates: server_context with auth, configuration in initializer, permission checks
#
# See: ../references/server.md, ../references/transport.md, ../references/tools.md
#
# Add these files to your Rails application

# config/routes.rb
Rails.application.routes.draw do
  post "/mcp", to: "mcp#handle"
end

# app/controllers/mcp_controller.rb
class McpController < ApplicationController
  skip_before_action :verify_authenticity_token

  def handle
    server = build_server
    response = server.handle_json(request.body.read)
    render json: response
  end

  private

  def build_server
    MCP::Server.new(
      name: "rails_mcp",
      version: Rails.application.config.version,
      tools: [
        UserSearchTool,
        CreateRecordTool,
        DatabaseQueryTool
      ],
      server_context: {
        user_id: current_user&.id,
        request_id: request.uuid,
        permissions: current_user&.permissions || []
      },
      configuration: Rails.application.config.mcp_configuration
    )
  end
end

# config/initializers/mcp.rb
Rails.application.config.mcp_configuration = MCP::Configuration.new(
  protocol_version: "2025-11-25",
  exception_reporter: ->(e, ctx) {
    Rails.logger.error("MCP Error: #{e.message}")
    Bugsnag.notify(e) { |r| r.add_metadata(:mcp, ctx) }
  },
  instrumentation_callback: ->(data) {
    ActiveSupport::Notifications.instrument("mcp.request", data)
  }
)

# app/tools/user_search_tool.rb
class UserSearchTool < MCP::Tool
  description "Searches for users by name or email"
  input_schema(
    properties: {
      query: { type: "string", minLength: 2 },
      limit: { type: "integer", minimum: 1, maximum: 100 }
    },
    required: ["query"]
  )

  class << self
    def call(query:, limit: 10, server_context:)
      unless server_context[:permissions].include?("users:read")
        return MCP::Tool::Response.new(
          [{ type: "text", text: "Permission denied" }],
          error: true
        )
      end

      users = User.where("name ILIKE ? OR email ILIKE ?", "%#{query}%", "%#{query}%")
                  .limit(limit)
                  .select(:id, :name, :email)

      MCP::Tool::Response.new(
        [{ type: "text", text: users.to_json }],
        structured_content: users.as_json
      )
    end
  end
end
