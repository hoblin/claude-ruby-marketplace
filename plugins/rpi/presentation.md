---
marp: true
theme: default
paginate: false
style: |
  section {
    font-size: 2.2em;
    text-align: center;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    background: #1a1a2e;
    color: #eee;
  }
  h1 { color: #e94560; font-size: 1.6em; }
  h2 { color: #16c79a; font-size: 1.3em; }
  h3 { color: #e8e8e8; font-size: 1.1em; }
  strong { color: #e94560; }
  em { color: #16c79a; }
  code { background: #0f3460; padding: 0.1em 0.3em; border-radius: 4px; font-size: 0.7em; }
  pre { text-align: left; font-size: 0.55em; background: #0f3460; padding: 0.8em; border-radius: 8px; }
  ul { text-align: left; }
  li { margin: 0.2em 0; }
  section.title { background: #0f3460; }
  section.title h1 { color: #e94560; font-size: 2em; }
  section.diagram pre { font-size: 0.5em; }
---

<!-- _class: title -->

# Thoughts Repository & RPI Plugin
## Context Engineering for AI-Assisted Development

---

# The Problem: Agent Tunnel Vision

AI agents only see files they've **explicitly read**

They have no awareness of:
- Overall **architecture**
- **Decision history** — why things are built this way
- What was **tried and failed**

---

## What's inside an AI context window?

```
┌─────────────────────────────────────────┐
│  System Prompt                          │
│  (instructions, tools, rules)           │
├─────────────────────────────────────────┤
│  Files the agent READ this session      │
│  (maybe 10-20 out of 500+ in project)  │
├─────────────────────────────────────────┤
│  Conversation history                   │
│  (your messages + agent responses)      │
├─────────────────────────────────────────┤
│  Tool results                           │
│  (grep output, test results, etc.)      │
└─────────────────────────────────────────┘
       ↑ This is ALL the agent knows
```

---

## The consequences

- Agent **duplicates** code that already exists elsewhere
- Builds features **beside** the architecture, not **within** it
- Makes decisions that **contradict** past team decisions
- Every session starts from **scratch**

---

<!-- _class: title -->

# Part 1: Thoughts Repository

---

# Thoughts ≠ Documentation

---

## Traditional documentation

- Describes **WHAT** the project does
- **Static** — lags behind the code
- Never explains **WHY** decisions were made
- Expensive to maintain

---

## Thoughts repository

- Captures **WHY** — decisions, brainstorms, trade-offs
- **Living** — written as part of the workflow, always up to date
- Contains **evolution** — what was tried, what failed, what changed
- Git-based — versioned, shared, team-wide

---

## Structure

```
~/thoughts/repos/{project}/shared/
│
├── notes/      Brainstorms, architectural decisions
│               "Why we switched from approach A to B"
│
├── research/   Codebase analysis reports
│               "How the auth system works today"
│
├── plans/      Implementation plans with phases
│               "Step-by-step plan for feature X"
│
└── handoffs/   Session context transfers
                "Where I left off, what's next"
```

---

## How it helps AI agents

```
WITHOUT thoughts repo:

  Agent reads 10 files → local view → reinvents wheel
  ┌──────────┐
  │ 10 files │ ──→  decisions based on incomplete picture
  └──────────┘

WITH thoughts repo:

  Agent reads thoughts FIRST → grand perspective → builds within
  ┌──────────────────────────────┐
  │ Architecture research        │
  │ Decision history             │ ──→  informed decisions
  │ Related brainstorms          │
  │ + the 10 files it needs      │
  └──────────────────────────────┘
```

---

## Example: Starting an unfamiliar feature

1. Run `research_codebase` — agent studies architecture
2. Report saved to `thoughts/shared/research/`

**For you:** understand what you're dealing with
**For agents:** every future session gets grand perspective

*Written once, used many times — by humans, agents, and new team members*

---

<!-- _class: title -->

# Part 2: RPI Plugin
## Research → Plan → Implement

---

## Core principle

> "The context window is the **ONLY lever**
> to affect output quality"

Research and exploration fill context with **noise**.
Solution: compress into artifacts, start fresh.

---

## Frequent Intentional Compaction

```
Session 1: Research + Create Plan
  Context fills with: search results, file reads, exploration
  OUTPUT: plan artifact (compressed understanding)

  ── fresh session ──

Session 2: Review + Iterate Plan
  Loads ONLY the plan artifact (clean context)
  OUTPUT: refined plan

  ── fresh session ──

Session 3: Implement Phase 1
  Loads plan + relevant code (focused context)
  OUTPUT: working code + updated checkboxes
```

---

## The workflow

```
  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
  │ create_plan  │ ──→ │ iterate_plan │ ──→ │implement_plan│
  │              │     │              │     │              │
  │ Research +   │     │ Review +     │     │ Phase by     │
  │ plan draft   │     │ refine       │     │ phase        │
  └──────┬───────┘     └──────┬───────┘     └──────┬───────┘
         │                    │                    │
         ▼                    ▼                    ▼
    thoughts/            thoughts/             code +
    plans/               plans/                plan updated
    (artifact)           (refined)             with ✅
```

---

## Research subagents (spawned in parallel)

| Agent | Answers |
|-------|---------|
| `codebase-analyzer` | **HOW** does this code work? |
| `codebase-pattern-finder` | **What patterns** exist to follow? |
| `documentation-researcher` | What do the **library docs** say? |
| `web-search-researcher` | What are **current best practices**? |
| `thoughts-analyzer` | What **decisions** were made before? |

---

## Don't outsource thinking

Agent **researches** and **drafts**
You **review** and **refine**

The plan is not ready until **you** say it's ready

A bad line in code = **one** bad line
A bad line in a plan = **hundreds** of bad lines

---

## Bonus commands

- `feature` — one-shot for smaller features
- `review-pr` — 5 parallel reviewers (Rails, Security, Perf, Testing, Docs)
- `create_handoff` / `resume_handoff` — transfer context between sessions
- `commit` — git commit without AI attribution

---

<!-- _class: title -->

# Key Takeaway

---

## Agents work better with **context**

**Thoughts repo** = team memory for decisions and architecture

**RPI plugin** = disciplined workflow with compaction

Together: agents build **within** the architecture, not beside it

---

# Questions?
