# MCP Resources Reference

## Resource Definition

```ruby
# Static resource
MCP::Resource.new(
  uri: "file:///path/to/file",
  name: "resource-name",
  title: "Resource Title",      # Optional
  description: "Description",   # Optional
  mime_type: "text/plain"       # Optional
)

# Resource template (dynamic URIs)
MCP::ResourceTemplate.new(
  uri_template: "file:///{path}",  # RFC 6570
  name: "template-name",
  title: "Template Title",
  description: "Description",
  mime_type: "text/plain"
)
```

## Resource Contents

```ruby
# Text content
MCP::Resource::TextContents.new(
  text: "File content",
  uri: "file:///path",
  mime_type: "text/plain"
)

# Binary content
MCP::Resource::BlobContents.new(
  data: "base64_encoded",
  uri: "file:///image.png",
  mime_type: "image/png"
)
```

---

## See Also

### Related References
- **[Server](server.md)** - Resource registration and `resources_read_handler`
- **[Transport](transport.md)** - Protocol methods (`resources/list`, `resources/read`, `resources/templates/list`)

### Related Examples
- **[`../examples/stdio_server.rb`](../examples/stdio_server.rb)** - Static resource with read handler
- **[`../examples/file_manager_tool.rb`](../examples/file_manager_tool.rb)** - File-based resources with security
