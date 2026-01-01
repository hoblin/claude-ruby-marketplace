# frozen_string_literal: true

# File Manager Tool with sandboxed operations
# Demonstrates: Security patterns, annotations, error responses, tool_name
#
# See: ../references/tools.md, ../references/gotchas.md

require "mcp"
require "fileutils"

class FileManagerTool < MCP::Tool
  tool_name "file_manager"
  description "Manages files in a sandboxed directory"

  input_schema(
    properties: {
      action: { type: "string", enum: %w[read write list delete] },
      path: { type: "string" },
      content: { type: "string" }
    },
    required: %w[action path]
  )

  annotations(
    destructive_hint: true,
    idempotent_hint: false,
    read_only_hint: false
  )

  SANDBOX_DIR = "/tmp/mcp_sandbox"

  class << self
    def call(action:, path:, content: nil, server_context: nil)
      full_path = File.join(SANDBOX_DIR, path)

      # Security: Ensure path is within sandbox
      unless full_path.start_with?(SANDBOX_DIR)
        return error_response("Path traversal not allowed")
      end

      case action
      when "read"  then read_file(full_path)
      when "write" then write_file(full_path, content)
      when "list"  then list_directory(full_path)
      when "delete" then delete_file(full_path)
      else error_response("Unknown action: #{action}")
      end
    end

    private

    def read_file(path)
      return error_response("File not found") unless File.exist?(path)

      MCP::Tool::Response.new([{ type: "text", text: File.read(path) }])
    end

    def write_file(path, content)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
      MCP::Tool::Response.new([{ type: "text", text: "Written #{content.bytesize} bytes" }])
    end

    def list_directory(path)
      return error_response("Directory not found") unless Dir.exist?(path)

      files = Dir.entries(path).reject { |f| f.start_with?(".") }
      MCP::Tool::Response.new(
        [{ type: "text", text: files.join("\n") }],
        structured_content: files
      )
    end

    def delete_file(path)
      return error_response("File not found") unless File.exist?(path)

      File.delete(path)
      MCP::Tool::Response.new([{ type: "text", text: "Deleted" }])
    end

    def error_response(message)
      MCP::Tool::Response.new([{ type: "text", text: message }], error: true)
    end
  end
end
