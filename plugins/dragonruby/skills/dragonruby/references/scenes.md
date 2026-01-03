# DragonRuby Scenes Reference

## Overview

Scenes separate distinct game states (title, gameplay, game over, pause). Each scene has its own logic, rendering, and input handling. DragonRuby provides no built-in scene system—implement patterns below.

## Scene State Variable

Store current scene in `args.state`:

```ruby
args.state.scene ||= :title       # Symbol (recommended)
args.state.scene ||= "gameplay"   # String (also works)
```

## Pattern 1: Send-Based Dispatch (Recommended)

Dynamic method dispatch using Ruby's `send`. Simple and extensible.

```ruby
def tick args
  args.state.scene ||= :title
  send("#{args.state.scene}_tick", args)
end

def title_tick args
  args.outputs.labels << { x: 640, y: 400, text: "Press SPACE to start", anchor_x: 0.5 }
  if args.inputs.keyboard.key_down.space
    args.state.scene = :gameplay
    return  # Early return prevents executing old scene code
  end
end

def gameplay_tick args
  # Main game logic
  if game_over_condition?
    args.state.scene = :game_over
    return
  end
end

def game_over_tick args
  args.outputs.labels << { x: 640, y: 400, text: "Game Over!", anchor_x: 0.5 }
  if args.inputs.keyboard.key_down.space
    $gtk.reset  # Full state reset
  end
end
```

### Naming Convention

Scene methods **must** match pattern: `{scene_name}_tick`

| `args.state.scene` | Method Called |
|---|---|
| `:title` | `title_tick` |
| `:gameplay` | `gameplay_tick` |
| `:game_over` | `game_over_tick` |
| `:pause` | `pause_tick` |

## Pattern 2: Case-Based Dispatch

Explicit control flow with case statement. Catches undefined scenes.

```ruby
def tick args
  args.state.current_scene ||= :title

  case args.state.current_scene
  when :title
    tick_title args
  when :game
    tick_game args
  when :game_over
    tick_game_over args
  else
    raise "Unknown scene: #{args.state.current_scene}"
  end
end
```

## Pattern 3: Safe Scene Transitions

Prevent mid-tick scene changes (debugging aid):

```ruby
def tick args
  args.state.current_scene ||= :title
  scene_before = args.state.current_scene

  case args.state.current_scene
  when :title then tick_title(args)
  when :game then tick_game(args)
  end

  # Validate no direct scene change
  if args.state.current_scene != scene_before
    raise "Scene changed mid-tick! Use args.state.next_scene instead."
  end

  # Apply deferred transition
  if args.state.next_scene
    args.state.current_scene = args.state.next_scene
    args.state.next_scene = nil
  end
end

def tick_title args
  if args.inputs.keyboard.key_down.space
    args.state.next_scene = :game  # Deferred, not immediate
  end
end
```

## Scene Transitions

### Direct Transition

```ruby
args.state.scene = :new_scene
return  # IMPORTANT: Prevent further execution
```

### With State Reset

```ruby
def transition_to_gameplay args
  args.state.score = 0
  args.state.timer = 30 * 60
  args.state.player = nil  # Will reinitialize
  args.state.scene = :gameplay
end
```

### Full Game Reset

```ruby
$gtk.reset  # Clears all state, restarts from tick 0
```

### Tracked Transitions

Track when scene changed for animations:

```ruby
def change_to_scene args, scene
  args.state.scene = scene
  args.state.scene_at = Kernel.tick_count
  args.inputs.keyboard.clear  # Prevent input bleed
end

# Use scene_at for animations
def title_tick args
  elapsed = Kernel.tick_count - args.state.scene_at
  alpha = [255, elapsed * 5].min  # Fade in
  args.outputs.labels << { x: 640, y: 400, text: "Title", a: alpha }
end
```

## Title Scene Pattern

```ruby
def title_tick args
  # Display title and instructions
  labels = []
  labels << { x: 640, y: 500, text: "Game Title", size_enum: 10, anchor_x: 0.5 }
  labels << { x: 640, y: 400, text: "by Author Name", anchor_x: 0.5 }
  labels << { x: 640, y: 200, text: "Arrow keys to move | Z to shoot", anchor_x: 0.5 }
  labels << { x: 640, y: 150, text: "Press SPACE to start", size_enum: 2, anchor_x: 0.5 }
  args.outputs.labels << labels

  # Start game on input
  if args.inputs.keyboard.key_down.space ||
     args.inputs.controller_one.key_down.a
    args.outputs.sounds << "sounds/start.wav"
    args.state.scene = :gameplay
    return
  end
end
```

## Gameplay Scene Pattern

```ruby
def gameplay_tick args
  # Initialize state
  args.state.player ||= { x: 640, y: 360, w: 64, h: 64 }
  args.state.score ||= 0
  args.state.timer ||= 60 * 60  # 60 seconds

  # Timer countdown
  args.state.timer -= 1

  # Check game over conditions
  if args.state.timer <= 0
    args.outputs.sounds << "sounds/game-over.wav"
    args.state.scene = :game_over
    return
  end

  # Handle input
  handle_player_input args

  # Update game logic
  update_entities args

  # Render
  render_gameplay args
end
```

## Game Over Scene Pattern

```ruby
def game_over_tick args
  # Continue timer for grace period
  args.state.timer -= 1

  # Display results
  labels = []
  labels << { x: 640, y: 450, text: "Game Over!", size_enum: 10, anchor_x: 0.5 }
  labels << { x: 640, y: 350, text: "Score: #{args.state.score}", size_enum: 4, anchor_x: 0.5 }
  labels << { x: 640, y: 200, text: "Press SPACE to restart", anchor_x: 0.5 }
  args.outputs.labels << labels

  # Grace period before accepting restart input
  return if args.state.timer > -30

  if args.inputs.keyboard.key_down.space
    $gtk.reset  # Full restart
  end
end
```

## Pause Scene Pattern

Overlay pause on gameplay:

```ruby
def tick args
  args.state.scene ||= :gameplay

  # Check for pause toggle
  if args.inputs.keyboard.key_down.escape && args.state.scene == :gameplay
    args.state.scene = :paused
    args.state.paused_at = Kernel.tick_count
    return
  end

  send("#{args.state.scene}_tick", args)
end

def paused_tick args
  # Render frozen gameplay underneath
  render_gameplay_static args

  # Dark overlay
  args.outputs.solids << { x: 0, y: 0, w: 1280, h: 720, r: 0, g: 0, b: 0, a: 180 }

  # Pause menu
  args.outputs.labels << { x: 640, y: 400, text: "PAUSED", size_enum: 10, anchor_x: 0.5, r: 255, g: 255, b: 255 }
  args.outputs.labels << { x: 640, y: 300, text: "Press ESC to resume", anchor_x: 0.5, r: 255, g: 255, b: 255 }

  if args.inputs.keyboard.key_down.escape
    args.state.scene = :gameplay
  end
end
```

## State Persistence Across Scenes

### Shared State

State persists automatically:

```ruby
def gameplay_tick args
  args.state.score += 1  # Score survives scene change
end

def game_over_tick args
  # args.state.score still accessible
  args.outputs.labels << { x: 640, y: 350, text: "Final Score: #{args.state.score}" }
end
```

### Selective Reset

Reset only what's needed:

```ruby
def reset_gameplay args
  args.state.player = nil
  args.state.enemies = []
  args.state.timer = 60 * 60
  # args.state.high_score preserved
end
```

## Conditional Rendering Pattern

Alternative to dispatch—render based on scene state:

```ruby
def tick args
  args.state.scene ||= :menu

  render_background args
  render_ui args

  render_menu args if args.state.scene == :menu
  render_game args if args.state.scene == :game
end

def render_menu args
  return unless args.state.scene == :menu
  # Menu rendering
end
```

## Class-Based Scenes (Advanced)

For complex games with many scenes:

```ruby
class TitleScene
  attr_accessor :args

  def id; :title; end

  def tick
    args.outputs.labels << { x: 640, y: 400, text: "Title" }
    args.state.next_scene = :game if args.inputs.keyboard.key_down.space
  end
end

class GameScene
  attr_accessor :args

  def id; :game; end

  def tick
    # Game logic
  end
end

def tick args
  $scenes ||= [TitleScene.new, GameScene.new]
  args.state.scene ||= :title

  scene = $scenes.find { |s| s.id == args.state.scene }
  scene.args = args
  scene.tick

  if args.state.next_scene
    args.state.scene = args.state.next_scene
    args.state.next_scene = nil
  end
end
```

## Antipatterns

### Missing Early Return

```ruby
# BAD: Executes both scenes
def gameplay_tick args
  if game_over?
    args.state.scene = :game_over
  end
  update_player args  # Still runs after scene change!
end

# GOOD: Early return
def gameplay_tick args
  if game_over?
    args.state.scene = :game_over
    return
  end
  update_player args
end
```

### Undefined Scene Methods

```ruby
# BAD: Crashes if scene method missing
send("#{args.state.scene}_tick", args)

# GOOD: Validate scene exists
valid_scenes = [:title, :gameplay, :game_over]
unless valid_scenes.include?(args.state.scene)
  raise "Invalid scene: #{args.state.scene}"
end
```

### Mid-Tick Scene Changes

```ruby
# BAD: Hard to debug
def some_helper args
  args.state.scene = :game_over  # Hidden transition
end

# GOOD: Centralized transitions
def transition_to_game_over args
  args.state.scene = :game_over
  args.state.game_ended_at = Kernel.tick_count
end
```

## Decision Tree

**Choosing a scene pattern:**

1. **Simple game (2-4 scenes)?** → Send-based dispatch (`examples/scenes/send_dispatch.rb`)
2. **Need explicit scene validation?** → Case-based dispatch (`examples/scenes/case_dispatch.rb`)
3. **Debugging scene transitions?** → Safe transitions pattern (`examples/scenes/safe_transitions.rb`)
4. **Complex game with shared scene data?** → Class-based scenes (`examples/scenes/class_based.rb`)
5. **Pause overlay on gameplay?** → Conditional rendering (`examples/scenes/pause_overlay.rb`)

## Quick Reference

| Task | Solution |
|---|---|
| Initialize scene | `args.state.scene \|\|= :title` |
| Change scene | `args.state.scene = :new_scene; return` |
| Full reset | `$gtk.reset` |
| Track transition time | `args.state.scene_at = Kernel.tick_count` |
| Grace period | `return if args.state.timer > -30` |
| Clear input bleed | `args.inputs.keyboard.clear` |
