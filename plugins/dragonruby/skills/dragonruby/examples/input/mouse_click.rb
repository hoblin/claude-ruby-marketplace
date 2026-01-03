# Handling mouse clicks and position
# args.inputs.mouse.click returns event info when clicked

def tick args
  # Check for mouse click this frame
  if args.inputs.mouse.click
    # Store the click event (has x, y, created_at properties)
    args.state.last_click = args.inputs.mouse.click
  end

  # Display click information
  if args.state.last_click
    click = args.state.last_click

    # Access click position
    args.outputs.labels << [640, 400, "Clicked at: #{click.x}, #{click.y}", 5, 1]

    # How many frames ago did it happen?
    args.outputs.labels << [640, 350, "Clicked #{click.created_at_elapsed} ticks ago", 5, 1]

    # Draw a marker at click position
    args.outputs.solids << [click.x - 5, click.y - 5, 10, 10, 255, 0, 0]
  else
    args.outputs.labels << [640, 360, "Click anywhere!", 5, 1]
  end
end
