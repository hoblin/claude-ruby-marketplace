# DragonRuby Rendering Primitives

Quick reference for `args.outputs` primitives. Screen: 1280x720, origin bottom-left.

## Render Order (Bottom to Top)

```
1. args.outputs.solids
2. args.outputs.sprites
3. args.outputs.primitives  (custom order, bypasses layers)
4. args.outputs.labels
5. args.outputs.lines
6. args.outputs.borders
7. args.outputs.debug       (dev only, hidden in production)
```

Within each collection: first-in renders first (behind later items).

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

## Mixed Primitives

Use `args.outputs.primitives` for custom render order. Requires `primitive_marker` for ambiguous types:

```ruby
args.outputs.primitives << [
  { x: 0, y: 0, w: 100, h: 100, primitive_marker: :solid },
  { x: 50, y: 50, w: 100, h: 100, path: 'sprite.png' },  # auto-detected
  { x: 100, y: 100, text: "Hello" },                      # auto-detected
  { x: 0, y: 0, x2: 100, y2: 100 }                        # auto-detected
]
```

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

## Common Antipatterns

```ruby
# Magic numbers
if player.x > 1280  # use args.grid.w

# Array syntax
[640, 500, 'Hello', 5, 1]  # use hash

# Manual centering
x: 640 - sprite_w / 2  # use anchor_x: 0.5

# Many solids
100.times { args.outputs.solids << rect }  # use sprites with path: :solid

# Recreating static content every frame
args.outputs.sprites << background  # use static_sprites
```

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
├─ Custom z-order needed?
│  └─ Use args.outputs.primitives with primitive_marker
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
