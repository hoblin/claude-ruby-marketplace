# Image rendering with anchors, rotation, and color tinting

def tick args
  # Basic sprite
  args.outputs.sprites << {
    x: 100, y: 500, w: 128, h: 101,
    path: 'dragonruby.png'
  }

  # Centered with anchors
  args.outputs.sprites << {
    x: 400, y: 500, w: 128, h: 101,
    path: 'dragonruby.png',
    anchor_x: 0.5, anchor_y: 0.5
  }

  # Rotation around center
  args.outputs.sprites << {
    x: 700, y: 500, w: 128, h: 101,
    path: 'dragonruby.png',
    angle: Kernel.tick_count % 360,
    angle_anchor_x: 0.5, angle_anchor_y: 0.5
  }

  # Color tinting, transparency, flipping
  args.outputs.sprites << {
    x: 1000, y: 500, w: 128, h: 101,
    path: 'dragonruby.png',
    r: 255, g: 128, b: 128,
    a: Kernel.tick_count % 255,
    flip_horizontally: true
  }
end
