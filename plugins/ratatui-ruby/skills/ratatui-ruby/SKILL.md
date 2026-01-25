---
name: RatatuiRuby
description: This skill should be used when the user asks to "create a TUI", "terminal interface", "terminal UI", "ratatui", "ratatui-ruby", "inline viewport", "full-screen terminal app", "terminal widgets", "tui.draw", "tui.poll_event", or mentions RatatuiRuby.run, managed loop, terminal rendering, Tea MVU, or building CLI applications with rich UI elements. Should also be used when editing RatatuiRuby application files, working with terminal widgets, or discussing TUI architecture patterns.
version: 1.2.0
---

# RatatuiRuby

This skill provides guidance for building terminal user interfaces with RatatuiRuby, a Ruby gem wrapping Rust's Ratatui library. Use for TUI development, terminal widgets, layout systems, event handling, and testing terminal applications.

## Quick Reference

### Minimal Application

```ruby
require "ratatui_ruby"

RatatuiRuby.run do |tui|
  loop do
    tui.draw do |frame|
      widget = tui.paragraph(text: "Hello, TUI!", block: tui.block(title: "App"))
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

### Key Concepts

| Concept | Purpose |
|---------|---------|
| `RatatuiRuby.run` | Managed loop handling terminal setup/teardown |
| `tui.draw` | Render widgets each frame |
| `tui.poll_event` | Capture keyboard/mouse input |
| `frame.area` | Available rendering area (Rect) |
| `frame.render_widget` | Render stateless widgets |
| `frame.render_stateful_widget` | Render widgets with state (List, Table) |

### Two Operating Modes

| Mode | Use Case | Setup |
|------|----------|-------|
| **Full-Screen** | Complete TUI applications | `RatatuiRuby.run { }` (default) |
| **Inline Viewport** | Rich CLI moments (spinners, progress) | `RatatuiRuby.run(viewport: :inline, height: 5) { }` |

**Full-Screen**: Takes over terminal, alternate screen, restored on exit.

**Inline Viewport**: Preserves scrollback, fixed-height widget area, output remains visible after exit.

## Core Pattern

The managed loop pattern handles terminal lifecycle:

```ruby
RatatuiRuby.run do |tui|
  loop do
    # 1. Draw UI
    tui.draw do |frame|
      # Render widgets
    end

    # 2. Handle events
    case tui.poll_event
    in {type: :key, code: "q"}
      break
    end
  end
end
```

## Common Widgets

| Widget | Factory | Purpose |
|--------|---------|---------|
| Paragraph | `tui.paragraph(text:)` | Text display |
| Block | `tui.block(title:, borders:)` | Borders, titles, padding |
| List | `tui.list(items:)` | Selectable item list |
| Table | `tui.table(rows:, widths:)` | Tabular data |
| Gauge | `tui.gauge(ratio:)` | Progress indication |
| Tabs | `tui.tabs(titles:)` | Tab navigation |
| Chart | `tui.chart(datasets:)` | Data visualization |
| Canvas | `tui.canvas { }` | Custom drawing |
| Scrollbar | `tui.scrollbar` | Scroll indication |

### Stateless vs Stateful Widgets

**Stateless** (Paragraph, Block, Gauge):

```ruby
widget = tui.paragraph(text: "Hello")
frame.render_widget(widget, frame.area)
```

**Stateful** (List, Table):

```ruby
# Create state once (outside draw loop)
list_state = tui.list_state(0)

# In draw block
list = tui.list(items: ["Item A", "Item B", "Item C"])
frame.render_stateful_widget(list, frame.area, list_state)

# Update state on input
list_state.select_next if event_down?
```

### Block Composition

Wrap widgets with Block for borders and titles:

```ruby
block = tui.block(
  title: "Main",
  titles: [
    {content: "Help: q", position: :bottom, alignment: :right}
  ],
  borders: [:all],
  border_style: {fg: "cyan"}
)

paragraph = tui.paragraph(text: "Content", block:)
```

## Layout

Split areas using constraints:

```ruby
layout = tui.layout(
  direction: :vertical,
  constraints: [
    tui.constraint(:percentage, 20),  # Header: 20%
    tui.constraint(:min, 0),           # Body: remaining
    tui.constraint(:length, 3)         # Footer: 3 rows
  ]
)

chunks = layout.split(frame.area)
# chunks[0] -> header area
# chunks[1] -> body area
# chunks[2] -> footer area
```

### Constraint Types

| Type | Syntax | Behavior |
|------|--------|----------|
| Length | `tui.constraint(:length, 5)` | Fixed 5 rows/cols |
| Percentage | `tui.constraint(:percentage, 50)` | 50% of parent |
| Min | `tui.constraint(:min, 10)` | At least 10 |
| Max | `tui.constraint(:max, 20)` | At most 20 |
| Ratio | `tui.constraint(:ratio, 1, 3)` | 1/3 of space |
| Fill | `tui.constraint(:fill)` | Expand into excess |

## Event Handling

### Pattern Matching

```ruby
case tui.poll_event
in {type: :key, code: "q"}
  break
in {type: :key, code: "j"} | {type: :key, code: "down"}
  list_state.select_next
in {type: :key, code: "k"} | {type: :key, code: "up"}
  list_state.select_previous
in {type: :key, code: "c", modifiers: ["ctrl"]}
  break
in {type: :mouse, kind: "down", button: "left", x:, y:}
  handle_click(x, y)
in {type: :resize}
  # Terminal resized, next draw adapts
end
```

### Event Helper Methods

```ruby
event = tui.poll_event
break if event.ctrl_c?
list_state.select_next if event.down? || event.j?
```

## Styling

Hash-based syntax for colors and modifiers:

```ruby
tui.paragraph(
  text: "Styled text",
  style: {fg: "green", bold: true},
  block: tui.block(border_style: {fg: "cyan"})
)
```

### Text Composition

```ruby
line = tui.line([
  tui.span("Normal "),
  tui.span("Bold", style: {bold: true}),
  tui.span(" Red", style: {fg: "red"})
])

tui.paragraph(text: line)
```

### Color Options

- Named: `"red"`, `"green"`, `"cyan"`, `"white"`
- Hex: `"#FF5733"`
- Indexed: 0-255 palette

## Testing

```ruby
require "ratatui_ruby/test_helper"

class MyAppTest < Minitest::Test
  include RatatuiRuby::TestHelper

  def test_renders_greeting
    with_test_terminal(80, 24) do
      RatatuiRuby.draw do |frame|
        widget = RatatuiRuby::Widgets::Paragraph.new(text: "Hello")
        frame.render_widget(widget, frame.area)
      end

      assert_snapshots("greeting")  # Creates/compares snapshots/greeting.txt
    end
  end

  def test_keyboard_navigation
    with_test_terminal do
      inject_keys("j", "j", "k")  # Down, down, up
      # Assert state changes
    end
  end
end
```

## Frameworks

### Tea (MVU Architecture)

Functional, Elm-style architecture for predictable state:

```ruby
require "ratatui_ruby/tea"

class Counter
  include RatatuiRuby::Tea::App

  def init
    [Model.new(count: 0), nil]
  end

  def view(model, tui)
    tui.paragraph(text: "Count: #{model.count}")
  end

  def update(message, model)
    case message
    in {type: :key, code: "q"}
      [model, RatatuiRuby::Tea::Command.exit]
    in {type: :key, code: "j"}
      [model.with(count: model.count + 1), nil]
    else
      [model, nil]
    end
  end
end

Counter.new.run
```

## Best Practices

### Do

- Use `RatatuiRuby.run` for managed terminal lifecycle
- Create state objects outside the draw loop
- Use pattern matching for event handling
- Use inline viewports for CLI "rich moments"
- Test with `RatatuiRuby::TestHelper`

### Don't

- Handle Ctrl+C manually (use `event.ctrl_c?` helper)
- Forget to break the loop (leads to CPU spin)
- Render widgets before poll_event (blocks input)
- Use full-screen for simple progress indicators

## Additional Resources

### Reference Files

For detailed API documentation and patterns:

- **`references/core-concepts.md`** - Managed loop, terminal lifecycle, inline vs full-screen
- **`references/widgets.md`** - Complete widget catalog, composition patterns
- **`references/layout.md`** - Constraints, directions, nested layouts
- **`references/events.md`** - Keyboard, mouse, event handling patterns
- **`references/styling.md`** - Colors, modifiers, text composition
- **`references/testing.md`** - TestHelper, snapshots, event injection
- **`references/frameworks.md`** - Tea MVU, Kit components
