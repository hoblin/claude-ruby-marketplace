# frozen_string_literal: true

# Dynamic Tool Registration
# Demonstrates: server.define_tool, notify_tools_list_changed, plugin pattern
#
# See: ../references/server.md, ../references/tools.md

require "mcp"

class PluginManager
  def initialize(server)
    @server = server
  end

  def load_plugin(name, &block)
    @server.define_tool(
      name: "plugin_#{name}",
      description: "Plugin: #{name}",
      input_schema: { properties: { input: { type: "string" } } }
    ) do |input:, server_context:|
      result = block.call(input, server_context)
      MCP::Tool::Response.new([{ type: "text", text: result.to_s }])
    end

    @server.notify_tools_list_changed
  end
end

# Usage
server = MCP::Server.new(name: "plugin_server", tools: [])
transport = MCP::Server::Transports::StreamableHTTPTransport.new(server)
server.transport = transport

manager = PluginManager.new(server)
manager.load_plugin("uppercase") { |input, _| input.upcase }
manager.load_plugin("reverse") { |input, _| input.reverse }
