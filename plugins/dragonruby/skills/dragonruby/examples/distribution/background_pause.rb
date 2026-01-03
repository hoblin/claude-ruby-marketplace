# Handle background/unfocused state gracefully
# Important for web and mobile where users tab away

def tick(args)
  if game_paused?(args)
    render_pause_screen(args)
    return
  end

  tick_game(args)
end

def game_paused?(args)
  # Only pause in production builds when window loses focus
  !args.inputs.keyboard.has_focus &&
    args.gtk.production &&
    Kernel.tick_count > 0
end

def render_pause_screen(args)
  args.outputs.background_color = [0, 0, 0]
  args.outputs.labels << {
    x: 640,
    y: 360,
    text: "Game Paused",
    size_enum: 10,
    alignment_enum: 1,
    r: 255, g: 255, b: 255
  }
  args.outputs.labels << {
    x: 640,
    y: 300,
    text: "Click to resume",
    size_enum: 2,
    alignment_enum: 1,
    r: 180, g: 180, b: 180
  }
end

def tick_game(args)
  # Normal game logic here
end
