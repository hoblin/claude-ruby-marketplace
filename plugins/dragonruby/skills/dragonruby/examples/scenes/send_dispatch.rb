# Send-Based Scene Dispatch
# Simplest pattern using Ruby's dynamic method dispatch
# Source: DragonRuby book Chapter 11

def tick args
  args.state.scene ||= :title
  send("#{args.state.scene}_tick", args)
end

def title_tick args
  args.outputs.labels << {
    x: 640, y: 500,
    text: "My Game",
    size_enum: 10,
    anchor_x: 0.5
  }
  args.outputs.labels << {
    x: 640, y: 300,
    text: "Press SPACE to start",
    anchor_x: 0.5
  }

  if args.inputs.keyboard.key_down.space
    args.state.scene = :gameplay
    return  # Early return prevents old scene code
  end
end

def gameplay_tick args
  args.state.player ||= { x: 640, y: 360, w: 64, h: 64, path: "sprites/player.png" }
  args.state.score ||= 0
  args.state.timer ||= 30 * 60

  args.state.timer -= 1

  if args.state.timer <= 0
    args.state.scene = :game_over
    return
  end

  # Handle input
  speed = 5
  args.state.player.x += speed if args.inputs.right
  args.state.player.x -= speed if args.inputs.left
  args.state.player.y += speed if args.inputs.up
  args.state.player.y -= speed if args.inputs.down

  # Render
  args.outputs.sprites << args.state.player
  args.outputs.labels << {
    x: 40, y: 700,
    text: "Score: #{args.state.score}"
  }
  args.outputs.labels << {
    x: 1240, y: 700,
    text: "Time: #{(args.state.timer / 60).ceil}",
    anchor_x: 1
  }
end

def game_over_tick args
  args.state.timer -= 1

  args.outputs.labels << {
    x: 640, y: 450,
    text: "Game Over!",
    size_enum: 10,
    anchor_x: 0.5
  }
  args.outputs.labels << {
    x: 640, y: 350,
    text: "Score: #{args.state.score}",
    size_enum: 4,
    anchor_x: 0.5
  }
  args.outputs.labels << {
    x: 640, y: 200,
    text: "Press SPACE to restart",
    anchor_x: 0.5
  }

  # Grace period before accepting input
  return if args.state.timer > -30

  if args.inputs.keyboard.key_down.space
    $gtk.reset
  end
end
