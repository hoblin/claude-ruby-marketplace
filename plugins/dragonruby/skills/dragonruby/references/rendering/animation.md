# DragonRuby Animation

Animation timing, sprite sequences, and easing. DragonRuby runs at 60 FPS (60 ticks/second).

## frame_index Method

Core animation API. Called on a timestamp, returns current frame index.

```ruby
# Basic usage - looping animation
frame = 0.frame_index(count: 6, hold_for: 8, repeat: true)
args.state.player.path = "sprites/dragon-#{frame}.png"
```

### Parameters

```ruby
timestamp.frame_index(
  count: 6,           # number of frames
  hold_for: 4,        # ticks per frame (4 ticks = ~67ms)
  repeat: true,       # loop forever or play once
  repeat_index: 0,    # frame to loop back to (skip intro frames)
  tick_count_override: Kernel.tick_count
)
```

**Returns**: Integer (0 to count-1) or `nil` if animation completed and `repeat: false`

### Timing Math

```
Animation duration = count × hold_for ticks
Duration in seconds = (count × hold_for) / 60

Example: 6 frames, hold_for: 8
  Duration = 6 × 8 = 48 ticks = 0.8 seconds
  Cycles per second = 60 / 48 = 1.25
```

### Animation from Event

```ruby
# Trigger animation on keypress
if args.inputs.keyboard.key_down.space
  args.state.attack_at = Kernel.tick_count
end

# Play attack animation once
if args.state.attack_at
  frame = args.state.attack_at.frame_index(count: 4, hold_for: 6, repeat: false)
  frame ||= 3  # stay on last frame when done
end
```

### Skip Intro Frames with repeat_index

```ruby
# Frames 0-2 are "launch", frames 3-8 are "loop"
frame = args.state.action_at.frame_index(
  count: 9,
  hold_for: 8,
  repeat: true,
  repeat_index: 3  # after first playthrough, loop starts at frame 3
)
```

## Spritesheet Animation

Use `tile_*` or `source_*` to crop frames from a single image.

### Horizontal Strip

```ruby
frame = args.state.started_at.frame_index(count: 6, hold_for: 4, repeat: true)
frame ||= 0

args.outputs.sprites << {
  x: 100, y: 100, w: 64, h: 64,
  path: 'sprites/player-run.png',
  tile_x: frame * 64,  # offset by frame width
  tile_y: 0,
  tile_w: 64,
  tile_h: 64
}
```

### Grid Spritesheet

```ruby
def frame_from_grid(index, cols:, tile_size:)
  row = index.idiv(cols)
  col = index % cols

  {
    tile_x: col * tile_size,
    tile_y: row * tile_size,
    tile_w: tile_size,
    tile_h: tile_size
  }
end

frame = args.state.started_at.frame_index(count: 12, hold_for: 4, repeat: true)
sprite = frame_from_grid(frame, cols: 4, tile_size: 32)
sprite.merge!(x: 100, y: 100, w: 64, h: 64, path: 'sprites/sheet.png')
args.outputs.sprites << sprite
```

### tile_* vs source_*

```ruby
# tile_* - origin at TOP-LEFT of image (common for texture atlases)
{ tile_x: 0, tile_y: 0, tile_w: 64, tile_h: 64 }

# source_* - origin at BOTTOM-LEFT of image
{ source_x: 0, source_y: 0, source_w: 64, source_h: 64 }
```

## Direction with Flipping

Mirror sprites instead of separate images per direction:

```ruby
args.state.player.direction ||= 1  # 1=right, -1=left

if args.inputs.left
  args.state.player.direction = -1
elsif args.inputs.right
  args.state.player.direction = 1
end

args.outputs.sprites << {
  x: args.state.player.x, y: args.state.player.y,
  w: 64, h: 64,
  path: 'sprites/player-walk.png',
  flip_horizontally: args.state.player.direction < 0
}
```

## Rotation Animation

```ruby
# Continuous rotation
args.state.angle ||= 0
args.state.angle += 2  # 2 degrees per frame

args.outputs.sprites << {
  x: 640, y: 360, w: 100, h: 100,
  path: 'sprites/wheel.png',
  angle: args.state.angle,
  angle_anchor_x: 0.5,  # rotate around center
  angle_anchor_y: 0.5
}
```

### Movement in Direction of Angle

```ruby
# Move in direction sprite is facing
args.state.player.x += args.state.player.angle.vector_x * speed
args.state.player.y += args.state.player.angle.vector_y * speed
```

## State-Based Animation

```ruby
def tick args
  args.state.player.action ||= :idle
  args.state.player.action_at ||= 0

  # Change state
  if args.inputs.keyboard.key_down.space
    args.state.player.action = :attack
    args.state.player.action_at = Kernel.tick_count
  end

  # Get frame based on state
  frame = case args.state.player.action
  when :idle
    args.state.player.action_at.frame_index(count: 4, hold_for: 12, repeat: true)
  when :attack
    idx = args.state.player.action_at.frame_index(count: 6, hold_for: 4, repeat: false)
    if idx.nil?
      args.state.player.action = :idle
      args.state.player.action_at = Kernel.tick_count
      0
    else
      idx
    end
  else
    0
  end

  args.state.player.path = "sprites/player-#{args.state.player.action}-#{frame}.png"
end
```

## Timing Helpers

### elapsed_time - Ticks Since Event

```ruby
args.state.last_hit_at ||= 0
time_since_hit = args.state.last_hit_at.elapsed_time

if time_since_hit < 30  # flash for 0.5 seconds
  args.state.player.a = (Kernel.tick_count % 10 < 5) ? 255 : 128
end
```

### elapsed? - Check If Duration Passed

```ruby
# Check if 2 seconds have passed
if args.state.spawn_at.elapsed?(120)
  spawn_enemy
  args.state.spawn_at = Kernel.tick_count
end
```

### Numeric.frame - Extended Info

```ruby
info = Numeric.frame(start_at: 0, count: 6, hold_for: 4, repeat: true)
# Returns:
# {
#   frame_index: 2,
#   frame_count: 6,
#   frames_left: 16,
#   started: true,
#   completed: false,
#   elapsed_time: 8,
#   duration: 24
# }
```

## Easing Functions

Smooth animation curves instead of linear movement.

### smooth_start - Accelerating

```ruby
progress = Easing.smooth_start(
  start_at: args.state.tween_start,
  end_at: args.state.tween_start + 60,
  tick_count: Kernel.tick_count,
  power: 2  # 2=quadratic, 3=cubic
)

args.state.player.x = 100 + (500 * progress)  # starts slow, ends fast
```

### smooth_stop - Decelerating

```ruby
progress = Easing.smooth_stop(start_at: 0, end_at: 60, tick_count: t, power: 2)
# starts fast, ends slow
```

### smooth_step - Ease In/Out

```ruby
progress = Easing.smooth_step(start_at: 0, end_at: 60, tick_count: t, power: 2)
# slow start, fast middle, slow end
```

### lerp - Linear Interpolation

```ruby
# Smoothly approach target
args.state.camera_x = args.state.camera_x.lerp(target_x, 0.1)  # 10% per frame
```

### remap - Range Mapping

```ruby
# Convert 0-1 to screen coordinates
x = progress.remap(0, 1, 100, 1180)
```

## Performance Tips

### Cache Calculations

```ruby
# Precompute tile positions
args.state.tile_positions ||= 6.map { |i| i * 64 }
sprite.tile_x = args.state.tile_positions[frame]
```

### Skip When Not Animating

```ruby
if args.state.player.moving
  frame = args.state.player.move_at.frame_index(count: 6, hold_for: 4, repeat: true)
else
  frame = 0  # idle frame, no calculation
end
```

### Use Classes for Many Sprites

```ruby
class AnimatedSprite
  attr_sprite

  def initialize(x, y, path_prefix, frame_count)
    @x, @y, @w, @h = x, y, 64, 64
    @path_prefix = path_prefix
    @frame_count = frame_count
    @started_at = Kernel.tick_count
  end

  def update
    frame = @started_at.frame_index(count: @frame_count, hold_for: 4, repeat: true)
    @path = "#{@path_prefix}#{frame}.png"
  end
end
```

## Best Practices

1. **Store animation start time** - use `Kernel.tick_count` when action begins
2. **Handle nil from frame_index** - returned when one-shot animation ends
3. **Use flip_horizontally** - instead of separate left/right sprites
4. **Use spritesheets** - fewer files, better performance
5. **Cache tile positions** - avoid multiplication every frame
6. **Reset action_at on state change** - ensures animation restarts

## Common Antipatterns

```ruby
# Recalculating from 0 every frame (animation never progresses correctly for one-shots)
frame = 0.frame_index(count: 6, hold_for: 4, repeat: false)

# Not handling nil
path = "sprite-#{frame}.png"  # crashes when frame is nil

# Separate images per direction
path = player.facing_left ? 'player-left.png' : 'player-right.png'
# Use flip_horizontally instead

# Hardcoded frame timing
hold_for: 8  # Magic number
# Define constants: WALK_SPEED = 8, ATTACK_SPEED = 4
```

## Quick Reference

| Need | Solution |
|------|----------|
| Loop animation forever | `repeat: true` |
| Play animation once | `repeat: false`, handle `nil` return |
| Skip intro frames on loop | `repeat_index: N` |
| Flip sprite direction | `flip_horizontally: true` |
| Rotate sprite | `angle: degrees`, `angle_anchor_x/y: 0.5` |
| Smooth movement | `value.lerp(target, 0.1)` |
| Accelerate in | `Easing.smooth_start` |
| Decelerate out | `Easing.smooth_stop` |
| Ease both | `Easing.smooth_step` |
| Time since event | `timestamp.elapsed_time` |
| Check if time passed | `timestamp.elapsed?(duration)` |

## Decision Tree

```
How are your animation frames stored?
│
├─ Separate PNG files (dragon-0.png, dragon-1.png...)?
│  └─ Use frame_index with string interpolation → examples/rendering/frame_animation.rb
│
└─ Single spritesheet image?
   └─ Use frame_index + tile_x/tile_y → examples/rendering/spritesheet_animation.rb

Animation behavior?
│
├─ Loop forever?
│  └─ repeat: true
│
├─ Play once and stop?
│  └─ repeat: false, handle nil return (stay on last frame or switch state)
│
├─ Loop but skip intro frames?
│  └─ Use repeat_index: N
│
└─ Different speeds per action?
   └─ Different hold_for values per state

Character direction?
│
├─ Left/right facing?
│  └─ flip_horizontally: direction < 0
│
└─ Angle-based movement?
   └─ Use angle + vector_x/vector_y

Smooth movement needed?
│
├─ Gradually approach target?
│  └─ value.lerp(target, 0.1)
│
├─ Accelerate from stop?
│  └─ Easing.smooth_start
│
├─ Decelerate to stop?
│  └─ Easing.smooth_stop
│
└─ Smooth in and out?
   └─ Easing.smooth_step
```

## Examples Index

| Example | Purpose |
|---------|---------|
| `examples/rendering/frame_animation.rb` | Separate files, looping + one-shot |
| `examples/rendering/spritesheet_animation.rb` | Single sheet with tile_x/tile_y |
| `examples/rendering/sprites.rb` | Rotation, flipping, tinting |
