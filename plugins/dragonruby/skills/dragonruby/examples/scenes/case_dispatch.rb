# Case-Based Scene Dispatch
# Explicit control flow with validation
# Source: DragonRuby samples/02_input_basics/07_managing_scenes

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
    # Catch undefined scenes
    args.outputs.labels << {
      x: 640, y: 360,
      text: "Unknown scene: #{args.state.current_scene}",
      anchor_x: 0.5,
      r: 255, g: 0, b: 0
    }
  end
end

def tick_title args
  args.outputs.labels << {
    x: 640, y: 360,
    text: "Title Scene (click to start)",
    anchor_x: 0.5
  }

  if args.inputs.mouse.click
    args.state.current_scene = :game
  end
end

def tick_game args
  args.outputs.labels << {
    x: 640, y: 360,
    text: "Game Scene (click for game over)",
    anchor_x: 0.5
  }

  if args.inputs.mouse.click
    args.state.current_scene = :game_over
  end
end

def tick_game_over args
  args.outputs.labels << {
    x: 640, y: 360,
    text: "Game Over (click to restart)",
    anchor_x: 0.5
  }

  if args.inputs.mouse.click
    args.state.current_scene = :title
  end
end
