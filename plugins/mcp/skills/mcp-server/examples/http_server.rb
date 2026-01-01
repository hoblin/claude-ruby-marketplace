#!/usr/bin/env ruby
# frozen_string_literal: true

# HTTP MCP Server with Rack
# Demonstrates: StreamableHTTP transport, configuration, logging, output_schema
#
# See: ../references/transport.md, ../references/server.md, ../references/tools.md
#
# Run: ruby http_server.rb
# Server starts on http://localhost:9292

require "mcp"
require "rack"
require "rackup"
require "json"
require "logger"

class WeatherTool < MCP::Tool
  description "Gets weather for a location"
  input_schema(
    properties: {
      location: { type: "string" },
      units: { type: "string", enum: %w[celsius fahrenheit] }
    },
    required: ["location"]
  )

  output_schema(
    properties: {
      temperature: { type: "number" },
      condition: { type: "string" }
    },
    required: %w[temperature condition]
  )

  annotations(read_only_hint: true, destructive_hint: false)

  class << self
    def call(location:, units: "celsius", server_context: nil)
      # Simulate API call
      data = { temperature: 22, condition: "sunny" }

      MCP::Tool::Response.new(
        [{ type: "text", text: data.to_json }],
        structured_content: data
      )
    end
  end
end

$logger = Logger.new($stdout)
$logger.level = Logger::INFO

config = MCP::Configuration.new(
  protocol_version: "2025-11-25",
  exception_reporter: ->(e, ctx) {
    $logger.error("MCP Error: #{e.message}")
    $logger.debug(ctx.inspect)
  },
  instrumentation_callback: ->(data) {
    $logger.info("MCP: #{data[:method]} (#{data[:duration]}s)")
  }
)

server = MCP::Server.new(
  name: "weather_server",
  version: "1.0.0",
  description: "Weather information server",
  tools: [WeatherTool],
  configuration: config
)

transport = MCP::Server::Transports::StreamableHTTPTransport.new(server)
server.transport = transport

app = proc do |env|
  request = Rack::Request.new(env)

  if request.post?
    body = request.body.read
    request.body.rewind
    $logger.debug("Request: #{body}")
  end

  response = transport.handle_request(request)
  $logger.debug("Response: #{response[2].first}") if response[2].respond_to?(:first)
  response
end

rack_app = Rack::Builder.new do
  use Rack::CommonLogger, $logger
  use Rack::ShowExceptions
  run app
end

puts "Starting MCP server on http://localhost:9292"
Rackup::Handler.get("puma").run(rack_app, Port: 9292, Host: "localhost")
