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

## Sources & Acknowledgments

This skill was built using knowledge from these excellent resources:

### Building Games with DragonRuby (The Book)

**Highly recommended for learning DragonRuby!**

An open-source book by [Brett Chalupa](https://github.com/brettchalupa) and the Dragon Rider Community. It provides a hands-on, project-based introduction to game development with DragonRuby GTK.

- [Read online](https://book.dragonriders.community)
- [GitHub repository](https://github.com/DragonRidersUnite/book)
- [Support the author](https://buymeacoffee.com/brettchalupa)

### Official Resources

- [DragonRuby Documentation](https://docs.dragonruby.org) - Complete API reference
- [DragonRuby Discord](https://discord.dragonruby.org) - Active community support
- [DragonRuby GTK](https://dragonruby.org/toolkit/game) - Get the engine

### Credits

- **Amir Rajan** - Creator of DragonRuby GTK
- **Brett Chalupa** - Author of "Building Games with DragonRuby"
- **Dragon Rider Community** - Book contributors and community support

## License

MIT
