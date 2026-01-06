# Filled rectangles and borders using args.outputs.primitives
# Use primitive_marker: :solid or :border for rectangle types

def tick args
  # Background using primitives
  args.outputs.primitives << {
    x: 0, y: 0, w: 1280, h: 720,
    r: 32, g: 32, b: 32,
    primitive_marker: :solid
  }

  # Solids with primitive_marker (recommended for FIFO control)
  args.outputs.primitives << {
    x: 100, y: 500, w: 100, h: 100,
    primitive_marker: :solid
  }

  args.outputs.primitives << {
    x: 220, y: 500, w: 100, h: 100,
    r: 255, g: 0, b: 0,
    primitive_marker: :solid
  }

  args.outputs.primitives << {
    x: 340, y: 500, w: 100, h: 100,
    r: 0, g: 255, b: 0, a: 128,
    primitive_marker: :solid
  }

  args.outputs.primitives << {
    x: 460, y: 500, w: 100, h: 100,
    r: 0, g: 128, b: 255, a: 200,
    primitive_marker: :solid
  }

  # path: :solid for better performance with many rectangles
  # (auto-detected as sprite, no primitive_marker needed)
  args.outputs.primitives << {
    x: 580, y: 500, w: 100, h: 100,
    path: :solid,
    r: 255, g: 255, b: 0
  }

  # Borders with primitive_marker
  args.outputs.primitives << {
    x: 100, y: 300, w: 100, h: 100,
    r: 255, g: 255, b: 255,
    primitive_marker: :border
  }

  args.outputs.primitives << {
    x: 220, y: 300, w: 100, h: 100,
    r: 0, g: 255, b: 255,
    primitive_marker: :border
  }

  # Labels explaining the approach
  args.outputs.primitives << { x: 340, y: 640, text: "primitive_marker: :solid", size_px: 18 }
  args.outputs.primitives << { x: 580, y: 640, text: "path: :solid (performance)", size_px: 18 }
  args.outputs.primitives << { x: 160, y: 440, text: "primitive_marker: :border", size_px: 18 }
end
