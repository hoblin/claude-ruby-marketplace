# Claude Ruby Marketplace

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin%20Marketplace-blueviolet)](https://github.com/anthropics/claude-code)

A Claude Code plugin marketplace for Ruby development: Rails applications, testing, and game development with DragonRuby.

## Installation

```bash
/plugin marketplace add hoblin/claude-ruby-marketplace
```

## Available Plugins

- [Rails Development](#rails-development) - rspec, activerecord, draper, mcp, ruby-lsp
- [Game Development](#game-development) - dragonruby
- [Development Tools](#development-tools) - rpi

### Rails Development

- [`ruby-lsp`](./plugins/ruby-lsp/README.md) (LSP) - Ruby language server (Shopify's ruby-lsp) *
- [`rspec`](./plugins/rspec/README.md) (Skill) - RSpec and FactoryBot testing patterns
- [`draper`](./plugins/draper/README.md) (Skill) - Draper decorator patterns for view logic
- [`activerecord`](./plugins/activerecord/README.md) (Skill) - ActiveRecord patterns for models and queries
- [`mcp`](./plugins/mcp/README.md) (Skill) - MCP server development with Ruby SDK

\* LSP plugins broken since v2.0.69 ([#13952](https://github.com/anthropics/claude-code/issues/13952)) - use v2.0.67 or wait for fix

### Game Development

- [`dragonruby`](./plugins/dragonruby/README.md) (Skill) - DragonRuby Game Toolkit for 2D games

Covers game loop, input handling, entities, collision detection, audio, rendering, animation, scenes, and cross-platform distribution.

### Development Tools

- [`rpi`](./plugins/rpi/README.md) (Workflow) - Research, Planning, Implementation - context engineering for AI-assisted development

## Installing Plugins

```bash
# Rails plugins
/plugin install rspec@claude-ruby-marketplace
/plugin install activerecord@claude-ruby-marketplace
/plugin install draper@claude-ruby-marketplace

# Game development
/plugin install dragonruby@claude-ruby-marketplace

# Development tools
/plugin install rpi@claude-ruby-marketplace
```

## For Contributors

See [CLAUDE.md](./CLAUDE.md) for development guidelines.

## Contributing

See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE)
