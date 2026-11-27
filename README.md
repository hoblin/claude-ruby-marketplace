# Claude Ruby Marketplace

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin%20Marketplace-blueviolet)](https://github.com/anthropics/claude-code)

Claude Code plugins for building software with agents, from Ruby developers. The main one is **rpi**.

## rpi

[`rpi`](./plugins/rpi/README.md) — **R**esearch, **P**lan, **I**mplement: takes a raw idea to production, with the human making the decisions and every decision kept for the work that follows.

Traditional software factories are designed to let agents work without a human. rpi is a human-first software factory: it puts the human and their decisions first.

Agents can now write most of a project's code. rpi keeps the ownership of it with the human: what the system should do is the human's to decide; every decision is kept with its reason in a thoughts repository the whole team shares; agents work from those records, bring back what nobody decided, and take everything else. An idea is explored in a brainstorm, the decisions become tickets, and worker agents deliver them to the merge, while a manager agent leads them and brings the human only what needs them.

Read [the rpi README](./plugins/rpi/README.md) for the process, the roles, the skills and the tools.

```bash
/plugin marketplace add hoblin/claude-ruby-marketplace
/plugin install rpi@claude-ruby-marketplace
```

## Ruby and Rails skills

Smaller plugins with reference knowledge for particular libraries:

- [`rspec`](./plugins/rspec/README.md) — RSpec and FactoryBot testing patterns.
- [`activerecord`](./plugins/activerecord/README.md) — ActiveRecord patterns for models and queries.
- [`draper`](./plugins/draper/README.md) — Draper decorator patterns for view logic.
- [`mcp`](./plugins/mcp/README.md) — MCP server development with the Ruby SDK.
- [`dragonruby`](./plugins/dragonruby/README.md) — DragonRuby Game Toolkit for 2D games.
- [`ratatui-ruby`](./plugins/ratatui-ruby/README.md) — RatatuiRuby for terminal user interfaces.
- [`ruby-lsp`](./plugins/ruby-lsp/README.md) — the Ruby language server (Shopify's ruby-lsp). LSP plugins are broken since Claude Code v2.0.69 ([#13952](https://github.com/anthropics/claude-code/issues/13952)).

Each installs the same way, e.g. `/plugin install rspec@claude-ruby-marketplace`.

## Contributing

See [CONTRIBUTING.md](.github/CONTRIBUTING.md), and [CLAUDE.md](./CLAUDE.md) for how the repository is laid out.

## License

[MIT](LICENSE)
