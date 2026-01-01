# MCP Server Reference

## Server Initialization

```ruby
MCP::Server.new(
  # Required
  name: "server_name",

  # Metadata
  version: "1.0.0",                    # Default: "0.1.0"
  description: "Server description",   # Protocol 2025-11-25+
  title: "Human-Readable Name",        # Protocol 2025-06-18+
  website_url: "https://example.com",  # Protocol 2025-06-18+
  instructions: "Usage instructions",  # Protocol 2025-03-26+

  # Components
  tools: [ToolClass1, ToolClass2],
  prompts: [PromptClass1],
  resources: [resource_instance],
  resource_templates: [template_instance],

  # Runtime
  server_context: { key: "value" },
  transport: transport_instance,

  # Configuration
  configuration: MCP::Configuration.new(...),
  capabilities: {                      # Override auto-detected
    tools: { listChanged: true },
    prompts: { listChanged: true },
    resources: { listChanged: true }
  }
)
```

## Configuration

```ruby
MCP::Configuration.new(
  protocol_version: "2025-11-25",      # Or: "2025-06-18", "2025-03-26", "2024-11-05"
  exception_reporter: ->(exception, server_context) { ... },
  instrumentation_callback: ->(data) { ... },
  validate_tool_call_arguments: true   # Default: true
)

# Global configuration
MCP.configure do |config|
  config.protocol_version = "2025-11-25"
  config.exception_reporter = ->(e, ctx) { ErrorTracker.report(e, ctx) }
  config.instrumentation_callback = ->(data) { StatsD.increment(data[:method]) }
end
```

### Instrumentation Data Keys

```ruby
{
  method: "tools/call",      # JSON-RPC method
  tool_name: "my_tool",      # For tools/call
  prompt_name: "my_prompt",  # For prompts/get
  resource_uri: "file://x",  # For resources/read
  error: :tool_not_found,    # Error symbol if failed
  duration: 0.123            # Seconds (auto-added)
}
```

## Handler Overrides

```ruby
# Replace default handlers
server.tools_list_handler do |params|
  [{ name: "custom", description: "Custom tool" }]
end

server.tools_call_handler do |params|
  MCP::Tool::Response.new([{ type: "text", text: "OK" }]).to_h
end

server.prompts_list_handler do |params|
  [{ name: "custom", description: "Custom prompt" }]
end

server.prompts_get_handler do |params|
  MCP::Prompt::Result.new(messages: [...]).to_h
end

server.resources_list_handler do |params|
  [{ uri: "file:///x", name: "x" }]
end

server.resources_read_handler do |params|
  { uri: params[:uri], mimeType: "text/plain", text: "Content" }
end

server.resources_templates_list_handler do |params|
  [{ uriTemplate: "file:///{id}", name: "template" }]
end
```

## Custom Methods

```ruby
# Define custom JSON-RPC method
server.define_custom_method(method_name: "custom/method") do |params|
  { result: params[:value] * 2 }  # Return value becomes result
end

# Notification method (return nil)
server.define_custom_method(method_name: "custom/notify") do |params|
  process_notification(params)
  nil  # No response sent
end
```

## Notifications

```ruby
# Requires: server.transport = transport
server.notify_tools_list_changed
server.notify_prompts_list_changed
server.notify_resources_list_changed
```

---

## See Also

### Related References
- **[Tools](tools.md)** - Tool definition DSL and response types
- **[Prompts](prompts.md)** - Prompt definition and content types
- **[Resources](resources.md)** - Resource and template definitions
- **[Transport](transport.md)** - STDIO and HTTP transport configuration
- **[Gotchas](gotchas.md)** - Configuration merging, notification quirks

### Related Examples
- **[`../examples/stdio_server.rb`](../examples/stdio_server.rb)** - Complete server with all components
- **[`../examples/http_server.rb`](../examples/http_server.rb)** - HTTP server with Rack
- **[`../examples/rails_integration.rb`](../examples/rails_integration.rb)** - Rails controller and routes
- **[`../examples/dynamic_tools.rb`](../examples/dynamic_tools.rb)** - Runtime registration with notifications
