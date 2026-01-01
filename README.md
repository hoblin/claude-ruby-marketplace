# Claude Ruby Marketplace

A Claude Code plugin marketplace for Ruby and Rails development.

## Installation

```bash
/plugin marketplace add hoblin/claude-ruby-marketplace
```

## Available Plugins

| Plugin | Type | Description |
|--------|------|-------------|
| [`ruby-lsp`](./plugins/ruby-lsp/README.md) | LSP | Ruby language server (Shopify's ruby-lsp) * |
| [`rspec`](./plugins/rspec/README.md) | Skill | RSpec and FactoryBot testing patterns for Rails |
| [`draper`](./plugins/draper/README.md) | Skill | Draper decorator patterns for Rails view logic |
| [`activerecord`](./plugins/activerecord/README.md) | Skill | ActiveRecord patterns for Rails models and queries |
| [`mcp`](./plugins/mcp/README.md) | Skill | MCP server development with Ruby SDK |

\* LSP plugins broken since v2.0.69 ([#13952](https://github.com/anthropics/claude-code/issues/13952)) - use v2.0.67 or wait for fix

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
