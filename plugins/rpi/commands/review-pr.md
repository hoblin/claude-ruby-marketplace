---
description: Multi-agent PR review for Rails - spawns parallel subagents for comprehensive code review
---

# PR Review Committee

Multi-agent review system for Ruby on Rails pull requests. Gathers context from ticket and historical knowledge, spawns five parallel review subagents, then presents unified findings for confirmation before posting.

## Input Format

```
/rpi:review-pr [mode] [PR] [additional instructions]
```

- **mode** (optional): `review` (default), `re-review`, or `self-review`
- **PR**: PR number or link (required)
- **additional instructions** (optional): file exclusions, focus areas, or any custom guidance

Examples:
```
/rpi:review-pr #1234
/rpi:review-pr re-review #1234
/rpi:review-pr self-review #1234
/rpi:review-pr #1234 exclude config/locales and .yml files
/rpi:review-pr re-review #1234 skip rails guru because it is not a rails project
```

## Process

### Step 1: Gather PR Metadata

```bash
gh pr view <PR_NUMBER> --json number,title,body,url,headRefName,baseRefName
```

Extract from PR body:
- **Ticket reference** (e.g., ENG-123, PROJ-456) — if found, fetch full ticket details for requirements and acceptance criteria
- **Business context** — why this change is needed

If re-review mode is activated, also save all existing review feedback to `/tmp/`:
```bash
# Review verdicts and bodies (APPROVED, CHANGES_REQUESTED, COMMENTED)
gh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/reviews > /tmp/pr_<NUMBER>_reviews.json

# Inline review comments on specific diff lines
gh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/comments > /tmp/pr_<NUMBER>_inline_comments.json

# Conversation-level comments
gh api repos/<OWNER>/<REPO>/issues/<PR_NUMBER>/comments > /tmp/pr_<NUMBER>_conversation.json
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
git diff $BASE -- . ':(exclude)config/locales' ':(exclude)*.yml' > /tmp/pr_<NUMBER>_diff.txt

# Include only specific directories
git diff $BASE -- app/models/ app/services/ spec/ > /tmp/pr_<NUMBER>_diff.txt

# Combine inclusion with exclusion
git diff $BASE -- app/ spec/ ':(exclude)spec/fixtures' > /tmp/pr_<NUMBER>_diff.txt
```

Verify the diff is non-empty: `wc -l < /tmp/pr_<NUMBER>_diff.txt`

### Step 3: Gather Historical Context

Spawn the **thoughts-analyzer** subagent to find historical knowledge about affected features.

```
subagent_type: rpi:thoughts-analyzer

Prompt: "Find relevant historical context for reviewing this feature.

## Ticket
<ticket reference, title, description, acceptance criteria from Step 1>

Search thoughts/ for plans, research, and decisions related to this feature. Extract key decisions, constraints, trade-offs, and technical specs that reviewers should know."
```

**Wait for this subagent to complete before proceeding.**

### Step 4: Spawn Review Subagents

Spawn all five review subagents **in parallel** using the Task tool with `subagent_type: Explore`. Each receives:
- Path to the diff file in `/tmp/`
- Ticket context (from Step 1)
- Historical context (from Step 3)
- Their specific review focus
- Any additional instructions from the user's input

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

Output: List findings tagged [major], [minor], or [nit] with file:line references."
```

#### Subagent 2: SecurityHawk

```
Prompt: "Review PR #<number> for security vulnerabilities.

Read the diff from: /tmp/pr_<number>_diff.txt

*Critical:* Activate the activerecord:activerecord skill for SQL injection prevention patterns.

## Ticket Context
<ticket title, acceptance criteria, business context>

## Historical Context
<output from thoughts-analyzer>

<any additional instructions from user input>

## Focus Areas
- SQL injection (raw queries, interpolation in where clauses)
- XSS vulnerabilities (unescaped output, html_safe misuse)
- CSRF protection gaps
- Mass assignment vulnerabilities (permit params)
- Authentication/authorization bypasses
- Secrets or credentials in code
- Insecure direct object references

Output: List findings tagged [major], [minor], or [nit] with file:line references."
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

Output: List findings tagged [major], [minor], or [nit] with file:line references."
```

### Step 5: Merge Results

After all subagents complete, compile findings into a unified review:

1. **Group by severity** — [major] first, then [minor], then [nit]
2. **Remove duplicates** — Multiple agents may flag the same issue
3. **Add actionable suggestions** — Include code snippets where helpful
4. **Preserve file:line references** — Format as `app/models/user.rb:42`

Determine verdict:
- **REQUEST_CHANGES** — If any [major] or multiple [minor] issues exist
- **APPROVE** — If no significant issues found

### Step 6: Finalize

If self-review mode is activated, skip to **Self-review** below.

#### Present and Post (review / re-review)

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

#### Self-review

Instead of presenting and posting, act on the findings:

1. **Fix findings** — Address [major] and [minor] issues directly in code. Apply [nit]s at own discretion.
2. **Commit and push** — Commit the fixes with a descriptive message and push to the PR branch.
3. **Assign reviewer** — Assign the user and request review from anyone mentioned in additional instructions.
4. **Wait for CI** — Monitor CI status. Once green, mark the PR as ready for review.

```bash
gh pr edit <PR_NUMBER> --add-assignee <user> --add-reviewer <reviewer>
# once CI is green:
gh pr ready <PR_NUMBER>
```

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
