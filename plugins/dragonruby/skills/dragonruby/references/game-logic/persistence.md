# Persistence (Save/Load)

## File System Overview

DragonRuby uses a sandboxed filesystem:

| Environment | Read Location | Write Location |
|-------------|---------------|----------------|
| Development | Game directory | Game directory |
| Windows | Data dir, then game | `C:\Users\<name>\AppData\Roaming\[devtitle]\[gametitle]` |
| macOS | Data dir, then game | `$HOME/Library/Application Support/[gametitle]` |
| Linux | Data dir, then game | `$HOME/.local/share/[gametitle]` |
| HTML5 | IndexedDB | IndexedDB |

## Basic File Operations

### Reading Files

```ruby
contents = $gtk.read_file("save.txt")

if contents
  puts contents
else
  puts "File does not exist"
end
```

**Returns:** String content or `nil` if file doesn't exist.

### Writing Files

```ruby
$gtk.write_file("save.txt", "Player score: 100")
```

**Behavior:** Overwrites existing file. Creates if doesn't exist.

### Appending to Files

```ruby
$gtk.append_file("log.txt", "Event at #{Kernel.tick_count}\n")
```

**Behavior:** Adds to end of file. Creates if doesn't exist.

### Deleting Files

```ruby
# Always check existence first
if $gtk.stat_file("temp.txt")
  $gtk.delete_file("temp.txt")
end
```

**Caution:** Raises exceptions if file open, permissions denied, or directory not empty.

### File Info

```ruby
info = $gtk.stat_file("save.txt")

if info
  puts info.file_size      # Integer
  puts info.mod_time       # Integer timestamp
  puts info.file_type      # :regular, :directory, :symlink
  puts info.readonly       # Boolean
end
```

### Listing Directory

```ruby
files = $gtk.list_files("sprites/")
# Returns: ["player.png", "enemy.png", ...]
```

## Type Conversion Patterns

### Reading Numbers (Nil-Safe)

```ruby
# .to_i on nil returns 0 - perfect for missing files
HIGH_SCORE_FILE = "high-score.txt"

args.state.high_score ||= $gtk.read_file(HIGH_SCORE_FILE).to_i
```

### Writing Numbers

```ruby
# Convert to string before writing
$gtk.write_file(HIGH_SCORE_FILE, args.state.score.to_s)
```

## Save-Once Pattern

**Critical:** Without flags, file writes 60 times/second!

```ruby
def game_over_tick(args)
  # Load high score (once per game over)
  args.state.high_score ||= $gtk.read_file("high-score.txt").to_i

  # Save new high score (once)
  if !args.state.saved_high_score && args.state.score > args.state.high_score
    $gtk.write_file("high-score.txt", args.state.score.to_s)
    args.state.saved_high_score = true  # Prevent repeated saves
  end
end
```

## High Score Pattern (Complete)

```ruby
HIGH_SCORE_FILE = "high-score.txt"

def game_over_tick(args)
  # Load lazily (once)
  args.state.high_score ||= $gtk.read_file(HIGH_SCORE_FILE).to_i

  # Save if beaten (once)
  if !args.state.saved && args.state.score > args.state.high_score
    $gtk.write_file(HIGH_SCORE_FILE, args.state.score.to_s)
    args.state.saved = true
  end

  # Display
  if args.state.score > args.state.high_score
    args.outputs.labels << { x: 260, y: 630, text: "New high-score!" }
  else
    args.outputs.labels << { x: 260, y: 630, text: "Best: #{args.state.high_score}" }
  end

  # Restart prompt
  if fire_input?(args)
    $gtk.reset
  end
end
```

## Complex State Serialization

For saving full game state (player, enemies, inventory, etc.):

### Serialize State

```ruby
# Save to file
$gtk.serialize_state("game_state.txt", args.state)

# Or get string without saving
serialized = $gtk.serialize_state(args.state)
```

**Warning:** Serialization over 20KB triggers performance warning.

### Deserialize State

```ruby
# Load from file
loaded_state = $gtk.deserialize_state("game_state.txt")

if loaded_state
  args.state = loaded_state
else
  puts "No save file found"
end
```

### Full Save/Load Implementation

```ruby
def save_game(args)
  $gtk.serialize_state("save.txt", args.state)
  $gtk.notify!("Game saved!")
end

def load_game(args)
  loaded = $gtk.deserialize_state("save.txt")
  if loaded
    args.state = loaded
    $gtk.notify!("Game loaded!")
  else
    $gtk.notify!("No save found")
  end
end

def tick(args)
  if args.inputs.keyboard.key_down.f5
    save_game(args)
  elsif args.inputs.keyboard.key_down.f9
    load_game(args)
  end
end
```

### Timestamped Backups

```ruby
def save_with_backup(args)
  timestamp = Time.now.to_i
  $gtk.serialize_state("save_#{timestamp}.txt", args.state)
  $gtk.serialize_state("save.txt", args.state)  # Main save
end
```

## Simple Data Formats

### Single Value (Text)

```ruby
# Save
$gtk.write_file("level.txt", args.state.current_level.to_s)

# Load
args.state.current_level = $gtk.read_file("level.txt").to_i
```

### Multiple Values (Delimited)

```ruby
# Save
data = "#{args.state.score},#{args.state.level},#{args.state.lives}"
$gtk.write_file("progress.txt", data)

# Load
contents = $gtk.read_file("progress.txt")
if contents
  parts = contents.split(",")
  args.state.score = parts[0].to_i
  args.state.level = parts[1].to_i
  args.state.lives = parts[2].to_i
end
```

### JSON-Like (Using serialize_state)

For structured data, prefer `serialize_state`/`deserialize_state` - handles complex nested objects automatically.

## File Path Conventions

```ruby
# Simple filenames in root
"high-score.txt"
"save.txt"

# Subdirectories (created automatically)
"saves/slot1.txt"
"data/progress.txt"

# Descriptive extensions
"player-data.txt"    # Simple text
"game-state.dat"     # Serialized state
```

## Development vs Production

### Development Mode

```ruby
# Writes directly to mygame/ directory
$gtk.write_file("debug.txt", "test")

# Useful for level editors, debug output
```

### Get Data Directory

```ruby
path = $gtk.get_game_dir
# Development: mygame/
# Production: OS-specific data path
```

### Development-Only Functions

```ruby
# Write outside sandbox (dev only!)
$gtk.write_file_root("../external.txt", "data")
$gtk.append_file_root("../log.txt", "entry\n")
```

## Anti-Patterns

### Missing Save-Once Flag

```ruby
# WRONG - writes 60 times/second!
if args.state.score > args.state.high_score
  $gtk.write_file("high-score.txt", args.state.score.to_s)
end

# CORRECT
if !args.state.saved && args.state.score > args.state.high_score
  $gtk.write_file("high-score.txt", args.state.score.to_s)
  args.state.saved = true
end
```

### Unchecked File Read

```ruby
# DANGEROUS - crashes on nil
score = $gtk.read_file("score.txt").to_i  # OK, nil.to_i = 0

# DANGEROUS - crashes if file missing
name = $gtk.read_file("name.txt").strip  # NoMethodError!

# SAFE
contents = $gtk.read_file("name.txt")
name = contents ? contents.strip : "Player"
```

### Deleting Without Check

```ruby
# WRONG - raises exception if missing
$gtk.delete_file("temp.txt")

# CORRECT
if $gtk.stat_file("temp.txt")
  $gtk.delete_file("temp.txt")
end
```

### Saving Every Frame

```ruby
# WRONG - massive I/O overhead
def tick(args)
  $gtk.write_file("autosave.txt", args.state.to_s)
end

# CORRECT - periodic saves
def tick(args)
  if Kernel.tick_count.zmod?(60 * 30)  # Every 30 seconds
    save_game(args)
  end
end
```

## Quick Reference

| Operation | Method | Returns |
|-----------|--------|---------|
| Read | `$gtk.read_file(path)` | String or nil |
| Write | `$gtk.write_file(path, data)` | - |
| Append | `$gtk.append_file(path, data)` | - |
| Delete | `$gtk.delete_file(path)` | - |
| Info | `$gtk.stat_file(path)` | Hash or nil |
| List | `$gtk.list_files(dir)` | Array |
| Serialize | `$gtk.serialize_state(path, state)` | String |
| Deserialize | `$gtk.deserialize_state(path)` | Object or nil |

## Decision Tree

```
What to save?
├── Single value (high score, level) → examples/game-logic/save_load.rb (simple pattern)
│   └── Use write_file + .to_s / read_file + .to_i
├── Multiple values → Delimited string or serialize_state
└── Full game state → examples/game-logic/save_load.rb (serialize pattern)
    └── Use serialize_state / deserialize_state

When to save?
├── On event (game over, checkpoint) → Save-once flag pattern
├── Periodically → zmod?(60 * 30) for every 30 seconds
└── On user action (F5 key) → examples/game-logic/save_load.rb

How to handle missing files?
├── Numeric data → .to_i handles nil (returns 0)
├── String data → Check for nil: contents ? contents : "default"
└── Complex data → deserialize_state returns nil if missing

File not saving correctly?
├── Writing 60x/second? → Add save-once flag
├── File empty? → Check .to_s conversion
└── Wrong location? → Development vs production paths differ
```
