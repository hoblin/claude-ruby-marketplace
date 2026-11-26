---
name: gh-issue
description: Write a GitHub issue that hands the human's decisions to the worker who will deliver them. Use when creating or editing an issue, with gh issue create or otherwise, and when turning a brainstorm's decisions into tickets.
---

# GitHub issue

A ticket hands what the human decided to the worker who will deliver it, someone who wasn't in the conversation. It answers three questions for that reader: WHAT problem are we solving, WHY does it matter, and HOW will we solve it. HOW is the approach that was decided, in business logic and architecture. Implementation details are for the worker to decide: a senior engineer who finds them in the code, the documentation and what the framework offers, so the ticket leaves them out.

## What it holds

- **Required reading first.** The ticket opens with the records the worker reads before starting: the design note where the project has one, then the brainstorm, naming the sections the ticket rests on. It points to them and restates neither.
- **The problem**, from the side of the people and the system it affects: what's missing or hurting, and why it matters. Stated rightly, it still stands when the solution is rejected. A ticket born from a brainstorm opens with the problem the brainstorm opened with.
- **The solution:** the approach that was decided.
- **The decisions no record holds,** each with its reason. A choice whose reason isn't obvious gets its own "Why …?" section; one nobody would question gets none.
- **What's particular to this work,** such as a base branch other than the default.

## Only what was decided

Every line is a decision the human made or a fact you checked. Writing the ticket, you meet details the conversation never touched. A detail about what the system should do goes back to the human as an open question: an open question in a ticket is an unfinished brainstorm. An implementation detail is for the worker to decide, and the ticket doesn't mention it. An assumption, the human's or your own, is marked as one. These rules exist because a detail you fill in yourself reaches the worker as the human's decision, and the worker builds what nobody asked for.

## Labels

A label says how far a ticket was thought through:

- `decided`: discussed with the human, no open questions; ready to hand out.
- `agent-filed`: an agent filed it on its own, with no human decision behind it; material for a decision, triaged with the human.
- `audit`: a focused sweep of one aspect across the project.

What counts is whether a human decided it, not who typed it: a ticket written down from a discussion with the human, with no open questions left, is `decided`. A label the repository lacks is created with `gh label create`.

## Title

What the work does, under 70 characters: "Add a due-date filter to list_issues".

## Changing a ticket

The body is edited only until someone starts working on it. Once implementation has begun, a change to the requirements goes in as a comment that says what changed and why. The worker builds from the body as it read it: a body rewritten behind its back moves the goal unseen, while a comment shows a change of requirements as one.

## Publishing

The issue goes out under the human's name, so it's signed `[<model>] on behalf of <their username>`: at the end of the body, and as a prefix on a comment.

```bash
gh issue create --title "<title>" --label decided --body-file <file>
gh issue edit <number> --body-file <file>
gh issue comment <number> --body-file <file>

# Attach issue 42 as a sub-issue of 36: the API takes the global id, not the number
gh api repos/OWNER/REPO/issues/36/sub_issues -X POST -F sub_issue_id=$(gh api repos/OWNER/REPO/issues/42 --jq '.id')
```
