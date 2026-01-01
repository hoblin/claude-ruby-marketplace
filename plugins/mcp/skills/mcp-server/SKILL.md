---
name: MCP Server (Ruby)
version: 1.0.0
description: This skill should be used when the user asks to "create an MCP server", "build MCP tools", "define MCP prompts", "register MCP resources", "implement Model Context Protocol", or mentions the mcp gem, MCP::Server, MCP::Tool, JSON-RPC transport, stdio transport, or streamable HTTP transport. Should also be used when editing MCP server files, working with tool/prompt/resource definitions, or discussing LLM tool integrations in Ruby.
---

# MCP Ruby SDK - Server Development Guide

Build Model Context Protocol servers in Ruby using the official `mcp` gem (maintained by Anthropic and Shopify).

## Design Philosophy

### Information Provider, Not Analyzer

MCP servers provide structured data; LLMs do the reasoning. Return comprehensive frameworks and raw information—let the client perform analysis and context-dependent decisions.

> "The MCP server's job is to be the world's best research assistant, not a competing analyst." — Matt Adams

### Context Preservation

Agents have limited context windows. Every byte returned that wasn't requested is a byte that could have held useful context. Treat context preservation as a first-class design constraint.

**Principles:**
- Never return data that wasn't explicitly requested
- Mutations are quiet—return confirmations, not data dumps
- Explicit over implicit—associations only when asked
- Filter large datasets before returning (10,000 rows → 5 relevant rows)

### Domain-Aligned Vocabulary

Tools should speak the language of your domain, not database/CRUD terminology. Agents are collaborators in your domain process, not database clients.

**Example:** A visual novel asset server uses `create_image`, `make_sprite`, `place_character`, `explore_variations`, `compare_images`—not `generate`, `remove_background`, `composite`, `batch_generate`, `get_diff`.

### Tool Budget Management

Too many tools overwhelm agents and increase costs. Design toolsets around clear use cases, not API endpoint mirrors.

- Group related functionality intelligently
- Use lazy loading for large tool sets (150K tokens → 2K via on-demand discovery)
- Tool names ≤64 characters, descriptions narrow and unambiguous

### Security: The Lethal Trifecta

Three capabilities that, when combined, create vulnerabilities (Simon Willison):
1. Access to private data
2. Exposure to untrusted content
3. External communication capabilities

**Required:** Explicit user consent before tool invocation, clear UI showing exposed tools, alerts when tool descriptions change.

## Domain Components

| Component | Purpose | Reference |
|-----------|---------|-----------|
| **Tools** | Define callable functions with input/output schemas | [`references/tools.md`](references/tools.md) |
| **Prompts** | Template-based message generators | [`references/prompts.md`](references/prompts.md) |
| **Resources** | Static and dynamic file/data registration | [`references/resources.md`](references/resources.md) |
| **Server** | Core server initialization and configuration | [`references/server.md`](references/server.md) |
| **Transport** | STDIO and HTTP transport options | [`references/transport.md`](references/transport.md) |
| **Gotchas** | Tricky behaviors and error handling | [`references/gotchas.md`](references/gotchas.md) |

## Key Concepts

| Concept | Purpose |
|---------|---------|
| `MCP::Tool` | Base class for defining callable tools |
| `MCP::Prompt` | Base class for prompt templates |
| `MCP::Resource` | Static resource registration |
| `MCP::ResourceTemplate` | Dynamic URI-based resources |
| `server_context` | Request-scoped data passed to handlers |
| `MCP::Tool::Response` | Structured tool return value |

## Tool Definition Patterns

| Pattern | Use Case |
|---------|----------|
| Class-based (`< MCP::Tool`) | Reusable tools with complex logic |
| Block-based (`MCP::Tool.define`) | Inline, simple tools |
| Dynamic (`server.define_tool`) | Runtime tool registration |

## Transport Decision Tree

```
What environment?
├── CLI tool / Local server
│   └── Use STDIO transport
└── Web server / Production
    └── Need sessions and notifications?
        ├── YES → Use Streamable HTTP (stateful)
        └── NO → Use Streamable HTTP (stateless)
```

### Quick Comparison

| Transport | Sessions | Notifications | Use For |
|-----------|----------|---------------|---------|
| STDIO | N/A | Yes | CLI tools, local dev |
| HTTP (stateful) | Yes | Yes | Web apps, long-lived connections |
| HTTP (stateless) | No | No | Simple request/response APIs |

## Protocol Version Features

| Feature | Minimum Version |
|---------|-----------------|
| `description` | 2025-11-25 |
| `instructions` | 2025-03-26 |
| `annotations` | 2025-03-26 |
| `output_schema` | 2025-03-26 |

## Best Practices

### Do

- Use `tool_name` for namespaced classes to avoid conflicts
- Use `additionalProperties: false` for strict schema validation
- Use mutex for shared state in HTTP transport (thread safety)
- Return error responses for business errors (`Response.new([...], error: true)`)
- Check protocol version before using newer features
- Use `server_context` for request-scoped data (user_id, env)

### Don't

- Don't use `$ref` in schemas (raises ArgumentError, inline only)
- Don't assume extra args are rejected (`additionalProperties` defaults to allowing extras)
- Don't use `rpc.` prefix (reserved for protocol methods)
- Don't send notifications in stateless mode (raises RuntimeError)
- Don't rely on validation order (required args checked before JSON Schema)

## Anti-Patterns Quick List

| Anti-Pattern | Solution |
|--------------|----------|
| Missing `additionalProperties: false` | Add to schema for strict validation |
| Using `$ref` in schemas | Inline all definitions |
| Notifications in stateless mode | Use stateful transport or skip notifications |
| Hardcoded server_context | Pass dynamically based on request |
| Ignoring protocol version | Check version before using gated features |
| Blocking in tool handlers | Use async patterns for long operations |

## Key Points

1. **Validation is multi-layered** - Required args checked first, then JSON Schema validation
2. **Notifications are fire-and-forget** - Errors reported but don't propagate
3. **Protocol version matters** - Features are gated by version
4. **Server context is opt-in** - Detected from method signature (must include `server_context:` parameter)
5. **Schemas are immutable** - Validated at class load time, not runtime

## Additional Resources

### Reference Files

For detailed DSL syntax by domain:

- **`references/tools.md`** - Tool definition, responses, schemas, annotations
- **`references/prompts.md`** - Prompt definition, arguments, content types
- **`references/resources.md`** - Resource registration, templates, read handlers
- **`references/server.md`** - Server initialization, configuration, custom methods
- **`references/transport.md`** - Transport config, protocol methods, sessions
- **`references/gotchas.md`** - Tricky behaviors, error handling, edge cases

### Example Files

Working examples in `examples/`:

- **`examples/stdio_server.rb`** - Complete STDIO server with tools, prompts, resources
- **`examples/http_server.rb`** - HTTP server with Rack and logging
- **`examples/rails_integration.rb`** - Rails controller, routes, and initializer
- **`examples/file_manager_tool.rb`** - Sandboxed file operations with security patterns
- **`examples/dynamic_tools.rb`** - Runtime tool registration with notifications
- **`examples/http_client.rb`** - HTTP client connecting to MCP server
- **`examples/streaming_client.rb`** - SSE streaming client for real-time notifications

### External Links

- [MCP Ruby SDK on GitHub](https://github.com/modelcontextprotocol/ruby-sdk)
- [MCP Protocol Specification](https://modelcontextprotocol.io)
- [RubyDoc API Reference](https://rubydoc.info/gems/mcp)
