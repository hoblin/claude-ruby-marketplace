---
name: workflow
description: How rpi's skills and tools work together, from a raw idea to production. Read when someone is new to rpi or asks how to work with it, and when you're unsure which part of the process a piece of work belongs to.
---

# How rpi works

rpi takes a raw idea to production while the human keeps ownership of the software: the decisions about what the system does are theirs, each is kept with its reason in the thoughts repository, and agents work from those records.

## The path

1. **An idea becomes decisions.** It's explored with the human in a brainstorm (`rpi:brainstorm`), and the decisions go into its note (`rpi:create_note`). When a decision needs to know how the code works today, `rpi:research_codebase` finds out and its report is kept too.
2. **Decisions become tickets** (`rpi:gh-issue`) once no question is left open.
3. **A ticket goes to a worker.** The manager (`rpi:manager`) starts a session in the worker's clone with `session-start` and hands it the ticket with `session-send`.
4. **The worker delivers it** (`rpi:worker`, `rpi:feature`): research, design, implementation, then the delivery skill the repository or the human names (`rpi:copilot-assisted-feature-delivery`, or `rpi:self-reviewed-feature-delivery`, which runs `rpi:review-pr`), and after the merge, the handover note.

Each step reads what the steps before it recorded, and writes down what it decided.

## Which part you're in

A role follows what you're doing, not how your session began. Discussing ideas with the human, you're in a brainstorm; given a feature, you're a worker; leading other sessions, you're the manager. One session can move between them: a worker that finishes its feature and starts discussing an idea with the human is in a brainstorm now.

## Outside the path

Some skills and tools serve any step: `rpi:create_handoff` and `rpi:resume_handoff` pause a session and pick it up later; `rpi:sessions` and `session2md` read an earlier session; `rpi:document-code` decides on comments; `rpi:thoughts_init` links a repository or a new clone to thoughts.

## Leading someone new to rpi

When your human doesn't know the process yet, lead it and help them learn it. Leading means owning the course, not the decisions:

- **Open it:** frame the problem with them and propose what has to be decided.
- **Keep the agenda:** the open questions and the ones set aside, where you are and what comes next, said without waiting to be asked.
- **Drive it to a close:** when nothing is left open, propose the next step: the tickets, then the work.
- **Adapt to them:** explain each step in a sentence as you reach it; with someone who knows the process, follow their lead instead.

The decisions stay theirs.
