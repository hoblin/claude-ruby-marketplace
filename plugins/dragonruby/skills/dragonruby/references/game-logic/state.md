# State Management

## args.state Container

Central property bag persisting across ticks.

```ruby
# All state persists automatically between frames
args.state.player ||= { x: 120, y: 280 }
args.state.score ||= 0
args.state.enemies ||= []
```

**Key characteristics:**
- Values retained across tick invocations
- Cleared on `$gtk.reset`
- Supports arbitrary nesting with automatic Entity backing

## Lazy Initialization (||= Pattern)

Initialize values only on first access - prevents reset every frame.

```ruby
# CORRECT: Set once, persist forever
args.state.player_x ||= 120
args.state.timer ||= 30 * 60

# WRONG: Resets every frame!
args.state.player_x = 120
```

**Why critical:** `tick` runs 60 times/second - without `||=`, values reset constantly.

## Frame-Based Timing

DragonRuby runs at 60 FPS. Convert seconds to frames:

```ruby
FPS = 60

# 30 seconds = 1800 frames
args.state.timer ||= 30 * FPS

# Display as seconds
seconds_left = (args.state.timer / FPS).round
```

### Timer Countdown Pattern

```ruby
# Decrement each frame
args.state.timer -= 1

# Check expiration
if args.state.timer < 0
  game_over_tick(args)
  return  # Early return critical!
end
```

### Periodic Execution with zmod?

Execute code every N frames:

```ruby
# Every second (60 frames)
if Kernel.tick_count.zmod?(60)
  spawn_enemy(args)
end

# Every 3 frames
if Kernel.tick_count.zmod?(3)
  update_animation(args)
end
```

### Elapsed Time Tracking

```ruby
# Record event timestamp
args.state.last_click_at ||= 0
if args.inputs.mouse.click
  args.state.last_click_at = Kernel.tick_count
end

# Check elapsed time
if args.state.last_click_at.elapsed_time > 120  # 2 seconds
  show_hint(args)
end

# Check if expired
if args.state.spawn_at.elapsed?(60)  # 1 second passed
  do_spawn(args)
end
```

### Entity created_at (Automatic)

Entities track creation time automatically:

```ruby
enemy = args.state.new_entity(:enemy, x: 100, y: 100)

# Available properties:
enemy.created_at           # Kernel.tick_count at creation
enemy.created_at_elapsed   # Frames since creation
enemy.global_created_at    # Never resets with $gtk.reset
```

## Grace Periods

Use negative timer values for input delays:

```ruby
# Timer continues counting negative
args.state.timer -= 1

if args.state.timer < 0
  # Show game over
  render_game_over(args)

  # Wait 30 frames before accepting restart input
  if args.state.timer < -30 && fire_input?(args)
    $gtk.reset
  end
  return
end
```

**Why:** Prevents accidental restarts when player is mashing buttons.

## Scoring System

```ruby
# Initialize
args.state.score ||= 0

# Update on events
if collision?(fireball, target)
  args.state.score += 1
end

# Display
args.outputs.labels << {
  x: 40, y: 700,
  text: "Score: #{args.state.score}"
}
```

## Game State Transitions

### Scene Pattern with send

```ruby
def tick(args)
  args.state.scene ||= :title
  send("#{args.state.scene}_tick", args)
end

def title_tick(args)
  # Title screen logic
  if fire_input?(args)
    args.state.scene = :gameplay
    return  # Early return on transition
  end
end

def gameplay_tick(args)
  # Main game logic
  if args.state.timer < 0
    args.state.scene = :game_over
    return
  end
end

def game_over_tick(args)
  # Game over logic
  if fire_input?(args)
    $gtk.reset
  end
end
```

### Early Return Pattern

**Critical:** After state changes, `return` to prevent subsequent code execution.

```ruby
def tick(args)
  if args.state.paused
    render_pause_menu(args)
    return  # Skip game logic!
  end

  # Normal gameplay only runs when not paused
  update_player(args)
  update_enemies(args)
end
```

## State Reset

### Full Reset ($gtk.reset)

Clears all `args.state` and resets `tick_count` to 0.

```ruby
# Restart game
if args.inputs.keyboard.key_down.r
  $gtk.reset
end
```

**During development:** Add at file end to force reinitialization on code reload:

```ruby
def tick(args)
  # game code
end

$gtk.reset  # Dev convenience - remove for production
```

### Custom Reset Handler

Define `reset` method for cleanup when `$gtk.reset` called:

```ruby
def reset(args)
  $game = nil  # Clear global instances
  puts "Game reset!"
end

def tick(args)
  $game ||= Game.new
  $game.tick(args)
end
```

### Partial Reset

Reset specific state without full reset:

```ruby
def restart_level(args)
  args.state.player.x = 120
  args.state.player.y = 280
  args.state.enemies = []
  # Keep score, reset position
end
```

## One-Time Initialization

Execute code only on first tick:

```ruby
def tick(args)
  if Kernel.tick_count == 0
    # First frame only
    args.audio[:music] = { input: "sounds/theme.ogg", looping: true }
  end
end
```

**Alternative:** Use `boot` method:

```ruby
def boot(args)
  args.state = {}
  # One-time setup
end

def tick(args)
  # Normal game loop
end
```

## Class-Based State (Alternative)

For larger games, use classes with `attr_gtk`:

```ruby
class Game
  attr_gtk

  def initialize
    @player = { x: 0, y: 0 }
    @enemies = []
  end

  def tick
    # Access: @player, state, inputs, outputs
    @player.x += 1 if inputs.right
  end
end

def tick(args)
  $game ||= Game.new
  $game.args = args
  $game.tick
end
```

## Common Antipatterns

### Resetting State Every Frame

```ruby
# WRONG
args.state.score = 0  # Resets to 0 every frame!

# CORRECT
args.state.score ||= 0
```

### Missing Early Return

```ruby
# WRONG - game logic runs during game over
if args.state.game_over
  render_game_over(args)
end
update_player(args)  # Still runs!

# CORRECT
if args.state.game_over
  render_game_over(args)
  return
end
update_player(args)
```

### Forgetting Timer Conversion

```ruby
# WRONG - timer is 30 frames (0.5 seconds)
args.state.timer ||= 30

# CORRECT - timer is 30 seconds
args.state.timer ||= 30 * 60
```

### Global State Pollution

```ruby
# WRONG - pollutes global namespace
@player_x = 100

# CORRECT
args.state.player_x ||= 100
```

## Decision Tree

```
Need to track time?
├── Countdown to event → examples/game-logic/timers.rb (countdown pattern)
├── Periodic action (every N frames) → examples/game-logic/timers.rb (zmod? pattern)
└── Time since event → elapsed_time / elapsed?

Need to track score?
├── Simple increment → examples/game-logic/scoring.rb
├── With combo/multiplier → examples/game-logic/scoring.rb (combo pattern)
└── With high score → examples/game-logic/scoring.rb + save_load.rb

Need multiple game states?
├── Title/Gameplay/GameOver → examples/game-logic/state_transitions.rb
├── Pause menu → Early return pattern
└── Level transitions → Partial reset pattern

Need to reset game?
├── Full restart → $gtk.reset (examples/game-logic/reset_patterns.rb)
├── Keep high score → Use ||= in defaults
├── Restart level only → examples/game-logic/reset_patterns.rb (partial_reset)
└── Reset position only → examples/game-logic/reset_patterns.rb (soft_reset)

Need restart delay?
└── Grace period → examples/game-logic/state_transitions.rb (game_over_tick)
```

## Examples

| File | Demonstrates |
|------|--------------|
| `examples/game-logic/timers.rb` | Countdown, zmod? periodic, elapsed_time |
| `examples/game-logic/scoring.rb` | Score tracking, combo multipliers |
| `examples/game-logic/state_transitions.rb` | Scene management, send pattern, grace periods |
| `examples/game-logic/reset_patterns.rb` | Full reset, partial reset, soft reset |
