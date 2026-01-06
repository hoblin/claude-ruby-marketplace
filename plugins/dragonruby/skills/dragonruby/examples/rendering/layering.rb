# FIFO render order demonstration using args.outputs.primitives
# Items render in insertion order - first added = behind, last added = on top

def tick args
  # All rendering uses args.outputs.primitives for FIFO control
  # Each primitive renders ON TOP of previously added primitives

  # 1. Background (rendered first = bottom layer)
  args.outputs.primitives << {
    x: 0, y: 0, w: 1280, h: 720,
    r: 50, g: 50, b: 80,
    primitive_marker: :solid
  }

  # 2. Ground
  args.outputs.primitives << {
    x: 0, y: 0, w: 1280, h: 200,
    r: 100, g: 150, b: 100,
    primitive_marker: :solid
  }

  # 3. Objects (back to front based on insertion order)
  args.outputs.primitives << { x: 100, y: 150, w: 100, h: 150, path: :solid, r: 34, g: 100, b: 34 }
  args.outputs.primitives << { x: 180, y: 150, w: 100, h: 150, path: :solid, r: 34, g: 139, b: 34 }
  args.outputs.primitives << { x: 260, y: 150, w: 100, h: 150, path: :solid, r: 50, g: 200, b: 50 }

  # Labels for objects
  args.outputs.primitives << { x: 150, y: 120, text: "Back",   anchor_x: 0.5 }
  args.outputs.primitives << { x: 230, y: 120, text: "Middle", anchor_x: 0.5 }
  args.outputs.primitives << { x: 310, y: 120, text: "Front",  anchor_x: 0.5 }

  # 4. UI bar (rendered last = top layer)
  args.outputs.primitives << {
    x: 0, y: 680, w: 1280, h: 40,
    r: 0, g: 0, b: 0, a: 200,
    primitive_marker: :solid
  }

  args.outputs.primitives << {
    x: 640, y: 700,
    text: "UI Layer - rendered last with primitives, appears on top",
    anchor_x: 0.5, r: 255, g: 255, b: 255
  }

  # Explanation
  args.outputs.primitives << {
    x: 640, y: 550,
    text: "FIFO: First In = Behind, Last In = On Top",
    anchor_x: 0.5, size_px: 20
  }
end
