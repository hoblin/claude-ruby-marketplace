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
  ┌──────────────────────────────────┐
  │ Architecture research            │
  │ Decision history                 │ ──→  informed decisions
  │ Related brainstorms              │
  │ + the 10 files it needs          │
  └──────────────────────────────────┘
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
## The Day-to-Day Workflow

---

## Prerequisites: Research before tickets

Before any implementation starts:

1. `research_codebase` — document how things work **today**
2. Save to thoughts repo — grand perspective for agents

This happens during **ticket creation**, not during implementation

---

## Decompose, don't plan

Large features → break into **small tickets** (human decision)

Each small ticket → one `feature` command

Planning happens during **decomposition**, not inside the agent

---

## The two commands we use daily

---

## `feature`

End-to-end: from ticket to **draft PR**

```
  Ticket description
       │
       ▼
  ┌─────────────────────────────────┐
  │  1. Read thoughts repo          │
  │     (architecture context)      │
  │                                 │
  │  2. Research codebase           │
  │     (patterns, existing code)   │
  │                                 │
  │  3. Implement                   │
  │     (following existing style)  │
  │                                 │
  │  4. QA checks                   │
  │     (tests, linting)            │
  │                                 │
  │  5. Create draft PR             │
  └─────────────────────────────────┘
```

---

## `review-pr`

Three modes for different stages:

---

### Mode 1: Self-review

*Right after implementation, before human review*

Agent spawns subagents → checks everything →
**fixes issues automatically** → marks PR as ready

---

### Mode 2: Human-requested review

*When you're assigned as reviewer*

Agent runs 5 parallel reviewers → leaves comments

| Reviewer | Checks |
|----------|--------|
| Rails | Architecture, patterns, conventions |
| Security | Vulnerabilities, input validation |
| Performance | N+1, slow queries, memory |
| Testing | Coverage, edge cases |
| Documentation | Missing docs, outdated comments |

---

### Mode 3: Address feedback

*After reviewer left comments*

Agent reads PR comments →
**applies fixes** (like self-review, but guided by feedback)

---

## The full cycle

```
  Decompose ticket (human)
       │
       ▼
  ┌──────────┐    ┌───────────────┐    ┌──────────────┐
  │ feature  │ →  │ review-pr     │ →  │ review-pr    │
  │          │    │ (self-review) │    │ (feedback)   │
  │ Ticket   │    │ Auto-fix +    │    │ Apply human  │
  │ → PR     │    │ mark ready    │    │ comments     │
  └──────────┘    └───────────────┘    └──────────────┘
                                              │
                                              ▼
                                        ✅ Merge
```

---

## What about `create_plan` / `iterate_plan`?

Still available for **very large features**

But in practice: decompose into small tickets works **better**

- Plans duplicate the work (plan → implement = write twice)
- Planning is slow — review is faster on actual code
- Small tickets = small context = better agent output

---

## Other useful commands

- `research_codebase` — document codebase state (pre-work research)
- `create_handoff` / `resume_handoff` — transfer context between sessions
- `commit` — git commit without AI attribution

---

<!-- _class: title -->

# Key Takeaway

---

## Agents work better with **context**

**Thoughts repo** = team memory for decisions and architecture

**RPI plugin** = disciplined workflow: `feature` → `review-pr`

Research **before** tickets. Decompose **before** implementation.

---

# Questions?
