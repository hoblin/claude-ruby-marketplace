# Movement with screen boundary clamping using .clamp method
# Prevents player from moving outside screen bounds

def tick args
  args.state.player ||= { x: 640, y: 360, w: 64, h: 64 }

  speed = 5

  # Apply movement using unified directional helpers
  args.state.player.x += args.inputs.left_right * speed
  args.state.player.y += args.inputs.up_down * speed

  # Clamp position to stay within screen bounds
  # args.grid.w is 1280, args.grid.h is 720 by default
  args.state.player.x = args.state.player.x.clamp(0, args.grid.w - args.state.player.w)
  args.state.player.y = args.state.player.y.clamp(0, args.grid.h - args.state.player.h)

  # Visual feedback at boundaries
  args.outputs.borders << [0, 0, args.grid.w, args.grid.h, 255, 0, 0]
  args.outputs.sprites << args.state.player.merge(path: 'sprites/square/blue.png')
  args.outputs.labels << [640, 700, "Try moving off screen - player is clamped", 5, 1]
end
