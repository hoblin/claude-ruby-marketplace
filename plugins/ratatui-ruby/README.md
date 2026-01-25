# RatatuiRuby Plugin

RatatuiRuby terminal user interface development patterns and best practices with Claude Code.

## Installation

```bash
/plugin marketplace add hoblin/claude-ruby-marketplace
/plugin install ratatui-ruby@claude-ruby-marketplace
```

## Features

This plugin provides comprehensive coverage of RatatuiRuby TUI development:

| Domain | Coverage |
|--------|----------|
| **Core Concepts** | Managed loop, terminal lifecycle, inline vs full-screen viewports |
| **Widgets** | 20+ widgets: Paragraph, List, Table, Gauge, Chart, Canvas, Tabs |
| **Layout** | Constraint-based layouts, directions, Flex options, nested splits |
| **Events** | Keyboard, mouse, resize, paste, focus events, pattern matching |
| **Styling** | Colors (named/indexed/hex), modifiers, text composition |
| **Testing** | Headless terminals, event injection, snapshots, style assertions |
| **Frameworks** | Rooibos (MVU architecture), Kit (component-based) |

## Usage

The skill activates automatically when:

- Working on RatatuiRuby application files
- Discussing terminal UI development
- Mentioning `RatatuiRuby.run`, `tui.draw`, `tui.poll_event`
- Asking about TUI patterns, widgets, or layouts

## Quick Start

```ruby
require "ratatui_ruby"

RatatuiRuby.run do |tui|
  loop do
    tui.draw do |frame|
      widget = tui.paragraph(
        text: "Hello, TUI!",
        block: tui.block(title: "App", borders: [:all])
      )
      frame.render_widget(widget, frame.area)
    end

    case tui.poll_event
    in {type: :key, code: "q"}
      break
    in {type: :key, code: "c", modifiers: ["ctrl"]}
      break
    else
      # Continue
    end
  end
end
```

## Sources & Acknowledgments

### Official Resources

- [RatatuiRuby Documentation](https://www.ratatui-ruby.dev/) - Complete API reference
- [RatatuiRuby Repository](https://git.sr.ht/~kerrick/ratatui_ruby) - Source code
- [Rooibos Framework](https://git.sr.ht/~kerrick/rooibos) - MVU architecture

### Related Projects

- [Ratatui (Rust)](https://ratatui.rs/) - The underlying Rust TUI library
- [RubyGems Package](https://rubygems.org/gems/ratatui_ruby) - Install via `gem install ratatui_ruby`

### Credits

- **Kerrick Long** - Creator of RatatuiRuby
- **Ratatui Community** - The Rust TUI library that powers RatatuiRuby

## License

MIT
