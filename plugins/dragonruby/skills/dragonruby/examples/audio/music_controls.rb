# music_controls.rb
# Music controls: pause, volume, seeking

def tick(args)
  defaults(args)
  input(args)
  render(args)
end

def defaults(args)
  return if args.audio[:music]

  args.audio[:music] = {
    input:   "sounds/music.ogg",
    looping: true,
    gain:    0.5,
    paused:  false
  }
end

def input(args)
  music = args.audio[:music]
  return unless music

  # Toggle pause
  music.paused = !music.paused if args.inputs.keyboard.key_down.space

  # Volume control
  if args.inputs.keyboard.key_down.up
    music.gain = (music.gain + 0.1).clamp(0, 1)
  elsif args.inputs.keyboard.key_down.down
    music.gain = (music.gain - 0.1).clamp(0, 1)
  end

  # Seeking
  if args.inputs.keyboard.key_down.right
    music.playtime += 5
  elsif args.inputs.keyboard.key_down.left
    music.playtime = [music.playtime - 5, 0].max
  end
end

def render(args)
  music = args.audio[:music]
  args.outputs.labels << [
    { x: 10, y: 700, text: "SPACE: #{music.paused ? 'Resume' : 'Pause'}" },
    { x: 10, y: 670, text: "UP/DOWN: Volume (#{(music.gain * 100).to_i}%)" },
    { x: 10, y: 640, text: "LEFT/RIGHT: Seek (+/- 5s)" },
    { x: 10, y: 610, text: "Position: #{music.playtime.to_i}s" }
  ]
end
