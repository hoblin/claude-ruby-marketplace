# Input Handling Reference

DragonRuby provides unified input through `args.inputs`, supporting keyboard, mouse, controller (up to 4), and touch devices.

## Unified Directional Input

Combine keyboard (arrows + WASD) and controller_one automatically:

```ruby
# Boolean checks - true if any matching input active
args.inputs.up        # Arrow up, W, dpad up, analog up
args.inputs.down      # Arrow down, S, dpad down, analog down
args.inputs.left      # Arrow left, A, dpad left, analog left
args.inputs.right     # Arrow right, D, dpad right, analog right

# Numeric values: -1, 0, or +1
args.inputs.left_right    # Horizontal: -1 left, 0 neutral, +1 right
args.inputs.up_down       # Vertical: -1 down, 0 neutral, +1 up

# Float values: -1.0 to +1.0 (analog-aware)
args.inputs.left_right_perc   # Prioritizes analog stick magnitude
args.inputs.up_down_perc      # Prioritizes analog stick magnitude

# Normalized vector for diagonal-safe movement
args.inputs.directional_vector  # { x: 0.707, y: 0.707 } or nil
args.inputs.directional_angle   # Degrees 0-360 or nil
```

### Directional Variants

| Method | WASD | Arrows | D-Pad | Analog | Returns |
|--------|------|--------|-------|--------|---------|
| `left_right` | ✓ | ✓ | ✓ | ✓ (60%) | -1, 0, +1 |
| `left_right_perc` | ✓ | ✓ | ✓ | ✓ | -1.0 to +1.0 |
| `left_right_directional` | ✗ | ✓ | ✓ | ✗ | -1, 0, +1 |
| `left_right_directional_perc` | ✗ | ✓ | ✓ | ✓ | -1.0 to +1.0 |

Same pattern for `up_down*` variants.

---

## Keyboard Input

Access via `args.inputs.keyboard`:

### Key States

```ruby
args.inputs.keyboard.key_down.space   # First frame pressed
args.inputs.keyboard.key_held.space   # Every frame while held
args.inputs.keyboard.key_up.space     # Frame released
args.inputs.keyboard.space            # Down OR held (shorthand)
args.inputs.keyboard.key_repeat.space # OS key repeat rate
```

### Dynamic Key Queries

```ruby
args.inputs.keyboard.key_down?(:enter)
args.inputs.keyboard.key_held?(:enter)
args.inputs.keyboard.key_up?(:enter)
args.inputs.keyboard.key_down_or_held?(:enter)
```

### Key Names Reference

| Category | Keys |
|----------|------|
| Letters | `a` through `z` |
| Numbers | `zero`, `one`, ... `nine` |
| Arrows | `left`, `right`, `up`, `down` (aliases for `left_arrow`, etc.) |
| Modifiers | `shift`, `ctrl`, `alt`, `meta` (+ `_left`, `_right` variants) |
| Function | `f1` through `f12` |
| Special | `space`, `enter`, `escape`, `tab`, `backspace`, `delete` |
| Navigation | `home`, `end`, `page_up`, `page_down`, `insert` |
| Numpad | `kp_zero` ... `kp_nine`, `kp_plus`, `kp_enter`, etc. |
| WASD Scancode | `w_scancode`, `a_scancode`, `s_scancode`, `d_scancode` |

### Modifier Combinations

```ruby
args.inputs.keyboard.ctrl_s     # Ctrl+S
args.inputs.keyboard.shift_a    # Shift+A
args.inputs.keyboard.alt_enter  # Alt+Enter
```

### Keyboard Helpers

```ruby
args.inputs.keyboard.truthy_keys  # Array of currently pressed keys
args.inputs.keyboard.has_focus    # true if game has keyboard focus
args.inputs.keyboard.active       # tick_count if any key pressed
args.inputs.text                  # String of last key pressed
```

---

## Controller Input

Access via `args.inputs.controller_one` (through `controller_four`):

### Connection

```ruby
args.inputs.controller_one.connected  # true if controller present
args.inputs.controller_one.name       # Controller name string
```

### Buttons

```ruby
# Same state pattern as keyboard
args.inputs.controller_one.key_down.a   # Just pressed
args.inputs.controller_one.key_held.a   # Being held
args.inputs.controller_one.key_up.a     # Just released
args.inputs.controller_one.a            # Down or held
```

| Category | Buttons |
|----------|---------|
| Face | `a`, `b`, `x`, `y` |
| D-Pad | `dpad_up`, `dpad_down`, `dpad_left`, `dpad_right` |
| Shoulder | `l1`, `r1`, `l2`, `r2` |
| Sticks | `l3` (left click), `r3` (right click) |
| System | `start`, `select`, `home` |

### Analog Sticks

```ruby
# Raw values: -32767 to +32767
args.inputs.controller_one.left_analog_x_raw
args.inputs.controller_one.left_analog_y_raw

# Percentage: -1.0 to +1.0
args.inputs.controller_one.left_analog_x_perc
args.inputs.controller_one.left_analog_y_perc

# Angle in degrees (nil if centered)
args.inputs.controller_one.left_analog_angle
args.inputs.controller_one.right_analog_angle

# Active check with threshold
args.inputs.controller_one.left_analog_active?(threshold_perc: 0.2)
```

### Directional Helpers (Controller-specific)

```ruby
# Combines D-pad + analog
args.inputs.controller_one.up       # D-pad or analog up
args.inputs.controller_one.left_right  # -1, 0, +1
args.inputs.controller_one.up_down     # -1, 0, +1
```

### Dead Zone

```ruby
args.inputs.controller_one.analog_dead_zone = 3600  # Default raw value
```

---

## Mouse Input

Access via `args.inputs.mouse`:

### Position

```ruby
args.inputs.mouse.x           # Current x
args.inputs.mouse.y           # Current y
args.inputs.mouse.moved       # true if moved this frame
args.inputs.mouse.relative_x  # Delta from previous frame
args.inputs.mouse.relative_y  # Delta from previous frame
```

### Button States

```ruby
# Simple boolean
args.inputs.mouse.button_left    # true if left down
args.inputs.mouse.button_middle
args.inputs.mouse.button_right

# Key state pattern
args.inputs.mouse.key_down.left   # Just pressed
args.inputs.mouse.key_held.left   # Being held
args.inputs.mouse.key_up.left     # Just released
```

### Click Events

```ruby
if (click = args.inputs.mouse.click)
  click.x               # Click x position
  click.y               # Click y position
  click.created_at      # Tick when clicked
end
```

### Click vs Drag Detection

```ruby
button = args.inputs.mouse.buttons.left

button.buffered_click  # true if quick click (not drag)
button.buffered_held   # true if held/dragging
button.click_at        # When click started
button.up_at           # When released
```

### Scroll Wheel

```ruby
if (wheel = args.inputs.mouse.wheel)
  wheel.x  # Horizontal scroll
  wheel.y  # Vertical scroll (positive = up)
end
```

### Collision Helpers

```ruby
args.inputs.mouse.inside_rect?({ x: 100, y: 100, w: 50, h: 50 })
args.inputs.mouse.inside_circle?({ x: 640, y: 360 }, radius: 100)
```

---

## Touch Input

For mobile/touch devices:

```ruby
# Simple finger access (nil if not touching)
args.inputs.finger_one   # { x:, y: }
args.inputs.finger_two   # { x:, y: }

# Side-based helpers
args.inputs.finger_left   # Touch on left side
args.inputs.finger_right  # Touch on right side

# Multi-touch hash
args.inputs.touch.each do |id, touch|
  touch.x
  touch.y
  touch.touch_order  # Order of touch (0-indexed)
  touch.moved        # Boolean
end

# Pinch zoom
args.inputs.pinch_zoom  # Pinch zoom amount
```

---

## Grid Boundaries

Use `args.grid` for screen boundaries:

```ruby
args.grid.w          # 1280 (width)
args.grid.h          # 720 (height)
args.grid.left       # 0
args.grid.right      # 1280
args.grid.top        # 720
args.grid.bottom     # 0
args.grid.center_x   # 640
args.grid.center_y   # 360
```

### Clamping Pattern

```ruby
# Keep entity within screen
entity.x = entity.x.clamp(args.grid.left, args.grid.right - entity.w)
entity.y = entity.y.clamp(args.grid.bottom, args.grid.top - entity.h)
```

---

## Input Source Detection

```ruby
args.inputs.last_active     # :keyboard, :mouse, or :controller
args.inputs.last_active_at  # Tick count of last input
```

---

## Best Practices

### Support Multiple Input Types

```ruby
# Accept action from any source
if args.inputs.keyboard.key_down.space ||
   args.inputs.keyboard.key_down.enter ||
   args.inputs.controller_one.key_down.a
  fire_action
end
```

### Use Unified Helpers for Movement

```ruby
# Instead of checking each key
speed = 5
player.x += args.inputs.left_right * speed
player.y += args.inputs.up_down * speed
```

### Normalize Diagonal Movement

```ruby
# Prevent faster diagonal movement
if (vector = args.inputs.directional_vector)
  player.x += vector.x * speed
  player.y += vector.y * speed
end
```

### Adapt UI to Input Type

```ruby
if args.inputs.last_active == :controller
  show_prompt "Press [A]"
else
  show_prompt "Press [Space]"
end
```

---

## Common Antipatterns

### Checking D-Pad AND Analog Separately

```ruby
# Bad: Redundant checks
if args.inputs.controller_one.dpad_left ||
   args.inputs.controller_one.left_analog_x_perc < -0.5
  move_left
end

# Good: Use built-in helper
if args.inputs.controller_one.left
  move_left
end
```

### Not Using Grid for Boundaries

```ruby
# Bad: Hardcoded values
if player.x > 1280
  player.x = 1280
end

# Good: Use grid constants
if player.x + player.w > args.grid.right
  player.x = args.grid.right - player.w
end
```

### Forgetting Diagonal Speed

```ruby
# Bad: Diagonal is ~1.41x faster
player.x += args.inputs.left_right * speed
player.y += args.inputs.up_down * speed

# Good: Normalized diagonal
if (v = args.inputs.directional_vector)
  player.x += v.x * speed
  player.y += v.y * speed
end
```

---

## Decision Tree

```
What type of movement?
├─ Simple 4-directional → examples/input/directional_input.rb
├─ With boundary clamping → examples/input/movement_with_bounds.rb
├─ Smooth analog → examples/input/analog_movement.rb
└─ Normalized diagonal → examples/input/normalized_movement.rb

What type of action trigger?
├─ One-shot (fire, jump) → use key_down, examples/input/action_triggers.rb
├─ Continuous (hold to run) → use key_held, examples/input/keyboard_input.rb
└─ On release (charge attacks) → use key_up, examples/input/keyboard_input.rb

Mouse interaction?
└─ Click handling → examples/input/mouse_click.rb

Controller input?
└─ Buttons and analog → examples/input/controller_input.rb
```

## Examples

| File | Demonstrates |
|------|--------------|
| `examples/input/directional_input.rb` | 4-directional movement with unified input |
| `examples/input/movement_with_bounds.rb` | Clamping player to screen boundaries |
| `examples/input/analog_movement.rb` | Smooth analog stick movement |
| `examples/input/normalized_movement.rb` | Normalized diagonal movement |
| `examples/input/action_triggers.rb` | One-shot actions with key_down |
| `examples/input/keyboard_input.rb` | Key states: down, held, up |
| `examples/input/mouse_click.rb` | Mouse click detection and position |
| `examples/input/controller_input.rb` | Controller buttons and analog sticks |
