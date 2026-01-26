---
description: Multi-agent PR review for Rails - spawns parallel subagents for comprehensive code review
---

# PR Review Committee

Multi-agent review system for Ruby on Rails pull requests. Spawns five parallel subagents, each focused on a specific review domain, then merges findings into a unified review.

## Process

### Step 1: Get the Diff

Obtain the PR diff using one of these methods:

```bash
# If PR number is known
gh pr diff <PR_NUMBER>

# If reviewing current branch against base
git diff origin/master...HEAD

# If reviewing staged changes
git diff --cached
```

### Step 2: Spawn Review Subagents

Spawn all five subagents **in parallel** using the Task tool with `subagent_type: Explore`. Each subagent receives the diff and its specific review focus.

**Critical:** Send a single message with all five Task tool calls to ensure parallel execution.

#### Subagent 1: RailsGuru

```
Prompt: "Review this Rails PR diff for conventions and architecture.

IMPORTANT: Activate the activerecord:activerecord skill for AR patterns reference.

Focus areas:
- MVC boundary violations (fat controllers, logic in views)
- Rails idioms (proper use of scopes, callbacks, concerns)
- REST conventions and route design
- ActiveRecord patterns (associations, validations placement)
- Service object patterns and naming

Diff:
<paste diff here>

Output: List findings tagged [major], [minor], or [nit] with file:line references."
```

#### Subagent 2: SecurityHawk

```
Prompt: "Review this Rails PR diff for security vulnerabilities.

IMPORTANT: Activate the activerecord:activerecord skill for SQL injection prevention patterns.

Focus areas:
- SQL injection (raw queries, interpolation in where clauses)
- XSS vulnerabilities (unescaped output, html_safe misuse)
- CSRF protection gaps
- Mass assignment vulnerabilities (permit params)
- Authentication/authorization bypasses
- Secrets or credentials in code
- Insecure direct object references

Diff:
<paste diff here>

Output: List findings tagged [major], [minor], or [nit] with file:line references."
```

#### Subagent 3: PerfPro

```
Prompt: "Review this Rails PR diff for performance issues.

IMPORTANT: Activate the activerecord:activerecord skill for N+1 and query optimization patterns.
IMPORTANT: Activate the appsignal-perf skill for performance monitoring insights.

Focus areas:
- N+1 query patterns (missing includes/preload/eager_load)
- Expensive queries in loops
- Missing database indexes for new queries
- Inefficient ActiveRecord usage (pluck vs select, find_each vs each)
- Memory bloat (loading large datasets)
- Missing caching opportunities
- Background job considerations (should this be async?)

Diff:
<paste diff here>

Output: List findings tagged [major], [minor], or [nit] with file:line references."
```

#### Subagent 4: TestCoach

```
Prompt: "Review this Rails PR diff for test quality and coverage.

IMPORTANT: Activate the rspec:rspec skill for RSpec best practices reference.

Focus areas:
- Missing test coverage for new code paths
- Flaky test patterns (time-dependent, order-dependent)
- Factory usage (proper traits, avoiding create when build suffices)
- Test isolation issues (shared state, missing cleanup)
- Assertion quality (testing behavior vs implementation)
- Missing edge case coverage

Diff:
<paste diff here>

Output: List findings tagged [major], [minor], or [nit] with file:line references."
```

#### Subagent 5: DocScribe

```
Prompt: "Review this Rails PR diff for documentation and clarity.

Focus areas:
- Method and class naming clarity
- Missing YARD documentation on public interfaces
- Complex logic lacking explanatory comments
- Changelog updates for notable changes
- Misleading or outdated comments
- Magic numbers or strings needing constants

Diff:
<paste diff here>

Output: List findings tagged [major], [minor], or [nit] with file:line references."
```

### Step 3: Merge Results

After all subagents complete, compile findings into a unified review:

1. **Group by severity** - [major] first, then [minor], then [nit]
2. **Remove duplicates** - Multiple agents may flag the same issue
3. **Add actionable suggestions** - Include code snippets where helpful
4. **Preserve file:line references** - Format as `app/models/user.rb:42`

### Step 4: Deliver Verdict

End the review with one of:
- **"Changes requested"** - If any [major] or multiple [minor] issues exist
- **"Approved with suggestions"** - If only [minor] issues or [nit]s remain
- **"Approved"** - If no significant issues found

## Output Format

```markdown
# PR Review: [Branch Name or PR Title]

## Major Issues
- [major] `app/models/user.rb:42` - SQL injection via string interpolation in where clause
  ```ruby
  # Instead of:
  User.where("name = '#{params[:name]}'")
  # Use:
  User.where(name: params[:name])
  ```

## Minor Issues
- [minor] `app/controllers/users_controller.rb:15` - Business logic belongs in model or service

## Suggestions
- [nit] `app/services/user_service.rb:8` - Consider more descriptive method name

---
**Verdict: Changes requested**
```

## Guidelines

- Reference code lines as `file_path:line_number`
- Focus only on changed lines, not surrounding unchanged code
- Provide concrete fix suggestions for [major] issues
- Keep findings concise and actionable
