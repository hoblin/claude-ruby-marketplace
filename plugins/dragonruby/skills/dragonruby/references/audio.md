# Audio

## Two Audio Systems

DragonRuby provides two distinct audio interfaces:

| System | Purpose | Format | Cleanup |
|--------|---------|--------|---------|
| `args.outputs.sounds` | One-shot effects | WAV | Automatic |
| `args.audio[:key]` | Continuous/looping | OGG/MP3 | Manual |

## One-Shot Sound Effects

Fire-and-forget sounds via `args.outputs.sounds`.

```ruby
# Simple path string
args.outputs.sounds << "sounds/coin.wav"

# With volume control
args.outputs.sounds << { path: "sounds/explosion.wav", gain: 0.5 }
```

**Event-driven triggers:**

```ruby
# On input
if args.inputs.keyboard.key_down.space
  args.outputs.sounds << "sounds/jump.wav"
end

# On collision
if args.geometry.intersect_rect?(bullet, enemy)
  args.outputs.sounds << "sounds/hit.wav"
  enemy.dead = true
end

# On timer event
if args.state.timer == 0
  args.outputs.sounds << "sounds/game-over.wav"
end
```

## Continuous Audio (args.audio)

Managed audio with full control via hash keys.

```ruby
# Start background music
args.audio[:music] = {
  input:   "sounds/theme.ogg",
  looping: true,
  gain:    0.8
}

# Stop music
args.audio[:music] = nil
# OR
args.audio.delete(:music)
```

**Initialize once pattern:**

```ruby
def tick(args)
  if Kernel.tick_count == 0
    args.audio[:music] = { input: "sounds/theme.ogg", looping: true }
  end
  # Game logic...
end
```

## Audio Properties

All configurable properties for `args.audio`:

```ruby
args.audio[:track] = {
  input:   "sounds/music.ogg",  # File path (required)
  gain:    1.0,                  # Volume: 0.0 to 1.0 (MUST be float)
  pitch:   1.0,                  # Pitch: 1.0 = normal (MUST be float)
  looping: true,                 # Loop continuously
  paused:  false,                # Pause playback
  x: 0.0, y: 0.0, z: 0.0        # 3D position: -1.0 to 1.0
}
```

**Dynamic properties (read-only, added by engine):**

```ruby
track = args.audio[:track]
track.playtime    # Current position in seconds
track.playlength  # Total duration in seconds
```

## Volume Control

### Per-Track Volume (gain)

```ruby
# Set volume (0.0 = silent, 1.0 = full)
args.audio[:music].gain = 0.5

# Fade out over time
args.audio[:music].gain -= 0.01 if args.audio[:music].gain > 0
```

### Global Volume

```ruby
# Adjust master volume
args.audio.volume += 0.1 if args.inputs.up
args.audio.volume -= 0.1 if args.inputs.down
```

## Pausing and Resuming

```ruby
# Pause
args.audio[:music].paused = true

# Resume
args.audio[:music].paused = false

# Toggle
args.audio[:music].paused = !args.audio[:music].paused
```

**Common pattern - pause on game over:**

```ruby
if args.state.timer == 0
  args.audio[:music].paused = true
  args.outputs.sounds << "sounds/game-over.wav"
end
```

## Seeking (Playback Position)

```ruby
# Jump to specific time (seconds)
args.audio[:music].playtime = 30.0

# Jump to 50% of track
args.audio[:music].playtime = args.audio[:music].playlength * 0.5

# Restart from beginning
args.audio[:music].playtime = 0
```

## Audio Formats

| Format | Use Case | Notes |
|--------|----------|-------|
| WAV | Sound effects | Uncompressed, high quality, max 44.1kHz |
| OGG | Music/loops | Compressed, cross-platform |
| MP3 | Music/loops | Compressed, widely supported |

**Convert WAV to OGG:**
```bash
ffmpeg -i sound.wav -ac 2 -b:a 160k -ar 44100 -acodec libvorbis sound.ogg
```

**Re-encode problematic OGG:**
```bash
ffmpeg -i sound.ogg -ac 2 -b:a 160k -ar 44100 -acodec libvorbis sound-fixed.ogg
```

## Multi-Track Management

```ruby
# Initialize multiple tracks
args.audio[:music] = { input: "sounds/music.ogg", looping: true }
args.audio[:ambient] = { input: "sounds/wind.ogg", looping: true, gain: 0.3 }

# Iterate all active audio
args.audio.each do |key, track|
  puts "#{key}: #{track.playtime}/#{track.playlength}s"
end

# Stop all audio
args.audio.each_key { |k| args.audio.delete(k) }
```

## Crossfading

Smooth transition between tracks:

```ruby
def start_crossfade(args, new_track)
  # Capture current track for fadeout
  current = args.audio[:music]
  args.audio[:music_fade] = {
    input:    current[:input],
    looping:  true,
    gain:     current[:gain],
    playtime: current[:playtime]
  }

  # Start new track at zero volume
  args.audio[:music] = {
    input:   new_track,
    looping: true,
    gain:    0.0
  }
end

def update_crossfade(args)
  # Fade in new track
  if args.audio[:music] && args.audio[:music].gain < 1.0
    args.audio[:music].gain = (args.audio[:music].gain + 0.01).clamp(0, 1)
  end

  # Fade out old track
  if args.audio[:music_fade]
    args.audio[:music_fade].gain -= 0.01
    if args.audio[:music_fade].gain <= 0
      args.audio.delete(:music_fade)
    end
  end
end
```

## 3D Audio Positioning

Position audio in stereo field:

```ruby
# x: -1.0 (left) to 1.0 (right)
# y: -1.0 (back) to 1.0 (front)
# z: distance (typically 0.0)

args.audio[:enemy_sound] = {
  input: "sounds/growl.ogg",
  looping: true,
  x: (enemy.x / 640.0) - 1.0,  # Scale screen x to -1..1
  y: 0.0,
  z: 0.0
}
```

## Sound Synthesis (Advanced)

Generate audio procedurally:

```ruby
def generate_sine_wave(frequency:, duration:)
  sample_rate = 48000
  samples_per_period = (sample_rate / frequency).ceil
  sample_count = (sample_rate * duration).floor

  sample_count.times.map do |i|
    Math.sin(2 * Math::PI * i / samples_per_period)
  end
end

# Play generated sound
wave = generate_sine_wave(frequency: 440, duration: 0.5)
args.audio[:beep] = {
  input: [1, 48000, wave]  # [channels, sample_rate, samples]
}
```

**Wave types:**
- Sine wave - smooth tone
- Square wave - harsh, retro (use gain: 0.3)
- Sawtooth wave - buzzy, synth-like (use gain: 0.3)
- Triangle wave - soft, mellow

## Anti-Patterns

### Re-initializing Music Every Frame

```ruby
# WRONG - restarts music every frame
def tick(args)
  args.audio[:music] = { input: "sounds/theme.ogg", looping: true }
end

# CORRECT - initialize once
def tick(args)
  if Kernel.tick_count == 0
    args.audio[:music] = { input: "sounds/theme.ogg", looping: true }
  end
end
```

### Integer for gain/pitch

```ruby
# WRONG - must be float
args.audio[:music].gain = 1
args.audio[:music].pitch = 2

# CORRECT
args.audio[:music].gain = 1.0
args.audio[:music].pitch = 2.0
```

### Forgetting to Stop Looping Audio

```ruby
# WRONG - music plays forever even after scene change
def change_scene(args)
  args.state.scene = :menu
end

# CORRECT - stop or pause music on transition
def change_scene(args)
  args.audio[:gameplay_music] = nil
  args.state.scene = :menu
end
```

### Playing Same Sound Multiple Times Per Frame

```ruby
# WRONG - multiple bullets fire same frame, overlapping sounds
args.state.bullets.each do |bullet|
  if bullet.just_fired
    args.outputs.sounds << "sounds/shoot.wav"
  end
end

# CORRECT - play once per frame
if args.state.bullets.any?(&:just_fired)
  args.outputs.sounds << "sounds/shoot.wav"
end
```

### Not Handling Missing Audio

```ruby
# WRONG - crashes if audio was deleted
args.audio[:music].paused = true

# CORRECT - guard against nil
args.audio[:music]&.paused = true
# OR
if args.audio[:music]
  args.audio[:music].paused = true
end
```

## Best Practices

1. **Use WAV for short effects, OGG/MP3 for music**
2. **Initialize looping audio on tick 0 or in boot**
3. **Pause music on game over, don't delete** (allows resume)
4. **Use descriptive keys** - `:gameplay_music`, `:menu_ambient`
5. **Clean up audio on scene transitions**
6. **Restart DragonRuby after changing sound files** (hot reload limitation)

## Decision Tree

```
Playing a sound?
├── One-shot effect (explosion, coin, jump)
│   └── examples/audio/sound_effects.rb
│       └── Need volume control? → { path: "...", gain: 0.5 }
│
├── Background music/ambient loops
│   └── examples/audio/background_music.rb
│       ├── Need pause/volume/seek? → examples/audio/music_controls.rb
│       ├── Need to stop? → args.audio[:key] = nil
│       └── Event-driven? → examples/audio/audio_events.rb
│
└── Transitioning between tracks?
    └── examples/audio/crossfade.rb

Managing audio state?
├── Initialize on game start → examples/audio/background_music.rb
├── Pause/resume controls → examples/audio/music_controls.rb
├── Stop on scene change → args.audio[:key] = nil
└── Volume adjustment → examples/audio/music_controls.rb

Triggering sounds?
├── On input (jump, shoot) → examples/audio/audio_events.rb
├── On collision → examples/audio/audio_events.rb
└── On timer/periodic → examples/audio/audio_events.rb

Need advanced audio?
├── 3D positioning → x, y, z properties (-1.0 to 1.0)
├── Track progress → .playtime / .playlength
├── Multiple tracks → different keys (:music, :sfx, :ambient)
└── Procedural audio → [channels, sample_rate, samples_array]
```
