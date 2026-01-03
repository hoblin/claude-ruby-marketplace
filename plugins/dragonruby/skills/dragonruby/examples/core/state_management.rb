# Demonstrates state management using args.state with ||= pattern
# The ||= operator initializes values only on first tick

def tick args
  # Initialize player only once (on first frame)
  # ||= means "assign if nil" - persists across frames
  args.state.player ||= {
    x: 640,
    y: 360,
    w: 50,
    h: 50,
    path: 'sprites/square/green.png'
  }

  # Initialize counter if not set
  args.state.counter ||= 0
  args.state.counter += 1

  # Move player with arrow keys
  args.state.player.x += 5 if args.inputs.right
  args.state.player.x -= 5 if args.inputs.left
  args.state.player.y += 5 if args.inputs.up
  args.state.player.y -= 5 if args.inputs.down

  # Render player and counter
  args.outputs.sprites << args.state.player
  args.outputs.labels << { x: 10, y: 710, text: "Counter: #{args.state.counter}" }
  args.outputs.labels << { x: 10, y: 680, text: "Use arrow keys to move" }
end
