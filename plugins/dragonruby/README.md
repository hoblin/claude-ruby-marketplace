# DragonRuby Plugin

DragonRuby Game Toolkit patterns and best practices for 2D game development with Claude Code.

## Installation

```bash
/plugin marketplace add https://github.com/hoblin/claude-ruby-marketplace
/plugin install dragonruby@claude-ruby-marketplace
```

## Features

This plugin provides comprehensive coverage of DragonRuby development:

| Domain | Coverage |
|--------|----------|
| **Core** | Game loop, tick method, args object, coordinate system |
| **Input** | Keyboard, mouse, controller, directional/analog movement |
| **Entities** | Spawning, collision detection, lifecycle management |
| **Game Logic** | State management, timers, persistence, save/load |
| **Audio** | Sound effects, background music, event-driven audio |
| **Rendering** | Sprites, labels, solids, primitives, layering |
| **Animation** | Frame-based animation, spritesheets, state-driven |
| **Scenes** | Scene management, transitions, menu systems |
| **Distribution** | itch.io, Steam, mobile, cross-platform builds |

## Usage

The skill activates automatically when:

- Working on DragonRuby game files
- Discussing game development concepts
- Mentioning `args.outputs`, `args.state`, `tick` method
- Asking about 2D game patterns

## Quick Start

```ruby
def tick args
  args.state.player ||= { x: 640, y: 360, w: 50, h: 50, path: 'player.png' }

  args.state.player.x += 5 if args.inputs.right
  args.state.player.x -= 5 if args.inputs.left

  args.outputs.sprites << args.state.player
end
```

## Resources

- [DragonRuby Documentation](https://docs.dragonruby.org)
- [DragonRuby Book](https://book.dragonriders.community)
- [Discord Community](https://discord.dragonruby.org)

## License

MIT
