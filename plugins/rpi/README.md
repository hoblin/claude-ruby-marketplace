# RPI Plugin

**R**esearch, **P**lanning, **I**mplementation - context engineering workflow for AI-assisted development.

## Philosophy

This workflow is adapted from HumanLayer's [Advanced Context Engineering for Coding Agents](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents).

> "The contents of your context window are the **ONLY lever** you have to affect the quality of your output."

LLMs are stateless functions. Each turn is `context window in → next step out`. The problem: research, code exploration, and iteration fill your context with noise. The solution: **Frequent Intentional Compaction** - compress understanding into artifacts, start fresh, reload only what's needed.

A bad line of code is just one bad line. A bad line in a **plan** creates hundreds of bad lines. A misunderstanding in **research** creates thousands. Focus human attention on the highest-leverage artifacts.

**Do not outsource thinking.** The agent researches and drafts - you review and refine. The plan is not ready until *you* say it's ready.

## Installation

```bash
claude plugin install rpi@claude-ruby-marketplace
```

Then run `/rpi:thoughts-init` to set up the thoughts system. The command will:
1. Check if `~/thoughts/` exists and create it if needed
2. Install helper scripts to `~/thoughts/bin/`
3. Configure PATH (may require terminal restart)
4. Initialize the current repository's thoughts symlinks

## The Workflow

The key insight: **you will start new sessions frequently**. Each session produces a document (plan, research, handoff) that captures refined understanding. The next session reads that document - no context is "transferred", just loaded fresh.

```
SESSION 1: Create Plan
─────────────────────────────────────────────────────────────
/rpi:create_plan MYX-123
  → Agent spawns research subagents
  → Agent asks questions on key decisions
  → Agent writes plan to thoughts/shared/plans/
  → Context full of research noise
─────────────────────────────────────────────────────────────
                    📄 ARTIFACT: plan file contains refined understanding

/new ─────────────────────────────────────────────────────────

SESSION 2: Iterate Plan (fresh context)
─────────────────────────────────────────────────────────────
(review plan file yourself first)

/rpi:iterate_plan ./thoughts/shared/plans/2026-01-06/MYX-123.md
  - Review ticket, parent task, sibling subtasks
  - Narrow scope to current task only
  → Agent reads plan, updates it, runs thoughts-sync
─────────────────────────────────────────────────────────────
                    📄 ARTIFACT: plan updated

/new ─────────────────────────────────────────────────────────

SESSION 3: Iterate Plan again (fresh context)
─────────────────────────────────────────────────────────────
/rpi:iterate_plan ./thoughts/shared/plans/2026-01-06/MYX-123.md
  - Wrong order of phases 5 and 6
  → Agent fixes, syncs
─────────────────────────────────────────────────────────────
                    📄 ARTIFACT: plan refined and approved

/new ─────────────────────────────────────────────────────────

SESSION 4: Implement Phase 1 (fresh context)
─────────────────────────────────────────────────────────────
/rpi:implement_plan ./thoughts/shared/plans/2026-01-06/MYX-123.md
  Start phase 1
  → Agent reads plan, implements phase 1
  → Agent updates checkboxes, commits code
─────────────────────────────────────────────────────────────
                    📄 ARTIFACT: plan updated with progress

/new ─────────────────────────────────────────────────────────

SESSION 5: Continue Implementation (fresh context)
─────────────────────────────────────────────────────────────
/rpi:implement_plan ./thoughts/shared/plans/2026-01-06/MYX-123.md
  Phase 1 done, continue with phases 2 and 3
  → Agent reads plan, sees phase 1 ✓, continues
─────────────────────────────────────────────────────────────
```

### Why New Sessions?

- Context fills with noise (search results, failed attempts, exploration)
- Fresh context + artifact = clean start with refined understanding
- Small phases fit in one session; complex phases get their own

## Plugin Contents

```
rpi/
├── agents/                    # Research subagents
│   ├── codebase-analyzer.md
│   ├── codebase-pattern-finder.md
│   ├── documentation-researcher.md
│   ├── thoughts-analyzer.md
│   └── web-search-researcher.md
├── commands/                  # Workflow commands
│   ├── create_plan.md
│   ├── iterate_plan.md
│   ├── implement_plan.md
│   ├── validate_plan.md
│   ├── research_codebase.md
│   ├── create_note.md
│   ├── create_handoff.md
│   ├── resume_handoff.md
│   ├── commit.md
│   ├── feature.md
│   ├── review-pr.md
│   └── thoughts_init.md
└── templates/                 # Setup templates
    └── thoughts-bin/          # Scripts for ~/thoughts/bin/
```

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

These agents are spawned by `/rpi:create_plan` and `/rpi:research_codebase` to gather context:

### Codebase Agents

| Agent | Purpose |
|-------|---------|
| **rpi:codebase-analyzer** | Traces data flow, understands HOW code works |
| **rpi:codebase-pattern-finder** | Finds existing patterns to model new code after |

### External Research Agents

| Agent | Purpose |
|-------|---------|
| **rpi:documentation-researcher** | Fetches library docs via Context7 |
| **rpi:web-search-researcher** | Searches web for modern docs and best practices |

### Thoughts Agents

| Agent | Purpose |
|-------|---------|
| **rpi:thoughts-analyzer** | Discovers and analyzes documents in `thoughts/` directory |

## Commands

### Planning

**`/rpi:create_plan`** - Create detailed implementation plans through interactive research

- Spawns research subagents to gather codebase and external context
- Interactive planning process with user feedback
- Creates plans with phases, success criteria, and detailed steps
- Each phase = one atomic commit
- Output: `thoughts/shared/plans/YYYY-MM-DD/{ticket}-description.md`

**`/rpi:iterate_plan`** - Update existing plans based on feedback

- Focused, precise updates to existing plans
- Confirms understanding before making changes
- Only researches what's necessary for specific changes

### Implementation

**`/rpi:implement_plan`** - Execute approved plan from `thoughts/shared/plans/`

- Follows plan's intent while adapting to reality
- Implements each phase fully before moving to next
- Updates checkboxes in plan files as work progresses
- Pauses for manual verification after each phase

**`/rpi:validate_plan`** - Verify implementation matches plan (for unsupervised runs)

- Runs automated verification commands
- Documents pass/fail status
- Identifies deviations from plan

**`/rpi:feature`** - One-shot feature implementation from branch to PR

- Gathers historical context via `rpi:thoughts-analyzer`
- Researches codebase via parallel `rpi:codebase-pattern-finder` and `rpi:codebase-analyzer`
- Implements feature following Rails best practices
- Runs QA checks and creates draft PR
- For smaller features that don't need multi-session planning

**`/rpi:review-pr`** - Multi-agent PR review with four modes

- **review** (default) — full review, post findings to GitHub
- **re-review** — verify previously requested changes were addressed
- **self-review** — fix findings directly, commit, push, and prepare PR for human review
- **address-feedback** — contextualize reviewer feedback against codebase and design intent, fix accepted concerns, reply to reviewer
- Supports file exclusion/inclusion patterns and custom instructions
- Saves diff to `/tmp/` for context-efficient subagent delegation

### Research & Notes

**`/rpi:research_codebase`** - Document codebase state before planning

- Spawns parallel sub-agents to investigate specific features
- Synthesizes findings into research document
- **ONLY documents, never suggests improvements** (documentarian role)
- Output: `thoughts/shared/research/YYYY-MM-DD/{ticket}-description.md`

**`/rpi:create_note`** - Capture findings as a persistent note

- Captures research findings, subagent outputs, or session context
- Preserves content losslessly without synthesis or transformation
- Lightweight alternative to `research_codebase` for single-source captures
- Output: `thoughts/shared/notes/YYYY-MM-DD/description.md`

### Session Continuity

**`/rpi:create_handoff`** - Compact context for session transfer

- Concise context compaction without losing details
- Captures: tasks, status, learnings, artifacts, next steps
- Includes file:line references for recent changes
- Output: `thoughts/shared/handoffs/{ticket}/YYYY-MM-DD/HH-MM-SS_description.md`

**`/rpi:resume_handoff`** - Resume work from handoff document

- Validates current state against handoff state
- Creates action plan from handoff's next steps
- Handles: clean continuation, diverged codebase, incomplete work, stale handoff

### Utilities

**`/rpi:commit`** - Create git commits with user approval (no Claude attribution)

**`/rpi:thoughts-init`** - Initialize thoughts system for current repository

- Diagnoses thoughts system state (~/thoughts, scripts, PATH, repo setup)
- Reports "ready" if everything configured
- Presents fixes needed and executes after authorization

## Document Conventions

### Naming Patterns

1. **Ticket-based**: `YYYY-MM-DD/{ticket}-{topic}.md`
   - Example: `2026-01-06/MYX-123-user-authentication.md`

2. **Timestamp-based**: `YYYY-MM-DD/HH-MM-SS_{topic}.md`
   - Example: `2026-01-06/14-30-00_api-flow.md`

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
