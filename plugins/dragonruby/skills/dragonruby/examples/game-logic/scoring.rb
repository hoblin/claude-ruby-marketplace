# Scoring System in DragonRuby
# Demonstrates score tracking, high score persistence, and display

def tick(args)
  defaults(args)
  handle_input(args)
  render(args)
end

def defaults(args)
  args.state.score ||= 0
  args.state.high_score ||= 0  # Persists across $gtk.reset
  args.state.combo ||= 0
  args.state.multiplier ||= 1
end

# Scoring patterns
def handle_input(args)
  # Simple score increment
  if args.inputs.keyboard.key_down.space
    add_score(args, 10)
  end

  # Score with multiplier
  if args.inputs.keyboard.key_down.z
    add_score_with_combo(args, 100)
  end

  # Break combo
  if args.inputs.keyboard.key_down.x
    reset_combo(args)
  end

  # Reset game (high score persists)
  if args.inputs.keyboard.key_down.r
    args.state.score = 0
    args.state.combo = 0
    args.state.multiplier = 1
  end
end

# Pattern 1: Simple score increment
def add_score(args, points)
  args.state.score += points
  update_high_score(args)
end

# Pattern 2: Score with combo multiplier
def add_score_with_combo(args, base_points)
  args.state.combo += 1
  args.state.multiplier = [1 + (args.state.combo / 5), 4].min  # Max 4x

  points = base_points * args.state.multiplier
  args.state.score += points
  update_high_score(args)
end

# Pattern 3: High score tracking
def update_high_score(args)
  if args.state.score > args.state.high_score
    args.state.high_score = args.state.score
    args.state.new_high_score = true
  end
end

def reset_combo(args)
  args.state.combo = 0
  args.state.multiplier = 1
end

def render(args)
  # Current score
  args.outputs.labels << {
    x: 40, y: 700, text: "SCORE: #{args.state.score}",
    size_enum: 5
  }

  # High score
  args.outputs.labels << {
    x: 40, y: 650, text: "HIGH SCORE: #{args.state.high_score}",
    size_enum: 3, r: 255, g: 215, b: 0
  }

  # Combo/multiplier
  if args.state.combo > 0
    args.outputs.labels << {
      x: 40, y: 600, text: "COMBO: #{args.state.combo} (x#{args.state.multiplier})",
      size_enum: 3, r: 255, g: 100, b: 100
    }
  end

  # New high score notification
  if args.state.new_high_score
    args.outputs.labels << {
      x: 640, y: 400, text: "NEW HIGH SCORE!",
      size_enum: 8, anchor_x: 0.5, r: 255, g: 215, b: 0
    }
  end

  # Instructions
  args.outputs.labels << { x: 40, y: 100, text: "SPACE: +10 points" }
  args.outputs.labels << { x: 40, y: 70, text: "Z: +100 with combo" }
  args.outputs.labels << { x: 40, y: 40, text: "X: Break combo | R: Reset score" }
end
