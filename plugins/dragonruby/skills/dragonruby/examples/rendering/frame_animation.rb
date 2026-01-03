# Frame animation using separate PNG files

def tick args
  # Looping animation: 6 frames, 4 ticks each, repeat forever
  looping_frame = 0.frame_index(6, 4, true)

  args.outputs.sprites << {
    x: 200, y: 400, w: 100, h: 100,
    path: "sprites/dragon_fly_#{looping_frame}.png"
  }

  # One-time animation triggered by spacebar
  if args.inputs.keyboard.key_down.space
    args.state.attack_at = Kernel.tick_count
  end

  if args.state.attack_at
    frame = args.state.attack_at.frame_index(6, 4, false)
    frame ||= 0  # Stay on first frame when complete

    args.outputs.sprites << {
      x: 600, y: 400, w: 100, h: 100,
      path: "sprites/dragon_fly_#{frame}.png"
    }
  end

  args.outputs.labels << {
    x: 640, y: 100,
    text: "Press SPACE for one-time animation",
    anchor_x: 0.5
  }
end
