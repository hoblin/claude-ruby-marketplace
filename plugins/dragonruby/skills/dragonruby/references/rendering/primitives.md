# DragonRuby Rendering Primitives

Quick reference for `args.outputs` primitives. Screen: 1280x720, origin bottom-left.

## Render Order

### Recommended: FIFO with `args.outputs.primitives`

Use `args.outputs.primitives` for full control over render order. Items render first-in, first-out (FIFO) regardless of type:

```ruby
args.outputs.primitives << { x: 0, y: 0, w: 100, h: 100, r: 255, primitive_marker: :solid }
args.outputs.primitives << { x: 50, y: 50, w: 64, h: 64, path: 'player.png' }  # renders ON TOP of solid
args.outputs.primitives << { x: 60, y: 120, text: "Score: 100" }               # renders ON TOP of sprite
```

### Fixed Layer Order (Typed Outputs)

When using typed outputs, DragonRuby renders in fixed order (bottom to top):

1. `args.outputs.solids`
2. `args.outputs.sprites`
3. `args.outputs.primitives`
4. `args.outputs.labels`
5. `args.outputs.lines`
6. `args.outputs.borders`
7. `args.outputs.debug` (dev only)

**Limitation**: A solid will always render behind a sprite, even if added later. Use `args.outputs.primitives` to bypass this constraint.

## Sprites

Most common primitive. Use hash syntax.

```ruby
args.outputs.sprites << {
  # Position & size (required)
  x: 100, y: 100, w: 64, h: 64,
  path: 'sprites/player.png',

  # Anchors (0.0-1.0, default: 0)
  anchor_x: 0.5,           # 0=left, 0.5=center, 1=right
  anchor_y: 0.5,           # 0=bottom, 0.5=center, 1=top

  # Rotation
  angle: 45,               # degrees clockwise
  angle_anchor_x: 0.5,     # rotation pivot (default: 0.5)
  angle_anchor_y: 0.5,

  # Flipping
  flip_horizontally: false,
  flip_vertically: false,

  # Color tinting (0-255)
  r: 255, g: 255, b: 255,  # saturation
  a: 255,                   # transparency

  # Blending
  blendmode_enum: 1         # 0=none, 1=alpha, 2=additive, 3=mod, 4=multiply
}
```

### Centering a Sprite

```ruby
# Manual offset (avoid)
{ x: 640 - 40, y: 360 - 40, w: 80, h: 80, path: 'sprite.png' }

# With anchors (preferred)
{ x: 640, y: 360, w: 80, h: 80, path: 'sprite.png', anchor_x: 0.5, anchor_y: 0.5 }
```

### Cropping (Spritesheets)

Two coordinate systems:

```ruby
# tile_* - top-left origin (common for texture atlases)
{ tile_x: 0, tile_y: 0, tile_w: 64, tile_h: 64 }

# source_* - bottom-left origin
{ source_x: 0, source_y: 0, source_w: 64, source_h: 64 }
```

### Sprite as Solid (Performance)

Prefer over `args.outputs.solids` for many rectangles:

```ruby
args.outputs.sprites << {
  x: 0, y: 0, w: 100, h: 100,
  path: :solid,
  r: 255, g: 0, b: 0, a: 128
}
```

## Solids

Filled rectangles. **Use sparingly** - textures not cached.

```ruby
args.outputs.solids << {
  x: 0, y: 0,
  w: args.grid.w, h: args.grid.h,  # full screen
  r: 92, g: 120, b: 230,           # RGB (0-255)
  a: 255                            # alpha (optional)
}
```

For many solids, use sprites with `path: :solid` instead.

## Labels

Text rendering. **Note**: Default anchor is TOP-LEFT (unlike other primitives).

```ruby
args.outputs.labels << {
  x: 640, y: 360,
  text: "Score: #{args.state.score}",

  # Size (choose one)
  size_enum: 0,   # -2=18px, -1=20px, 0=22px, 1=24px, 2=26px
  size_px: 22,    # explicit pixels (overrides size_enum)

  # Alignment (legacy)
  alignment_enum: 1,           # 0=left, 1=center, 2=right
  vertical_alignment_enum: 1,  # 0=bottom, 1=center, 2=top

  # Anchors (preferred over alignment_enum)
  anchor_x: 0.5,  # overrides alignment_enum
  anchor_y: 0.5,  # default: 1.0 (top)

  # Color
  r: 0, g: 0, b: 0, a: 255,

  # Font
  font: 'fonts/manaspc.ttf'
}
```

### Common Label Patterns

```ruby
# Top-left score
{ x: 40, y: args.grid.h - 40, text: "Score: #{score}", size_enum: 4 }

# Top-right timer
{ x: args.grid.w - 40, y: args.grid.h - 40, text: "Time: #{time}",
  alignment_enum: 2 }

# Centered title
{ x: 640, y: 400, text: "GAME OVER", size_px: 48,
  anchor_x: 0.5, anchor_y: 0.5 }
```

## Borders

Unfilled rectangles (outlines). Same properties as solids.

```ruby
args.outputs.borders << {
  x: 100, y: 100, w: 200, h: 150,
  r: 255, g: 0, b: 0, a: 255
}
```

## Lines

Line segments between two points.

```ruby
args.outputs.lines << {
  x: 100, y: 100,   # start
  x2: 300, y2: 300, # end
  r: 255, g: 0, b: 0, a: 255
}

# Alternative: relative with w/h
{ x: 100, y: 100, w: 200, h: 200 }  # equivalent to x2: 300, y2: 300
```

## Mixed Primitives (Recommended)

Use `args.outputs.primitives` for FIFO render order control. Requires `primitive_marker` for solids and borders:

```ruby
def tick args
  # All primitives render in insertion order (FIFO)
  args.outputs.primitives << { x: 0, y: 0, w: 1280, h: 720, r: 30, g: 30, b: 50, primitive_marker: :solid }  # background
  args.outputs.primitives << { x: 100, y: 100, w: 64, h: 64, path: 'player.png' }                            # sprite (auto-detected via path)
  args.outputs.primitives << { x: 100, y: 170, text: "Player 1" }                                            # label (auto-detected via text)
  args.outputs.primitives << { x: 90, y: 90, w: 84, h: 100, r: 255, g: 255, b: 0, primitive_marker: :border } # border ON TOP
end
```

### primitive_marker Values

| Type | primitive_marker | Auto-detected by |
|------|------------------|------------------|
| Solid | `:solid` | Required |
| Border | `:border` | Required |
| Sprite | `:sprite` | `path` property |
| Label | `:label` | `text` property |
| Line | `:line` | `x2`/`y2` properties |

## Static Outputs (Performance)

Cache primitives that don't change:

```ruby
# First frame only
if args.state.tick_count == 0
  args.outputs.static_sprites << {
    x: 0, y: 0, w: 1280, h: 720,
    path: 'backgrounds/level1.png'
  }
end

# Clear when needed
args.outputs.static_sprites.clear
```

Available: `static_solids`, `static_sprites`, `static_labels`, `static_lines`, `static_borders`, `static_primitives`

## Debug Output

Rendered only in development, hidden in production builds:

```ruby
args.outputs.debug << { x: 10, y: 710, text: "FPS: #{args.gtk.current_framerate}" }.label!

# Quick watch
args.outputs.debug.watch args.state.player
```

## Background Color

```ruby
args.outputs.background_color = [92, 120, 230]      # RGB
args.outputs.background_color = [92, 120, 230, 255] # RGBA
```

## Hash vs Array Syntax

```ruby
# Array (avoid) - positional, hard to read
args.outputs.sprites << [100, 100, 64, 64, 'sprite.png']
args.outputs.labels << [640, 360, "Text", 0, 1, 255, 255, 255]

# Hash (preferred) - explicit, maintainable
args.outputs.sprites << { x: 100, y: 100, w: 64, h: 64, path: 'sprite.png' }
args.outputs.labels << { x: 640, y: 360, text: "Text", anchor_x: 0.5 }
```

## Class Syntax (Best Performance)

```ruby
class Player
  attr_sprite  # adds all sprite properties

  def initialize
    @x, @y, @w, @h = 100, 100, 64, 64
    @path = 'sprites/player.png'
  end
end

args.outputs.sprites << Player.new
```

Also available: `attr_label`, `attr_line`

## Best Practices

1. **Use hash syntax** - explicit, maintainable
2. **Use `args.grid.w/h`** - not magic numbers
3. **Use anchors for centering** - not manual offset calculations
4. **Use `path: :solid`** - instead of `args.outputs.solids` for many rectangles
5. **Use static outputs** - for backgrounds and unchanging elements
6. **Render in order** - backgrounds first, UI last
7. **Flatten arrays** - DragonRuby handles `sprites << [player, enemies, bullets]`
8. **Use `args.outputs.primitives`** - for full FIFO control over render order

## Common Antipatterns

### Magic Numbers

```ruby
# WRONG - hardcoded screen dimensions
if player.x > 1280
  player.x = 1280
end

# CORRECT - use grid constants
if player.x > args.grid.w
  player.x = args.grid.w
end
```

**Why:** Screen dimensions may vary; grid constants ensure portability.

### Array Syntax

```ruby
# WRONG - positional arguments are hard to read
args.outputs.labels << [640, 500, 'Hello', 5, 1]

# CORRECT - hash syntax is explicit and maintainable
args.outputs.labels << { x: 640, y: 500, text: 'Hello', size_enum: 5, alignment_enum: 1 }
```

**Why:** Array syntax is error-prone and difficult to maintain.

### Manual Centering

```ruby
# WRONG - manual offset calculation
{ x: 640 - sprite_w / 2, y: 360 - sprite_h / 2, w: sprite_w, h: sprite_h, path: 'sprite.png' }

# CORRECT - use anchors
{ x: 640, y: 360, w: sprite_w, h: sprite_h, path: 'sprite.png', anchor_x: 0.5, anchor_y: 0.5 }
```

**Why:** Anchors are clearer and automatically handle size changes.

### Many Solids

```ruby
# WRONG - solids are not cached, poor performance
100.times { |i| args.outputs.solids << { x: i * 10, y: 0, w: 8, h: 100 } }

# CORRECT - use sprites with path: :solid for many rectangles
100.times { |i| args.outputs.sprites << { x: i * 10, y: 0, w: 8, h: 100, path: :solid, r: 255 } }
```

**Why:** Sprites with `path: :solid` are GPU-cached and much faster for many rectangles.

### Recreating Static Content

```ruby
# WRONG - recreates background every frame
def tick(args)
  args.outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: 'background.png' }
end

# CORRECT - use static_sprites (renders once)
def tick(args)
  if Kernel.tick_count == 0
    args.outputs.static_sprites << { x: 0, y: 0, w: 1280, h: 720, path: 'background.png' }
  end
end
```

**Why:** Static outputs are only processed once, reducing per-frame overhead.

## Property Defaults

| Property | Default |
|----------|---------|
| `anchor_x`, `anchor_y` | 0 (bottom-left) |
| `angle` | 0 |
| `r`, `g`, `b` | 255 (sprites), 0 (others) |
| `a` | 255 |
| `blendmode_enum` | 1 (alpha) |
| `flip_horizontally/vertically` | false |

## Decision Tree

```
What do you want to render?
│
├─ Image/texture?
│  └─ Use sprites → examples/rendering/sprites.rb
│
├─ Colored rectangle?
│  ├─ Few rectangles? → Use solids
│  └─ Many rectangles? → Use sprites with path: :solid → examples/rendering/solids.rb
│
├─ Text?
│  └─ Use labels → examples/rendering/labels.rb
│
├─ Outline rectangle?
│  └─ Use borders → examples/rendering/solids.rb
│
├─ Line segment?
│  └─ Use lines
│
├─ Need control over render order?
│  └─ Use args.outputs.primitives with primitive_marker (recommended for most cases)
│
├─ Static content (doesn't change)?
│  └─ Use static_* outputs → once on first frame
│
└─ Debug info only?
   └─ Use args.outputs.debug → hidden in production

Performance concern?
│
├─ Many similar sprites?
│  └─ Use class with attr_sprite
│
├─ Background never changes?
│  └─ Use static_sprites
│
└─ Rendering many rectangles?
   └─ Use sprites with path: :solid instead of solids
```

## Examples Index

| Example | Purpose |
|---------|---------|
| `examples/rendering/solids.rb` | Filled rectangles, backgrounds, borders |
| `examples/rendering/sprites.rb` | Images, anchors, rotation, color tinting |
| `examples/rendering/labels.rb` | Text alignment, sizing, fonts |
| `examples/rendering/layering.rb` | Render order, z-index control |
