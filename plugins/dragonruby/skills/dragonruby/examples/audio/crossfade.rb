# crossfade.rb
# Smooth crossfade between two music tracks

def tick(args)
  defaults(args)
  update_crossfade(args)
  input(args)
  render(args)
end

def defaults(args)
  return if args.audio[:track_a]

  # Initialize two tracks - one playing, one silent
  args.audio[:track_a] = { input: "sounds/music.ogg", gain: 1.0, looping: true }
  args.audio[:track_b] = { input: "sounds/music2.ogg", gain: 0.0, looping: true }
  args.state.active_track = :track_a
end

def update_crossfade(args)
  active = args.state.active_track
  inactive = active == :track_a ? :track_b : :track_a

  # Fade in active track
  if args.audio[active]
    args.audio[active].gain = (args.audio[active].gain + 0.01).clamp(0, 1)
  end

  # Fade out inactive track
  if args.audio[inactive]
    args.audio[inactive].gain = (args.audio[inactive].gain - 0.01).clamp(0, 1)
  end
end

def input(args)
  # Swap tracks on SPACE
  if args.inputs.keyboard.key_down.space
    args.state.active_track = args.state.active_track == :track_a ? :track_b : :track_a
  end
end

def render(args)
  a_vol = (args.audio[:track_a]&.gain.to_f * 100).to_i
  b_vol = (args.audio[:track_b]&.gain.to_f * 100).to_i

  args.outputs.labels << [
    { x: 640, y: 400, text: "Press SPACE to crossfade", alignment_enum: 1 },
    { x: 640, y: 360, text: "Track A: #{a_vol}%", alignment_enum: 1 },
    { x: 640, y: 330, text: "Track B: #{b_vol}%", alignment_enum: 1 }
  ]
end
