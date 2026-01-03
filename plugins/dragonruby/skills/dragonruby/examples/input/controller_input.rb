# Controller button and analog stick input
# Access via args.inputs.controller_one (or controller_two, etc.)

def tick args
  controller = args.inputs.controller_one
  args.state.player ||= { x: 640, y: 360, w: 32, h: 32 }

  # Button inputs (key_down, key_held, key_up work like keyboard)
  if controller.key_down.a
    args.outputs.labels << [640, 600, "A button pressed!", 5, 1]
  end

  # D-pad directions
  if controller.key_held.up
    args.state.player.y += 5
  end

  # Analog stick positions: left_analog_x_perc and left_analog_y_perc
  # Returns value from -1.0 to 1.0 (0.0 when centered)
  args.state.player.x += controller.left_analog_x_perc * 8
  args.state.player.y += controller.left_analog_y_perc * 8

  # Display analog values
  args.outputs.labels << [10, 700, "Left stick X: #{controller.left_analog_x_perc.to_sf}"]
  args.outputs.labels << [10, 670, "Left stick Y: #{controller.left_analog_y_perc.to_sf}"]

  args.outputs.sprites << args.state.player.merge(path: 'sprites/square/blue.png')
end
