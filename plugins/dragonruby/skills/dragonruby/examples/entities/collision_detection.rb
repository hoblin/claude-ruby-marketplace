# Collision Detection Patterns
# Demonstrates intersect_rect? and find_intersect_rect

def tick(args)
  args.state.player ||= { x: 640, y: 360, w: 32, h: 32 }
  args.state.enemies ||= 8.map { |i| { x: i * 150 + 50, y: 300, w: 40, h: 40 } }

  # Move player with arrow keys
  args.state.player.x += args.inputs.left_right * 5
  args.state.player.y += args.inputs.up_down * 5

  # Reset hit status
  args.state.enemies.each { |e| e.hit = false }

  # Method 1: intersect_rect? - check each entity
  args.state.enemies.each do |enemy|
    if args.state.player.intersect_rect?(enemy)
      enemy.hit = true
    end
  end

  # Method 2: find_intersect_rect - returns first collision (faster)
  collision = Geometry.find_intersect_rect(
    args.state.player,
    args.state.enemies
  )

  # Method 3: find_all_intersect_rect - returns all collisions
  all_hits = Geometry.find_all_intersect_rect(
    args.state.player,
    args.state.enemies
  )

  # Render player (green)
  args.outputs.solids << args.state.player.merge(r: 0, g: 255, b: 0)

  # Render enemies (red if hit, gray otherwise)
  args.outputs.borders << args.state.enemies.map do |e|
    e.merge(r: e.hit ? 255 : 128, g: e.hit ? 0 : 128, b: e.hit ? 0 : 128)
  end

  args.outputs.labels << { x: 10, y: 710, text: "Collisions: #{all_hits.length}" }
end
