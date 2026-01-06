# RPI Plugin

**R**esearch, **P**lanning, **I**mplementation - context engineering workflow for AI-assisted development.

## Overview

The Thoughts system implements **frequent intentional compaction** - a context management methodology that compresses codebase "truth" and implementation "intent" into reusable artifacts. The core philosophy:

> "The contents of your context window are the ONLY lever you have to affect the quality of your output."

This plugin enables context continuity between AI sessions by centralizing research, plans, and handoffs across multiple projects.

## Plugin Contents

```
rpi/
├── agents/                    # Research subagents
│   ├── codebase-analyzer.md
│   ├── codebase-locator.md
│   ├── codebase-pattern-finder.md
│   ├── documentation-researcher.md
│   ├── thoughts-analyzer.md
│   ├── thoughts-locator.md
│   └── web-search-researcher.md
└── commands/                  # Workflow commands
    ├── create_plan.md
    ├── iterate_plan.md
    ├── implement_plan.md
    ├── validate_plan.md
    ├── research_codebase.md
    ├── create_handoff.md
    ├── resume_handoff.md
    └── commit.md
```

## The RPI Trifecta

### Research → Planning → Implementation

```
┌────────────────────────────────────────────────────────────────────┐
│                        /create_plan                                 │
│  ┌─────────────┐     ┌─────────────┐                               │
│  │  RESEARCH   │────▶│  PLANNING   │  (research happens inline)    │
│  │  subagents  │     │  output     │                               │
│  └─────────────┘     └─────────────┘                               │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│                      /implement_plan                                │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Execute plan phase-by-phase, update progress checkboxes     │  │
│  └──────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
```

## Key Concepts

### Context Compression

- **Truth**: Codebase understanding compressed into research artifacts
- **Intent**: Implementation goals compressed into plan artifacts
- **Continuity**: Work state compressed into handoff artifacts

### Persistent Memory Layer

The thoughts repository (`~/thoughts/`) acts as external memory for AI-assisted development:
- Research documents preserve codebase understanding
- Plans preserve implementation decisions
- Handoffs preserve work-in-progress state
- All artifacts are versioned and backed up via git

## Thoughts Directory Structure

The plugin expects a thoughts repository at `~/thoughts/` with this structure:

```
~/thoughts/
├── global/                        # Cross-repository content
│   ├── {user}/                   # Personal cross-repo notes
│   └── shared/                   # Team-shared cross-repo notes
└── repos/                         # Per-repository thoughts
    └── {repo-name}/
        ├── {user}/               # Personal notes
        └── shared/
            ├── handoffs/         # Context transfer documents
            ├── plans/            # Implementation plans
            ├── research/         # Codebase research
            └── notes/            # General notes
```

## Research Subagents

These agents are spawned by `/create_plan` and `/research_codebase` to gather context:

### Codebase Agents

| Agent | Purpose |
|-------|---------|
| **codebase-analyzer** | Traces data flow, understands HOW code works |
| **codebase-locator** | Finds WHERE code lives (files, functions, classes) |
| **codebase-pattern-finder** | Finds existing patterns to model new code after |

### External Research Agents

| Agent | Purpose |
|-------|---------|
| **documentation-researcher** | Fetches library docs via Context7 |
| **web-search-researcher** | Searches web for modern docs and best practices |

### Thoughts Agents

| Agent | Purpose |
|-------|---------|
| **thoughts-locator** | Discovers relevant documents in `thoughts/` directory |
| **thoughts-analyzer** | Deep-dives into specific thoughts documents |

## Commands

### Planning

**`/create_plan`** - Create detailed implementation plans through interactive research

- Spawns research subagents to gather codebase and external context
- Interactive planning process with user feedback
- Creates plans with phases, success criteria, and detailed steps
- Each phase = one atomic commit
- Output: `thoughts/shared/plans/YYYY-MM-DD-{ticket}-description.md`

**`/iterate_plan`** - Update existing plans based on feedback

- Focused, precise updates to existing plans
- Confirms understanding before making changes
- Only researches what's necessary for specific changes

### Implementation

**`/implement_plan`** - Execute approved plan from `thoughts/shared/plans/`

- Follows plan's intent while adapting to reality
- Implements each phase fully before moving to next
- Updates checkboxes in plan files as work progresses
- Pauses for manual verification after each phase

**`/validate_plan`** - Verify implementation matches plan (for unsupervised runs)

- Runs automated verification commands
- Documents pass/fail status
- Identifies deviations from plan

### Pre-Planning Research

**`/research_codebase`** - Document codebase state before planning

- Spawns parallel sub-agents to investigate specific features
- Synthesizes findings into research document
- **ONLY documents, never suggests improvements** (documentarian role)
- Output: `thoughts/shared/research/YYYY-MM-DD-{ticket}-description.md`

### Session Continuity

**`/create_handoff`** - Compact context for session transfer

- Concise context compaction without losing details
- Captures: tasks, status, learnings, artifacts, next steps
- Includes file:line references for recent changes
- Output: `thoughts/shared/handoffs/{ticket}/YYYY-MM-DD_HH-MM-SS_description.md`

**`/resume_handoff`** - Resume work from handoff document

- Validates current state against handoff state
- Creates action plan from handoff's next steps
- Handles: clean continuation, diverged codebase, incomplete work, stale handoff

### Utilities

**`/commit`** - Create git commits with user approval (no Claude attribution)

## Workflow Example

```bash
# Optional: Research complex feature before planning
/research_codebase "How does user authentication work?"

# Create implementation plan (includes research phase)
/create_plan MYX-123

# Iterate on plan based on feedback
/iterate_plan MYX-123

# Implement the approved plan
/implement_plan MYX-123

# For unsupervised runs: validate implementation
/validate_plan MYX-123

# Switching sessions? Create handoff
/create_handoff MYX-123

# Resume in new session
/resume_handoff MYX-123
```

## Document Conventions

### Naming Patterns

1. **Ticket-based**: `YYYY-MM-DD-{ticket}-{topic}.md`
   - Example: `2026-01-06-MYX-123-user-authentication.md`

2. **Timestamp-based**: `YYYY-MM-DD_HH-MM-SS_{topic}.md`
   - Example: `2026-01-06_14-30-00_api-flow.md`

### YAML Frontmatter

All documents include metadata:

```yaml
---
date: 2026-01-06 14:30:45 PST
researcher: hoblin
git_commit: abc123...
branch: feature/auth
repository: my-app
---
```

## Installation

```bash
claude plugin install rpi@claude-ruby-marketplace
```

**Prerequisites**: The thoughts repository must be set up at `~/thoughts/`. See [HumanLayer's context engineering approach](https://github.com/humanlayer/humanlayer) for the underlying methodology.

## Philosophy

This system is adapted from HumanLayer's context engineering approach. The goal is to make AI-assisted development more effective by ensuring essential context is always available without exceeding context window limits.
