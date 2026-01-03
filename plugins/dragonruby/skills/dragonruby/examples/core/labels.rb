# Demonstrates text rendering with alignment, size, and color

def tick args
  # Different text sizes
  args.outputs.labels << { x: 100, y: 600, text: "Small text", size_px: 18 }
  args.outputs.labels << { x: 100, y: 550, text: "Medium text", size_px: 22 }
  args.outputs.labels << { x: 100, y: 500, text: "Large text", size_px: 26 }

  # Text alignment (centered at x: 640)
  args.outputs.labels << { x: 640, y: 400, text: "Left aligned", anchor_x: 0, anchor_y: 0.5 }
  args.outputs.labels << { x: 640, y: 350, text: "Center aligned", anchor_x: 0.5, anchor_y: 0.5 }
  args.outputs.labels << { x: 640, y: 300, text: "Right aligned", anchor_x: 1, anchor_y: 0.5 }

  # Colored text (RGB values 0-255)
  args.outputs.labels << { x: 100, y: 200, text: "Red text", r: 255, g: 0, b: 0 }
  args.outputs.labels << { x: 100, y: 150, text: "Green text", r: 0, g: 255, b: 0 }
  args.outputs.labels << { x: 100, y: 100, text: "Blue text", r: 0, g: 0, b: 255 }
  args.outputs.labels << { x: 100, y: 50, text: "Faded text", r: 0, g: 0, b: 0, a: 128 }

  # Reference line for alignment demonstration
  args.outputs.lines << { x: 640, y: 0, x2: 640, y2: 720 }
end
