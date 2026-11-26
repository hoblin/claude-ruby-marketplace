---
name: self-reviewed-feature-delivery
description: Finish a pull request through blind self-review by reviewer subagents, from the first review to the merge. Use when the repository's CLAUDE.md or the human says a pull request is finished with self-review.
---

# Self-reviewed feature delivery

The implementation is written; this loop brings the pull request to the merge with reviewer subagents, run by `rpi:review-pr` in its self-review mode. They read the change cold, without the decisions and reasons you carry, so their review is advice to weigh, not a gate to pass. That same blindness is their value: free of your assumptions, they see what you've stopped seeing, and even a wrong finding points at a place worth a second look. With the review skill you verify each finding against the code and fix what you accept.

## The reviewers

Each reviewer reads the diff, the ticket and the history, and nothing of yours. A reviewer told what to look for, or what another reviewer found, sees through your eyes and misses what you missed. When the repository's `CLAUDE.md` names the reviewers for a change, run those, and give each generic reviewer only its own domain and focus, without introducing any bias or passing on your assumptions.

## The loop

The pull request stays a draft until the loop ends.

1. **Run `/rpi:review-pr self-review <number>`.** One pass reviews the change, judges the findings, fixes what you accept and pushes. Put a Monitor on CI and go on to the next pass; a CI failure reaches you through it.
2. **Run it again with only the reviewers whose findings you fixed,** and repeat. A reviewer that found a problem focused on it and may have passed over others; with that problem fixed, a fresh blind pass reads the change without the focus it gave itself.
3. **The loop ends when a pass leaves no finding you accept.**

A pull request that conflicts with its base branch gets no CI run, so a wait on it never ends. Before every wait, check `gh pr view <number> --json mergeable --jq .mergeable`: `MERGEABLE`, `CONFLICTING`, or `UNKNOWN` (still computing; ask again in a few seconds). On `CONFLICTING`, merge the base branch in with a merge commit, push, and only then wait.

## The merge

Mark the pull request ready (`gh pr ready <number>`) and put a Monitor on CI. When the repository or the human asks for a person's review, it comes now, while CI runs: the agents have already brought the pull request in order, so the person's attention goes to what only they can judge. What they point out is fixed. The merge waits for both: a green CI and, when a person reviews, their approval. Then merge as the repository's `CLAUDE.md` says: a squash, with the pull request's title and body.
