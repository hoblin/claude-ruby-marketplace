# Layout System

RatatuiRuby's constraint-based layout divides screen areas dynamically, adapting to terminal resizing for responsive TUI designs.

## Core Components

- **Layout** - Divides areas using constraints
- **Constraint** - Sizing rules for sections
- **Rect** - Rectangular screen areas

## Layout Split

Primary method for dividing areas:

```ruby
# Using TUI factory (recommended)
top, bottom = tui.split(
  frame.area,
  direction: :vertical,
  constraints: [
    tui.constraint_percentage(75),
    tui.constraint_percentage(25)
  ]
)

# Full signature
tui.layout_split(
  area,                    # Rect to split
  direction: :vertical,    # :vertical or :horizontal
  constraints: [],         # Array of constraints
  flex: :legacy            # Flex algorithm
)
```

**Returns:** `Array<Rect>` of computed sections.

## Direction

### Vertical (Top to Bottom)

```ruby
header, content, footer = tui.split(
  frame.area,
  direction: :vertical,
  constraints: [
    tui.constraint_length(3),      # Top header
    tui.constraint_fill(1),        # Expanding content
    tui.constraint_length(1)       # Bottom status
  ]
)
```

### Horizontal (Left to Right)

```ruby
sidebar, main = tui.split(
  frame.area,
  direction: :horizontal,
  constraints: [
    tui.constraint_length(20),     # Fixed sidebar
    tui.constraint_min(0)          # Expanding main
  ]
)
```

## Constraints

### Length (Fixed Size)

Exact, immutable size:

```ruby
tui.constraint_length(10)
tui.fixed(10)              # CSS-style alias

# Always 10 cells regardless of available space
```

**Use:** Fixed headers, footers, sidebars.

### Percentage

Proportional share of available space:

```ruby
tui.constraint_percentage(50)
tui.percent(50)            # CSS-style alias

# 50% of available space
```

**Use:** Proportional layouts, split screens.

### Min (Minimum)

At least N cells, grows if space permits:

```ruby
tui.constraint_min(10)

# Enforces minimum, can expand beyond
```

**Use:** Sections needing minimum space but can expand.

### Max (Maximum)

Upper bound on section size:

```ruby
tui.constraint_max(20)

# Never exceeds 20 cells
```

**Use:** Limiting size while allowing responsiveness.

### Ratio

Exact fractional allocation:

```ruby
tui.constraint_ratio(1, 3)         # One-third

# Golden ratio
constraints = [
  tui.constraint_ratio(1, 3),
  tui.constraint_ratio(2, 3)
]
```

**Use:** Mathematical proportions, aspect ratios.

### Fill (Flexible)

Distributes remaining space after satisfying strict rules:

```ruby
tui.constraint_fill(1)
tui.flex(2)                        # Flexbox alias
tui.fr(1)                          # CSS Grid fraction

# Weighted distribution
constraints = [
  tui.constraint_length(20),       # Fixed 20
  tui.constraint_fill(1),          # Gets 1x remaining
  tui.constraint_fill(2)           # Gets 2x remaining
]
```

**Use:** Flexible sections that grow.

### Batch Creation

```ruby
Constraint.from_lengths([10, 20, 10])
Constraint.from_percentages([25, 50, 25])
Constraint.from_mins([5, 10, 5])
Constraint.from_maxes([20, 30, 40])
Constraint.from_ratios([[1, 4], [2, 4], [1, 4]])
Constraint.from_fills([1, 2, 1])
```

### Polymorphic Factory

```ruby
tui.constraint(:length, 10)
tui.constraint(:percentage, 50)
tui.constraint(:min, 10)
tui.constraint(:max, 20)
tui.constraint(:fill, 1)
tui.constraint(:ratio, 1, 3)
```

## Flex Options

Controls extra space distribution:

| Option | Behavior |
|--------|----------|
| `:legacy` | Default |
| `:start` | Pack at beginning |
| `:end` | Pack at end |
| `:center` | Center sections |
| `:space_between` | Space between sections |
| `:space_around` | Space around sections |
| `:space_evenly` | Evenly distribute all space |

```ruby
tui.split(
  frame.area,
  direction: :vertical,
  constraints: [tui.constraint_length(10)],
  flex: :center
)
```

## Rect Class

Encapsulates terminal grid geometry.

### Constructor

```ruby
rect = tui.rect(x: 10, y: 5, width: 50, height: 15)
```

### Properties

```ruby
rect.x       # Column index of top-left
rect.y       # Row index of top-left
rect.width   # Width in characters
rect.height  # Height in rows
```

### Geometry Queries

```ruby
rect.area                  # width × height
rect.empty?                # True if width or height is zero
rect.contains?(15, 8)      # Point-in-rectangle hit testing
```

### Boundary Accessors

```ruby
rect.left                  # Left edge x
rect.right                 # Right edge x
rect.top                   # Top edge y
rect.bottom                # Bottom edge y
```

### Transformations

```ruby
moved = rect.offset(10, 5)         # Translate
resized = rect.resize(new_size)    # Change dimensions
inner = rect.inner(margin)         # Shrink by margin
outer = rect.outer(margin)         # Expand by margin
clamped = rect.clamp(other_rect)   # Constrain to bounds
```

### Centering

```ruby
screen = frame.area

# Center both axes
dialog = screen.centered(
  tui.constraint_length(40),
  tui.constraint_length(20)
)

# Single axis
centered_h = screen.centered_horizontally(tui.constraint_length(40))
centered_v = screen.centered_vertically(tui.constraint_length(20))
```

### Set Operations

```ruby
overlap = rect1.intersection(rect2)    # Returns nil if disjoint
rect1.intersects?(rect2)               # Check overlap
bounding = rect1.union(rect2)          # Smallest enclosing box
```

### Iteration

```ruby
rect.rows { |row_rect| }               # Each row (height=1)
rect.columns { |col_rect| }            # Each column (width=1)
rect.positions { |x, y| }              # All cells, row-major

# Destructuring
x, y, width, height = rect
```

## Nested Layouts

```ruby
# Level 1: sidebar and content
sidebar, content = tui.split(
  frame.area,
  direction: :horizontal,
  constraints: [
    tui.constraint_length(20),
    tui.constraint_min(0)
  ]
)

# Level 2: header and body within content
header, body = tui.split(
  content,
  direction: :vertical,
  constraints: [
    tui.constraint_length(3),
    tui.constraint_fill(1)
  ]
)

# Level 3: columns within body
left, right = tui.split(
  body,
  direction: :horizontal,
  constraints: [
    tui.constraint_percentage(50),
    tui.constraint_percentage(50)
  ]
)

# Render to computed areas
frame.render_widget(sidebar_widget, sidebar)
frame.render_widget(header_widget, header)
frame.render_widget(left_widget, left)
frame.render_widget(right_widget, right)
```

## Common Patterns

### Responsive Dashboard

```ruby
header, main, footer = tui.split(
  frame.area,
  direction: :vertical,
  constraints: [
    tui.constraint_length(1),       # Fixed header
    tui.constraint_fill(1),         # Expanding main
    tui.constraint_length(1)        # Fixed status
  ]
)
```

### Three-Column Layout

```ruby
sidebar, content, tools = tui.split(
  frame.area,
  direction: :horizontal,
  constraints: [
    tui.constraint_percentage(20),
    tui.constraint_percentage(60),
    tui.constraint_percentage(20)
  ]
)
```

### Centered Modal Dialog

```ruby
dialog = frame.area.centered(
  tui.constraint_length(60),        # 60 chars wide
  tui.constraint_length(20)         # 20 rows tall
)

frame.render_widget(modal_widget, dialog)
```

### Even Distribution

```ruby
buttons = tui.split(
  control_area,
  direction: :horizontal,
  constraints: Constraint.from_fills([1, 1, 1, 1]),
  flex: :space_evenly
)
```

### Cached Layout for Mouse Handling

Compute during rendering, reuse for event handling:

```ruby
class App
  attr_accessor :button_area

  def draw(frame, tui)
    @button_area = frame.area.centered(
      tui.constraint_length(20),
      tui.constraint_length(3)
    )
    frame.render_widget(button, @button_area)
  end

  def handle_event(event)
    if event.mouse? && @button_area.contains?(event.x, event.y)
      handle_button_click
    end
  end
end
```

## Factory Methods Summary

| Factory | Purpose |
|---------|---------|
| `tui.split(area, direction:, constraints:)` | Split area |
| `tui.rect(x:, y:, width:, height:)` | Create Rect |
| `tui.constraint_length(n)` / `tui.fixed(n)` | Fixed size |
| `tui.constraint_percentage(n)` / `tui.percent(n)` | Proportional |
| `tui.constraint_min(n)` | Minimum |
| `tui.constraint_max(n)` | Maximum |
| `tui.constraint_ratio(n, d)` | Fractional |
| `tui.constraint_fill(n)` / `tui.flex(n)` / `tui.fr(n)` | Flexible |
| `tui.constraint(type, ...)` | Polymorphic |

## Best Practices

1. **Use TUI factories** for cleaner code
2. **Compute layouts fresh each frame** for responsive resizing
3. **Cache Rects** when needed for mouse hit testing
4. **Start with vertical splits** for top-level structure
5. **Use Fill** for flexible sections that should grow
6. **Use Length** for fixed UI elements
7. **Use Percentage/Ratio** for proportional layouts
8. **Leverage Rect.centered()** for common positioning
9. **Apply margins via Block borders** rather than layout level
10. **Keep layouts immutable** - create new rather than modify
