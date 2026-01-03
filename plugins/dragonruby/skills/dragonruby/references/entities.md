# Entities Domain Reference

Game entity management: storage, spawning, collision detection, and lifecycle.

## Entity Storage

Store entities in `args.state` arrays with lazy initialization:

```ruby
def tick(args)
  args.state.enemies ||= []
  args.state.bullets ||= []
  args.state.particles ||= []
end
```

**Naming convention:** Use descriptive plurals (enemies, bullets, projectiles).

## Entity Representation

### Hash-Based Entities (Recommended for most games)

```ruby
entity = {
  # Required for rendering
  x: 100, y: 100, w: 40, h: 40,
  path: 'sprites/enemy.png',

  # Optional visual properties
  r: 255, g: 255, b: 255, a: 255,
  angle: 0,
  flip_horizontally: false,

  # Custom properties
  speed: 5,
  health: 100,
  dead: false
}
```

### Tracked Entities (with automatic metadata)

```ruby
args.state.new_entity(:enemy) do |e|
  e.x = 100
  e.y = 200
  e.w = 40
  e.h = 40
  e.path = 'sprites/enemy.png'
end
# Adds: entity_id, created_at, created_at_elapsed
```

### Class-Based Entities (for 1000+ entities)

```ruby
class Enemy
  attr_sprite  # Enables x, y, w, h, path, etc.

  def initialize(x, y)
    @x, @y = x, y
    @w, @h = 40, 40
    @path = 'sprites/enemy.png'
    @speed = 5
  end

  def update
    @x += @speed
  end
end
```

## Spawning Patterns

### Factory Methods

```ruby
def spawn_enemy(args)
  size = 40
  {
    x: rand(args.grid.w - size),
    y: rand(args.grid.h - size),
    w: size,
    h: size,
    path: 'sprites/enemy.png',
    speed: rand(3) + 1,
    dead: false
  }
end

# Usage
args.state.enemies << spawn_enemy(args)
```

### Random Positioning with Gutters

Prevent entities from spawning partially off-screen:

```ruby
def spawn_in_bounds(args)
  size = 64
  {
    # Gutter formula: rand(max - size * 2) + size
    x: rand(args.grid.w - size * 2) + size,
    y: rand(args.grid.h - size * 2) + size,
    w: size,
    h: size
  }
end
```

**Formula breakdown:**
- `args.grid.h - size * 2` = available height (subtract top + bottom gutters)
- `rand(available)` = random position in safe zone
- `+ size` = offset for bottom/left gutter

### Spawn in Specific Region

```ruby
# Right 40% of screen
x: rand(args.grid.w * 0.4) + args.grid.w * 0.6

# Top half with padding
y: rand(args.grid.h / 2 - 50) + args.grid.h / 2 + 25
```

### Batch Spawning

```ruby
def spawn_wave(args, count)
  count.times.map { spawn_enemy(args) }
end

args.state.enemies += spawn_wave(args, 10)
```

## Collision Detection

### Basic Rectangle Collision

```ruby
# Instance method
if player.intersect_rect?(enemy)
  handle_collision
end

# Module method
if args.geometry.intersect_rect?(player, enemy)
  handle_collision
end

# With tolerance (default 0.1)
if player.intersect_rect?(enemy, 0.5)
  handle_collision
end
```

### Find First Collision

```ruby
# Returns first intersecting entity or nil
hit = args.geometry.find_intersect_rect(bullet, args.state.enemies)
if hit
  hit.dead = true
end
```

### Find All Collisions

```ruby
# Returns array (empty if no collisions)
hits = args.geometry.find_all_intersect_rect(explosion, args.state.enemies)
hits.each { |enemy| enemy.health -= 50 }
```

### Many-to-Many Collision

```ruby
# Iterate through all collision pairs
args.geometry.each_intersect_rect(bullets, enemies) do |bullet, enemy|
  bullet.dead = true
  enemy.health -= bullet.damage
end
```

### Nested Loop Pattern

```ruby
args.state.bullets.each do |bullet|
  args.state.enemies.each do |enemy|
    if args.geometry.intersect_rect?(bullet, enemy)
      bullet.dead = true
      enemy.dead = true
    end
  end
end
```

### Quad Trees (100+ entities)

```ruby
# Create once for static/semi-static entities
args.state.quad_tree ||= args.geometry.quad_tree_create(args.state.terrain)

# Fast collision lookup
hit = args.geometry.find_intersect_rect_quad_tree(
  args.state.player,
  args.state.quad_tree
)
```

## Entity Lifecycle

### Two-Phase Removal Pattern

**Phase 1:** Mark entities as dead during update loops:

```ruby
args.state.bullets.each do |bullet|
  bullet.x += bullet.speed

  # Mark off-screen bullets
  if bullet.x > args.grid.w
    bullet.dead = true
    next  # Skip further processing
  end

  # Mark on collision
  args.state.enemies.each do |enemy|
    if args.geometry.intersect_rect?(bullet, enemy)
      bullet.dead = true
      enemy.dead = true
    end
  end
end
```

**Phase 2:** Reject dead entities after all processing:

```ruby
args.state.bullets.reject! { |b| b.dead }
args.state.enemies.reject! { |e| e.dead }
```

### Off-Screen Removal

```ruby
# Remove bullets past screen edge
args.state.bullets.reject! { |b| b.x > args.grid.w }

# Remove any entity outside bounds
args.state.entities.reject! do |e|
  e.x < -100 || e.x > 1380 || e.y < -100 || e.y > 820
end
```

### Age-Based Removal

```ruby
# Mark particles after certain age
args.state.particles.each do |p|
  p.age ||= 0
  p.age += 1
  p.dead = true if p.age > 60  # 1 second at 60 FPS
end
args.state.particles.reject!(&:dead)
```

## Collection Rendering

### Basic Rendering

```ruby
# Render entire collection
args.outputs.sprites << args.state.enemies

# DragonRuby flattens nested arrays automatically
args.outputs.sprites << [
  args.state.player,
  args.state.enemies,
  args.state.bullets
]
```

### Conditional Rendering

```ruby
# Only render alive entities
args.outputs.sprites << args.state.enemies.select(&:alive)

# Simple frustum culling
args.outputs.sprites << args.state.entities.select do |e|
  e.x.between?(-100, 1380) && e.y.between?(-100, 820)
end
```

## Geometry API Reference

| Method | Returns | Use Case |
|--------|---------|----------|
| `intersect_rect?(other)` | `true/false` | Basic collision check |
| `inside_rect?(other)` | `true/false` | Fully contained check |
| `find_intersect_rect(rect, coll)` | `rect/nil` | First collision |
| `find_all_intersect_rect(rect, coll)` | `Array` | All collisions |
| `each_intersect_rect(c1, c2) {}` | — | Iterate pairs |
| `quad_tree_create(coll)` | `quad_tree` | Build spatial index |
| `find_intersect_rect_quad_tree(r, tree)` | `rect/nil` | Fast lookup |
| `distance(p1, p2)` | `Float` | Distance between points |
| `angle_to(from, to)` | `Float` | Angle in degrees |

## Performance Tiers

| Entity Count | Recommended Approach |
|--------------|---------------------|
| < 100 | Hash-based entities |
| 100-500 | `args.state.new_entity` or classes |
| 500-1000 | Classes with `attr_sprite` |
| 1000+ | `static_sprites` + `draw_override` |

For collision detection:

| Entity Count | Recommended Approach |
|--------------|---------------------|
| < 100 | `intersect_rect?` / nested loops |
| 100-500 | `find_intersect_rect` / `each_intersect_rect` |
| 500+ | Quad trees |

## Common Antipatterns

### ❌ Modifying Collection While Iterating

```ruby
# BUG: Modifying during iteration
args.state.enemies.each do |enemy|
  if enemy.health <= 0
    args.state.enemies.delete(enemy)  # WRONG
  end
end
```

**Fix:** Mark and reject in separate phases.

### ❌ Keeping Dead Entities

```ruby
# Memory leak: dead entities accumulate
args.state.bullets.each do |b|
  b.x += b.speed
  # Never removed when off-screen
end
```

**Fix:** Always reject off-screen and dead entities.

### ❌ Using Arrays Instead of Hashes

```ruby
# Unreadable: what is [0]?
bullet = [x, y, w, h, 'sprites/bullet.png']
bullet[0] += speed
```

**Fix:** Use hashes with named properties.

### ❌ Forgetting Gutters

```ruby
# Can spawn partially off-screen
y: rand(args.grid.h)
```

**Fix:** Use `rand(max - size * 2) + size` formula.

### ❌ Collision After Death

```ruby
args.state.bullets.each do |bullet|
  bullet.x += bullet.speed
  # No check if already dead - wastes cycles
  args.state.enemies.each do |enemy|
    if args.geometry.intersect_rect?(bullet, enemy)
      bullet.dead = true
      enemy.dead = true
    end
  end
end
```

**Fix:** Use `next if bullet.dead` after marking.

## Complete Entity System

```ruby
def tick(args)
  defaults(args)
  update_entities(args)
  check_collisions(args)
  cleanup_entities(args)
  render_entities(args)
end

def defaults(args)
  args.state.player ||= { x: 100, y: 360, w: 40, h: 40, path: 'sprites/player.png' }
  args.state.enemies ||= []
  args.state.bullets ||= []
end

def update_entities(args)
  args.state.bullets.each do |b|
    b.x += 10
    b.dead = true if b.x > args.grid.w
  end

  args.state.enemies.each do |e|
    e.x -= e.speed
    e.dead = true if e.x < -e.w
  end
end

def check_collisions(args)
  args.state.bullets.each do |bullet|
    next if bullet.dead

    args.state.enemies.each do |enemy|
      next if enemy.dead

      if args.geometry.intersect_rect?(bullet, enemy)
        bullet.dead = true
        enemy.dead = true
        args.state.score ||= 0
        args.state.score += 100
      end
    end
  end
end

def cleanup_entities(args)
  args.state.bullets.reject!(&:dead)
  args.state.enemies.reject!(&:dead)
end

def render_entities(args)
  args.outputs.sprites << [
    args.state.player,
    args.state.enemies,
    args.state.bullets
  ]
end
```

## Decision Tree

**How should I store game objects?**
```
Need to track many objects of same type?
├─ Yes → Use args.state arrays with ||= initialization
│        See: examples/entities/entity_storage.rb
└─ No (single object like player) → Use args.state.player directly
```

**Which entity representation?**
```
How many entities?
├─ < 100 → Hash-based entities (simplest)
│          See: examples/entities/entity_storage.rb
├─ 100-1000 → args.state.new_entity (tracking) or classes
│             See: examples/entities/factory_methods.rb
└─ 1000+ → Classes with attr_sprite
```

**How should I spawn entities?**
```
Creating entities in multiple places?
├─ Yes → Use factory methods (spawn_enemy, spawn_bullet)
│        See: examples/entities/factory_methods.rb
└─ No → Inline creation is fine

Need random positions?
├─ Yes, anywhere on screen → Use gutter formula
│  See: examples/entities/random_spawning.rb
└─ Yes, specific region → Calculate bounds manually
```

**Which collision method?**
```
How many entities to check?
├─ Single entity vs single entity → intersect_rect?
│  See: examples/entities/collision_detection.rb
├─ Single entity vs collection (find first) → find_intersect_rect
├─ Single entity vs collection (find all) → find_all_intersect_rect
├─ Collection vs collection → each_intersect_rect or nested loops
│  See: examples/entities/entity_lifecycle.rb
└─ 100+ static entities → quad_tree
```

**How should I remove entities?**
```
When to remove?
├─ On collision → Mark dead, reject after loop
│  See: examples/entities/entity_lifecycle.rb
├─ Off-screen → Check bounds, mark dead
├─ After time → Track age, mark when expired
└─ All at once → Use reject! after all updates
```

## Examples

| File | Demonstrates |
|------|--------------|
| `examples/entities/entity_storage.rb` | Arrays in args.state, ||= initialization |
| `examples/entities/factory_methods.rb` | spawn_* patterns, new_entity |
| `examples/entities/collision_detection.rb` | intersect_rect?, find methods |
| `examples/entities/entity_lifecycle.rb` | Create → update → mark → reject |
| `examples/entities/random_spawning.rb` | Gutter formula, bounded positions |
