# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Repository Purpose

This is a **Claude Code plugin marketplace** for Ruby and Rails development. It contains:
- LSP plugins (ruby-lsp, typeprof)
- Skills plugins (rspec, draper, activerecord, etc.)
- Commands and agents for Ruby workflows

## Before Editing

**REQUIRED**: Activate relevant skills before editing:

- Editing skills? → `Skill: plugin-dev:skill-development`
- Editing plugin structure? → `Skill: plugin-dev:plugin-structure`
- Editing hooks? → `Skill: plugin-dev:hook-development`

## Directory Structure

```
.claude-plugin/
  marketplace.json       # Plugin catalog (required)
plugins/
  ruby-lsp/              # LSP plugin
    .claude-plugin/
      plugin.json
    .lsp.json            # LSP server config
    README.md
  rspec/                 # Skills plugin
    .claude-plugin/
      plugin.json
    skills/
      rspec/
        SKILL.md
        references/
        examples/
```

## Versioning

This marketplace uses **two levels of versioning**:

### Plugin Versions (plugin.json)
Each plugin has a version in its `plugin.json`. Bump when:
- Plugin structure changes
- New skills/commands/agents added to the plugin
- Plugin configuration changes

### Skill Versions (SKILL.md frontmatter)
Each skill has its own version in SKILL.md frontmatter. Bump when:
- Skill content changes (references, examples, trigger phrases)
- Skill guidance is updated

**Before committing:**
1. Identify what changed (`git status`)
2. For skill content changes → bump `version` in SKILL.md frontmatter
3. For plugin structure changes → bump `version` in plugin.json
4. Version bump levels:
   - **patch** (0.0.x): Bug fixes, typos
   - **minor** (0.x.0): New features, content additions
   - **major** (x.0.0): Breaking changes

## Testing Plugins

```bash
# Test locally before committing
claude --plugin-dir ./plugins/ruby-lsp

# Or install from local marketplace
/plugin marketplace add ./
/plugin install ruby-lsp@claude-ruby-marketplace
```

## LSP Plugins

LSP config goes in `.lsp.json` at plugin root (not in marketplace.json due to known bug #15148).

Required fields:
- `command`: LSP binary name
- `extensionToLanguage`: Maps file extensions to language IDs

Optional: `args`, `transport`, `env`, `initializationOptions`, `settings`

## Adding New Plugins

1. Create `plugins/<plugin-name>/` directory
2. Add `.claude-plugin/plugin.json` with name and version
3. Add plugin entry to `.claude-plugin/marketplace.json`
4. Add appropriate content (skills/, commands/, .lsp.json, etc.)
