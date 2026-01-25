# Core Concepts

RatatuiRuby provides immediate-mode terminal rendering with managed lifecycle. This reference covers application initialization, terminal lifecycle, viewport modes, and core objects.

## RatatuiRuby.run

Entry point handling complete terminal lifecycle with exception safety.

```ruby
RatatuiRuby.run do |tui|
  loop do
    tui.draw do |frame|
      frame.render_widget(tui.paragraph(text: "Hello"), frame.area)
    end

    case tui.poll_event
    in {type: :key, code: "q"}
      break
    end
  end
end
# Terminal restored automatically
```

### Options

| Option | Default | Purpose |
|--------|---------|---------|
| `focus_events` | `true` | Enable focus change events |
| `bracketed_paste` | `true` | Enable bracketed paste mode |
| `viewport` | `:fullscreen` | Viewport mode (`:fullscreen` or `:inline`) |
| `height` | `nil` | Lines for inline viewport (required when `viewport: :inline`) |

```ruby
RatatuiRuby.run(viewport: :inline, height: 8) do |tui|
  # 8-line inline viewport
end
```

### Manual Lifecycle (Advanced)

For fine-grained control, use `init_terminal` and `restore_terminal` with `ensure`:

```ruby
RatatuiRuby.init_terminal
begin
  RatatuiRuby.draw do |frame|
    frame.render_widget(widget, frame.area)
  end
ensure
  RatatuiRuby.restore_terminal  # Always executes
end
```

## Terminal Lifecycle

Three-phase lifecycle prevents terminal corruption.

### Phase 1: Setup (`init_terminal`)

- Enters alternate screen (fullscreen) or creates fixed region (inline)
- Enables raw mode for direct key capture
- Configures focus events and bracketed paste
- Sets `@tui_session_active = true`

### Phase 2: Loop

Application code executes with access to TUI instance:
- `draw` renders UI
- `poll_event` captures input
- Application logic manages state

### Phase 3: Teardown (`restore_terminal`)

Guaranteed cleanup via `ensure` block:
- Leaves alternate screen
- Disables raw mode
- Flushes warnings
- Sets `@tui_session_active = false`

### Signal Handling

- Most signals (SIGTERM, SIGINT) trigger stack unwinding, allowing `ensure` execution
- **SIGKILL cannot be caught** - may leave terminal in raw mode
- **Ctrl+C in raw mode** captured as key event, not SIGINT - handle explicitly:

```ruby
case tui.poll_event
in {type: :key, code: "c", modifiers: ["ctrl"]}
  break
end
```

## Viewport Modes

### Fullscreen (Default)

Takes over entire terminal, clears on exit.

```ruby
RatatuiRuby.run do |tui|
  # Fullscreen is default
end

# Or explicitly:
RatatuiRuby.run(viewport: :fullscreen) do |tui|
  # ...
end
```

**Characteristics:**
- Alternate screen buffer for isolated rendering
- All content cleared on exit
- No scrollback preservation
- Full terminal dimensions via `frame.area`
- Best for complete TUI applications

### Inline Mode

Fixed-height region preserving scrollback after exit.

```ruby
RatatuiRuby.run(viewport: :inline, height: 8) do |tui|
  # 8-line region
end
```

**Characteristics:**
- Fixed height (required parameter)
- Content persists in scrollback
- Supports `insert_before` for logging above viewport
- Best for status displays, progress indicators, inline widgets

**Logging during inline mode:**

```ruby
RatatuiRuby.insert_before(height, widget) do |frame|
  # Insert content above viewport into scrollback
end
```

## Frame Object

Controlled access to terminal buffer during rendering. Valid only within `draw` block.

### Methods

#### `area()`

Returns `Rect` of entire drawable region:

```ruby
tui.draw do |frame|
  puts "Size: #{frame.area.width}x#{frame.area.height}"
end
```

#### `render_widget(widget, area)`

Renders stateless widget at specified area:

```ruby
tui.draw do |frame|
  para = tui.paragraph(text: "Content")
  frame.render_widget(para, frame.area)
end
```

#### `render_stateful_widget(widget, area, state)`

Renders widget with persistent state (scroll position, selection):

```ruby
@list_state = tui.list_state

tui.draw do |frame|
  list = tui.list(items: ["A", "B", "C"])
  frame.render_stateful_widget(list, frame.area, @list_state)
end

# State reflects current selection/offset
puts "Selected: #{@list_state.selected}"
```

State object is single source of truth, overriding widget configuration.

#### `set_cursor_position(x, y)`

Positions cursor at zero-indexed coordinates:

```ruby
tui.draw do |frame|
  frame.render_widget(tui.paragraph(text: "Name: [alice]"), frame.area)
  frame.set_cursor_position(7, 0)  # After "Name: ["
end
```

### Thread Safety

Frame is not Ractor-shareable. Valid only during draw block execution.

### Layout Reuse Pattern

Store layout results for hit testing:

```ruby
tui.draw do |frame|
  sidebar, main = tui.layout_split(frame.area, ...)
  frame.render_widget(sidebar_widget, sidebar)
  frame.render_widget(main_widget, main)
  @regions = {sidebar:, main:}  # Reuse for click detection
end
```

## TUI Factory Object

Manages lifecycle and provides concise factory methods.

### Access

```ruby
RatatuiRuby.run do |tui|
  # tui is RatatuiRuby::TUI instance
end
```

### Factory Comparison

```ruby
# Without factories (verbose):
para = RatatuiRuby::Widgets::Paragraph.new(
  text: "Hello",
  block: RatatuiRuby::Widgets::Block.new(borders: [:all])
)

# With factories (concise):
para = tui.paragraph(text: "Hello", block: tui.block(borders: [:all]))
```

### Factory Modules

| Module | Methods | Purpose |
|--------|---------|---------|
| **WidgetFactories** | `paragraph`, `block`, `list`, `table`, `gauge` | UI components |
| **LayoutFactories** | `rect`, `constraint_*`, `layout`, `layout_split` | Layouts |
| **StyleFactories** | `style`, `color`, `modifier` | Formatting |
| **TextFactories** | `text_span`, `text_line`, `text_width` | Styled text |
| **StateFactories** | `list_state`, `table_state`, `scrollbar_state` | Widget state |
| **CanvasFactories** | `shape_map`, `shape_line`, `shape_point` | Canvas shapes |
| **BufferFactories** | Buffer inspection | Testing |
| **Core** | `draw`, `poll_event`, `get_cell_at` | Terminal ops |

### DWIM Coercion

Factories implement "Do What I Mean" argument coercion with automatic type normalization and validation.

## Module Functions

### Drawing

```ruby
# Declarative (tree-based)
RatatuiRuby.draw(widget)

# Imperative (block-based)
RatatuiRuby.draw do |frame|
  frame.render_widget(widget, frame.area)
end
```

### Event Polling

```ruby
event = RatatuiRuby.poll_event                # ~60 FPS default (16ms)
event = RatatuiRuby.poll_event(timeout: nil)  # Block until event
event = RatatuiRuby.poll_event(timeout: 0.0)  # Non-blocking
```

### Terminal Inspection

| Method | Returns |
|--------|---------|
| `get_terminal_size()` | Full terminal dimensions as `Rect` |
| `get_terminal_area()` | Alias for `get_terminal_size` |
| `get_viewport_area()` | Current viewport area |
| `get_viewport_size()` | Alias for `get_viewport_area` |
| `get_cell_at(x, y)` | `Buffer::Cell` at coordinates (for testing) |

## Complete Example

```ruby
RatatuiRuby.run do |tui|
  @list_state = tui.list_state(selected: 0)
  items = ["Dashboard", "Settings", "Help", "Quit"]

  loop do
    tui.draw do |frame|
      sidebar, content = tui.layout_split(
        frame.area,
        direction: :horizontal,
        constraints: [tui.constraint_length(20), tui.constraint_min(0)]
      )

      # Sidebar with stateful list
      list = tui.list(
        items:,
        block: tui.block(title: "Menu", borders: [:all])
      )
      frame.render_stateful_widget(list, sidebar, @list_state)

      # Content area
      selected_item = items[@list_state.selected] || "None"
      frame.render_widget(
        tui.paragraph(
          text: "Selected: #{selected_item}",
          block: tui.block(title: "Content", borders: [:all])
        ),
        content
      )
    end

    case tui.poll_event
    in {type: :key, code: "q"}
      break
    in {type: :key, code: "j"} | {type: :key, code: "down"}
      @list_state.select_next
    in {type: :key, code: "k"} | {type: :key, code: "up"}
      @list_state.select_previous
    in {type: :key, code: "c", modifiers: ["ctrl"]}
      break
    else
      # Continue
    end
  end
end
```
