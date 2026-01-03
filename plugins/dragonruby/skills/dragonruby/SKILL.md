---
name: DragonRuby Game Toolkit
description: This skill should be used when the user asks to "create a game", "make a game", "game development", "dragonruby", "drgtk", "game loop", "tick method", "sprite rendering", "game state", or mentions args.outputs, args.state, args.inputs, coordinate system, collision detection, animation frames, or scene management. Should also be used when editing DragonRuby game files, working on 2D game logic, or discussing game performance optimization.
version: 0.1.0
---

# DragonRuby Game Toolkit

This skill provides comprehensive guidance for building 2D games with DragonRuby Game Toolkit (DRGTK). Use for game loop implementation, sprite rendering, input handling, collision detection, animation, and scene management.

## Quick Reference

### Basic Game Structure

```ruby
def boot args
  args.state = {}
end

def tick args
  # Called 60 times per second
  args.state.player ||= { x: 640, y: 360, w: 50, h: 50, path: 'player.png' }

  # Handle input
  args.state.player.x += 5 if args.inputs.right
  args.state.player.x -= 5 if args.inputs.left

  # Render
  args.outputs.sprites << args.state.player
end
```

### Key Concepts

| Concept | Purpose |
|---------|---------|
| `def tick(args)` | Main game loop (60 FPS) |
| `args.outputs` | Render sprites, labels, primitives |
| `args.state` | Persistent game data storage |
| `args.inputs` | Keyboard, mouse, controller input |
| `args.grid` | Screen dimensions (1280x720) |
| `args.geometry` | Collision detection helpers |

### Coordinate System

- **Screen**: 1280x720 pixels
- **Origin**: Bottom-left (0, 0)
- **Y-axis**: Increases upward

```
(0, 720) ─────────────── (1280, 720)
    │                        │
    │     1280 × 720         │
    │                        │
(0, 0) ─────────────── (1280, 0)
```

## Rendering Primitives

### Sprites (Images)

```ruby
args.outputs.sprites << {
  x: 100, y: 100, w: 64, h: 64,
  path: 'sprites/player.png',
  angle: 45,
  anchor_x: 0.5, anchor_y: 0.5,
  r: 255, g: 255, b: 255, a: 255,
  flip_horizontally: false
}
```

### Labels (Text)

```ruby
args.outputs.labels << {
  x: 640, y: 360,
  text: "Score: #{args.state.score}",
  size_px: 22,
  anchor_x: 0.5, anchor_y: 0.5,
  r: 255, g: 255, b: 255
}
```

### Solids and Borders

```ruby
# Filled rectangle (prefer sprites with path: :solid)
args.outputs.sprites << { x: 0, y: 0, w: 100, h: 100, path: :solid, r: 255, g: 0, b: 0 }

# Outline rectangle
args.outputs.borders << { x: 0, y: 0, w: 100, h: 100, r: 0, g: 0, b: 0 }
```

## State Management

Use `args.state` with `||=` for lazy initialization:

```ruby
def tick args
  args.state.player ||= { x: 640, y: 360 }
  args.state.enemies ||= []
  args.state.score ||= 0
  args.state.scene ||= :title
end
```

## Input Handling

### Unified Input (Keyboard + Controller)

```ruby
# Directional (arrows, WASD, gamepad)
args.inputs.up / down / left / right

# Magnitude values
args.inputs.left_right  # -1, 0, or 1
args.inputs.up_down     # -1, 0, or 1
```

### Keyboard

```ruby
args.inputs.keyboard.key_down.space   # Pressed this frame
args.inputs.keyboard.key_held.space   # Held down
args.inputs.keyboard.key_up.space     # Released this frame
```

### Mouse

```ruby
args.inputs.mouse.click               # Any button clicked
args.inputs.mouse.x / .y              # Position
args.inputs.mouse.inside_rect?(rect)  # Collision check
```

## Collision Detection

```ruby
if args.geometry.intersect_rect?(player, enemy)
  enemy.dead = true
  args.state.score += 1
end

# Clean up dead entities
args.state.enemies.reject! { |e| e.dead }
```

## Animation

```ruby
# Frame-based animation
sprite_index = 0.frame_index(count: 6, hold_for: 8, repeat: true)
args.state.player.path = "sprites/player-#{sprite_index}.png"
```

## Scene Management

```ruby
def tick args
  args.state.scene ||= :title
  send("#{args.state.scene}_tick", args)
end

def title_tick args
  args.outputs.labels << { x: 640, y: 400, text: "Press SPACE", anchor_x: 0.5 }
  args.state.scene = :gameplay if args.inputs.keyboard.key_down.space
end

def gameplay_tick args
  # Game logic here
end
```

## Best Practices

### Do

- Use hash syntax for sprites/labels (clearer than arrays)
- Use `||=` for state initialization
- Remove offscreen entities to prevent memory leaks
- Update logic before rendering
- Use `$gtk.reset` during development to reset state

### Don't

- Hardcode magic numbers (use constants like `FPS = 60`)
- Forget early returns in scene methods
- Render before updating state (causes 1-frame lag)
- Let collections grow infinitely (reject dead entities)

## Additional Resources

### Reference Files

For detailed API documentation and patterns:

- **`references/core.md`** - Game loop, args object, rendering, coordinates, state management

### Example Files

Working code in `examples/`:

- **`examples/core/hello_world.rb`** - Minimal tick with labels
- **`examples/core/sprites.rb`** - Sprite rendering with rotation, alpha
- **`examples/core/labels.rb`** - Text alignment, size, colors
- **`examples/core/state_management.rb`** - args.state with ||= pattern
- **`examples/core/coordinate_system.rb`** - Bottom-left origin demo

## Development Workflow

```ruby
def tick args
  # Game logic
end

$gtk.reset  # Add at end during development
```

### Reset Methods

```ruby
$gtk.reset            # Immediate reset
$gtk.reset_next_tick  # Reset before next tick (safer)
```

### Debug Output

```ruby
args.outputs.debug << "Frame: #{Kernel.tick_count}"
args.outputs.debug.watch args.state.player
```
