# Frameworks: Rooibos and Kit

RatatuiRuby ecosystem includes two architectural frameworks: **Rooibos** (MVU/functional) and **Kit** (component-based/OOP). Both build on the core rendering engine.

> **Note:** These frameworks are **separate gems**, not part of the core `ratatui_ruby` gem.

## Rooibos: Model-View-Update

Functional architecture emphasizing immutability and pure functions. Also called The Elm Architecture.

**Status:** v0.2.0 Pre-Release (ALPHA)

**Installation:** `gem install ratatui_ruby-tea` (provides `RatatuiRuby::TEA`)

**Repository:** https://git.sr.ht/~kerrick/ratatui_ruby-tea

### Core Principle

"View as a Function of State" — UI is a pure function of an immutable model. Given the same state, rendering is identical.

### Architecture Components

#### Model: Immutable State

```ruby
Model = Data.define(:text, :count, :files, :error)
```

All state lives in a single frozen object. Updates create new instances.

#### Init: Initialization

```ruby
Init = -> do
  Model.new(
    text: "Hello! Press 'q' to quit.",
    count: 0,
    files: [],
    error: nil
  )
end
```

With initial command:

```ruby
Init = -> do
  model = Model.new(text: "Loading...", files: [])
  command = Rooibos::Command.system('ls -la', :got_files)
  [model, command]
end
```

#### View: Pure Rendering

```ruby
View = -> (model, tui) do
  tui.paragraph(
    text: model.text,
    alignment: :center,
    block: tui.block(
      title: "My App",
      borders: [:all],
      border_style: {fg: "cyan"}
    )
  )
end
```

Views are pure functions — no side effects or state mutation.

#### Update: Message Handler

```ruby
Update = -> (msg, model) do
  case msg
  in [:got_files, {stdout:, status: 0}]
    [model.with(files: stdout.lines), nil]

  in [:got_files, {stderr:, status:}]
    [model.with(error: "Exit #{status}: #{stderr}"), nil]

  in {key: 'q'} | {key: 'ctrl_c'}
    Rooibos::Command.exit

  in {key: 'r'}
    [model, Rooibos::Command.system('ls -la', :got_files)]

  else
    [model, nil]
  end
end
```

Returns:
- `[new_model, command]` — State change with side effect
- `model` — No state change
- `command` — Side effect without state change

### Command System

Commands execute off the main thread, producing messages when complete.

#### Built-In Commands

```ruby
# Shell execution
Rooibos::Command.system('git status', :git_result)

# One-shot timer
Rooibos::Command.wait(5, :timeout)

# Recurring timer
Rooibos::Command.tick(1.0, :clock_tick)

# HTTP request
Rooibos::Command.http(:get, 'https://api.example.com', :got_data)

# Parallel execution
Rooibos::Command.batch([
  Rooibos::Command.system('git status', :status),
  Rooibos::Command.http(:get, 'https://api.example.com', :data)
])

# Sequential execution
Rooibos::Command.sequence([
  Rooibos::Command.system('npm install', :install_done),
  Rooibos::Command.system('npm test', :test_done)
])

# Exit application
Rooibos::Command.exit
```

### Message Handling Pattern

```ruby
def update(msg, model)
  case msg
  in [:got_files, {stdout:, status: 0}]
    files = stdout.lines.map(&:strip)
    [model.with(files:, loading: false), nil]

  in [:got_files, {stderr:, status:}]
    [model.with(error: "Failed: #{stderr}", loading: false), nil]

  in [:clock_tick]
    new_model = model.with(time: Time.now.strftime("%H:%M:%S"))
    # Re-dispatch to continue subscription
    [new_model, Rooibos::Command.tick(1.0, :clock_tick)]

  in {key: 'r'}
    [model.with(loading: true), Rooibos::Command.system('ls', :got_files)]

  else
    [model, nil]
  end
end
```

### Running Rooibos Application

```ruby
RatatuiRuby::TEA.run(
  model: Init.call,
  update: Update,
  view: View
)
```

### Fractal Architecture (Large Apps)

Decompose into **bags** — modules with Model, INITIAL, UPDATE, VIEW:

```ruby
module Counter
  Model = Data.define(:count)
  INITIAL = Model.new(count: 0)

  UPDATE = -> (msg, model) do
    case msg
    in :increment
      [model.with(count: model.count + 1), nil]
    in :decrement
      [model.with(count: model.count - 1), nil]
    else
      [model, nil]
    end
  end

  VIEW = -> (model, tui) do
    tui.paragraph(text: "Count: #{model.count}")
  end
end

# Parent integrates child bag
ParentUpdate = -> (msg, model) do
  case msg
  in [:counter, counter_msg]
    new_counter, cmd = Counter::UPDATE.call(counter_msg, model.counter)
    mapped_cmd = cmd&.map { |m| [:counter, m] }
    [model.with(counter: new_counter), mapped_cmd]
  end
end
```

---

## Kit: Component-Based Architecture

Retained-mode components owning state and handling events. Similar to React class components, Vue Options API, Qt widgets.

**Status:** Coming Soon (design phase)

### Core Principle

"Encapsulated State" — Components own UI state independently, persisting between frames.

### Component Structure

```ruby
class MyButton
  include Kit::Component

  def initialize(label:)
    @label = label
    @click_count = 0
  end

  def mount
    # Called once when entering tree
    @mounted_at = Time.now
  end

  def render(frame, area)
    frame.render_widget(
      tui.paragraph(text: @label, style: current_style),
      area
    )
  end

  def handle_event(event)
    return unless event.key? && event.code == "enter"
    @click_count += 1
    :consumed  # Stops propagation
  end
end
```

### Component Mixins

| Mixin | Purpose |
|-------|---------|
| `Kit::KeyboardInteractive` | `focusable?`, `focus_boundary?`, `tab_index` |
| `Kit::MouseInteractive` | `area`, `contains_point?(x, y)` |
| `Kit::Lifecycle` | Mount/unmount hooks |
| `Kit::Visual` | `tui` accessor |
| `Kit::Stateful` | `state`, `is_focused?`, `hovered?`, `pressed?`, `disabled?` |
| `Kit::Component` | All mixins combined |

### State Management

```ruby
class TextInput
  include Kit::Component

  def initialize
    @buffer = ""
    @cursor_pos = 0
  end

  def handle_event(event)
    case event
    when {key: /^[a-zA-Z0-9]$/}
      @buffer.insert(@cursor_pos, event.key)
      @cursor_pos += 1
      :consumed

    when {key: "backspace"}
      return if @cursor_pos.zero?
      @buffer.slice!(@cursor_pos - 1)
      @cursor_pos -= 1
      :consumed

    when {key: "left"}
      @cursor_pos = [@cursor_pos - 1, 0].max
      :consumed

    else
      nil  # Propagate
    end
  end

  def render(frame, area)
    display = @buffer.dup.insert(@cursor_pos, "│")
    frame.render_widget(tui.paragraph(text: display), area)
  end
end
```

### Declarative Styling

```ruby
class MyButton
  include Kit::Component

  styles do
    state :focused, fg: :yellow, bold: true
    state :hovered, fg: :blue
    state :pressed, bg: :white, fg: :black
    state :normal, fg: :white
  end

  def render(frame, area)
    frame.render_widget(
      tui.paragraph(text: @label, style: current_style),
      area
    )
  end
end
```

`current_style` automatically resolves based on interaction state.

### Focus Management

```ruby
# Programmatic focus
Kit.focus.set(button)
Kit.focus.next           # Tab
Kit.focus.prev           # Shift+Tab
Kit.focus.blur

# Focus boundaries (modals)
Kit.focus.enter_boundary(modal)
Kit.focus.exit_boundary
```

Component focus control:

```ruby
def focusable? = true
def focus_boundary? = false
def tab_index = 0  # Positive: explicit order, 0: tree order, -1: skip
```

### Event Propagation

Return values control propagation:
- `nil` / `false` — Unhandled, propagate to parent
- Truthy (`:consumed`, `:submitted`) — Handled, stop propagation

```ruby
def handle_event(event)
  # Delegate to focused child first
  result = @child.handle_event(event) if @child.is_focused?
  return result if result

  # Handle component-level events
  case event
  when {key: "enter"}
    submit_form
    :submitted
  else
    nil  # Propagate
  end
end
```

---

## Integration: Adapter Pattern

Reuse Rooibos views in Kit components:

```ruby
# Pure Rooibos view
TeaView = -> (model, tui) do
  tui.paragraph(text: "Count: #{model.count}")
end

# Kit component adapter
class DashboardWidget
  include Kit::Component

  def initialize(record)
    @record = record  # Mutable
  end

  def render(frame, area)
    # Convert to immutable model
    tea_model = Data.define(:count).new(count: @record.count)
    widget = TeaView.call(tea_model, tui)
    frame.render_widget(widget, area)
  end

  def handle_event(event)
    case event
    when {key: "+"}
      @record.update!(count: @record.count + 1)
      :consumed
    end
  end
end
```

---

## When to Choose Each

### Choose Rooibos When:

- State predictability matters (dashboards, installers)
- Extensive testing required (pure functions are trivially testable)
- State reproducibility critical (time-travel debugging)
- Functional programming preferred
- Single source of truth simplifies reasoning

### Choose Kit When:

- Component reusability prioritized (shared libraries)
- Complex multi-panel interfaces (each panel owns state)
- Rich interactive components (inputs, forms)
- Object-oriented programming preferred
- Team distributes component ownership

### Decision Matrix

| Criterion | Rooibos | Kit |
|-----------|---------|-----|
| State predictability | Excellent | Good |
| Testability | Exceptional | Good |
| Component reuse | Limited | Excellent |
| Complex interactions | Harder | Natural |
| Learning curve | Steeper | Shallower |
| Code volume | Larger | Smaller |
| Debugging | Time-travel | Standard |

---

## Comparison with Raw RatatuiRuby.run

```ruby
# Raw approach
RatatuiRuby.run do |tui|
  loop do
    tui.draw { |frame| frame.render_widget(widget, frame.area) }
    break if tui.poll_event.ctrl_c?
  end
end
```

**Raw approach:**
- Maximum control
- Minimal abstraction
- Best for simple scripts and prototypes

**Rooibos:**
- Declarative MVU
- Automatic re-rendering
- Command system for side effects

**Kit:**
- Stateful components
- Focus/hover tracking
- Event propagation system

Choose raw for prototypes. Use Rooibos or Kit for production applications.

---

## Complete Rooibos Example

> Requires the `ratatui_ruby-tea` gem.

```ruby
require "ratatui_ruby"
require "ratatui_ruby/tea"

Model = Data.define(:items, :selected, :loading)

Init = -> do
  model = Model.new(items: [], selected: 0, loading: true)
  [model, Rooibos::Command.system('ls', :got_files)]
end

View = -> (model, tui) do
  if model.loading
    tui.paragraph(text: "Loading...")
  else
    tui.list(
      items: model.items,
      block: tui.block(title: "Files", borders: [:all]),
      highlight_style: {fg: "yellow", bold: true}
    )
  end
end

Update = -> (msg, model) do
  case msg
  in [:got_files, {stdout:, status: 0}]
    items = stdout.lines.map(&:strip)
    [model.with(items:, loading: false), nil]

  in {key: 'j'} | {key: 'down'}
    new_idx = [model.selected + 1, model.items.length - 1].min
    [model.with(selected: new_idx), nil]

  in {key: 'k'} | {key: 'up'}
    new_idx = [model.selected - 1, 0].max
    [model.with(selected: new_idx), nil]

  in {key: 'q'} | {key: 'ctrl_c'}
    Rooibos::Command.exit

  else
    [model, nil]
  end
end

RatatuiRuby::TEA.run(model: Init.call, update: Update, view: View)
```
