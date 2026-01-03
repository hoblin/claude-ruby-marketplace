# DragonRuby Core Reference

## Game Loop

DragonRuby runs at **60 FPS**. The `tick` method executes every frame (~16ms).

```ruby
def boot args
  args.state = {}  # Initialize state (required in future versions)
end

def tick args
  # Called 60 times per second
  # All game logic goes here
end

def reset args
  # Called BEFORE $gtk.reset executes
end
```

### Time Conversions

```ruby
FPS = 60

# Seconds to ticks
timer = 30 * FPS  # 1800 ticks = 30 seconds

# Ticks to seconds
remaining = (args.state.timer / FPS).round

# Helper methods
1.seconds  # => 60 frames
5.seconds  # => 300 frames
```

### Tick Counters

```ruby
Kernel.tick_count         # Resets on $gtk.reset
Kernel.global_tick_count  # Never resets
```

## Coordinate System

- **Resolution**: 1280×720 (auto-scaled)
- **Origin**: Bottom-left `(0, 0)`
- **Top-right**: `(1280, 720)`
- **Y increases upward** (unlike most engines)

```
(0, 720)              (1280, 720)
  ┌─────────────────────┐
  │                     │
  │     1280 × 720      │
  │                     │
  └─────────────────────┘
(0, 0)                (1280, 0)
```

### Movement Directions

```ruby
player.x += speed  # Right
player.x -= speed  # Left
player.y += speed  # Up
player.y -= speed  # Down
```

### Grid Helpers

```ruby
args.grid.w       # 1280
args.grid.h       # 720
args.grid.left    # 0
args.grid.right   # 1280
args.grid.top     # 720
args.grid.bottom  # 0

# Positioning from top
y: 30.from_top    # 30 pixels from top
```

## args Object

The `args` parameter contains everything needed for the game:

| Property | Purpose |
|----------|---------|
| `args.outputs` | Render to screen |
| `args.state` | Persistent game data |
| `args.inputs` | Keyboard/mouse/controller |
| `args.grid` | Screen dimensions |
| `args.geometry` | Collision helpers |
| `args.audio` | Sound playback |

## args.state - Game State

Persistent data storage across ticks. Use `||=` for lazy initialization.

```ruby
args.state.player ||= { x: 120, y: 280, health: 100 }
args.state.enemies ||= []
args.state.score ||= 0
args.state.scene ||= :title

# Arbitrary nesting
args.state.player.x += 5
args.state.level.enemies ||= []
```

### Entity Properties (Auto-Added)

When storing objects in `args.state`, they get these properties:
- `entity_id` - Unique identifier
- `entity_type` - Symbol type
- `created_at` - Tick when created
- `created_at_elapsed` - Ticks since creation

## args.outputs - Rendering

### Render Order (bottom to top)

1. `solids` - Filled rectangles
2. `sprites` - Images
3. `primitives` - Mixed types
4. `labels` - Text
5. `lines` - Line segments
6. `borders` - Outline rectangles
7. `debug` - Debug only (not in production)

### Sprites

```ruby
# Hash syntax (RECOMMENDED)
args.outputs.sprites << {
  x: 100, y: 100,
  w: 128, h: 128,
  path: "sprites/player.png",

  # Anchoring (default: bottom-left)
  anchor_x: 0.5, anchor_y: 0.5,  # Center

  # Rotation
  angle: 45,
  angle_anchor_x: 0.5, angle_anchor_y: 0.5,

  # Color/opacity
  r: 255, g: 255, b: 255, a: 255,

  # Flipping
  flip_horizontally: false,
  flip_vertically: false,

  # Blending
  blendmode_enum: 1  # 0=none, 1=alpha, 2=additive
}

# Array syntax (quick prototyping only)
args.outputs.sprites << [100, 100, 128, 128, "sprites/player.png"]
```

### Labels

```ruby
args.outputs.labels << {
  x: 640, y: 360,
  text: "Score: #{score}",
  size_enum: 0,       # -2=18px, -1=20px, 0=22px, 1=24px, 2=26px
  size_px: 22,        # Or exact pixels
  alignment_enum: 1,  # 0=left, 1=center, 2=right
  vertical_alignment_enum: 1,  # 0=bottom, 1=center, 2=top
  anchor_x: 0.5, anchor_y: 0.5,
  r: 255, g: 255, b: 255, a: 255,
  font: "fonts/custom.ttf"
}
```

**Note**: Label default anchor is TOP-LEFT (unlike sprites which use bottom-left).

### Solids and Borders

```ruby
# Filled rectangle
args.outputs.solids << { x: 0, y: 0, w: 100, h: 100, r: 255, g: 0, b: 0 }

# Outline rectangle
args.outputs.borders << { x: 0, y: 0, w: 100, h: 100, r: 0, g: 0, b: 0 }

# BETTER: Use sprite with :solid (cached, better performance)
args.outputs.sprites << { x: 0, y: 0, w: 100, h: 100, path: :solid, r: 255, g: 0, b: 0 }
```

### Lines

```ruby
args.outputs.lines << {
  x: 100, y: 100,
  x2: 200, y2: 200,
  r: 0, g: 0, b: 0, a: 255
}
```

### Batch Rendering

```ruby
# Push multiple items efficiently
args.outputs.sprites << [player, *enemies, *fireballs]
```

## Project Structure

```
mygame/
  app/
    main.rb         # Entry point with def tick(args)
  sprites/          # PNG, JPG images
  sounds/           # WAV, OGG audio
  fonts/            # TTF fonts
  data/             # Game data files
  metadata/
    game_metadata.txt
```

### Asset Paths

```ruby
# Relative to mygame/
path: "sprites/player.png"  # mygame/sprites/player.png
font: "fonts/custom.ttf"    # mygame/fonts/custom.ttf
```

## Hot Reload

Code auto-reloads on save. State persists unless reset.

```ruby
# Force state reset during development
def tick args
  # ... game logic
end

$gtk.reset  # Add at end of file

# Or reset before next tick (safer during tick)
$gtk.reset_next_tick
```

## Hash vs Array Syntax

| Syntax | Use Case |
|--------|----------|
| Hash | Production code, clarity |
| Array | Quick prototyping only |

```ruby
# Hash - PREFERRED
{ x: 100, y: 200, w: 32, h: 32, path: "player.png" }

# Array - position meanings unclear
[100, 200, 32, 32, "player.png"]
```

## Tick Structure Pattern

```ruby
def tick args
  # 1. Initialize state
  args.state.player ||= { x: 640, y: 360 }

  # 2. Handle input
  args.state.player.x += 5 if args.inputs.right

  # 3. Update game logic
  update_enemies(args)
  check_collisions(args)

  # 4. Render (always last!)
  args.outputs.sprites << args.state.player
end
```

## Class-Based Development

```ruby
class Game
  attr_gtk  # Adds state, inputs, outputs, etc.

  def tick
    @player ||= { x: 0, y: 0 }
    @player.x += 1
    outputs.sprites << @player  # No args. prefix needed
  end
end

def tick args
  $game ||= Game.new
  $game.args = args
  $game.tick
end

def reset args
  $game = nil
end
```

## Debug Output

```ruby
# Debug labels (not in production builds)
args.outputs.debug << "Frame: #{Kernel.tick_count}"
args.outputs.debug << { x: 10, y: 10, text: "FPS: #{$gtk.current_framerate}" }

# Watch variables
args.outputs.debug.watch args.state.player
```

## Common Antipatterns

### State Persistence During Hot Reload

```ruby
# WRONG: Changed value doesn't apply
args.state.player_x ||= 200  # Still uses old value

# FIX: Add $gtk.reset at end of file
```

### Magic Numbers

```ruby
# WRONG
args.state.timer = 30 * 60

# RIGHT
FPS = 60
args.state.timer = 30 * FPS
```

### Infinite Collections

```ruby
# WRONG: Memory leak
args.state.fireballs.each { |f| f.x += 5 }

# RIGHT: Remove offscreen
args.state.fireballs.each do |f|
  f.x += 5
  f.dead = true if f.x > args.grid.w
end
args.state.fireballs.reject! { |f| f.dead }
```

### Render Before Update

```ruby
# WRONG: Off by 1 frame
args.outputs.sprites << player
player.x += 5

# RIGHT: Update then render
player.x += 5
args.outputs.sprites << player
```

### Missing Early Return

```ruby
# WRONG: Game still runs after game over
if game_over?
  show_game_over(args)
end
handle_input(args)  # Still executes!

# RIGHT
if game_over?
  show_game_over(args)
  return
end
handle_input(args)
```

## Decision Tree

```
What are you trying to do?
├─ Display text → examples/core/labels.rb
├─ Show an image → examples/core/sprites.rb
├─ Store game data → examples/core/state_management.rb
├─ Basic game structure → examples/core/hello_world.rb
└─ Understand coordinates → examples/core/coordinate_system.rb
```

## Examples

| File | Demonstrates |
|------|--------------|
| `examples/core/hello_world.rb` | Minimal tick method, basic rendering |
| `examples/core/sprites.rb` | Image rendering, anchors, rotation, color |
| `examples/core/labels.rb` | Text display, alignment, sizing, fonts |
| `examples/core/state_management.rb` | args.state, ||= initialization, persistence |
| `examples/core/coordinate_system.rb` | Grid helpers, positioning, movement directions |
