# Detecting specific keyboard events: key_down, key_held, key_up
# key_down: fires once when key is first pressed
# key_held: fires every frame while key is held
# key_up: fires once when key is released

def tick args
  args.state.bullets ||= []

  # key_down: fires ONCE per press (good for actions)
  if args.inputs.keyboard.key_down.space
    args.state.bullets << { x: 100, y: 100, created_at: Kernel.tick_count }
  end

  # key_held: fires EVERY FRAME while pressed (good for continuous movement)
  if args.inputs.keyboard.key_held.w
    args.outputs.labels << [640, 360, "W is being held", 5, 1]
  end

  # key_up: fires ONCE when released (good for charging mechanics)
  if args.inputs.keyboard.key_up.escape
    args.state.menu_opened_at = Kernel.tick_count
  end

  # Display status
  args.outputs.labels << [10, 700, "Press SPACE to fire (key_down)"]
  args.outputs.labels << [10, 670, "Hold W for message (key_held)"]
  args.outputs.labels << [10, 640, "Press ESC to log release (key_up)"]
end
