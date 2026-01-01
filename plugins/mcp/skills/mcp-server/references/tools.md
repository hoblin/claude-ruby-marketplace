# MCP Tools Reference

## Tool Definition

Three patterns for defining tools:

### Class-Based (recommended)

```ruby
class MyTool < MCP::Tool
  # Name (optional - defaults to snake_case of class name)
  tool_name "custom_name"

  # Metadata
  title "Human Title"
  description "What this tool does"

  # Input validation (JSON Schema)
  input_schema(
    type: "object",          # Default if omitted
    properties: {
      message: { type: "string", minLength: 1 },
      count: { type: "integer", minimum: 0, maximum: 100 },
      options: {
        type: "object",
        properties: { verbose: { type: "boolean" } }
      },
      tags: {
        type: "array",
        items: { type: "string" }
      }
    },
    required: ["message"],
    additionalProperties: false  # Strict mode
  )

  # Output documentation (optional)
  output_schema(
    properties: {
      result: { type: "string" },
      success: { type: "boolean" }
    },
    required: ["result", "success"]
  )

  # Behavior hints (protocol 2025-03-26+)
  annotations(
    read_only_hint: false,     # Default: false
    destructive_hint: true,    # Default: true
    idempotent_hint: false,    # Default: false
    open_world_hint: true,     # Default: true
    title: "Tool Title"
  )

  # Custom metadata
  meta(version: "1.0", author: "Team")

  # Implementation
  class << self
    def call(message:, count: 1, options: {}, server_context: nil)
      MCP::Tool::Response.new([
        { type: "text", text: "Result" }
      ])
    end
  end
end
```

### Block-Based (Tool.define)

```ruby
tool = MCP::Tool.define(
  name: "tool_name",
  title: "Tool Title",
  description: "Description",
  input_schema: { properties: { x: { type: "string" } } },
  output_schema: { properties: { y: { type: "string" } } },
  annotations: { read_only_hint: true },
  meta: { version: "1.0" }
) do |x:, server_context: nil|
  MCP::Tool::Response.new([{ type: "text", text: x }])
end
```

### Dynamic (server.define_tool)

```ruby
server.define_tool(
  name: "dynamic_tool",
  description: "Added at runtime",
  input_schema: { properties: { arg: { type: "string" } } }
) do |arg:, server_context:|
  MCP::Tool::Response.new([{ type: "text", text: arg }])
end
```

## Tool Response

```ruby
MCP::Tool::Response.new(
  content,                    # Array of content items
  error: false,              # Mark as error without exception
  structured_content: nil    # Machine-readable data
)

# Content item types
{ type: "text", text: "..." }
{ type: "image", data: "base64...", mimeType: "image/png" }
{ type: "resource", resource: { uri: "...", ... } }
```

## Schema Objects

```ruby
# As Hash (auto-converted)
input_schema({ properties: { x: { type: "string" } } })

# As InputSchema object
input_schema MCP::Tool::InputSchema.new(
  properties: { x: { type: "string" } },
  required: ["x"]
)

# Schema methods
schema.to_h
schema.missing_required_arguments({ x: "value" })  # => []
schema.validate_arguments({ x: 123 })  # Raises ValidationError
```

**Constraints:**
- `$ref` is NOT allowed (raises ArgumentError)
- Type defaults to "object" if not specified
- Required fields auto-convert symbols to strings

---

## See Also

### Related References
- **[Server](server.md)** - Dynamic tool registration with `server.define_tool`
- **[Gotchas](gotchas.md)** - Schema quirks, tool name derivation, validation flow

### Related Examples
- **[`../examples/stdio_server.rb`](../examples/stdio_server.rb)** - Class-based and dynamic tool definitions
- **[`../examples/file_manager_tool.rb`](../examples/file_manager_tool.rb)** - Complex tool with security patterns
- **[`../examples/dynamic_tools.rb`](../examples/dynamic_tools.rb)** - Runtime tool registration
