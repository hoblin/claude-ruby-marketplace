# Reset Patterns in DragonRuby
# Demonstrates full reset, partial reset, and custom reset handlers

def tick(args)
  defaults(args)
  handle_input(args)
  render(args)
end

def defaults(args)
  args.state.score ||= 0
  args.state.level ||= 1
  args.state.high_score ||= 0  # Persists across $gtk.reset
  args.state.player ||= { x: 640, y: 360 }
end

def handle_input(args)
  # Move player
  args.state.player.x -= 5 if args.inputs.left
  args.state.player.x += 5 if args.inputs.right
  args.state.player.y -= 5 if args.inputs.down
  args.state.player.y += 5 if args.inputs.up

  # Add score
  if args.inputs.keyboard.key_down.space
    args.state.score += 10
    args.state.level += 1 if args.state.score.zmod?(100)
  end

  # Update high score
  args.state.high_score = [args.state.high_score, args.state.score].max

  # Pattern 1: Full reset (clears all args.state)
  if args.inputs.keyboard.key_down.r
    $gtk.reset
  end

  # Pattern 2: Partial reset (preserve some state)
  if args.inputs.keyboard.key_down.p
    partial_reset(args)
  end

  # Pattern 3: Soft reset (reset position only)
  if args.inputs.keyboard.key_down.s
    soft_reset(args)
  end
end

# Full reset clears everything - use ||= with values you want to persist
# High score persists because of ||= pattern in defaults

# Pattern 2: Partial reset - keep high score, reset game
def partial_reset(args)
  # Save what we want to keep
  high_score = args.state.high_score

  # Clear specific state
  args.state.score = 0
  args.state.level = 1
  args.state.player = { x: 640, y: 360 }

  # Note: high_score wasn't touched, so it remains
end

# Pattern 3: Soft reset - minimal state change
def soft_reset(args)
  args.state.player.x = 640
  args.state.player.y = 360
  # Keep score and level
end

def render(args)
  # Player
  args.outputs.solids << {
    x: args.state.player.x - 25,
    y: args.state.player.y - 25,
    w: 50, h: 50, r: 0, g: 150, b: 255
  }

  # Stats
  args.outputs.labels << { x: 40, y: 700, text: "Score: #{args.state.score}", size_enum: 5 }
  args.outputs.labels << { x: 40, y: 660, text: "Level: #{args.state.level}", size_enum: 3 }
  args.outputs.labels << { x: 40, y: 620, text: "High Score: #{args.state.high_score}", size_enum: 3, r: 255, g: 215, b: 0 }

  # Instructions
  args.outputs.labels << { x: 40, y: 100, text: "Arrows: Move | SPACE: Score" }
  args.outputs.labels << { x: 40, y: 70, text: "R: Full reset | P: Partial reset | S: Soft reset" }
end

# Custom reset handler - called when $gtk.reset executes
def reset(args)
  puts "Game reset! Custom cleanup here."
  # Clear any global variables or class instances
  $game = nil if defined?($game)
end

# Development convenience: uncomment to reset on code reload
# $gtk.reset
