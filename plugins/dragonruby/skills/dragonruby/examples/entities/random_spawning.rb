# Random Spawning with Gutters
# Demonstrates safe positioning within screen bounds

def tick(args)
  args.state.enemies ||= []

  # Spawn enemy every 45 frames
  if args.state.tick_count.zmod?(45)
    args.state.enemies << spawn_with_gutters(args)
  end

  # Render enemies
  args.outputs.sprites << args.state.enemies

  # Show play area boundary
  gutter = 50
  args.outputs.borders << [gutter, gutter, 1280 - gutter * 2, 720 - gutter * 2, 128, 128, 128]
  args.outputs.labels << [10, 710, "Enemies spawn within gray boundary"]
end

# Safe spawn: entities never appear partially off-screen
def spawn_with_gutters(args)
  size = 32
  gutter = 50

  # Available spawn area (screen minus gutters on all sides)
  play_w = args.grid.w - gutter * 2 - size
  play_h = args.grid.h - gutter * 2 - size

  {
    x: gutter + rand * play_w,
    y: gutter + rand * play_h,
    w: size,
    h: size,
    path: 'sprites/enemy.png'
  }
end

# Alternative: spawn only on right side of screen
def spawn_right_side(args)
  size = 40
  {
    # Right 40% of screen: rand(width * 0.4) + width * 0.6
    x: rand(args.grid.w * 0.4) + args.grid.w * 0.6,
    # Full height with top/bottom gutters
    y: rand(args.grid.h - size * 2) + size,
    w: size,
    h: size
  }
end
