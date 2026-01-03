# Demonstrates DragonRuby's coordinate system
# Origin (0, 0) is at BOTTOM-LEFT corner
# Screen size is 1280 x 720 by default

def tick args
  # Show mouse position (updates in real-time)
  pos = args.inputs.mouse.position
  args.outputs.labels << {
    x: pos.x + 10,
    y: pos.y + 10,
    text: "x: #{pos.x.to_i}, y: #{pos.y.to_i}"
  }

  # Draw axis lines
  args.outputs.lines << { x: 0, y: 360, x2: 1280, y2: 360, r: 100, g: 100, b: 100 }
  args.outputs.lines << { x: 640, y: 0, x2: 640, y2: 720, r: 100, g: 100, b: 100 }

  # Corner labels to show coordinate system
  args.outputs.labels << { x: 10, y: 710, text: "Top-Left (0, 720)" }
  args.outputs.labels << { x: 10, y: 30, text: "Bottom-Left (0, 0) - ORIGIN" }
  args.outputs.labels << { x: 1000, y: 710, text: "Top-Right (1280, 720)" }
  args.outputs.labels << { x: 1000, y: 30, text: "Bottom-Right (1280, 0)" }

  # Center marker
  args.outputs.solids << { x: 638, y: 358, w: 4, h: 4, r: 255, g: 0, b: 0 }
  args.outputs.labels << { x: 640, y: 340, text: "Center (640, 360)", anchor_x: 0.5 }
end
