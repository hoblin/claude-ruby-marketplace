# Pause Overlay Pattern
# Overlay pause menu on frozen gameplay
# Source: DragonRuby samples/99_genre_arcade/flappy_dragon

def tick args
  args.state.scene ||= :gameplay

  # Toggle pause
  if args.inputs.keyboard.key_down.escape
    if args.state.scene == :gameplay
      args.state.scene = :paused
      args.state.paused_at = Kernel.tick_count
    elsif args.state.scene == :paused
      args.state.scene = :gameplay
    end
    return
  end

  send("#{args.state.scene}_tick", args)
end

def gameplay_tick args
  args.state.player ||= { x: 640, y: 360, w: 64, h: 64 }
  args.state.score ||= 0

  # Handle input
  speed = 5
  args.state.player.x += speed if args.inputs.right
  args.state.player.x -= speed if args.inputs.left
  args.state.player.y += speed if args.inputs.up
  args.state.player.y -= speed if args.inputs.down

  # Clamp to screen
  args.state.player.x = args.state.player.x.clamp(0, 1280 - 64)
  args.state.player.y = args.state.player.y.clamp(0, 720 - 64)

  args.state.score += 1

  render_gameplay args
end

def paused_tick args
  # Render frozen gameplay (no updates)
  render_gameplay args

  # Dark overlay
  args.outputs.primitives << {
    x: 0, y: 0, w: 1280, h: 720,
    r: 0, g: 0, b: 0, a: 180
  }.to_solid

  # Pause menu
  args.outputs.labels << {
    x: 640, y: 450,
    text: "PAUSED",
    size_enum: 15,
    anchor_x: 0.5,
    r: 255, g: 255, b: 255
  }
  args.outputs.labels << {
    x: 640, y: 350,
    text: "Press ESC to resume",
    anchor_x: 0.5,
    r: 255, g: 255, b: 255
  }
  args.outputs.labels << {
    x: 640, y: 300,
    text: "Press Q to quit",
    anchor_x: 0.5,
    r: 255, g: 255, b: 255
  }

  if args.inputs.keyboard.key_down.q
    $gtk.reset
  end
end

def render_gameplay args
  # Background
  args.outputs.solids << {
    x: 0, y: 0, w: 1280, h: 720,
    r: 50, g: 80, b: 120
  }

  # Player (simple box)
  args.outputs.solids << {
    x: args.state.player.x,
    y: args.state.player.y,
    w: args.state.player.w,
    h: args.state.player.h,
    r: 255, g: 200, b: 100
  }

  # Score
  args.outputs.labels << {
    x: 40, y: 700,
    text: "Score: #{args.state.score}",
    r: 255, g: 255, b: 255
  }
end
