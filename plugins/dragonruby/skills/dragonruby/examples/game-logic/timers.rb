# Timer Patterns in DragonRuby
# Demonstrates frame-based timing, countdowns, and periodic execution

FPS = 60

def tick(args)
  defaults(args)
  tick_countdown_timer(args)
  tick_progress_bar(args)
  tick_periodic_spawner(args)
  render(args)
end

def defaults(args)
  # Countdown timer (30 seconds)
  args.state.countdown ||= 30 * FPS

  # Progress bar (fills over 5 seconds)
  args.state.progress ||= 0
  args.state.progress_max ||= 5 * FPS

  # Periodic spawner
  args.state.spawn_rate ||= FPS  # Every second
  args.state.spawned_count ||= 0
end

# Pattern 1: Countdown Timer
def tick_countdown_timer(args)
  return if args.state.countdown <= 0

  args.state.countdown -= 1

  if args.state.countdown <= 0
    args.state.time_up = true
  end
end

# Pattern 2: Progress Bar (fills up)
def tick_progress_bar(args)
  return if args.state.progress >= args.state.progress_max

  args.state.progress += 1
end

# Pattern 3: Periodic Execution with zmod?
def tick_periodic_spawner(args)
  # Execute every spawn_rate frames
  if Kernel.tick_count.zmod?(args.state.spawn_rate)
    args.state.spawned_count += 1
  end
end

def render(args)
  # Display countdown as seconds
  seconds_left = (args.state.countdown / FPS).ceil
  args.outputs.labels << {
    x: 640, y: 600, text: "Time: #{seconds_left}s",
    size_enum: 5, anchor_x: 0.5
  }

  # Display progress percentage
  progress_pct = (args.state.progress.fdiv(args.state.progress_max) * 100).round
  args.outputs.labels << {
    x: 640, y: 500, text: "Progress: #{progress_pct}%",
    size_enum: 3, anchor_x: 0.5
  }

  # Progress bar visual
  bar_width = 400
  filled = (args.state.progress.fdiv(args.state.progress_max) * bar_width).round
  args.outputs.solids << { x: 440, y: 450, w: bar_width, h: 20, r: 100, g: 100, b: 100 }
  args.outputs.solids << { x: 440, y: 450, w: filled, h: 20, r: 0, g: 200, b: 0 }

  # Spawn counter
  args.outputs.labels << {
    x: 640, y: 400, text: "Spawned: #{args.state.spawned_count}",
    size_enum: 3, anchor_x: 0.5
  }

  # Time up message
  if args.state.time_up
    args.outputs.labels << {
      x: 640, y: 300, text: "TIME UP!",
      size_enum: 10, anchor_x: 0.5, r: 255, g: 0, b: 0
    }
  end
end
