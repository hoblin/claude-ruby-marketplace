# Minimal DragonRuby example - Shows a simple label
# The tick method is called 60 times per second

def tick args
  # Display text at position (640, 360) - center of the 1280x720 screen
  args.outputs.labels << {
    x: 640,
    y: 360,
    text: "Hello, DragonRuby!",
    size_px: 22,
    anchor_x: 0.5,
    anchor_y: 0.5
  }

  # Show the current frame count
  args.outputs.labels << {
    x: 640,
    y: 320,
    text: "Frame: #{Kernel.tick_count}",
    size_px: 18,
    anchor_x: 0.5,
    anchor_y: 0.5
  }
end
