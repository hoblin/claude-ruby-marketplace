# audio_events.rb
# Sound effects triggered by game events

def tick(args)
  defaults(args)
  input(args)
  calc(args)
  render(args)
end

def defaults(args)
  args.state.player ||= { x: 640, y: 360, w: 50, h: 50, dy: 0 }
  args.state.coins  ||= [{ x: 700, y: 360, w: 30, h: 30 }]
  args.state.timer  ||= 0
end

def input(args)
  player = args.state.player

  # Sound on input event (jump)
  if args.inputs.keyboard.key_down.space && player.dy == 0
    args.outputs.sounds << "sounds/jump.wav"
    player.dy = 10
  end
end

def calc(args)
  player = args.state.player

  # Gravity
  player.dy -= 0.5
  player.y += player.dy
  player.y = 360 if player.y <= 360
  player.dy = 0 if player.y == 360

  # Sound on collision event (coin pickup)
  args.state.coins.reject! do |coin|
    if player.intersect_rect?(coin)
      args.outputs.sounds << { path: "sounds/coin.wav", gain: 0.8 }
      true
    end
  end

  # Sound on timer event (every 3 seconds)
  args.state.timer += 1
  if args.state.timer.zmod?(180)
    args.outputs.sounds << { path: "sounds/ambient.wav", gain: 0.3 }
  end
end

def render(args)
  args.outputs.solids << args.state.player
  args.outputs.solids << args.state.coins.map { |c| c.merge(r: 255, g: 200, b: 0) }
  args.outputs.labels << { x: 10, y: 720, text: "SPACE to jump (input event)" }
end
