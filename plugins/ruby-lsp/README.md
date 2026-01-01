# ruby-lsp

> **Note**: LSP plugins are currently broken in Claude Code - the LSP server registration function is not implemented. Last working version is 2.0.67. See [Issue #13952](https://github.com/anthropics/claude-code/issues/13952) for status and workarounds.

Ruby language server for Claude Code, providing code intelligence features like go-to-definition, find references, hover documentation, and diagnostics.

Uses [Shopify's ruby-lsp](https://github.com/Shopify/ruby-lsp) - the modern Ruby language server.

## Supported Extensions

`.rb`, `.rake`, `.gemspec`, `.ru`, `.erb`

## Features

- Go-to-definition
- Find references
- Hover documentation
- Code completion
- Diagnostics (syntax errors, linting via RuboCop)
- Document symbols
- Formatting (via RuboCop)

## Installation

The `ruby-lsp` gem must be installed and available in your PATH.

### Via Bundler (recommended for projects)

Add to your Gemfile:

```ruby
group :development do
  gem 'ruby-lsp'
end
```

Then run:

```bash
bundle install
```

### Global installation

```bash
gem install ruby-lsp
```

### Via mise

```bash
mise use ruby@3.4
gem install ruby-lsp
```

## Verification

Check that ruby-lsp is available:

```bash
which ruby-lsp
ruby-lsp --version
```

## More Information

- [ruby-lsp on GitHub](https://github.com/Shopify/ruby-lsp)
- [ruby-lsp on RubyGems](https://rubygems.org/gems/ruby-lsp)
- [VS Code Extension](https://marketplace.visualstudio.com/items?itemName=Shopify.ruby-lsp)
