# Render order demonstration - later items appear on top

def tick args
  # Layer 1: Background
  args.outputs.solids << { x: 0, y: 0, w: 1280, h: 720, r: 50, g: 50, b: 80 }

  # Layer 2: Ground
  args.outputs.solids << { x: 0, y: 0, w: 1280, h: 200, r: 100, g: 150, b: 100 }

  # Layer 3: Objects (back to front)
  args.outputs.sprites << { x: 100, y: 150, w: 100, h: 150, path: :solid, r: 34, g: 100, b: 34 }
  args.outputs.sprites << { x: 180, y: 150, w: 100, h: 150, path: :solid, r: 34, g: 139, b: 34 }
  args.outputs.sprites << { x: 260, y: 150, w: 100, h: 150, path: :solid, r: 50, g: 200, b: 50 }

  args.outputs.labels << { x: 150, y: 120, text: "Back",   anchor_x: 0.5 }
  args.outputs.labels << { x: 230, y: 120, text: "Middle", anchor_x: 0.5 }
  args.outputs.labels << { x: 310, y: 120, text: "Front",  anchor_x: 0.5 }

  # Layer 4: UI (always on top)
  args.outputs.solids << { x: 0, y: 680, w: 1280, h: 40, r: 0, g: 0, b: 0, a: 200 }
  args.outputs.labels << {
    x: 640, y: 700,
    text: "UI Layer - rendered last, appears on top",
    anchor_x: 0.5, r: 255, g: 255, b: 255
  }

  args.outputs.labels << {
    x: 640, y: 550,
    text: "Order: Background -> Ground -> Objects -> UI",
    anchor_x: 0.5, size_px: 20
  }
end
