# RPI

**R**esearch, **P**lan, **I**mplement: takes a raw idea to production, with the human making the decisions and every decision kept for the work that follows.

## The problem

Agents can now write most of a project's code. The question is who owns it: who decides how the software is built, and who can still say why it is the way it is.

Left to themselves, agents decide by default. They fill a gap in a ticket with a guess, settle a choice between themselves, copy what the code already does, record "that's how it was designed" as a reason. Each of these is a decision nobody made, and the software drifts from what its owner would have built. Keeping control the old way, by watching every step, makes the human the bottleneck and spends the attention the agents were meant to save.

rpi keeps ownership with the human at the speed of agents. The human makes the decisions about what the system does; every decision is kept with its reason; agents work from those records, bring back what nobody decided, and take everything else.

## The key: decisions that outlive the session

A decision that lives only in a conversation dies with the session, and then nobody owns it: the human has forgotten it, and the next agent never saw it. rpi keeps every decision in the thoughts repository, the project's long-term memory, and its process works the records at every step, from a raw idea to production:

- an idea is worked out with the human in a brainstorm, which leaves no question open and writes each decision down with its reason;
- a ticket points to those records instead of retelling them;
- a worker reads them in full before deciding anything itself;
- a handover writes back what was decided during the work.

A decision stays in force until a new one replaces it, and the old one stays in the history. So months later the record still answers what was decided, why, and what was tried before.

It works for a whole team the same way. The thoughts repository is shared and synced after every write, so a decision any member of the team makes goes straight into the work of every other member and their agents.

## The process

### Research: from an idea to decisions

The human and an agent think it through together (`rpi:brainstorm`). The agent is a partner, not a stenographer: it argues, brings facts instead of guesses, and asks one question at a time. Facts come from subagents reading the records and the code (`rpi:research_codebase`, `rpi:thoughts-analyzer`), so the conversation stays on the decisions.

The brainstorm note (`rpi:create_note`) keeps each decision with its reasons, what was rejected and why, and what is still open. A decision kept with its reasons can be questioned later on its merits; a bare one can only be obeyed or overturned blind.

### Plan: from decisions to tickets

When no question is left open, the decisions become tickets (`rpi:gh-issue`). A ticket answers WHAT problem we solve, WHY it matters and HOW: the approach decided in business logic and architecture, never the implementation details, which are the worker's. Its label says how far it was thought through: `decided`, `draft`, `agent-filed` or `audit`.

Large work is decomposed into small tickets rather than planned in detail: the first tickets are written in full (`decided`), the later ones get their details once the first are built (`draft`), since building changes the decisions. A small ticket is a small context, and the agent works better in it.

### Implement: from a ticket to the merge

A worker delivers one ticket (`rpi:feature`), as a senior engineer who owns the delivery (`rpi:worker`):

1. Reads what earlier work decided, then researches the code it will touch.
2. **Designs** before writing: reads those files whole, finds what the application, the framework and the gems already offer (their documentation through `mdri`), and decides where the new code lives.
3. Implements, tests, opens the pull request.
4. Brings it to the merge with the delivery the repository or the human names: Copilot as the reviewer (`rpi:copilot-assisted-feature-delivery`) or blind self-review by reviewer subagents (`rpi:self-reviewed-feature-delivery`). Whether a person reviews before the merge is the human's to say; when nothing says, the worker asks rather than guesses.
5. Writes the handover: the decisions made along the way and the scope changes, with their reasons.

## Roles

A role follows what the agent is doing, not how its session began.

- **The human** brings the ideas, steers the process and decides what the system should do; they review what they choose to.
- **The manager** (`rpi:manager`) leads the workers: hands tickets out, relays between them and the human, and brings the human only what needs them. It works through rpi's executables.
- **Workers** (`rpi:worker`) are senior engineers, each in its own session and its own clone of the repository.

Any agent discussing ideas with the human runs the brainstorm; any agent given a feature works as a worker.

## Skills

- **`rpi:workflow`** — how rpi's skills and tools work together, for an agent finding its place in the process or leading someone new to it.
- **`rpi:brainstorm`** — exploring an idea with the human from every side until it closes in decisions, and keeping the brainstorm note.
- **`rpi:gh-issue`** — writing a ticket that hands the decisions to the worker.
- **`rpi:manager`** — leading worker sessions.
- **`rpi:worker`** — delivering a feature as a senior engineer.
- **`rpi:feature`** — a feature end to end, from branch creation to the merge.
- **`rpi:copilot-assisted-feature-delivery`** — finishing a pull request with Copilot as its reviewer.
- **`rpi:self-reviewed-feature-delivery`** — finishing a pull request through blind self-review.
- **`rpi:review-pr`** — reviewing a pull request with independent reviewer subagents: someone else's, a re-review, a self-review, or the feedback yours received.
- **`rpi:research_codebase`** — documenting how the code works today.
- **`rpi:create_note`** — saving anything worth keeping to thoughts.
- **`rpi:create_handoff`**, **`rpi:resume_handoff`** — pausing a session and picking it up later, in this one or another.
- **`rpi:document-code`** — deciding whether a comment belongs, and writing the ones that do.
- **`rpi:sessions`** — reading an earlier Claude Code session.
- **`rpi:thoughts_init`** — linking a repository to thoughts.

## Subagents

The skills hand research and review to subagents: each reads with fresh eyes, given the question and not the answer it's expected to find.

Research:

- **`rpi:thoughts-analyzer`** — finding what earlier work decided, in the thoughts repository.
- **`rpi:codebase-analyzer`** — tracing how the code being changed works.
- **`rpi:codebase-pattern-finder`** — finding the existing code a change should be modelled after.
- **`rpi:documentation-researcher`** — a library's current documentation.
- **`rpi:web-search-researcher`** — what only the web knows.

Review, run by `rpi:review-pr`:

- **`rpi:review-ticket-delivery`** — whether the pull request delivers its ticket; always runs, and carries the security sweep.
- **`rpi:review-rails`** — Rails conventions and architecture.
- **`rpi:review-performance`** — performance and data leaking across tenants.
- **`rpi:review-tests-rspec`**, **`rpi:review-tests-minitest`** — test quality and coverage, whichever the repository uses.
- **`rpi:review-docs`** — the documentation in the code.
- **`rpi:review-generic`** — any domain in the change no expert reviewer covers.

## Tools

rpi brings a few command-line tools for what an agent does often: leading other sessions, reading past ones, keeping the thoughts repository in sync. As rpi lets the human focus on what matters, the tools do the same for an agent: instead of scripting the same commands again, it spends its attention on the work and on communication. Each tool's `--help` opens with a line saying what it does, and a hook puts those lines into every session, and back after a compaction, under the folder the tools live in, so an agent knows the tools exist before it needs one and finds them whether or not that folder is on its PATH. A person can run them by hand too.

The session tools let the manager lead worker sessions in tmux: a tmux session per project, named after it, and a window per clone, named after the clone (`one`, `two`). A worker is addressed as `<project>:<clone>` and runs as `<project>-<clone>`.

- **`session-start <project>:<clone> <dir> [claude flags…]`** — finds or creates the window, the agent and a fresh session in `<dir>`; refuses an agent that is working or asking. Extra flags pass through to Claude Code, such as `--resume <session-id>`.
- **`session-send <project>:<clone> <text>`** — types into the input box and presses Enter, as the worker's human would.
- **`session-list [project]`** — each session: working or idle and for how long, model, context size, last ask, latest step.
- **`session-peek <project>:<clone>`** — the screen now, and the conversation since the last ask.
- **`session-stop <project>:<clone>`** — stops the current turn; the session keeps its context.
- **`session-close <project>:<clone>`** — closes an idle session; the window stays for `session-start`.
- **`session2md <session.jsonl>`** — renders a session as the conversation it was.

The thoughts tools take an optional path inside the thoughts repository to act on, `~/thoughts` by default.

- **`thoughts-sync [directory] [-m message]`** — commits, pulls and pushes the thoughts repository.
- **`thoughts-status [directory]`** — its git state and the notes not yet synced.
- **`thoughts-init-repo [directory]`** — links the current repository's `thoughts/` folder to it.
- **`spec-metadata [directory]`** — the date, git and thoughts details a document's frontmatter records.

## Installation

```bash
claude plugin install rpi@claude-ruby-marketplace
```

Then run `/rpi:thoughts-init` in a repository. It creates `~/thoughts/` if needed and links the repository's `thoughts/` folder. `~/thoughts/` is a git repository the team shares.

To run several workers at once, keep a full clone of the repository for each (`one`, `two`, …), each with its own databases and services, so the workers don't get in each other's way. A worktree shares too much of that. Link each clone to thoughts with `/rpi:thoughts-init`.
