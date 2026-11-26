---
name: copilot-assisted-feature-delivery
description: Finish a pull request with Copilot as its reviewer, from marking it ready to the merge. Use when the repository's CLAUDE.md or the human says a pull request is finished with Copilot.
---

# Copilot-assisted feature delivery

The implementation is written; this loop brings the pull request to the merge with Copilot as its reviewer. You know this code better than Copilot does, so its review is advice to weigh, not a gate to pass. Copilot is valuable even when it's wrong: a wrong claim still points at a place worth a second look.

## Weighing a finding

Each finding is a claim to verify against the code.

- **A claim that's right is fixed:** a real defect, a real risk, or a small point within the feature's scope.
- **A claim that's wrong, a nitpick, a style point or a speculative edge case gets one reply** in its thread, a line saying why the code stays and pointing to the evidence.

Every push of fixes brings a new review, and every review finds new small points. Fixing those round after round costs hours and buys nothing; weighing each finding on its merits is what lets the loop end.

## The loop

Repositories differ. In some, Copilot reviews a pull request on its own once it's marked ready; in some, only when asked; in some, it isn't available at all, and then this loop doesn't apply. So right after marking the pull request ready, see whether its review was requested: `gh pr view <number> --json reviewRequests,reviews`. When Copilot is in neither, request it as in step 6; a wait on a review nobody requested never ends.

1. **Mark the pull request ready.**
2. **Start a Monitor for Copilot's new review comments on the pull request,** and let it wake you when they arrive.
3. **Verify every finding against the code** and decide, as above, whether it's fixed or declined.
4. **Fix what you accepted, and push.**
5. **Close every thread.** A fixed finding gets a reply naming the fix, a declined one its reason; then the thread is resolved. An open thread reads as an unanswered finding to whoever looks next, the human included.
6. **Ask Copilot to review again:** `gh pr edit <number> --add-reviewer copilot-pull-request-reviewer`, and go back to step 2.
7. **The loop ends when Copilot's review recommends merging.**

A pull request that conflicts with its base branch gets neither a CI run nor a review, so a wait on it never ends. Before every wait, check `gh pr view <number> --json mergeable --jq .mergeable`: `MERGEABLE`, `CONFLICTING`, or `UNKNOWN` (still computing; ask again in a few seconds). On `CONFLICTING`, merge the base branch in with a merge commit, push, and only then wait.

When Copilot keeps raising new small points round after round, decide with the human when the pull request is done: through the manager when it leads your work, directly when you're talking with them. Copilot helps; the decision is yours and the human's.

## The merge

When the repository or the human asks for a person's review, it comes now: the agents have already brought the pull request in order, so the person's attention goes to what only they can judge. What they point out is fixed. Then merge as the repository's `CLAUDE.md` says: a squash, with the pull request's title and body.
