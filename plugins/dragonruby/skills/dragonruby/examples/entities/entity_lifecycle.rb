# Entity Lifecycle Pattern
# Demonstrates: create -> update -> mark dead -> reject

def tick(args)
  defaults(args)
  spawn_bullets(args)
  update_bullets(args)
  check_collisions(args)
  cleanup_dead(args)
  render(args)
end

def defaults(args)
  args.state.bullets ||= []
  args.state.targets ||= 5.map { |i| { x: 1000, y: i * 120 + 100, w: 50, h: 50, dead: false } }
end

# Step 1: CREATE entities
def spawn_bullets(args)
  return unless args.inputs.mouse.click

  args.state.bullets << {
    x: 0,
    y: args.inputs.mouse.y,
    w: 10,
    h: 10,
    speed: 12,
    dead: false
  }
end

# Step 2: UPDATE entities
def update_bullets(args)
  args.state.bullets.each do |bullet|
    bullet.x += bullet.speed

    # Mark off-screen bullets as dead
    bullet.dead = true if bullet.x > args.grid.w
  end
end

# Step 3: MARK dead on collision (don't modify arrays during iteration)
def check_collisions(args)
  args.state.bullets.each do |bullet|
    next if bullet.dead

    args.state.targets.each do |target|
      next if target.dead

      if Geometry.intersect_rect?(bullet, target)
        bullet.dead = true
        target.dead = true
      end
    end
  end
end

# Step 4: REJECT dead entities after all processing
def cleanup_dead(args)
  args.state.bullets.reject!(&:dead)
  args.state.targets.reject!(&:dead)
end

def render(args)
  args.outputs.solids << args.state.bullets.map { |b| b.merge(r: 255, g: 200, b: 0) }
  args.outputs.borders << args.state.targets
  args.outputs.labels << [10, 710, "Click to shoot. Targets: #{args.state.targets.length}"]
end
