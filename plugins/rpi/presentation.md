---
marp: true
theme: default
paginate: false
style: |
  section {
    font-size: 2.5em;
    text-align: center;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    background: #1a1a2e;
    color: #eee;
  }
  h1 { color: #e94560; font-size: 1.8em; }
  h2 { color: #0f3460; font-size: 1.4em; color: #16c79a; }
  strong { color: #e94560; }
  em { color: #16c79a; }
  code { background: #0f3460; padding: 0.1em 0.3em; border-radius: 4px; font-size: 0.8em; }
  section.title { background: #0f3460; }
  section.title h1 { color: #e94560; font-size: 2em; }
  section.problem { background: #1a1a2e; }
  section.solution { background: #16213e; }
---

<!-- _class: title -->

# Thoughts Repository & RPI Plugin
## Context Engineering for AI-Assisted Development

---

# The Problem

---

## AI agents have **tunnel vision**

---

They only see the files they've read

---

No **grand perspective**

No architecture awareness

No decision history

---

Every new session =

## **blank slate**

---

They don't know **WHY**

things are built a certain way

---

Result?

---

Agents **reinvent the wheel**

---

They duplicate existing code

instead of reusing it

---

They build features **beside** the architecture

not **within** it

---

<!-- _class: title -->

# Thoughts Repository

---

## A team **knowledge base**

stored in Git

---

Not documentation

---

Documentation describes **WHAT**

---

Thoughts capture **WHY**

---

Why decisions were made

What was tried and failed

How architecture evolved

---

## Traditional docs

- Static
- Lag behind the code
- Describe features
- Expensive to maintain

---

## Thoughts repo

- **Living** documentation
- Always up to date
- Describes **decisions**
- Written as part of the workflow

---

## Structure

```
~/thoughts/repos/{project}/shared/
├── notes/       # Brainstorms, decisions
├── plans/       # Implementation plans
├── research/    # Architecture research
└── handoffs/    # Session context transfer
```

---

## Git-based

Version controlled

Shared across the team

One command: `thoughts-sync`

---

## How it helps AI agents

---

Agent starts working on a feature

---

First: reads **thoughts repo**

via `thoughts-analyzer`

---

Finds architectural research

Finds decision history

Finds related brainstorms

---

Tunnel vision gets

## **grand perspective**

---

Features get **integrated**

into existing architecture

---

Not injected as separate islands

---

## Example: Killing Two Birds

---

Unfamiliar feature?

Run `research_codebase`

---

Agent studies the architecture

Saves report to thoughts

---

**For you:**

understand what you're dealing with

---

**For agents:**

every future session sees

the grand perspective

---

Written once

Used **many** times

---

By humans ✅

By agents ✅

By new team members ✅

---

<!-- _class: title -->

# RPI Plugin
## Research → Plan → Implement

---

## The core insight

---

> "Context window is the **ONLY lever**
> to affect output quality"

---

Research fills context with **noise**

---

## Solution:

Frequent Intentional Compaction

---

Compress understanding into **artifacts**

Start fresh session

Load only what's needed

---

## The Workflow

---

## 1. `create_plan`

Research + interactive planning

→ plan saved to thoughts

---

### Parallel subagents gather context:

---

`codebase-analyzer`

**HOW** code works

---

`codebase-pattern-finder`

Find existing **patterns** to follow

---

`documentation-researcher`

Library **docs**

---

`web-search-researcher`

**Latest** best practices

---

`thoughts-analyzer`

Search **thoughts repo** 🔄

---

## 2. `iterate_plan`

Review and refine

**Fresh session!**

---

## Don't outsource thinking

---

Agent researches and drafts

**You** review and refine

---

A bad line in **code** =

one bad line

---

A bad line in a **plan** =

hundreds of bad lines

---

## 3. `implement_plan`

Execute phase by phase ✅

---

Each phase = one atomic commit

Checkboxes track progress

---

## 4. `validate_plan`

Verify implementation matches plan

---

## Bonus Commands

---

`feature` — one-shot for small features

---

`review-pr` — 5 parallel reviewers

Rails · Security · Performance · Testing · Docs

---

`create_handoff` / `resume_handoff`

Context transfer between sessions

---

`commit`

Git commit without AI attribution

---

<!-- _class: title -->

# Key Takeaway

---

## Agents work better

when they have **context**

---

Thoughts repo = **team memory**

RPI = **workflow discipline**

---

Together: agents build **within**

the architecture, not beside it

---

# Questions?

---
