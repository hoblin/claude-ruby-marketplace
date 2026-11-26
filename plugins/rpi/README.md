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
2. Initialize the current repository's thoughts symlinks

The thoughts tools (`thoughts-sync`, `thoughts-status`, `thoughts-init-repo`, `spec-metadata`) are rpi executables, on the agent's PATH while rpi is enabled.

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
├── agents/                    # Research + review subagents
│   ├── codebase-analyzer.md
│   ├── codebase-pattern-finder.md
│   ├── documentation-researcher.md
│   ├── review-docs.md
│   ├── review-generic.md
│   ├── review-performance.md
│   ├── review-rails.md
│   ├── review-tests-minitest.md
│   ├── review-tests-rspec.md
│   ├── review-ticket-delivery.md
│   ├── thoughts-analyzer.md
│   └── web-search-researcher.md
├── skills/                    # Workflow skills
│   ├── research_codebase/SKILL.md
│   ├── create_note/SKILL.md
│   ├── create_handoff/SKILL.md
│   ├── resume_handoff/SKILL.md
│   ├── feature/SKILL.md
│   ├── review-pr/SKILL.md
│   ├── document-code/SKILL.md
│   ├── sessions/SKILL.md
│   ├── thoughts_init/SKILL.md
│   ├── brainstorm/SKILL.md    # Roles in the software factory
│   ├── manager/SKILL.md
│   ├── worker/SKILL.md
│   ├── copilot-assisted-feature-delivery/SKILL.md
│   └── self-reviewed-feature-delivery/SKILL.md
├── bin/                       # Executables, on the agent's PATH
│   ├── session-start … session-close
│   ├── session2md
│   └── thoughts-sync, thoughts-status, thoughts-init-repo, spec-metadata
├── hooks/                     # SessionStart: lists the executables
└── lib/                       # Code the executables share
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

These agents are spawned by `/rpi:feature` and `/rpi:research_codebase` to gather context:

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

## Review Subagents

These agents are spawned in parallel by `/rpi:review-pr`, which picks the roster for the repo's tech stack. Each carries a static system prompt — the orchestrator hands them artifact paths and parameters, never interpretation:

| Agent | Audits |
|-------|--------|
| **rpi:review-rails** | Rails conventions and architecture |
| **rpi:review-ticket-delivery** | whether the PR delivers the ticket (always runs; carries the security sweep) |
| **rpi:review-performance** | performance and cross-tenant leakage |
| **rpi:review-tests-rspec** | test quality and coverage (RSpec repos) |
| **rpi:review-tests-minitest** | test quality and coverage (minitest repos) |
| **rpi:review-docs** | documentation quality and clarity |
| **rpi:review-generic** | any domain in the diff with no expert reviewer |

## Commands

### Implementation

**`/rpi:feature`** - One-shot feature implementation from branch to PR

- Gathers historical context via `rpi:thoughts-analyzer`
- Researches codebase via parallel `rpi:codebase-pattern-finder` and `rpi:codebase-analyzer`
- Implements feature following Rails best practices
- Runs QA checks and creates draft PR
- Self-reviews automatically once CI is green (`/rpi:review-pr` self-review) and marks the PR ready
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

**`/rpi:document-code`** - The canon for comments and docstrings

- Loads before a comment gets written, not only when documentation is the task
- Rails as the reference: the shape of a contract, where volume belongs, which layer you document
- The delete test, plus the anti-patterns that recur — reasoning narrated in a docstring, restating the line below, shortening when the answer is deletion

**`/rpi:thoughts-init`** - Initialize thoughts system for current repository

- Diagnoses thoughts system state (~/thoughts, repo setup)
- Reports "ready" if everything configured
- Presents fixes needed and executes after authorization

**`/rpi:sessions`** - Read an earlier Claude Code session through `session2md`

### Roles

The skills a software factory runs on: a manager session leads worker sessions, each delivering one feature, with the human deciding what the system should do.

| Skill | For |
|-------|-----|
| **`/rpi:brainstorm`** | Thinking a decision through with the human, and keeping the brainstorm note |
| **`/rpi:manager`** | Turning decisions into tickets, handing them to workers, relaying between workers and the human |
| **`/rpi:worker`** | Delivering one feature as a senior engineer |
| **`/rpi:copilot-assisted-feature-delivery`** | Finishing a pull request with Copilot as its reviewer |
| **`/rpi:self-reviewed-feature-delivery`** | Finishing a pull request through blind self-review by reviewer subagents |

## Executables

On the agent's PATH while rpi is enabled, and runnable by hand. Each prints `--help`, whose first line says what the tool does: a SessionStart hook puts those lines into every session, and back after a compaction, so a new executable is listed on its own.

`session2md` renders a session `.jsonl` as the conversation it was.

The rest let a manager session lead worker sessions in tmux: a tmux session per project, named after it, and a window per clone, named after the clone (`one`, `two`). A worker is addressed as `<project>:<clone>`, and runs as `<project>-<clone>`. Every answer says what happened, what happens next and what need not be done.

| Executable | Does |
|------------|------|
| `session-start <project>:<clone> <dir> [claude flags…]` | Finds or creates the window, the agent and a fresh session in `<dir>`; refuses an agent that is working or asking. Starts `claude --permission-mode=bypassPermissions --remote-control <name> --model opus -n <name>`; extra flags pass through, e.g. `--resume <session-id>` |
| `session-send <project>:<clone> <text>` | Types into the input box and presses Enter, as the worker's human would; text on stdin works too |
| `session-list [project]` | Each session: working or idle and for how long, model, context size, last ask, latest step |
| `session-peek <project>:<clone>` | The screen now (current action, input box, dialog, status line) and the conversation since the last ask |
| `session-stop <project>:<clone>` | Presses Esc: stops the current turn or closes a dialog; the session keeps its context |
| `session-close <project>:<clone>` | Closes an idle session with `/exit`; the window stays for `session-start` |

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
