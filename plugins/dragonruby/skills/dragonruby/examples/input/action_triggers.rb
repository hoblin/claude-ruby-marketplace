# One-shot actions using key_down pattern
# Perfect for jump, shoot, interact buttons

def tick args
  args.state.player ||= { x: 640, y: 100, dy: 0, on_ground: true }
  args.state.bullets ||= []

  # Jump: only trigger once per press (not while held)
  if args.inputs.keyboard.key_down.space && args.state.player.on_ground
    args.state.player.dy = 15  # Jump velocity
    args.state.player.on_ground = false
  end

  # Shoot: fire one bullet per keypress
  if args.inputs.keyboard.key_down.f
    args.state.bullets << { x: args.state.player.x, y: args.state.player.y,
                            created_at: Kernel.tick_count }
  end

  # Simple gravity and ground collision
  args.state.player.dy -= 0.5
  args.state.player.y += args.state.player.dy

  if args.state.player.y <= 100
    args.state.player.y = 100
    args.state.player.dy = 0
    args.state.player.on_ground = true
  end

  # Cleanup old bullets
  args.state.bullets.reject! { |b| b.created_at.elapsed_time > 60 }

  # Render
  args.outputs.sprites << args.state.player.merge(w: 32, h: 32, path: 'sprites/square/blue.png')
  args.outputs.sprites << args.state.bullets.map { |b| b.merge(w: 8, h: 8, path: 'sprites/square/red.png') }
end
