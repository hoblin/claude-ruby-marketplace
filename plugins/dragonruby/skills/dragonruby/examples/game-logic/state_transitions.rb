# State Transitions in DragonRuby
# Demonstrates scene management and game over detection

def tick(args)
  args.state.scene ||= :title
  send("#{args.state.scene}_tick", args)
end

# === TITLE SCENE ===
def title_tick(args)
  args.outputs.labels << {
    x: 640, y: 450, text: "MY GAME",
    size_enum: 15, anchor_x: 0.5
  }
  args.outputs.labels << {
    x: 640, y: 350, text: "Press SPACE to start",
    size_enum: 3, anchor_x: 0.5
  }

  if args.inputs.keyboard.key_down.space
    # Initialize game state
    args.state.player = { x: 640, y: 100, health: 3 }
    args.state.score = 0
    args.state.scene = :gameplay
    return  # Early return on transition
  end
end

# === GAMEPLAY SCENE ===
def gameplay_tick(args)
  # Initialize
  args.state.player ||= { x: 640, y: 100, health: 3 }
  args.state.score ||= 0

  # Update
  handle_gameplay_input(args)
  check_game_over(args)

  # Render
  render_gameplay(args)
end

def handle_gameplay_input(args)
  player = args.state.player
  player.x -= 5 if args.inputs.left
  player.x += 5 if args.inputs.right

  # Simulate damage
  if args.inputs.keyboard.key_down.x
    player.health -= 1
  end

  # Simulate scoring
  if args.inputs.keyboard.key_down.space
    args.state.score += 10
  end
end

def check_game_over(args)
  if args.state.player.health <= 0
    args.state.game_over_at = Kernel.tick_count
    args.state.scene = :game_over
    return  # Early return critical!
  end
end

def render_gameplay(args)
  # Player
  args.outputs.solids << {
    x: args.state.player.x - 25, y: args.state.player.y,
    w: 50, h: 50, r: 0, g: 200, b: 0
  }

  # HUD
  args.outputs.labels << { x: 40, y: 700, text: "Score: #{args.state.score}" }
  args.outputs.labels << { x: 40, y: 670, text: "Health: #{args.state.player.health}" }
  args.outputs.labels << { x: 40, y: 40, text: "X: Take damage | SPACE: Score" }
end

# === GAME OVER SCENE ===
def game_over_tick(args)
  args.outputs.labels << {
    x: 640, y: 450, text: "GAME OVER",
    size_enum: 15, anchor_x: 0.5, r: 255, g: 0, b: 0
  }
  args.outputs.labels << {
    x: 640, y: 380, text: "Final Score: #{args.state.score}",
    size_enum: 5, anchor_x: 0.5
  }

  # Grace period before accepting restart (30 frames = 0.5 sec)
  elapsed = Kernel.tick_count - args.state.game_over_at
  if elapsed > 30
    args.outputs.labels << {
      x: 640, y: 300, text: "Press SPACE to restart",
      size_enum: 3, anchor_x: 0.5
    }

    if args.inputs.keyboard.key_down.space
      $gtk.reset
    end
  end
end
