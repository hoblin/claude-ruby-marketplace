# Safe Scene Transitions
# Prevents mid-tick scene changes for easier debugging
# Source: DragonRuby samples/02_input_basics/07_managing_scenes

def tick args
  args.state.current_scene ||= :title

  # Capture scene before tick
  scene_before = args.state.current_scene

  # Dispatch to scene
  case args.state.current_scene
  when :title
    tick_title args
  when :game
    tick_game args
  when :game_over
    tick_game_over args
  end

  # Validate: scene should not change mid-tick
  if args.state.current_scene != scene_before
    raise "Scene changed mid-tick! Set args.state.next_scene instead."
  end

  # Apply deferred transition at end of tick
  if args.state.next_scene
    args.state.current_scene = args.state.next_scene
    args.state.next_scene = nil
  end
end

def tick_title args
  args.outputs.labels << {
    x: 640, y: 360,
    text: "Title (click to start)",
    anchor_x: 0.5
  }

  if args.inputs.mouse.click
    # Use next_scene for deferred transition
    args.state.next_scene = :game
  end
end

def tick_game args
  args.outputs.labels << {
    x: 640, y: 360,
    text: "Game (click for game over)",
    anchor_x: 0.5
  }

  if args.inputs.mouse.click
    args.state.next_scene = :game_over
  end
end

def tick_game_over args
  args.outputs.labels << {
    x: 640, y: 360,
    text: "Game Over (click to restart)",
    anchor_x: 0.5
  }

  if args.inputs.mouse.click
    args.state.next_scene = :title
  end
end
