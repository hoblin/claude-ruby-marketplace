# MCP Ruby SDK - Gotchas and Error Handling

## Tricky Behaviors

### Schema Transformation

**Symbol keys become string keys:**
```ruby
input_schema({ required: [:message] })
# Stored as: { required: ["message"] }
```

### JSON-RPC ID Validation

**IDs are validated against alphanumeric pattern:**
```ruby
id: "<script>alert('xss')</script>"  # REJECTED
id: "request-123_ABC"  # OK
id: "550e8400-e29b-41d4-a716-446655440000"  # OK (UUID)
```

**Invalid IDs in error responses become nil:**
```ruby
error_response(id: "<invalid>")
# Returns: { ..., id: nil, ... }
```

### Batch Requests

**Single-item batch responses are unwrapped:**
```ruby
# Request: [{ ... }] (array with one item)
# Response: { ... } (single object, NOT array)

# Request: [{ ... }, { ... }] (two items)
# Response: [{ ... }, { ... }] (array)
```

### Server Context Detection

**Framework inspects method signature:**
```ruby
# These receive server_context:
def call(message:, server_context: nil)  # Detected
def call(message:, server_context:)      # Detected
def call(**kwargs)                        # Detected (keyrest)

# This doesn't:
def call(message:)  # NOT detected
```

### Tool Name Derivation

**Class names auto-convert to snake_case:**
```ruby
class MyCustomTool < MCP::Tool; end
# Name: "my_custom_tool"

class HTMLParser < MCP::Tool; end
# Name: "html_parser"
```

### Notifications

**No response for notifications (requests without id):**
```ruby
server.handle({ jsonrpc: "2.0", method: "ping" })  # => nil
```

**Silent no-op if no transport:**
```ruby
server.notify_tools_list_changed  # Does nothing if transport not set
```

### StreamableHTTP Transport

**GET only works in stateful mode:**
```ruby
# Stateless: GET returns 405
# Stateful: GET sets up SSE stream
```

**Session cleanup on stream errors:**
```ruby
# IOError/EPIPE automatically cleans up session
```

### Configuration Merging

**Non-nil values from other config take precedence:**
```ruby
config1 = Configuration.new(protocol_version: "2025-03-26")
config2 = Configuration.new  # Uses default

merged = config1.merge(config2)
# Uses config1's version (config2 didn't set explicitly)
```

### Validation Flow

**Two-step validation:**
```ruby
# Step 1: Check required fields (always)
# Step 2: JSON Schema validation (if validate_tool_call_arguments = true)
```

---

## Error Handling

### Error Classes

```ruby
MCP::Server::RequestHandlerError      # General request errors
  # error_type: :internal_error, :tool_not_found, :prompt_not_found,
  #             :missing_required_arguments, :invalid_schema

MCP::Server::MethodAlreadyDefinedError  # Duplicate custom method
MCP::Server::ToolNotUnique              # Duplicate tool names
MCP::Tool::InputSchema::ValidationError  # Schema validation failed
MCP::Methods::MissingRequiredCapabilityError  # Capability not supported
```

### JSON-RPC Error Codes

```ruby
PARSE_ERROR = -32700       # Invalid JSON
INVALID_REQUEST = -32600   # Malformed request
METHOD_NOT_FOUND = -32601  # Method doesn't exist
INVALID_PARAMS = -32602    # Invalid parameters
INTERNAL_ERROR = -32603    # Server error
```

### Tool Errors vs JSON-RPC Errors

```ruby
# Tool errors (business logic) - return response with isError: true
{ content: [...], isError: true }

# JSON-RPC errors (protocol) - return error object
{ jsonrpc: "2.0", id: 1, error: { code: -32600, ... } }
```

### Client Error Handling

```ruby
client.call_tool(tool:, arguments:)
rescue MCP::Client::RequestHandlerError => e
  case e.error_type
  when :bad_request          # 400
  when :unauthorized         # 401
  when :forbidden            # 403
  when :not_found            # 404
  when :unprocessable_entity # 422
  when :internal_error       # Other
  end
end
```

### Transport Error Handling

**StdioTransport catches Interrupt:**
```ruby
# Ctrl-C exits with status 130 (SIGINT)
```

**StreamableHTTP handles stream errors:**
```ruby
# IOError/EPIPE caught, session cleaned up, returns false
```

---

## See Also

### Related References
- **[Tools](tools.md)** - Schema definition and validation
- **[Server](server.md)** - Configuration and notifications
- **[Transport](transport.md)** - Transport-specific behaviors

### Related Examples
- **[`../examples/stdio_server.rb`](../examples/stdio_server.rb)** - Basic patterns avoiding common pitfalls
- **[`../examples/http_server.rb`](../examples/http_server.rb)** - HTTP error handling
