# Smooth analog movement using percentage values
# Allows for speed variation based on stick deflection

def tick args
  controller = args.inputs.controller_one
  args.state.player ||= { x: 640, y: 360, w: 32, h: 32, dx: 0, dy: 0 }

  max_speed = 8

  # Analog stick returns -1.0 to 1.0, multiply by max speed
  # Small tilts = slow movement, full tilt = max speed
  args.state.player.dx = controller.left_analog_x_perc * max_speed
  args.state.player.dy = controller.left_analog_y_perc * max_speed

  # Apply velocity
  args.state.player.x += args.state.player.dx
  args.state.player.y += args.state.player.dy

  # Clamp to screen
  args.state.player.x = args.state.player.x.clamp(0, 1280 - args.state.player.w)
  args.state.player.y = args.state.player.y.clamp(0, 720 - args.state.player.h)

  # Visual speed indicator
  speed = Math.sqrt(args.state.player.dx**2 + args.state.player.dy**2)
  args.outputs.labels << [640, 700, "Speed: #{speed.to_sf} (tilt stick for variable speed)", 5, 1]

  args.outputs.sprites << args.state.player.merge(path: 'sprites/square/blue.png')
end
