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
    args.outputs.labels << { x: 640, y: 400, text: "Clicked at: #{click.x}, #{click.y}", size_enum: 5, alignment_enum: 1 }

    # How many frames ago did it happen?
    args.outputs.labels << { x: 640, y: 350, text: "Clicked #{click.created_at_elapsed} ticks ago", size_enum: 5, alignment_enum: 1 }

    # Draw a marker at click position
    args.outputs.primitives << { x: click.x - 5, y: click.y - 5, w: 10, h: 10, r: 255, g: 0, b: 0, primitive_marker: :solid }
  else
    args.outputs.labels << { x: 640, y: 360, text: "Click anywhere!", size_enum: 5, alignment_enum: 1 }
  end
end
