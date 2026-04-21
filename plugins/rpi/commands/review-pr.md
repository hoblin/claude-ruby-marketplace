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

Wait for ticket details before proceeding — "Step 4: Gather Historical Context" needs the ticket context to ask the right questions.

### Step 4: Gather Historical Context

Spawn the **thoughts-analyzer** subagent to find historical knowledge about affected features.

```
subagent_type: rpi:thoughts-analyzer

Prompt: "What do we know about <ticket reference and title from "Step 3: Fetch Original Ticket">? What decisions, constraints, and trade-offs should reviewers be aware of?"
```

**Wait for this subagent to complete, then proceed to "Step 5-a: Spawn Review Subagents".**

### Step 5-a: Spawn Review Subagents

If address-feedback mode is activated, skip to "Step 5-b: Spawn Codebase Research Subagents (address-feedback)" below.

Spawn all five review subagents **in parallel** using the Task tool with `subagent_type: Explore`. Each receives:
- Path to the diff file in `/tmp/`
- Ticket context (from "Step 1: Gather PR Metadata")
- Historical context (from "Step 4: Gather Historical Context")
- Their specific review focus
- Any additional instructions from the user's input
- Verification discipline: before claiming code is missing, grep or read to verify absence; before citing a line as problematic, read its context. Every "X is missing" or "X is broken" finding must include the exact search performed.

If re-review mode is activated, each subagent also receives the paths to `/tmp/pr_<NUMBER>_reviews.json`, `/tmp/pr_<NUMBER>_inline_comments.json`, and `/tmp/pr_<NUMBER>_conversation.json` with this modified instruction: "Primary goal: verify that previously requested changes were addressed. Secondary goal: check for new problems introduced."

**Critical:** Send a single message with all five Task tool calls to ensure parallel execution.

#### Subagent 1: RailsGuru

```
Prompt: "Review PR #<number> for Rails conventions and architecture.

Read the diff from: /tmp/pr_<number>_diff.txt

*Critical:* Activate the activerecord:activerecord skill for AR patterns reference.

## Ticket Context
<ticket title, acceptance criteria, business context>

## Historical Context
<output from thoughts-analyzer>

<any additional instructions from user input>

## Focus Areas
- MVC boundary violations (fat controllers, logic in views)
- Rails idioms (proper use of scopes, callbacks, concerns)
- REST conventions and route design
- ActiveRecord patterns (associations, validations placement)
- Service object patterns and naming
- Security-adjacent AR patterns: raw SQL interpolation, mass assignment gaps, missing tenant/org scoping on shared-model queries

Output: List findings tagged [major], [minor], or [nit] with file:line references."
```

#### Subagent 2: TicketDelivery

```
Prompt: "Your role: verify this PR delivers the ticket. Code-quality subagents judge how the work was done; you judge whether the work was done.

Read the diff from: /tmp/pr_<number>_diff.txt

The ticket defines 'done'. The PR description is how the author frames their work — useful context, not authority. When the two disagree, the ticket wins and the disagreement itself is a finding.

## Ticket (verbatim — do not summarize)
<full ticket title, description, every Task, every Acceptance Criterion>

## PR description (verbatim)
<PR body from Step 1>

## Historical Context
<output from thoughts-analyzer>

<any additional instructions from user input>

## How to work

Map each requirement in the ticket — Tasks, Acceptance Criteria, named targets — to evidence in the diff. For each, produce one line: ✅ delivered, ⚠️ partial, or ❌ missing, with file:line references.

A requirement is delivered when the code does what the ticket asked for in meaning, not merely in mention. Match semantics against the ticket's verbs: 'add Y' needs Y; 'replace X with Y' needs Y and no X. When the ticket lists multiple targets, verify each separately.

Output: the verification table first. Then findings tagged [major] (requirement not delivered), [minor] (partial delivery), [nit] (scope drift / advisory)."
```

#### Subagent 3: PerfPro

```
Prompt: "Review PR #<number> for performance issues.

Read the diff from: /tmp/pr_<number>_diff.txt

*Critical:* Activate the activerecord:activerecord skill for N+1 and query optimization patterns.
*Critical:* Activate the appsignal-perf skill for performance monitoring insights.

## Ticket Context
<ticket title, acceptance criteria, business context>

## Historical Context
<output from thoughts-analyzer>

<any additional instructions from user input>

## Focus Areas
- N+1 query patterns (missing includes/preload/eager_load)
- Expensive queries in loops
- Missing database indexes for new queries
- Inefficient ActiveRecord usage (pluck vs select, find_each vs each)
- Memory bloat (loading large datasets)
- Missing caching opportunities
- Background job considerations (should this be async?)
- Cross-tenant data leakage in aggregation (missing organization_id scope on joins, unscoped WHERE in reports)

Output: List findings tagged [major], [minor], or [nit] with file:line references."
```

#### Subagent 4: TestCoach

```
Prompt: "Review PR #<number> for test quality and coverage.

Read the diff from: /tmp/pr_<number>_diff.txt

*Critical:* Activate the rspec:rspec skill for RSpec best practices reference.

## Ticket Context
<ticket title, acceptance criteria, business context>

## Historical Context
<output from thoughts-analyzer>

<any additional instructions from user input>

## Focus Areas
- Missing test coverage for new code paths
- Flaky test patterns (time-dependent, order-dependent)
- Factory usage (proper traits, avoiding create when build suffices)
- Test isolation issues (shared state, missing cleanup)
- Assertion quality (testing behavior vs implementation)
- Missing edge case coverage
- Missing coverage for authorization boundaries (cross-org access denial, role-based access denied, unauthenticated request rejected)

Output: List findings tagged [major], [minor], or [nit] with file:line references."
```

#### Subagent 5: DocScribe

```
Prompt: "Review PR #<number> for documentation and clarity.

Read the diff from: /tmp/pr_<number>_diff.txt

## Ticket Context
<ticket title, acceptance criteria, business context>

## Historical Context
<output from thoughts-analyzer>

<any additional instructions from user input>

## Focus Areas
- Method and class naming clarity
- Missing YARD documentation on public interfaces
- Complex logic lacking explanatory comments
- Changelog updates for notable changes
- Misleading or outdated comments
- Magic numbers or strings needing constants
- Secrets, tokens, or credentials appearing in logs, comments, error messages, or test fixtures; permission-gating magic constants that should be named

Output: List findings tagged [major], [minor], or [nit] with file:line references."
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

### Step 7: Present Review (review / re-review)

If self-review or address-feedback mode is activated, skip to "Step 8: Apply Fixes".

Present the merged review to the user, including:
- PR reference and ticket (if found)
- Determined verdict
- All findings grouped by severity

Use the AskUserQuestion tool to confirm: "Shall I post this review to the PR? [Yes/Edit/Cancel]"
- **Yes** — post the review
- **Edit** — let the user modify the review, then ask again
- **Cancel** — discard

Once confirmed, post the review:

```bash
gh pr review <PR_NUMBER> --approve --body "<review body>"
# or
gh pr review <PR_NUMBER> --request-changes --body "<review body>"
```

### Step 8: Apply Fixes (self-review / address-feedback)

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
