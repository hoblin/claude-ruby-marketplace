#!/usr/bin/env ruby
# frozen_string_literal: true

# HTTP Client Example
# Demonstrates: MCP::Client, HTTP transport, tool/prompt discovery and invocation
#
# See: ../references/transport.md

require "mcp"

# Create HTTP transport
http = MCP::Client::HTTP.new(
  url: "http://localhost:9292",
  headers: { "Authorization" => "Bearer token123" }
)

client = MCP::Client.new(transport: http)

# List tools
tools = client.tools
puts "Available tools:"
tools.each do |tool|
  puts "  - #{tool.name}: #{tool.description}"
end

# Call a tool
if (weather_tool = tools.find { |t| t.name == "weather" })
  result = client.call_tool(
    tool: weather_tool,
    arguments: { location: "London", units: "celsius" }
  )
  puts "Weather: #{result.dig('result', 'content', 0, 'text')}"
end

# List prompts
prompts = client.prompts
prompts.each do |prompt|
  puts "Prompt: #{prompt['name']}"
end

# Get a prompt
if prompts.any?
  prompt_result = client.get_prompt(
    name: prompts.first["name"],
    arguments: { code: "puts 'hello'" }
  )
  puts "Messages: #{prompt_result['messages'].length}"
end
