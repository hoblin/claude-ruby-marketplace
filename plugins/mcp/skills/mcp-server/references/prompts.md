# MCP Prompts Reference

## Prompt Definition

### Class-Based

```ruby
class MyPrompt < MCP::Prompt
  prompt_name "custom_name"  # Optional
  title "Prompt Title"
  description "What this prompt does"

  arguments [
    MCP::Prompt::Argument.new(
      name: "message",
      title: "Message Title",
      description: "The input message",
      required: true
    ),
    MCP::Prompt::Argument.new(
      name: "context",
      description: "Optional context",
      required: false
    )
  ]

  meta(version: "1.0", category: "general")

  class << self
    def template(args, server_context:)
      MCP::Prompt::Result.new(
        description: "Result description",
        messages: [
          MCP::Prompt::Message.new(
            role: "user",
            content: MCP::Content::Text.new(args[:message])
          ),
          MCP::Prompt::Message.new(
            role: "assistant",
            content: MCP::Content::Text.new("Response")
          )
        ]
      )
    end
  end
end
```

### Block-Based

```ruby
prompt = MCP::Prompt.define(
  name: "prompt_name",
  title: "Title",
  description: "Description",
  arguments: [
    MCP::Prompt::Argument.new(name: "arg", required: true)
  ],
  meta: { version: "1.0" }
) do |args, server_context:|
  MCP::Prompt::Result.new(
    messages: [
      MCP::Prompt::Message.new(
        role: "user",
        content: MCP::Content::Text.new(args[:arg])
      )
    ]
  )
end
```

## Content Types

```ruby
# Text content
MCP::Content::Text.new(
  "Text content",
  annotations: { key: "value" }  # Optional
)

# Image content
MCP::Content::Image.new(
  "base64_encoded_data",
  "image/png",
  annotations: { source: "camera" }
)
```

---

## See Also

### Related References
- **[Server](server.md)** - Prompt registration and handler overrides
- **[Transport](transport.md)** - Protocol methods (`prompts/list`, `prompts/get`)

### Related Examples
- **[`../examples/stdio_server.rb`](../examples/stdio_server.rb)** - Class-based prompt definition (`CodeReviewPrompt`)
