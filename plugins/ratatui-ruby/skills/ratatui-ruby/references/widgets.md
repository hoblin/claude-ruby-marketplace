# Widgets

RatatuiRuby provides 20+ widgets for building terminal interfaces. This reference covers the complete widget catalog, composition patterns, and state management.

## Widget Architecture

Widgets follow structural typing: any object implementing `render(area)` functions as a widget. The method receives a `Rect` and returns drawing commands.

### Stateless vs Stateful

**Stateless widgets** render based on initialization parameters:
- Paragraph, Block, Gauge, LineGauge, BarChart, Sparkline, Tabs, Calendar, Canvas

**Stateful widgets** require external state objects:
- List → `ListState`
- Table → `TableState`

```ruby
# Stateless
frame.render_widget(tui.paragraph(text: "Hello"), area)

# Stateful
@list_state = tui.list_state(0)
frame.render_stateful_widget(tui.list(items:), area, @list_state)
```

## Block (Universal Container)

Foundation for composition. Provides borders, titles, and padding.

```ruby
Block.new(
  title: nil,              # Main title
  titles: [],              # Additional titles [{content:, position:, alignment:}]
  title_alignment: nil,    # :left, :center, :right (nil = :left)
  title_style: nil,
  borders: [:all],         # :top, :bottom, :left, :right, :all
  border_style: nil,
  border_type: nil,        # :plain, :rounded, :double, :thick, :quadrant
  border_set: nil,         # Custom characters
  style: nil,              # Content area style
  padding: 0,              # Integer or [left, right, top, bottom]
  children: []             # Child widgets to render inside
)
```

### Border Options

```ruby
Block.new(borders: [:top, :bottom])      # Horizontal only
Block.new(borders: [:left, :right])      # Vertical only
Block.new(borders: [:all])               # All sides

# Border types
Block.new(border_type: :rounded)         # Rounded corners
Block.new(border_type: :double)          # Double lines
```

### Inner Area

Calculate content area after borders/padding:

```ruby
block = Block.new(borders: [:all], padding: 1)
inner_rect = block.inner(outer_rect)
```

### Multiple Titles

```ruby
tui.block(
  title: "Main",
  titles: [
    {content: "Help: ?", position: :bottom, alignment: :right},
    {content: "v1.0", position: :top, alignment: :right}
  ],
  borders: [:all]
)
```

## Text Display

### Paragraph

Text display with wrapping, alignment, and scrolling.

```ruby
Paragraph.new(
  text:,                   # String or Text::Line array
  style: nil,
  block: nil,
  wrap: false,             # Enable wrapping
  alignment: :left,        # :left, :center, :right
  scroll: [0, 0]           # [vertical, horizontal] offsets
)
```

**Methods:**
- `line_count(width)` — Lines needed at width
- `line_width()` — Minimum width without wrapping

```ruby
tui.paragraph(
  text: "Long content...",
  wrap: true,
  scroll: [@scroll_y, 0],
  block: tui.block(title: "Output", borders: [:all])
)
```

## List Widgets

### List

Selectable item list with automatic scrolling.

```ruby
List.new(
  items: [],                              # Strings, Spans, Lines, or ListItems
  selected_index: nil,                    # Current selection
  offset: nil,                            # Manual scroll (nil = auto)
  style: nil,
  highlight_style: nil,                   # Selected item style
  highlight_symbol: "> ",                 # Selection prefix
  repeat_highlight_symbol: false,
  highlight_spacing: :when_selected,      # :always, :when_selected, :never
  direction: :top_to_bottom,              # :top_to_bottom, :bottom_to_top
  scroll_padding: nil,                    # Margin around selection
  block: nil
)
```

**Methods:**
- `empty?()` — No items
- `len()` / `length()` / `size()` — Item count
- `selected?()` — Item selected
- `selected_item()` — Current item or nil

**Auto-scroll vs Manual:**
- `offset: nil` — Auto-scroll to keep selection visible
- `offset: N` — Manual scroll (for log viewers)

### ListState

External state for complex applications:

```ruby
@list_state = tui.list_state(0)  # positional: initial selected index

# In draw
frame.render_stateful_widget(list, area, @list_state)

# Navigation
@list_state.select_next
@list_state.select_previous
@list_state.select_first
@list_state.select_last
```

## Table

Structured data with row/column selection.

```ruby
Table.new(
  header: nil,                            # Array of strings/Text/Paragraphs
  rows: [],                               # 2D array of cells
  widths: [],                             # Constraints or Integers
  row_highlight_style: nil,
  highlight_symbol: "> ",
  highlight_spacing: :when_selected,
  column_highlight_style: nil,
  cell_highlight_style: nil,              # When row AND column selected
  selected_row: nil,
  selected_column: nil,
  offset: nil,
  block: nil,
  footer: nil,
  flex: :legacy,                          # :start, :center, :end, :space_between
  style: nil,
  column_spacing: 1
)
```

**Methods:**
- `row_selected?()` — Row selected
- `column_selected?()` — Column selected
- `cell_selected?()` — Both selected
- `empty?()` — No rows

**Cell Types:** String, Text::Span, Text::Line, Paragraph, or Cell objects.

```ruby
tui.table(
  header: ["Name", "Status", "CPU"],
  rows: [
    ["web-1", "Running", "45%"],
    ["db-1", "Running", "22%"]
  ],
  widths: [
    tui.constraint(:length, 20),
    tui.constraint(:length, 10),
    tui.constraint(:min, 5)
  ],
  block: tui.block(title: "Services", borders: [:all])
)
```

## Progress Widgets

### Gauge

Progress bar with percentage/ratio display.

```ruby
Gauge.new(
  ratio: nil,              # Float 0.0-1.0 (exclusive with percent)
  percent: nil,            # Integer 0-100
  label: nil,              # Overlay text
  style: nil,              # Background
  gauge_style: nil,        # Filled bar
  block: nil,
  use_unicode: true
)
```

**Methods:**
- `filled?()` — ratio > 0
- `complete?()` — ratio >= 1.0
- `percent()` — Integer percentage

```ruby
tui.gauge(
  ratio: 0.65,
  label: "Downloading...",
  gauge_style: {fg: "green"},
  block: tui.block(title: "Progress", borders: [:all])
)
```

### LineGauge

Compact single-line progress.

```ruby
LineGauge.new(
  ratio: nil,              # Float (0.0 - 1.0)
  percent: nil,            # Integer (0 - 100), alternative to ratio
  label: nil,              # Overlay text
  style: nil,
  filled_style: nil,
  unfilled_style: nil,
  block: nil,
  filled_symbol: "█",
  unfilled_symbol: "░"
)
```

## Chart Widgets

### Chart

Cartesian plotting with datasets and axes.

```ruby
Chart.new(
  datasets: [],            # Array of Dataset objects
  x_axis: nil,             # Axis configuration
  y_axis: nil,
  legend_position: nil,    # Corner or nil to hide
  marker: :braille,        # :braille, :dot, :block, :bar
  style: nil,
  block: nil
)
```

### BarChart

Categorical data as bars.

```ruby
BarChart.new(
  data:,                   # Hash, Array, or BarGroup list
  bar_width: 3,
  bar_gap: 1,
  group_gap: 0,
  max: nil,                # Y-axis max (auto if nil)
  style: nil,
  block: nil,
  direction: :vertical,    # :vertical, :horizontal
  label_style: nil,
  value_style: nil,
  bar_set: nil
)
```

**Data Formats:**

```ruby
# Hash
{"Apples" => 10, "Oranges" => 15}

# Array of tuples
[["Mon", 20], ["Tue", 30]]

# With styling
[["Label", 42, {fg: "red"}]]

# Grouped
[BarGroup.new(label: "Q1", bars: [Bar.new(10), Bar.new(15)])]
```

### Sparkline

Compact trend visualization.

```ruby
Sparkline.new(
  data:,                           # Array of Integers or nil
  max: nil,
  style: nil,
  block: nil,
  direction: :left_to_right,
  absent_value_symbol: nil,        # For nil values
  absent_value_style: nil,
  bar_set: nil
)
```

`nil` in data marks absent values (rendered differently from `0`).

## Navigation Widgets

### Tabs

Tab bar for multi-view navigation.

```ruby
Tabs.new(
  titles: [],              # Tab titles
  selected_index: 0,
  block: nil,
  divider: nil,            # Separator between tabs
  highlight_style: nil,    # Selected tab
  style: nil,
  padding_left: 0,
  padding_right: 0
)
```

**Methods:**
- `width()` — Total width including dividers

```ruby
tui.tabs(
  titles: ["General", "Network", "Display"],
  selected_index: @tab_index,
  highlight_style: {fg: "yellow", bold: true}
)
```

### Scrollbar

Scroll position indicator. Stateless widget that takes position directly.

```ruby
Scrollbar.new(
  content_length:,         # Total scrollable content length (required)
  position:,               # Current scroll position (required)
  orientation: :vertical,  # :vertical, :horizontal, :vertical_left, :vertical_right, :horizontal_top, :horizontal_bottom
  thumb_symbol: "█",
  thumb_style: nil,
  track_symbol: nil,
  track_style: nil,
  begin_symbol: nil,       # Arrow at start
  begin_style: nil,
  end_symbol: nil,         # Arrow at end
  end_style: nil,
  style: nil,
  block: nil
)
```

## Layout Widgets

### Center

Centers child widget.

```ruby
Center.new(
  child:,                  # Widget to center
  width_percent: 100,
  height_percent: 100
)
```

### Clear

Clears area (fills with spaces).

## Canvas & Drawing

### Canvas

High-resolution drawing surface using Braille characters.

```ruby
Canvas.new(
  shapes: [],              # Array of Shape objects
  x_bounds: [0.0, 100.0],  # [min, max] X range
  y_bounds: [0.0, 100.0],  # [min, max] Y range
  marker: :braille,        # :braille, :half_block, :dot, :block, :bar
  block: nil,
  background_color: nil
)
```

**Shapes:** Point, Line, Circle, Rectangle, Map, Label

**Coordinate System:** Float-based, independent of terminal cells.

**Methods:**
- `get_point(x, y)` — Convert to normalized grid coordinates [0.0-1.0]

```ruby
tui.canvas(
  shapes: [
    tui.shape_line(x1: 0, y1: 0, x2: 100, y2: 100, color: "red"),
    tui.shape_point(x: 50, y: 50)  # Point only has x: and y:
  ],
  x_bounds: [0.0, 100.0],
  y_bounds: [0.0, 100.0],
  marker: :braille
)
```

### Calendar

Monthly calendar display.

```ruby
Calendar.new(
  year:,                      # Integer year (required)
  month:,                     # Integer month 1-12 (required)
  events: {},                 # Hash<Date, Style> to highlight
  default_style: nil,         # Style for days
  header_style: nil,          # Style for month name header
  show_month_header: false,
  show_weekdays_header: true,
  show_surrounding: nil,      # Style or nil for adjacent month days
  block: nil
)
```

## Composition Patterns

### Block Wrapping

Most widgets accept `block:` parameter:

```ruby
tui.list(
  items: ["A", "B", "C"],
  block: tui.block(
    title: "Menu",
    borders: [:all],
    border_type: :rounded
  )
)
```

### Coordinate Offsetting (Custom Widgets)

Always add area origin to drawing coordinates:

```ruby
def render(area)
  # CORRECT
  Draw.string(area.x + 5, area.y + 2, "Text", style)

  # WRONG - assumes origin at (0,0)
  Draw.string(5, 2, "Text", style)
end
```

### Bounds Checking

Validate dimensions before rendering:

```ruby
def render(area)
  return [] if area.width < 10 || area.height < 3
  # ... render
end
```

## Factory Methods Quick Reference

| Widget | Factory | Key Parameters |
|--------|---------|----------------|
| Paragraph | `tui.paragraph()` | `text:`, `wrap:`, `alignment:` |
| Block | `tui.block()` | `title:`, `borders:`, `border_type:` |
| List | `tui.list()` | `items:`, `highlight_style:` |
| Table | `tui.table()` | `header:`, `rows:`, `widths:` |
| Gauge | `tui.gauge()` | `ratio:` or `percent:`, `label:` |
| LineGauge | `tui.line_gauge()` | `data:`, `max:` |
| BarChart | `tui.bar_chart()` | `data:`, `direction:` |
| Sparkline | `tui.sparkline()` | `data:`, `max:` |
| Chart | `tui.chart()` | `datasets:`, `x_axis:`, `y_axis:` |
| Tabs | `tui.tabs()` | `titles:`, `selected_index:` |
| Canvas | `tui.canvas()` | `shapes:`, `x_bounds:`, `y_bounds:` |
| Calendar | `tui.calendar()` | `date:`, `events:` |
| Scrollbar | `tui.scrollbar()` | `content_length:`, `position:`, `orientation:` |
| Center | `tui.center()` | `child:` |

## State Objects

| State | Widget | Key Methods |
|-------|--------|-------------|
| `ListState` | List | `select_next`, `select_previous`, `selected` |
| `TableState` | Table | `select_next`, `select_previous`, `select_next_column`, `select_previous_column` |
| `ScrollbarState` | (deprecated) | `position=`, `content_length` |

Create via factory methods:

```ruby
@list_state = tui.list_state(0)           # positional: initial selected index
@table_state = tui.table_state            # optional positional: selected index
@scrollbar_state = tui.scrollbar_state(100)  # positional: content_length
@scrollbar_state.position = 0             # set position via setter
```
