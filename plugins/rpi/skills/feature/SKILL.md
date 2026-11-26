---
description: Deliver a feature or chore end to end, from branch creation to the merge, starting from its ticket
argument-hint: "<ticket URL or ID> [additional instructions]"
---

## Input Format

```
/rpi:feature <TICKET> [additional instructions]
```

- **TICKET**: the ticket's URL or ID (required)
- **additional instructions** (optional): constraints, focus areas, or any custom guidance

Examples:
```
/rpi:feature https://linear.app/team/ENG-1234
/rpi:feature #47
/rpi:feature ENG-1234 the SpaceshipLauncher class must inherit from BaseVehicle
```

## Context

Create and complete a new feature or chore for this project, from branch creation to the merge.

Fetch the ticket.

Pass any additional instructions from user input through to all subagents and apply them during implementation.

## Workflow

### Step 1: Setup

Pull latest base branch (usually `main` or `master`)
Create feature branch: `<type>/<issue-id>-<short-description>` (e.g., `feature/eng-1234-add-api-endpoint`)
Update the ticket: assign to "me", change status to "In Progress"

### Step 2: Gather Historical Context

Spawn `rpi:thoughts-analyzer` with ticket reference, title, description, acceptance criteria, and any additional instructions from user input.

DO NOT proceed to Step 3 until this subagent returns. Its output is required input for Step 3.

### Step 3: Research Codebase

After Step 2 completes, spawn research subagents in parallel, passing ticket info, historical context output from Step 2, and any additional instructions from user input:

`rpi:codebase-pattern-finder` - find similar implementations to model after
`rpi:codebase-analyzer` - analyze the area being modified

Wait for both subagents to complete before proceeding.

### Step 4: Design

The research reports point you to the code; Design reads it and decides how the feature fits what already exists, so it is built into the application rather than beside it.

- **Read whole** the files you will change and the files your change touches.
- **List what the feature needs:** the capabilities, not a code plan. For each, find what already exists: the application's own mechanics first, then the framework and the bundle's gems. Their documentation is extracted for the versions the bundle locks: `mdri <Constant>` lists a namespace's classes and a class's methods, `mdri <Constant>#method` one method's documentation. Read down to what you need.
- **Decide where the new code lives** in the architecture. Write your own code only where nothing exists.

### Step 5: Implementation

Activate the `rpi:document-code` skill before modifying any file.
Follow Rails best practices, CLAUDE.md, and any additional instructions from user input.
Keep code clean and DRY.
When modifying code: fix lurking bugs, refactor, add missing tests and regression tests.
Ensure solid RSpec coverage with well-documented business logic (viewable with `--format documentation`).
Review changes for completeness.

### Step 6: Testing & Quality

Run specs for changed/affected files only (never full suite locally): `bundle exec rspec spec/path/to/changed_spec.rb`
`bundle exec reek` – Code smell detection
`bundle exec standardrb --fix`
`npx @herb-tools/linter --fix app/views/**/*.erb` (if views changed)
Fix all issues, even flaky tests.

### Step 7: Translations (i18n)

`bundle exec i18n-tasks missing` – Check for missing translations
`bundle exec i18n-tasks normalize` – Normalize locale files
Add missing translations (manually or via OpenAI)

### Step 8: Pull Request

Push branch.
`gh pr create --draft`
Title: `<issue-id> feat: <description>` or `<issue-id> chore: <description>` or `<issue-id> fix: <description>`
Description: summary, test plan, breaking changes. Link to the issue.

### Step 9: CI Monitoring

Arm a Monitor on the checks; Step 10 can start while they run.
If tests fail, investigate root cause vs flakiness.
Fix flaky tests – don't just retry; stabilize the test.

### Step 10: Delivery

Follow the delivery skill the repository's `CLAUDE.md` or the human names: `rpi:copilot-assisted-feature-delivery` or `rpi:self-reviewed-feature-delivery`.

### Step 11: Handover

Record what the work decided, with `rpi:create_note`: the decisions made along the way, the ticket's scope widened or narrowed, and why. How it was built stays in the code; the note keeps what the code can't show, for the next agent who comes to this part of the project.

## Conventions (Beautiful Code)

Boy Scout Rule: Leave the code cleaner than you found it.
Favor Plain Old Ruby Objects (POROs) and service objects; keep controllers and models thin.
Avoid N+1 queries by using includes (and consider Bullet for detection).
Use clear, explicit naming; avoid magic values.
Documentation follows the `rpi:document-code` skill.
Use squash merges to keep commit history clean.
Write small, focused commits using Conventional Commits (feat:, chore:, fix:)
