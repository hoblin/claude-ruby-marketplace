# Entity Storage Pattern
# Demonstrates storing entities in args.state arrays

def tick(args)
  # Initialize entity collections as empty arrays
  # The ||= ensures they're only created once
  args.state.enemies ||= []
  args.state.bullets ||= []

  # Add entities to collections on input
  if args.inputs.mouse.click
    args.state.bullets << {
      x: 0,
      y: args.inputs.mouse.y,
      w: 10,
      h: 10,
      speed: 5
    }
  end

  # Spawn enemies every 60 frames (1 second)
  if args.state.tick_count.zmod?(60)
    args.state.enemies << {
      x: 1280,
      y: rand * 720,
      w: 32,
      h: 32
    }
  end

  # Render all entities from arrays
  args.outputs.solids << args.state.bullets
  args.outputs.borders << args.state.enemies

  # Display counts
  args.outputs.labels << { x: 10, y: 710, text: "Enemies: #{args.state.enemies.length}" }
  args.outputs.labels << { x: 10, y: 690, text: "Bullets: #{args.state.bullets.length}" }
end
