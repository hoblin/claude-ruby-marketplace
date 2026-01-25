# Event Handling

RatatuiRuby provides a robust event system for keyboard, mouse, resize, paste, and focus events. This reference covers polling, event types, and handling patterns.

## poll_event

Primary method for retrieving user input:

```ruby
event = RatatuiRuby.poll_event(timeout: 0.016)
```

### Timeout Options

| Value | Behavior |
|-------|----------|
| `0.016` (default) | ~60 FPS, smooth rendering loops |
| `nil` | Block until event arrives |
| `0.0` | Non-blocking, return immediately |
| Positive float | Wait specified duration |

### Return Types

- `Event::Key` — Keyboard input
- `Event::Mouse` — Mouse interactions
- `Event::Resize` — Terminal dimension changes
- `Event::Paste` — Clipboard content
- `Event::FocusGained` — Terminal received focus
- `Event::FocusLost` — Terminal lost focus
- `Event::None` — No event (Null Object pattern)

## Event Base Class

Type-checking predicates:

```ruby
event.key?           # Keyboard event
event.mouse?         # Mouse activity
event.resize?        # Terminal resize
event.paste?         # Clipboard paste
event.focus_gained?  # Focus acquisition
event.focus_lost?    # Focus loss
event.none?          # No event
```

## Key Events

### Attributes

```ruby
event.code       # Key identifier: "a", "enter", "up", "f1"
event.modifiers  # Active modifiers: ["ctrl"], ["alt", "shift"]
event.kind       # Category: :standard, :function, :media, :modifier, :system
```

### Comparison Methods

```ruby
# Symbol comparison
event == :ctrl_c
event == :shift_up
event == :q

# String comparison
event == "c"
event == "enter"

# Object comparison
event == Event::Key.new(code: "c", modifiers: ["ctrl"])
```

### Helper Predicates

Dynamic methods via `method_missing`:

```ruby
event.ctrl_c?      # Ctrl+C
event.enter?       # Enter key
event.shift_up?    # Shift+Up
event.q?           # "q" key
event.esc?         # Escape
event.space?       # Space bar
event.tab?         # Tab key
```

DWIM (Do What I Mean) shortcuts:

```ruby
event.pause?       # Matches "pause" and "media_pause"
event.play?        # Matches "media_play"
```

### Character Detection

```ruby
event.text?        # True for printable characters
event.char         # Character or nil for special keys
event.to_s         # Character or empty string
```

### Key Categories

**Navigation:**
- `up`, `down`, `left`, `right`
- `home`, `end`, `page_up`, `page_down`
- `insert`, `delete`

**System:**
- `print_screen`, `pause`, `menu`

**Media:**
- `play`, `media_pause`, `play_pause`, `stop`
- `track_next`, `track_previous`
- `mute_volume`, `lower_volume`, `raise_volume`

**Modifiers:**
- `left_shift`, `right_shift`
- `left_control`, `right_control`
- `left_alt`, `right_alt`

### Pattern Matching

```ruby
case event
in type: :key, code: "c", modifiers: ["ctrl"]
  break
in type: :key, code: "q"
  break
in type: :key, kind: :media
  handle_media_key
in type: :key, code: "j"
  move_down
in type: :key, code: "k"
  move_up
end
```

## Mouse Events

### Attributes

```ruby
event.kind       # "down", "up", "drag", "moved", "scroll_up", "scroll_down"
event.button     # "left", "right", "middle", "none", nil
event.x          # Column coordinate (zero-indexed)
event.y          # Row coordinate (zero-indexed)
event.modifiers  # Active keyboard modifiers
```

### Event Type Methods

```ruby
event.down?        # Button pressed
event.up?          # Button released
event.drag?        # Dragging
event.scroll_up?   # Scroll up
event.scroll_down? # Scroll down
```

### Usage

```ruby
if event.mouse? && event.down? && event.button == "left"
  handle_click(event.x, event.y)
end
```

### Pattern Matching

```ruby
case event
in type: :mouse, kind: "down", button: "left", x:, y:
  handle_click(x, y)
in type: :mouse, kind: "drag", x:, y:
  handle_drag(x, y)
in type: :mouse, kind: "scroll_up"
  scroll_up
in type: :mouse, kind: "scroll_down"
  scroll_down
end
```

## Resize Events

### Attributes

```ruby
event.width      # New terminal width in columns
event.height     # New terminal height in rows
```

### Usage

```ruby
if event.resize?
  recalculate_layout(event.width, event.height)
end
```

### Pattern Matching

```ruby
case event
in type: :resize, width:, height:
  update_dimensions(width, height)
end
```

## Paste Events

Handles pasted text as atomic action (prevents rapid keystroke flood).

### Attributes

```ruby
event.content    # Pasted text string
```

### Usage

```ruby
if event.paste?
  insert_text(event.content)
end
```

### Pattern Matching

```ruby
case event
in type: :paste, content:
  process_pasted_content(content)
end
```

## Focus Events

Track terminal window focus state. **Limited terminal support** (iTerm2, Kitty, newer xterm).

### FocusGained

```ruby
if event.focus_gained?
  resume_animations
  refresh_data
end
```

### FocusLost

```ruby
if event.focus_lost?
  pause_animations
  reduce_polling_frequency
end
```

### Pattern Matching

```ruby
case event
in type: :focus_gained
  restore_foreground_mode
in type: :focus_lost
  enter_background_mode
end
```

## None Events (Null Object)

Returns when no input available. Eliminates nil-checks:

```ruby
if event.none?
  # Timeout expired, continue rendering
  update_clock_display
end

# Safe to call predicates (all return false)
event.ctrl_c?  # => false
event.key?     # => false
```

## Complete Event Loop

```ruby
RatatuiRuby.run do |tui|
  loop do
    tui.draw { |frame| render_view(model, frame) }

    case tui.poll_event
  # Exit conditions
  in {type: :key, code: "q"} | {type: :key, code: "c", modifiers: ["ctrl"]}
    break

  # Navigation
  in type: :key, code: "up" | "k"
    model = move_up(model)
  in type: :key, code: "down" | "j"
    model = move_down(model)
  in type: :key, code: "enter"
    model = activate(model)

  # Mouse
  in type: :mouse, kind: "down", button: "left", x:, y:
    model = handle_click(model, x, y)
  in type: :mouse, kind: "scroll_up"
    model = scroll_up(model)
  in type: :mouse, kind: "scroll_down"
    model = scroll_down(model)

  # Terminal
  in type: :resize, width:, height:
    model = update_layout(model, width, height)
  in type: :paste, content:
    model = insert_text(model, content)

  # Focus
  in type: :focus_lost
    model = enter_background(model)
  in type: :focus_gained
    model = resume_foreground(model)

  else
    # Catch unmatched events (required to prevent NoMatchingPatternError)
    nil
  end
  end
end
```

## Event Handling Patterns

### Helper Method Approach

```ruby
event = tui.poll_event
break if event.ctrl_c?
@list_state.select_next if event.down? || event.j?
@list_state.select_previous if event.up? || event.k?
```

### Predicate Chain

```ruby
event = tui.poll_event
case
when event.ctrl_c? then break
when event.enter? then activate_selection
when event.up?, event.k? then move_up
when event.down?, event.j? then move_down
end
```

### Mixed Pattern Matching

```ruby
case tui.poll_event
in Event::Key if _1.ctrl_c?
  break
in Event::Key => e if e.text?
  insert_character(e.char)
in Event::Mouse => e if e.down?
  handle_click(e.x, e.y)
end
```

## Terminal Compatibility Notes

Some key combinations intercepted by terminal emulators:
- Ctrl+PageUp/PageDown (tab switching)
- Ctrl+Tab
- Cmd+key (macOS)

For broader key support, use Kitty, WezTerm, or Alacritty with enhanced key protocols.

## Quick Reference

| Event Type | Key Attributes | Common Predicates |
|------------|----------------|-------------------|
| Key | `code`, `modifiers`, `kind` | `ctrl_c?`, `enter?`, `up?`, `down?`, `text?` |
| Mouse | `kind`, `button`, `x`, `y`, `modifiers` | `down?`, `up?`, `drag?`, `scroll_up?` |
| Resize | `width`, `height` | `resize?` |
| Paste | `content` | `paste?` |
| FocusGained | — | `focus_gained?` |
| FocusLost | — | `focus_lost?` |
| None | — | `none?` |
