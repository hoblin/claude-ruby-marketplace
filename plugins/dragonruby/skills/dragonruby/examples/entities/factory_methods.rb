# Factory Methods Pattern
# Demonstrates spawn_* factory methods for entity creation

def tick(args)
  args.state.enemies ||= []
  args.state.projectiles ||= []

  # Spawn enemies using factory method
  spawn_enemy(args) if args.state.tick_count.zmod?(90)

  # Spawn projectiles on click
  spawn_projectile(args, args.inputs.mouse) if args.inputs.mouse.click

  # Update entities
  args.state.projectiles.each { |p| p.x += p.speed }

  # Render
  args.outputs.borders << args.state.enemies
  args.outputs.solids << args.state.projectiles
end

# Factory method: encapsulates entity creation logic
def spawn_enemy(args)
  size = 40
  args.state.enemies << {
    x: args.grid.w + size,
    y: rand(args.grid.h - size * 2) + size,
    w: size,
    h: size,
    path: 'sprites/enemy.png',
    speed: rand(3) + 1
  }
end

# Factory with parameters
def spawn_projectile(args, mouse)
  args.state.projectiles << {
    x: 0,
    y: mouse.y,
    w: 8,
    h: 8,
    speed: rand * 8 + 4,
    r: 255, g: 128, b: 0
  }
end
