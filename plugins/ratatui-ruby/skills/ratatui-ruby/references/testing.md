# Testing Infrastructure

RatatuiRuby provides comprehensive TUI testing through the `TestHelper` module: headless terminals, event injection, snapshots, and style assertions.

## Setup

```ruby
require "ratatui_ruby/test_helper"
require "minitest/autorun"

class MyAppTest < Minitest::Test
  include RatatuiRuby::TestHelper

  def test_basic
    with_test_terminal do
      widget = tui.paragraph(text: "Hello")
      RatatuiRuby.draw { |frame| frame.render_widget(widget, frame.area) }
      assert_includes buffer_content.first, "Hello"
    end
  end
end
```

Including `TestHelper` automatically enables debug mode for Rust backtraces.

## Headless Terminal

### with_test_terminal

```ruby
with_test_terminal(width = 80, height = 24, **opts) { || ... }
```

**Options:**
- `width`, `height`: Terminal dimensions (default: 80x24)
- `timeout`: Max execution time in seconds (default: 2, `nil` to disable)
- `viewport`: Optional viewport configuration

```ruby
def test_custom_dimensions
  with_test_terminal(120, 40, timeout: 5) do
    # Test code
  end
end
```

### Buffer Inspection

#### buffer_content

Returns array of strings (one per row):

```ruby
content = buffer_content
assert_equal "Header", content[0].strip
assert_includes content[1], "Body"
```

#### get_cell(x, y)

Cell attributes at coordinates:

```ruby
cell = get_cell(0, 0)
cell["symbol"]  # Character
cell["fg"]      # Foreground color
cell["bg"]      # Background color
```

#### cursor_position

```ruby
pos = cursor_position
pos[:x]  # Column
pos[:y]  # Row
```

#### print_buffer

Outputs buffer with ANSI colors for debugging:

```ruby
print_buffer  # Visual inspection during development
```

## Event Injection

### inject_keys

**String format (characters):**
```ruby
inject_keys("h", "e", "l", "l", "o")
```

**Symbol format (named keys):**
```ruby
inject_keys(:enter, :esc, :tab, :backspace)
inject_keys(:up, :down, :left, :right)
inject_keys(:ctrl_c, :ctrl_d)
```

**Hash format (modifiers):**
```ruby
inject_keys({code: "k", modifiers: ["ctrl"]})
inject_keys({code: "s", modifiers: ["ctrl", "shift"]})
```

### Mouse Events

```ruby
inject_mouse(x: 10, y: 5, kind: :down, button: :left, modifiers: [])
inject_mouse(x: 10, y: 5, kind: :up, button: :left)
```

**Convenience methods:**
```ruby
inject_click(x: 15, y: 8)                          # Left click
inject_right_click(x: 20, y: 10, modifiers: ["ctrl"])
inject_drag(x: 10, y: 5)                           # During drag
```

### inject_sync

Wait for async operations to complete:

```ruby
start_async_operation
inject_sync
assert_includes buffer_content.join, "Data loaded"
```

### inject_event

Generic method for any event type:

```ruby
event = RatatuiRuby::Event::Resize.new(width: 100, height: 30)
inject_event(event)
```

## Snapshot Testing

### assert_snapshots (Recommended)

Creates both plain text and ANSI snapshots:

```ruby
def test_initial_screen
  with_test_terminal do
    MyApp.new.run_once
    assert_snapshots("initial")
  end
end
```

Creates:
- `snapshots/initial.txt` - Plain text
- `snapshots/initial.ansi` - With ANSI codes

### Snapshot Workflow

**Create/update snapshots:**
```bash
UPDATE_SNAPSHOTS=1 bundle exec rake test
```

**Compare against existing:**
```bash
bundle exec rake test
```

### Content Normalization

Handle dynamic content:

```ruby
assert_snapshots("dashboard") do |lines|
  lines.map { |line| line.gsub(/\d{4}-\d{2}-\d{2}/, "YYYY-MM-DD") }
end

assert_snapshots("users") do |lines|
  lines.map { |line| line.gsub(/ID:\s*\d+/, "ID: XXXXX") }
end
```

### Deterministic Data

Seed random generators for stable snapshots:

```ruby
def setup
  @rng = Random.new(42)
  @data = (0..20).map { @rng.rand(0.0..10.0) }
end
```

### Specialized Methods

```ruby
assert_plain_snapshot("layout")   # Only .txt
assert_rich_snapshot("styles")    # Only .ansi
```

## Style Assertions

### assert_cell_style

```ruby
assert_cell_style(0, 0, char: "H", fg: :red, bg: :black)
assert_cell_style(1, 0, char: "e", fg: :red)
```

### Color Assertions

```ruby
assert_color(:red, x: 0, y: 0, layer: :fg)
assert_color(196, x: 1, y: 0, layer: :fg)        # Indexed
assert_color("#FF0000", x: 2, y: 0, layer: :fg)  # Hex

# Shortcuts
assert_fg_color(:red, 0, 0)
assert_bg_color(:black, 0, 0)
```

### Area Style

```ruby
# Hash notation
assert_area_style({x: 0, y: 0, w: 80, h: 1}, fg: :white, bg: :blue)

# Rect object
sidebar = RatatuiRuby::Rect.new(x: 0, y: 1, width: 20, height: 23)
assert_area_style(sidebar, bg: :dark_gray)
```

### Modifier Assertions

```ruby
assert_bold(0, 0)
assert_italic(5, 0)
assert_underlined(10, 0)
assert_crossed_out(15, 0)
assert_reversed(20, 0)
assert_dim(25, 0)
assert_hidden(30, 0)
assert_slow_blink(35, 0)
assert_rapid_blink(40, 0)
```

## Test Doubles

### MockFrame

Captures rendered widgets for inspection:

```ruby
frame = RatatuiRuby::TestHelper::TestDoubles::MockFrame.new
area = RatatuiRuby::TestHelper::TestDoubles::StubRect.new(width: 80, height: 24)

View::Log.new.call(state, tui, frame, area)

widget = frame.rendered_widgets.first[:widget]
assert_equal "Event Log", widget.block.title
```

### StubRect

Fixed dimensions for layout testing:

```ruby
narrow = RatatuiRuby::TestHelper::TestDoubles::StubRect.new(
  x: 0, y: 0, width: 40, height: 24
)

wide = RatatuiRuby::TestHelper::TestDoubles::StubRect.new(
  width: 120, height: 24
)
```

## RSpec Integration

```ruby
require "ratatui_ruby/test_helper"

RSpec.describe MyApp do
  include RatatuiRuby::TestHelper

  describe "rendering" do
    it "displays welcome message" do
      with_test_terminal do
        subject.run_once
        expect(buffer_content.join).to include("Welcome")
      end
    end
  end

  describe "navigation" do
    it "responds to arrow keys" do
      with_test_terminal do
        subject.run_once
        inject_keys(:down, :down, :enter)
        subject.handle_events
        expect(buffer_content[2]).to include("Selected")
      end
    end
  end
end
```

## Testing Patterns

### State Transitions

```ruby
def test_menu_navigation
  with_test_terminal do
    app = MyApp.new
    app.run_once
    assert_snapshots("menu_initial")

    inject_keys(:down)
    app.handle_events
    assert_snapshots("menu_item_1")

    inject_keys(:enter)
    app.handle_events
    assert_snapshots("menu_selected")
  end
end
```

### Full User Flow

```ruby
def test_complete_flow
  with_test_terminal(120, 40, timeout: 5) do
    app = MyApp.new
    app.run_once

    # Initial render
    assert_snapshots("startup")
    assert_fg_color(:white, 0, 0)

    # Navigate
    inject_keys(:down, :down)
    app.handle_events
    assert_bold(0, 2)

    # Click
    inject_click(x: 5, y: 2)
    app.handle_events
    assert_includes buffer_content.join, "Selected"

    assert_snapshots("after_selection")
  end
end
```

### Isolated View Testing

```ruby
def test_header_view_isolated
  frame = RatatuiRuby::TestHelper::TestDoubles::MockFrame.new
  area = RatatuiRuby::TestHelper::TestDoubles::StubRect.new(width: 80, height: 3)
  state = {title: "App", version: "1.0"}

  View::Header.new.render(state, frame, area)

  widget = frame.rendered_widgets.first[:widget]
  assert_equal "App", widget.block.title
end
```

### Progressive Assertions

```ruby
def test_dashboard
  with_test_terminal do
    render_dashboard

    # Level 1: Snapshot
    assert_snapshots("dashboard")

    # Level 2: Content
    assert_includes buffer_content.join, "Dashboard"

    # Level 3: Styles
    assert_fg_color(:cyan, 0, 0)
    assert_bold(0, 0)

    # Level 4: Cell inspection
    cell = get_cell(0, 0)
    assert_equal "D", cell["symbol"]
  end
end
```

## Debugging

```ruby
def test_complex_layout
  with_test_terminal do
    MyApp.new.render_dashboard

    print_buffer           # Visual output
    binding.irb            # Interactive debugging

    assert_snapshots("dashboard")
  end
end
```

## Quick Reference

| Method | Purpose |
|--------|---------|
| `with_test_terminal` | Headless terminal context |
| `buffer_content` | Array of row strings |
| `get_cell(x, y)` | Cell attributes |
| `cursor_position` | Cursor coordinates |
| `print_buffer` | Debug output |
| `inject_keys(...)` | Keyboard events |
| `inject_mouse(...)` | Mouse events |
| `inject_click(x:, y:)` | Left click |
| `inject_sync` | Wait for async |
| `assert_snapshots(name)` | Visual comparison |
| `assert_cell_style(x, y, ...)` | Cell validation |
| `assert_fg_color(color, x, y)` | Foreground color |
| `assert_bg_color(color, x, y)` | Background color |
| `assert_area_style(area, ...)` | Region validation |
| `assert_bold(x, y)` | Bold modifier |
| `MockFrame` | Widget capture |
| `StubRect` | Fixed dimensions |
