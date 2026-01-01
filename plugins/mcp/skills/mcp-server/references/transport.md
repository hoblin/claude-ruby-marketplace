# MCP Transport Reference

## Transport Configuration

### StdioTransport

```ruby
transport = MCP::Server::Transports::StdioTransport.new(server)
transport.open   # Blocking loop
transport.close  # Signal stop
transport.send_response({ jsonrpc: "2.0", result: {} })
transport.send_notification("method", { key: "value" })
```

### StreamableHTTPTransport

```ruby
transport = MCP::Server::Transports::StreamableHTTPTransport.new(
  server,
  stateless: false  # Default: false (session-based)
)

# Link to server for notifications
server.transport = transport

# Handle Rack requests
response = transport.handle_request(rack_request)
# Returns: [status, headers, body]

# Send notifications
transport.send_notification("method", params, session_id: id)  # Specific session
transport.send_notification("method", params)  # Broadcast to all
```

## Request Handling

```ruby
# Handle Hash request
response = server.handle({
  jsonrpc: "2.0",
  method: "tools/call",
  params: { name: "my_tool", arguments: { x: 1 } },
  id: 1
})

# Handle JSON string
json_response = server.handle_json('{"jsonrpc":"2.0",...}')
```

## Protocol Methods

```ruby
# Core methods
"initialize"
"ping"
"tools/list"
"tools/call"
"prompts/list"
"prompts/get"
"resources/list"
"resources/read"
"resources/templates/list"

# Notifications (no response)
"notifications/initialized"
"notifications/tools/list_changed"
"notifications/prompts/list_changed"
"notifications/resources/list_changed"
```

## Error Classes

```ruby
MCP::Server::RequestHandlerError      # General request errors
MCP::Server::MethodAlreadyDefinedError  # Duplicate custom method
MCP::Server::ToolNotUnique            # Duplicate tool names
MCP::Tool::InputSchema::ValidationError  # Schema validation failed
MCP::Tool::OutputSchema::ValidationError  # Output validation failed
MCP::Methods::MissingRequiredCapabilityError  # Capability not supported
```

## Protocol Versions

| Version | Features Added |
|---------|----------------|
| 2024-11-05 | Base protocol |
| 2025-03-26 | `instructions`, `annotations`, `title` (server) |
| 2025-06-18 | `title`, `website_url` |
| 2025-11-25 | `description` (latest stable) |

---

## See Also

### Related References
- **[Server](server.md)** - Server initialization and `server.transport` linking
- **[Gotchas](gotchas.md)** - StreamableHTTP quirks, notification behavior, error handling

### Related Examples
- **[`../examples/stdio_server.rb`](../examples/stdio_server.rb)** - STDIO transport usage
- **[`../examples/http_server.rb`](../examples/http_server.rb)** - Streamable HTTP with Rack
- **[`../examples/rails_integration.rb`](../examples/rails_integration.rb)** - HTTP transport in Rails
- **[`../examples/http_client.rb`](../examples/http_client.rb)** - Client connecting to HTTP server
- **[`../examples/streaming_client.rb`](../examples/streaming_client.rb)** - SSE streaming client
