# Save/Load Patterns in DragonRuby
# Demonstrates file persistence for game data

HIGH_SCORE_FILE = "high-score.txt"
SAVE_FILE = "game-save.txt"

def tick(args)
  defaults(args)
  handle_input(args)
  render(args)
end

def defaults(args)
  args.state.score ||= 0
  args.state.level ||= 1
  args.state.player_name ||= "Player"

  # Load high score on first tick (nil-safe with .to_i)
  args.state.high_score ||= $gtk.read_file(HIGH_SCORE_FILE).to_i
end

def handle_input(args)
  # Increment score for testing
  if args.inputs.keyboard.key_down.space
    args.state.score += 10
  end

  # Save high score (simple pattern)
  if args.inputs.keyboard.key_down.s
    save_high_score(args)
  end

  # Full game save (serialize_state)
  if args.inputs.keyboard.key_down.f5
    save_game(args)
  end

  # Load game
  if args.inputs.keyboard.key_down.f9
    load_game(args)
  end

  # Reset
  if args.inputs.keyboard.key_down.r
    args.state.score = 0
    args.state.level = 1
  end
end

# Pattern 1: Simple high score save (with save-once flag)
def save_high_score(args)
  if args.state.score > args.state.high_score
    $gtk.write_file(HIGH_SCORE_FILE, args.state.score.to_s)
    args.state.high_score = args.state.score
    $gtk.notify!("High score saved!")
  else
    $gtk.notify!("Score not high enough")
  end
end

# Pattern 2: Full state serialization
def save_game(args)
  # Create save data hash (subset of state)
  save_data = {
    score: args.state.score,
    level: args.state.level,
    player_name: args.state.player_name,
    saved_at: Time.now.to_i
  }

  $gtk.serialize_state(SAVE_FILE, save_data)
  $gtk.notify!("Game saved!")
end

# Pattern 3: Load with validation
def load_game(args)
  loaded = $gtk.deserialize_state(SAVE_FILE)

  if loaded
    args.state.score = loaded.score || 0
    args.state.level = loaded.level || 1
    args.state.player_name = loaded.player_name || "Player"
    $gtk.notify!("Game loaded!")
  else
    $gtk.notify!("No save file found")
  end
end

def render(args)
  args.outputs.labels << { x: 40, y: 700, text: "Score: #{args.state.score}", size_enum: 5 }
  args.outputs.labels << { x: 40, y: 650, text: "Level: #{args.state.level}", size_enum: 3 }
  args.outputs.labels << { x: 40, y: 600, text: "High Score: #{args.state.high_score}", size_enum: 3 }

  # File status
  save_exists = $gtk.stat_file(SAVE_FILE) ? "Yes" : "No"
  args.outputs.labels << { x: 40, y: 500, text: "Save file exists: #{save_exists}" }

  # Instructions
  args.outputs.labels << { x: 40, y: 100, text: "SPACE: +10 score | S: Save high score" }
  args.outputs.labels << { x: 40, y: 70, text: "F5: Save game | F9: Load game | R: Reset" }
end
