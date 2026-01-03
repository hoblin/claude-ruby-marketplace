# Text rendering with alignment and sizing

def tick args
  # Size options
  args.outputs.labels << { x: 640, y: 650, text: "Basic Label" }
  args.outputs.labels << { x: 640, y: 600, text: "Small",  size_enum: -1 }
  args.outputs.labels << { x: 640, y: 570, text: "Medium", size_enum: 0 }
  args.outputs.labels << { x: 640, y: 540, text: "Large",  size_enum: 1 }
  args.outputs.labels << { x: 640, y: 500, text: "Custom", size_px: 32 }

  # Alignment with anchors
  args.outputs.labels << { x: 640, y: 450, text: "Left",   anchor_x: 0,   anchor_y: 0.5 }
  args.outputs.labels << { x: 640, y: 420, text: "Center", anchor_x: 0.5, anchor_y: 0.5 }
  args.outputs.labels << { x: 640, y: 390, text: "Right",  anchor_x: 1,   anchor_y: 0.5 }

  # Colors
  args.outputs.labels << { x: 640, y: 340, text: "Red",   r: 255, g: 0,   b: 0 }
  args.outputs.labels << { x: 640, y: 310, text: "Green", r: 0,   g: 255, b: 0 }
  args.outputs.labels << { x: 640, y: 280, text: "Blue",  r: 0,   g: 0,   b: 255 }
  args.outputs.labels << { x: 640, y: 250, text: "Faded", a: 128 }

  # Custom font
  args.outputs.labels << {
    x: 640, y: 200,
    text: "Custom Font",
    font: "fonts/manaspc.ttf",
    size_px: 24, anchor_x: 0.5
  }

  # Reference line
  args.outputs.lines << { x: 640, y: 0, x2: 640, y2: 720, r: 100, g: 100, b: 100 }
end
