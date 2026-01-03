# Scene Transition Patterns
# Various ways to handle scene changes

# --- Pattern 1: Instant Transition ---
def instant_transition args
  args.state.scene = :new_scene
  return  # Important: early return
end

# --- Pattern 2: Tracked Transition ---
# Track when scene changed for animations/effects
def change_to_scene args, scene
  args.state.scene = scene
  args.state.scene_at = Kernel.tick_count
  args.inputs.keyboard.clear  # Prevent input bleed
end

def title_tick_with_fade args
  elapsed = Kernel.tick_count - (args.state.scene_at || 0)
  alpha = [255, elapsed * 8].min  # Fade in over ~32 frames

  args.outputs.labels << {
    x: 640, y: 400,
    text: "Title",
    anchor_x: 0.5,
    a: alpha
  }
end

# --- Pattern 3: State Reset on Transition ---
def transition_to_gameplay args
  # Reset gameplay state
  args.state.player = nil  # Will reinitialize
  args.state.enemies = []
  args.state.score = 0
  args.state.timer = 60 * 60

  # Keep persistent state
  # args.state.high_score preserved

  args.state.scene = :gameplay
end

# --- Pattern 4: Full Game Reset ---
def restart_game
  $gtk.reset  # Clears ALL state, tick_count resets
end

# --- Pattern 5: Grace Period ---
# Prevent accidental input after scene change
def game_over_tick args
  args.state.grace_timer ||= 60  # 1 second grace period
  args.state.grace_timer -= 1

  args.outputs.labels << {
    x: 640, y: 400,
    text: "Game Over!",
    anchor_x: 0.5
  }

  # Don't accept input during grace period
  return if args.state.grace_timer > 0

  args.outputs.labels << {
    x: 640, y: 300,
    text: "Press SPACE to restart",
    anchor_x: 0.5
  }

  if args.inputs.keyboard.key_down.space
    $gtk.reset
  end
end

# --- Example: Complete Flow ---
def tick args
  args.state.scene ||= :title

  case args.state.scene
  when :title
    args.outputs.labels << { x: 640, y: 400, text: "Title - Press SPACE", anchor_x: 0.5 }
    if args.inputs.keyboard.key_down.space
      transition_to_gameplay args
    end

  when :gameplay
    args.state.timer ||= 60 * 60
    args.state.timer -= 1
    args.outputs.labels << { x: 640, y: 400, text: "Time: #{(args.state.timer / 60).ceil}", anchor_x: 0.5 }
    if args.state.timer <= 0
      args.state.scene = :game_over
      args.state.grace_timer = nil  # Reset for game_over_tick
    end

  when :game_over
    game_over_tick args
  end
end
