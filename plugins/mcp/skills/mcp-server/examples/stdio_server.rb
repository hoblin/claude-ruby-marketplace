#!/usr/bin/env ruby
# frozen_string_literal: true

# Complete STDIO MCP Server
# Demonstrates: Class-based tools, prompts, resources, dynamic tool definition
#
# See: ../references/tools.md, ../references/prompts.md, ../references/transport.md
#
# Run: ruby stdio_server.rb
# Then type JSON-RPC requests:
#   {"jsonrpc":"2.0","id":1,"method":"ping"}
#   {"jsonrpc":"2.0","id":2,"method":"tools/list"}
#   {"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"add","arguments":{"a":5,"b":3}}}

require "mcp"

class AddTool < MCP::Tool
  description "Adds two numbers together"
  input_schema(
    properties: {
      a: { type: "number" },
      b: { type: "number" }
    },
    required: %w[a b]
  )

  class << self
    def call(a:, b:, server_context: nil)
      MCP::Tool::Response.new([{
        type: "text",
        text: "#{a} + #{b} = #{a + b}"
      }])
    end
  end
end

class CodeReviewPrompt < MCP::Prompt
  description "Generates a code review prompt"
  arguments [
    MCP::Prompt::Argument.new(
      name: "code",
      description: "The code to review",
      required: true
    ),
    MCP::Prompt::Argument.new(
      name: "language",
      description: "Programming language",
      required: false
    )
  ]

  class << self
    def template(args, server_context:)
      lang = args[:language] || "unknown"
      MCP::Prompt::Result.new(
        description: "Code review request",
        messages: [
          MCP::Prompt::Message.new(
            role: "user",
            content: MCP::Content::Text.new(
              "Review this #{lang} code:\n\n```#{lang}\n#{args[:code]}\n```"
            )
          )
        ]
      )
    end
  end
end

config_resource = MCP::Resource.new(
  uri: "config://app",
  name: "app-config",
  description: "Application configuration",
  mime_type: "application/json"
)

server = MCP::Server.new(
  name: "example_server",
  version: "1.0.0",
  tools: [AddTool],
  prompts: [CodeReviewPrompt],
  resources: [config_resource]
)

# Dynamic tool example
server.define_tool(
  name: "echo",
  description: "Echoes input back",
  input_schema: {
    properties: { message: { type: "string" } },
    required: ["message"]
  }
) do |message:|
  MCP::Tool::Response.new([{ type: "text", text: message }])
end

# Resource handler
server.resources_read_handler do |params|
  case params[:uri]
  when "config://app"
    { uri: params[:uri], mimeType: "application/json", text: '{"env":"prod"}' }
  else
    { uri: params[:uri], mimeType: "text/plain", text: "Unknown resource" }
  end
end

transport = MCP::Server::Transports::StdioTransport.new(server)
transport.open
