---
description: Multi-agent PR review for Rails - spawns parallel subagents for comprehensive code review
---

# PR Review Committee

Multi-agent review system for Ruby on Rails pull requests. Gathers context from ticket and historical knowledge, spawns five parallel review subagents, then presents unified findings for confirmation before posting.

## Process

### Step 1: Gather PR Context

```bash
# Get PR metadata, body, comments, and reviews
gh pr view <PR_NUMBER> --json number,title,body,url,comments,reviews

# Get the diff
gh pr diff <PR_NUMBER>
```

If no PR exists (local changes only): `git diff <base-branch>...HEAD` (adjust base branch as needed)

Extract from PR body:
- **Ticket reference** (e.g., ENG-123, PROJ-456) - if found, fetch ticket details for context
- **Acceptance criteria** - what the PR should accomplish
- **Business context** - why this change is needed

### Step 2: Gather Historical Context

Spawn the **thoughts-analyzer** subagent to find historical knowledge about affected features.

```
subagent_type: thoughts-analyzer

Prompt: "Analyze the thoughts directory for historical context related to this PR.

Files changed in PR:
<list of changed files>

Features affected:
<extracted from diff - models, controllers, services touched>

Find:
1. Previous implementation plans for these features
2. Past research documents about these areas
3. Known issues or technical debt documented
4. Architectural decisions that affect this code

Output: Summary of relevant historical context that reviewers should know."
```

**Wait for this subagent to complete before proceeding.**

### Step 3: Spawn Review Subagents

Spawn all five review subagents **in parallel** using the Task tool with `subagent_type: Explore`. Each receives:
- The diff
- Ticket context (from Step 1)
- Historical context (from Step 2)
- Their specific review focus

**Critical:** Send a single message with all five Task tool calls to ensure parallel execution.

#### Subagent 1: RailsGuru

```
Prompt: "Review this Rails PR diff for conventions and architecture.

IMPORTANT: Activate the activerecord:activerecord skill for AR patterns reference.

## Ticket Context
<ticket title, acceptance criteria, business context>

## Historical Context
<output from thoughts-analyzer>

## Focus Areas
- MVC boundary violations (fat controllers, logic in views)
- Rails idioms (proper use of scopes, callbacks, concerns)
- REST conventions and route design
- ActiveRecord patterns (associations, validations placement)
- Service object patterns and naming

## Diff
<paste diff here>

Output: List findings tagged [major], [minor], or [nit] with file:line references."
```

#### Subagent 2: SecurityHawk

```
Prompt: "Review this Rails PR diff for security vulnerabilities.

IMPORTANT: Activate the activerecord:activerecord skill for SQL injection prevention patterns.

## Ticket Context
<ticket title, acceptance criteria, business context>

## Historical Context
<output from thoughts-analyzer>

## Focus Areas
- SQL injection (raw queries, interpolation in where clauses)
- XSS vulnerabilities (unescaped output, html_safe misuse)
- CSRF protection gaps
- Mass assignment vulnerabilities (permit params)
- Authentication/authorization bypasses
- Secrets or credentials in code
- Insecure direct object references

## Diff
<paste diff here>

Output: List findings tagged [major], [minor], or [nit] with file:line references."
```

#### Subagent 3: PerfPro

```
Prompt: "Review this Rails PR diff for performance issues.

IMPORTANT: Activate the activerecord:activerecord skill for N+1 and query optimization patterns.
IMPORTANT: Activate the appsignal-perf skill for performance monitoring insights.

## Ticket Context
<ticket title, acceptance criteria, business context>

## Historical Context
<output from thoughts-analyzer>

## Focus Areas
- N+1 query patterns (missing includes/preload/eager_load)
- Expensive queries in loops
- Missing database indexes for new queries
- Inefficient ActiveRecord usage (pluck vs select, find_each vs each)
- Memory bloat (loading large datasets)
- Missing caching opportunities
- Background job considerations (should this be async?)

## Diff
<paste diff here>

Output: List findings tagged [major], [minor], or [nit] with file:line references."
```

#### Subagent 4: TestCoach

```
Prompt: "Review this Rails PR diff for test quality and coverage.

IMPORTANT: Activate the rspec:rspec skill for RSpec best practices reference.

## Ticket Context
<ticket title, acceptance criteria, business context>

## Historical Context
<output from thoughts-analyzer>

## Focus Areas
- Missing test coverage for new code paths
- Flaky test patterns (time-dependent, order-dependent)
- Factory usage (proper traits, avoiding create when build suffices)
- Test isolation issues (shared state, missing cleanup)
- Assertion quality (testing behavior vs implementation)
- Missing edge case coverage

## Diff
<paste diff here>

Output: List findings tagged [major], [minor], or [nit] with file:line references."
```

#### Subagent 5: DocScribe

```
Prompt: "Review this Rails PR diff for documentation and clarity.

## Ticket Context
<ticket title, acceptance criteria, business context>

## Historical Context
<output from thoughts-analyzer>

## Focus Areas
- Method and class naming clarity
- Missing YARD documentation on public interfaces
- Complex logic lacking explanatory comments
- Changelog updates for notable changes
- Misleading or outdated comments
- Magic numbers or strings needing constants

## Diff
<paste diff here>

Output: List findings tagged [major], [minor], or [nit] with file:line references."
```

### Step 4: Merge Results

After all subagents complete, compile findings into a unified review:

1. **Group by severity** - [major] first, then [minor], then [nit]
2. **Remove duplicates** - Multiple agents may flag the same issue
3. **Add actionable suggestions** - Include code snippets where helpful
4. **Preserve file:line references** - Format as `app/models/user.rb:42`

Determine verdict:
- **REQUEST_CHANGES** - If any [major] or multiple [minor] issues exist
- **COMMENT** - If only [minor] issues or [nit]s remain
- **APPROVE** - If no significant issues found

### Step 5: Present Review and Await Confirmation

Present the merged review to the user, including:
- PR reference and ticket (if found)
- Determined verdict
- All findings grouped by severity

Ask for confirmation: "Shall I post this review to the PR? [Yes/Edit/Cancel]"

### Step 6: Post Review via gh CLI

Once confirmed, post the review:

```bash
# For APPROVE
gh pr review <PR_NUMBER> --approve --body "<review body>"

# For COMMENT (suggestions only)
gh pr review <PR_NUMBER> --comment --body "<review body>"

# For REQUEST_CHANGES
gh pr review <PR_NUMBER> --request-changes --body "<review body>"
```

The review body should be formatted as clean markdown without the confirmation prompt.

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
- If user chooses "Edit", allow them to modify the review before posting
