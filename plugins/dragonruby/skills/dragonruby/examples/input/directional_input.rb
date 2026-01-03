# Basic directional movement using args.inputs.up/down/left/right
# These shortcuts check keyboard arrows, WASD, and controller d-pad

def tick args
  # Initialize player on first tick
  args.state.player ||= { x: 640, y: 360, w: 32, h: 32,
                          path: 'sprites/square/blue.png' }

  # Check directional inputs - returns true when pressed or held
  if args.inputs.up
    args.state.player.y += 5
  elsif args.inputs.down
    args.state.player.y -= 5
  end

  if args.inputs.left
    args.state.player.x -= 5
  elsif args.inputs.right
    args.state.player.x += 5
  end

  # Render player
  args.outputs.sprites << args.state.player
end
