#!/usr/bin/env ruby
# frozen_string_literal: true

# SSE Streaming Client
# Demonstrates: SSE connections, session management, real-time notifications
#
# See: ../references/transport.md, ../references/gotchas.md

require "net/http"
require "json"

class MCPStreamingClient
  def initialize(base_url)
    @base_url = base_url
    @session_id = nil
  end

  def connect
    response = post_request("initialize", {})
    @session_id = response["Mcp-Session-Id"]

    @sse_thread = Thread.new { listen_sse }
    sleep(0.5)
  end

  def call_tool(name, arguments)
    post_request("tools/call", { name:, arguments: })
  end

  def disconnect
    @sse_thread&.kill
    delete_request if @session_id
    @session_id = nil
  end

  private

  def post_request(method, params)
    uri = URI(@base_url)
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(uri.path.empty? ? "/" : uri.path)
    request["Content-Type"] = "application/json"
    request["Mcp-Session-Id"] = @session_id if @session_id

    request.body = {
      jsonrpc: "2.0",
      method:,
      params:,
      id: rand(10000)
    }.to_json

    response = http.request(request)
    @session_id ||= response["Mcp-Session-Id"]

    JSON.parse(response.body)
  end

  def listen_sse
    uri = URI(@base_url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new(uri)
      request["Mcp-Session-Id"] = @session_id
      request["Accept"] = "text/event-stream"

      http.request(request) do |response|
        response.read_body do |chunk|
          chunk.split("\n").each do |line|
            next unless line.start_with?("data: ")

            data = JSON.parse(line[6..])
            puts "SSE Event: #{data['method']}"
          end
        end
      end
    end
  rescue StandardError => e
    puts "SSE Error: #{e.message}"
  end

  def delete_request
    uri = URI(@base_url)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Delete.new(uri.path.empty? ? "/" : uri.path)
    request["Mcp-Session-Id"] = @session_id
    http.request(request)
  end
end

# Usage
client = MCPStreamingClient.new("http://localhost:9292")
client.connect
result = client.call_tool("echo", { message: "Hello!" })
puts result
client.disconnect
