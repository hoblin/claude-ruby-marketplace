# Demonstrates sprite rendering with hash properties
# Shows position, size, path, angle, and alpha (transparency)

def tick args
  # Basic sprite rendering
  args.outputs.sprites << {
    x: 100,
    y: 200,
    w: 128,
    h: 101,
    path: 'dragonruby.png'
  }

  # Sprite with animated alpha (fading effect)
  args.outputs.sprites << {
    x: 300,
    y: 200,
    w: 128,
    h: 101,
    path: 'dragonruby.png',
    a: Kernel.tick_count % 255
  }

  # Rotating sprite with anchoring
  args.outputs.sprites << {
    x: 500,
    y: 250,
    w: 128,
    h: 101,
    path: 'dragonruby.png',
    angle: Kernel.tick_count % 360,
    anchor_x: 0.5,
    anchor_y: 0.5
  }
end
