## Command

```
/feature <FEATURE_DESCRIPTION> [--project <PROJECT_NAME>] [--type <feature|chore>]
```

## Context

Create and complete a new feature or chore for this Ruby on Rails project, from branch creation to PR readiness. Input can be a Linear issue URL or a plain description.

With Linear issue URL: Extract ID, fetch details via Linear MCP.
With description only: Create new Linear issue in the appropriate project.

## Workflow

### Step 1: Setup

Pull latest base branch (usually `main` or `master`)
Create feature branch: `<type>/<issue-id>-<short-description>` (e.g., `feature/eng-1234-add-api-endpoint`)
Update Linear ticket: assign to "me", change status to "In Progress"

### Step 2: Gather Historical Context

Spawn `rpi:thoughts-analyzer` with ticket reference, title, description, and acceptance criteria.

Wait for this subagent to complete before proceeding.

### Step 3: Research Codebase

Spawn research subagents in parallel, passing ticket info and historical context from Step 2:

`rpi:codebase-pattern-finder` - find similar implementations to model after
`rpi:codebase-analyzer` - analyze the area being modified

Wait for both subagents to complete before proceeding.

### Step 4: Implementation

Follow Rails best practices and CLAUDE.md.
Keep code clean, DRY, well-documented.
When modifying code: fix lurking bugs, refactor, add missing tests and regression tests.
Ensure solid RSpec coverage with well-documented business logic (viewable with `--format documentation`).
Review changes for completeness.

### Step 5: Testing & Quality

Run specs for changed/affected files only (never full suite locally): `bundle exec rspec spec/path/to/changed_spec.rb`
`bundle exec reek` – Code smell detection
`bundle exec standardrb --fix`
`npx @herb-tools/linter --fix app/views/**/*.erb` (if views changed)
Fix all issues, even flaky tests.

### Step 6: Translations (i18n)

`bundle exec i18n-tasks missing` – Check for missing translations
`bundle exec i18n-tasks normalize` – Normalize locale files
Add missing translations (manually or via OpenAI)

### Step 7: Pull Request

Push branch.
`gh pr create --draft`
Title: `<issue-id> feat: <description>` or `<issue-id> chore: <description>` or `<issue-id> fix: <description>`
Description: summary, test plan, breaking changes. Link to Linear issue.

### Step 8: CI Monitoring

Monitor checks until all pass.
If tests fail, investigate root cause vs flakiness.
Fix flaky tests – don't just retry; stabilize the test.

### Step 9: Finalization

Update PR title/description if needed.

## Requirements

No direct pushes to `master`.
Always branch per task.
All tests must pass.
All i18n translations must be present and normalized.
Flaky tests must be fixed, not ignored.

## Conventions (Beautiful Code)

Boy Scout Rule: Leave the code cleaner than you found it.
Favor Plain Old Ruby Objects (POROs) and service objects; keep controllers and models thin.
Avoid N+1 queries by using includes (and consider Bullet for detection).
Use clear, explicit naming; avoid magic values.
Document all public APIs.
Use squash merges to keep commit history clean.
Write small, focused commits using Conventional Commits (feat:, chore:, fix:)

## Arguments

`$ARGUMENTS`
