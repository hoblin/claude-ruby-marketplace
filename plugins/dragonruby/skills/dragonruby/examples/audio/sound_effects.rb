# sound_effects.rb
# One-shot sound effects using args.outputs.sounds

def tick(args)
  args.state.notes ||= [:c3, :d3, :e3, :f3, :g3, :a3, :b3, :c4]

  # Basic sound playback - add path string
  if args.inputs.mouse.click
    args.outputs.sounds << "sounds/#{args.state.notes.sample}.wav"
  end

  # Sound with volume control - use hash
  if args.inputs.keyboard.key_down.space
    args.outputs.sounds << {
      path: "sounds/#{args.state.notes.sample}.wav",
      gain: 0.5  # Volume: 0.0 to 1.0
    }
  end

  # Multiple sounds at once
  if args.inputs.keyboard.key_down.enter
    args.outputs.sounds << "sounds/jump.wav"
    args.outputs.sounds << { path: "sounds/coin.wav", gain: 0.3 }
  end

  args.outputs.labels << [
    { x: 640, y: 400, text: "Click or SPACE for sounds", alignment_enum: 1 },
    { x: 640, y: 360, text: "ENTER for multiple sounds", alignment_enum: 1 }
  ]
end
