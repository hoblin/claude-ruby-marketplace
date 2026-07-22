---
description: Multi-agent PR review with four modes (review, re-review, self-review, address-feedback) - spawns parallel subagents, saves diff to /tmp for context efficiency, supports file exclusion patterns
---

## Input Format

```
/rpi:review-pr [mode] [PR] [additional instructions]
```

- **mode** (optional): `review` (default), `re-review`, `self-review`, or `address-feedback`
- **PR**: PR number or link (required)
- **additional instructions** (optional): file exclusions, focus areas, or any custom guidance

Examples:
```
/rpi:review-pr #1234
/rpi:review-pr re-review #1234
/rpi:review-pr self-review #1234
/rpi:review-pr address-feedback #1234
/rpi:review-pr #1234 exclude config/locales and .yml files
/rpi:review-pr re-review #1234 skip rails guru because it is not a rails project
```

## Process

Your role is **orchestrator and judge**, not doer. You collect artifacts, delegate analysis to subagents, and apply judgment to their output. The subagents read the code and comments — you decide what to do about their findings. Your context budget is reserved for judgment, not for reading raw data.

Steps are sequential — later steps depend on earlier results. Complete each step and wait for its results before starting the next. Skipping ahead without subagent results means the judgment layer in "Step 6: Merge Results" has nothing to work with. Only parallelize where explicitly marked (e.g., "spawn in parallel").

### Step 1: Gather PR Metadata

```bash
gh pr view <PR_NUMBER> --json number,title,body,url,headRefName,baseRefName
```

If re-review or address-feedback mode is activated, also save all existing review feedback to `/tmp/`:

**Do not read these files — pass them to subagents by path only.** The subagents will read and analyze the content. Reading them here would consume context budget that the main agent needs for judgment in "Step 6: Merge Results".
```bash
# Review verdicts and bodies (APPROVED, CHANGES_REQUESTED, COMMENTED)
gh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/reviews \
  --jq '[.[] | {id, state, body, html_url, commit_id, submitted_at, author_association, user: .user.login}]' \
  | tee /tmp/pr_<NUMBER>_reviews.json | jq length

# Inline review comments on specific diff lines
gh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/comments \
  --jq '[.[] | {id, pull_request_review_id, body, path, line, start_line, side, diff_hunk, commit_id, created_at, author_association, in_reply_to_id, user: .user.login}]' \
  | tee /tmp/pr_<NUMBER>_inline_comments.json | jq length

# Conversation-level comments
gh api repos/<OWNER>/<REPO>/issues/<PR_NUMBER>/comments \
  --jq '[.[] | {id, body, html_url, created_at, updated_at, author_association, user: .user.login}]' \
  | tee /tmp/pr_<NUMBER>_conversation.json | jq length
```

If `toon` is available, pipe each extraction through it and save as `.txt` instead — token-efficient artifacts, and every subagent that reads them benefits. Note the sanity check changes with the format: toon output is not JSON, so end the pipeline with `| tee /tmp/pr_<NUMBER>_reviews.txt | wc -l` instead of `| jq length`.

### Step 2: Fetch and Save Diff

Checkout the PR branch locally and generate the diff. Save it to `/tmp/` — only subagents will read it.

```bash
git fetch origin
git checkout <branch>

# Use merge-base for a clean diff (handles diverged base branch)
BASE=$(git merge-base origin/<baseRefName> HEAD)
git diff $BASE -- . > /tmp/pr_<NUMBER>_diff.txt
```

If the user provided file exclusion or inclusion patterns in additional instructions, apply them using git's pathspec syntax:

```bash
# Exclude specific paths
git diff $BASE -- . ':(exclude)path/to/noisy/dir' ':(exclude)*.ext' > /tmp/pr_<NUMBER>_diff.txt

# Include only specific directories
git diff $BASE -- path/to/dir1/ path/to/dir2/ > /tmp/pr_<NUMBER>_diff.txt

# Combine inclusion with exclusion
git diff $BASE -- path/to/dir/ ':(exclude)path/to/dir/subdir' > /tmp/pr_<NUMBER>_diff.txt
```

Verify the diff is non-empty: `wc -l < /tmp/pr_<NUMBER>_diff.txt`

### Step 3: Fetch Original Ticket

The PR references the original ticket (e.g., ENG-123, PROJ-456). Fetch full ticket details — requirements and acceptance criteria define what "correct" looks like for this change. You can't review a feature without knowing what was in the task description before it was implemented.

Save the ticket **verbatim** to `/tmp/pr_<NUMBER>_ticket.md` — full title, description, every Task, every Acceptance Criterion, plus the ticket comments. Do not summarize, annotate, or reorder it: a paraphrase is where your conclusions leak into the reviewers' inputs, and a reviewer fed conclusions ratifies them instead of auditing the code.

Wait for ticket details before proceeding — "Step 4: Gather Historical Context" needs the ticket context to ask the right questions.

### Step 4: Gather Historical Context

Spawn the **thoughts-analyzer** subagent to find historical knowledge about affected features.

```
subagent_type: rpi:thoughts-analyzer

Prompt: "What do we know about <ticket reference and title from "Step 3: Fetch Original Ticket">? What decisions, constraints, and trade-offs should reviewers be aware of?"
```

The harness saves the subagent's report to a task output file and shows the path when it completes — note that path. It is the historical-context artifact you pass to reviewers. If no path was surfaced (the report came back inline), save it verbatim to `/tmp/pr_<NUMBER>_context.md` yourself. Either way the artifact is a copy, never a rewrite: a re-summary is exactly where your conclusions leak in.

**Wait for this subagent to complete, then proceed to "Step 5-a: Spawn Review Subagents".**

### Step 5-a: Spawn Review Subagents

If address-feedback mode is activated, skip to "Step 5-b: Spawn Codebase Research Subagents (address-feedback)" below.

Spawn the review subagents **in parallel** using the Task tool, each by its own `subagent_type` from the roster below. Their review instructions live in their agent definitions — you hand each one **paths and parameters only**:

- PR number
- Path to the diff file: `/tmp/pr_<NUMBER>_diff.txt`
- Path to the ticket artifact: `/tmp/pr_<NUMBER>_ticket.md`
- Path to the historical-context artifact: the thoughts-analyzer task output file from "Step 4: Gather Historical Context"
- Any additional instructions from the user's input (if any), passed through verbatim

**Why subagents review at all: they are fresh eyes.** Each reviewer arrives with zero knowledge of this PR beyond its own charter — that absence of bias is exactly what finds the gaps and blind spots you've already rationalized past. **Never add interpretation, summaries, or framing** — no "this looks consistent with…", no digest of what the metadata showed you. A reviewer fed your conclusions ratifies them instead of auditing the code; the bare prompt is what keeps the eyes fresh.

If re-review mode is activated, each subagent also receives the paths to `/tmp/pr_<NUMBER>_reviews.json`, `/tmp/pr_<NUMBER>_inline_comments.json`, and `/tmp/pr_<NUMBER>_conversation.json` (or `.txt` when `| toon` was applied at extraction — prefer token-efficient artifact formats) — receiving prior-feedback paths is what tells a reviewer it is a re-review; no mode flag is needed.

**Spawn every reviewer whose domain exists in this repo — coverage is the point.** The full roster is the default; an omission needs a reason: the test-framework twin that doesn't apply (`rpi:review-tests-rspec` for RSpec repos, `rpi:review-tests-minitest` for minitest repos — pick the one matching the stack, never both), a domain genuinely absent from the repo (no Rails reviewer in a non-Rails project), or an explicit user skip. Never trim the roster for brevity or token thrift — an unreviewed domain is a silent LGTM.

**No expert for a domain in the diff? Spawn the generalist.** When the stack includes a domain no expert reviewer covers (say, a Python service in the diff), spawn `rpi:review-generic` with the domain and a focus list — scope only: what to look for, never what you expect it to find. Better a generic reviewer than an unreviewed domain.

**Critical:** Send a single message with all the Task tool calls to ensure parallel execution.

#### The reviewer roster

| `subagent_type` | Audits |
|---|---|
| `rpi:review-rails` | Rails conventions and architecture |
| `rpi:review-ticket-delivery` | whether the PR delivers the ticket (always runs; carries the security sweep) |
| `rpi:review-performance` | performance and cross-tenant leakage |
| `rpi:review-tests-rspec` | test quality and coverage (RSpec repos) |
| `rpi:review-tests-minitest` | test quality and coverage (minitest repos) |
| `rpi:review-docs` | documentation quality and clarity |
| `rpi:review-generic` | any domain in the diff with no expert reviewer (focus list from you) |

Example spawn — same shape for all:

```
subagent_type: rpi:review-rails

Prompt: "PR #<number>.
Diff: /tmp/pr_<number>_diff.txt
Ticket: /tmp/pr_<number>_ticket.md
Historical context: <thoughts-analyzer task output file path>
<re-review only — Reviews: /tmp/pr_<number>_reviews.json, Inline comments: /tmp/pr_<number>_inline_comments.json, Conversation: /tmp/pr_<number>_conversation.json>
<additional instructions from user input, verbatim>"
```

### Step 5-b: Spawn Codebase Research Subagents (address-feedback)

Unless address-feedback mode is activated, skip to "Step 6: Merge Results" below.

Spawn **rpi:codebase-analyzer** and **rpi:codebase-pattern-finder** in parallel. Each receives:
- Paths to comment files and diff file in `/tmp/`
- Historical context (from "Step 4: Gather Historical Context")
- Any additional instructions from the user's input

### Step 6: Merge Results

After all subagents complete, compile findings into a unified review.

**Critical: Subagents are pattern matchers. You are the judgment layer.** Subagents are designed to be paranoid and thorough — they flag everything that matches their heuristics. Your job is to filter their output, not rubber-stamp it. A [major] from a subagent can become a [nit] or be dropped entirely after applying judgment.

For each concern, evaluate:
- **Real-world probability** — Can this actually happen in practice, or is it purely theoretical? A race condition that requires two users to open a personal link within the same millisecond is not a real issue.
- **Cost-benefit** — Does the fix add more complexity than the problem warrants? If the "fix" makes the code harder to read without solving a problem a human would encounter, drop it.
- **Scope** — Review fixes should improve code you're touching, not introduce new artifacts. Clean up, don't build out.
- **Design intent** — Was this a deliberate choice? A concern that flags a conscious trade-off documented in historical context is a decline, not a fix.
- **Precedent** — "Existing code does the same" declines nothing on its own: a precedent does not legitimize an antipattern, it locates another instance of it. Legitimacy comes from documented standards, not recurrence.

Then classify:
- **Accept & fix** — concern valid, apply the suggested fix or a better one
- **Accept, different approach** — concern valid, but context points to a different solution
- **Decline** — not valid in context, or a deliberate design choice

Then compile:

1. **Group by severity** — [major] first, then [minor], then [nit]
2. **Remove duplicates** — Multiple sources may flag the same issue
3. **Add actionable suggestions** — Include code snippets where helpful
4. **Preserve file:line references** — Format as `app/models/user.rb:42`

Determine verdict:
- **REQUEST_CHANGES** — If any [major] or multiple [minor] concerns are accepted
- **APPROVE** — If no significant concerns survive the judgment filter

In re-review, REQUEST_CHANGES when a previously requested change is unaddressed or a new [major] is accepted. A couple of new [minor]/[nit] findings don't restart the cycle — carry them in the review body as non-blocking suggestions. (A pile-up of accepted minors is judgment territory, as always.)

### Step 7: Present Review (review / re-review)

If self-review or address-feedback mode is activated, skip to "Step 9: Apply Fixes".

Present the merged review to the user, including:
- PR reference and ticket (if found)
- Determined verdict
- All findings grouped by severity

### Step 8: Confirm and Post (review / re-review)

Use the AskUserQuestion tool to confirm: "Shall I post this review to the PR? [Yes/Edit/Cancel]"
- **Yes** — post the review
- **Edit** — let the user modify the review, then ask again
- **Cancel** — discard

If the verdict is APPROVE and nothing in the gathered artifacts blocks delivery (no "don't merge until…" notes, dependent PRs, or coordinated-deploy requirements in the ticket, reviews, or findings), include a fourth option: **Approve & merge**.
- **Approve & merge** — post the approving review, then monitor `gh pr checks <PR_NUMBER> --watch`; when green, merge using the repository's convention (e.g. squash). If CI fails, stop and report — never merge red.

Once confirmed, post the review:

```bash
gh pr review <PR_NUMBER> --approve --body "<review body>"
# or
gh pr review <PR_NUMBER> --request-changes --body "<review body>"
```

### Step 9: Apply Fixes (self-review / address-feedback)

Your role changes from orchestrator to doer. You now have the judgment results — act on them.

1. **Fix concerns** — Address [major] and [minor] issues directly in code. Apply [nit]s at own discretion.
2. **Commit and push** — Commit the fixes with a descriptive message and push to the PR branch.
3. **Monitor CI** — Wait for CI to pass. The PR cannot be finalized until CI is green.

```bash
gh pr checks <PR_NUMBER> --watch
```

Fixes are pushed and CI is green. Now finalize the PR — proceed to the section matching your mode below.

#### Self-Review Finalization

Assign the user and request review from anyone mentioned in additional instructions. Then mark the PR as ready for human review.

```bash
gh pr edit <PR_NUMBER> --add-assignee <user> --add-reviewer <reviewer>
gh pr ready <PR_NUMBER>
```

Done when the PR is marked ready and appears in the reviewer's queue.

#### Address-Feedback Finalization

Reply to each reviewer comment on GitHub with the resolution:
- Accept & fix: "Fixed in `<commit sha>`."
- Accept, different approach: "Agreed with the concern. Took a different approach: [explanation]. Fixed in `<commit sha>`."
- Decline: "This was intentional — [rationale]."

```bash
# Reply to an inline comment
gh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/comments/<COMMENT_ID>/replies -f body="<reply>"

# Reply to a conversation-level comment
gh api repos/<OWNER>/<REPO>/issues/<PR_NUMBER>/comments -f body="<reply>"
```

Then request re-review from the original reviewers:

```bash
gh pr edit <PR_NUMBER> --add-reviewer <original_reviewer>
```

Done when all comments are answered and re-review is requested.

## Posted Review Format

```markdown
## PR Review Summary

**Verdict: REQUEST_CHANGES**

### Major Issues
- `app/models/user.rb:42` - SQL injection via string interpolation in where clause
  ```ruby
  # Instead of:
  User.where("name = '#{params[:name]}'")
  # Use:
  User.where(name: params[:name])
  ```

### Minor Issues
- `app/controllers/users_controller.rb:15` - Business logic belongs in model or service

### Suggestions
- `app/services/user_service.rb:8` - Consider more descriptive method name

---
*Review generated with multi-agent analysis*
```

## Guidelines

- Focus only on changed lines, not surrounding unchanged code
- Provide concrete fix suggestions for [major] issues
- The main agent must never read the diff file — only subagents read it
- Pass additional instructions from user input through to all subagents
