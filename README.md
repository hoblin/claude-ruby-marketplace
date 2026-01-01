# Claude Ruby Marketplace

A Claude Code plugin marketplace for Ruby and Rails development.

## Installation

```bash
/plugin marketplace add hoblin/claude-ruby-marketplace
```

## Available Plugins

| Plugin | Type | Description |
|--------|------|-------------|
| `ruby-lsp` | LSP | Ruby language server (Shopify's ruby-lsp) |
| `rspec` | Skill | RSpec and FactoryBot testing patterns for Rails |
| `draper` | Skill | Draper decorator patterns for Rails view logic |
| `activerecord` | Skill | ActiveRecord patterns for Rails models and queries |
| `mcp` | Skill | MCP server development with Ruby SDK |

## Installing Plugins

```bash
# Install individual plugins
/plugin install ruby-lsp@claude-ruby-marketplace
/plugin install rspec@claude-ruby-marketplace
/plugin install activerecord@claude-ruby-marketplace

# Or enable in your project's .claude/settings.json
```

## For Contributors

See [CLAUDE.md](./CLAUDE.md) for development guidelines.

## License

MIT
