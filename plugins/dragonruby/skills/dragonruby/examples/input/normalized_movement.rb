# Normalized diagonal movement using left_right and up_down
# Prevents faster diagonal movement by normalizing the vector

def tick args
  args.state.player ||= { x: 640, y: 360, w: 32, h: 32 }

  speed = 5

  # args.inputs.left_right returns -1, 0, or 1
  # args.inputs.up_down returns -1, 0, or 1
  dx = args.inputs.left_right
  dy = args.inputs.up_down

  # Calculate vector length (diagonal movement without normalization = 1.41x speed)
  length = Math.sqrt(dx * dx + dy * dy)

  # Normalize: divide by length to get unit vector, then multiply by speed
  if length > 0
    dx = (dx / length) * speed
    dy = (dy / length) * speed
  end

  # Apply normalized movement
  args.state.player.x += dx
  args.state.player.y += dy

  # Show speed comparison
  args.outputs.labels << { x: 640, y: 700, text: "Move diagonally - speed stays constant", size_enum: 5, alignment_enum: 1 }
  args.outputs.labels << { x: 640, y: 670, text: "Current speed: #{Math.sqrt(dx**2 + dy**2).to_sf}", size_enum: 5, alignment_enum: 1 }

  args.outputs.sprites << args.state.player.merge(path: 'sprites/square/blue.png')
end
