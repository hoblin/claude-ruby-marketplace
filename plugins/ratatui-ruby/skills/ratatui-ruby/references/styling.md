# Styling System

RatatuiRuby provides colors, modifiers, and hierarchical text composition for visually appealing terminal interfaces.

## Style Class

### Properties

```ruby
Style::Style.new(
  fg: nil,              # Foreground color
  bg: nil,              # Background color
  underline_color: nil, # Underline color
  modifiers: [],        # Text effects to apply
  remove_modifiers: []  # Effects to remove from inherited styles
)
```

### Creating Styles

```ruby
# Full constructor
Style::Style.new(fg: :red, bg: :white, modifiers: [:bold])

# Convenience method
Style::Style.with(fg: "#ff00ff")

# Empty style
Style::Style.default
```

### Factory Method

```ruby
tui.style(fg: :red, modifiers: [:bold])
```

## Color Options

### Named Colors (Symbols)

**Standard:** `:black`, `:red`, `:green`, `:yellow`, `:blue`, `:magenta`, `:cyan`, `:white`

**Light variants:** `:light_red`, `:light_green`, `:light_yellow`, `:light_blue`, `:light_magenta`, `:light_cyan`

**Gray variants:** `:gray`, `:dark_gray`

**Special:** `:reset` — Terminal default

```ruby
tui.style(fg: :cyan, bg: :black)
```

### Indexed Colors (0-255)

Xterm 256-color palette:

```ruby
tui.style(fg: 196)   # Bright red
tui.style(bg: 240)   # Dark gray
```

### True Color (Hex)

24-bit color via `"#RRGGBB"`:

```ruby
tui.style(fg: "#ff00ff")  # Magenta
tui.style(bg: "#1a1a1a")  # Near-black
```

## Color Factory Methods

Convert colors from design tools:

### Hex Conversion

```ruby
Color.from_u32(0xFF0000)  # => "#ff0000"
Color.hex(0x00FF00)       # => "#00ff00"
```

### HSL Conversion

```ruby
Color.from_hsl(0, 100, 50)    # Hue 0-360, Sat 0-100, Light 0-100
Color.hsl(120, 100, 50)       # => "#00ff00" (green)
```

### HSLuv (Perceptually Uniform)

Equal lightness values appear equally bright:

```ruby
Color.from_hsluv(12.18, 100, 53.2)   # => "#ff0000"
Color.hsluv(-94.13, 100, 32.3)       # => "#0000ff"
```

## Text Modifiers

```ruby
tui.style(modifiers: [:bold, :underlined])
```

| Modifier | Effect |
|----------|--------|
| `:bold` | Bold weight |
| `:dim` | Reduced brightness |
| `:italic` | Italicized |
| `:underlined` | Underline |
| `:slow_blink` | Slow blink |
| `:rapid_blink` | Fast blink |
| `:reversed` | Swap fg/bg |
| `:hidden` | Concealed text |
| `:crossed_out` | Line-through |

## Text Composition

### Span (Styled Fragment)

```ruby
# Create span
tui.text_span(content: "Bold text", style: tui.style(modifiers: [:bold]))

# Raw/unstyled
Text::Span.raw("Plain text")

# Styled shorthand
Text::Span.styled("Quick", style)
```

**Methods:**
- `width()` — Unicode-aware display width
- `patch_style(style)` — Merge styles
- `reset_style()` — Remove styling

### Line (Span Collection)

```ruby
tui.text_line(
  spans: [span1, span2, span3],
  alignment: :center,
  style: base_style
)

# From string
Text::Line.from_string("Hello")
```

**Alignment methods:**
```ruby
line.left_aligned
line.centered
line.right_aligned
```

**Methods:**
- `push_span(span)` — Add span (returns new Line)
- `patch_style(style)` — Merge across all spans
- `width()` — Total display width

### Text Width Calculation

Unicode-aware measurement:

```ruby
tui.text_width("Hello")    # => 5
tui.text_width("你好")     # => 4 (CJK = 2 cells each)
tui.text_width("Hello 👍") # => 8 (emoji = 2 cells)
```

## Hierarchical Styling

### Widget-Level

```ruby
tui.block(
  title: "Title",
  title_style: tui.style(fg: :cyan, modifiers: [:bold]),
  border_style: tui.style(fg: :magenta),
  style: tui.style(bg: :black)
)
```

### Line-Level

Affects all contained spans:

```ruby
tui.text_line(
  spans: [span1, span2],
  style: tui.style(fg: :blue)
)
```

### Span-Level

Overrides line styles:

```ruby
tui.text_span(
  content: "Special",
  style: tui.style(fg: :red, modifiers: [:underlined], underline_color: :red)
)
```

### Style Merging

`patch_style()` merges without replacing:

```ruby
base = Style::Style.with(fg: :blue)
result = span.patch_style(Style::Style.with(modifiers: [:bold]))
# fg remains :blue, modifiers adds [:bold]
```

## Hash-Based Syntax

Widgets accept styles as hashes:

```ruby
tui.paragraph(
  text: "Content",
  style: {fg: "green", modifiers: [:bold]},
  block: tui.block(border_style: {fg: "cyan"})
)
```

## Complete Example

```ruby
# Create styled spans
normal = tui.text_span(content: "Normal, ")
bold = tui.text_span(
  content: "Bold",
  style: tui.style(modifiers: [:bold])
)
colored = tui.text_span(
  content: " and colored",
  style: tui.style(fg: :green, modifiers: [:italic])
)

# Compose into centered line
line = tui.text_line(spans: [normal, bold, colored]).centered

# Use in widget
tui.paragraph(
  text: [line],
  block: tui.block(
    title: "Styled Text",
    title_style: tui.style(fg: :cyan, modifiers: [:bold]),
    border_style: tui.style(fg: :magenta),
    borders: [:all]
  )
)
```

## Quick Reference

| Factory | Creates |
|---------|---------|
| `tui.style(fg:, bg:, modifiers:)` | Style object |
| `tui.text_span(content:, style:)` | Styled text fragment |
| `tui.text_line(spans:, alignment:)` | Line of spans |
| `tui.text_width(string)` | Display width |
| `Color.hex(0xRRGGBB)` | Hex color string |
| `Color.hsl(h, s, l)` | HSL to hex |
| `Color.hsluv(h, s, l)` | Perceptually uniform HSL |
