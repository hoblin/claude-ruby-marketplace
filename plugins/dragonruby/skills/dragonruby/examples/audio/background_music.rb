# background_music.rb
# Looping music using args.audio[:key]

def tick(args)
  # Initialize music once - loops automatically
  if Kernel.tick_count == 0
    args.audio[:music] = {
      input:   "sounds/music.ogg",  # Path to music file
      gain:    0.8,                  # Volume (0.0 to 1.0)
      looping: true                  # Loop when finished
    }
  end

  # Stop music with Q key
  if args.inputs.keyboard.key_down.q
    args.audio[:music] = nil
  end

  # Start music with P key (if stopped)
  if args.inputs.keyboard.key_down.p && !args.audio[:music]
    args.audio[:music] = { input: "sounds/music.ogg", looping: true }
  end

  status = args.audio[:music] ? "Playing" : "Stopped"
  args.outputs.labels << [
    { x: 640, y: 400, text: "Music: #{status}", alignment_enum: 1 },
    { x: 640, y: 360, text: "P = Play | Q = Stop", alignment_enum: 1 }
  ]
end
