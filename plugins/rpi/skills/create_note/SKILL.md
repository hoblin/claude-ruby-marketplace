---
description: Capture findings or context as a persistent note in the thoughts system
---

# Create Note

You are tasked with capturing content as a persistent note in the thoughts system. This could be findings from a research subagent, insights from the current session, or any content worth preserving for future reference.

## Process

### 1. Gather Metadata

Run `spec-metadata` (in the PATH) to get date, time, git commit, branch, and repository name.

### 2. Filepath & Naming

Create your file under `./thoughts/shared/notes/YYYY-MM-DD/description.md`, where:
- YYYY-MM-DD is today's date
- description is a brief kebab-case description of the content

Examples:
- `2026-02-23/rails-8-turbo-stream-patterns.md`
- `2026-02-23/sidekiq-retry-best-practices.md`
- `2026-02-23/authentication-library-comparison.md`

### 3. Note Writing

Using the above conventions, write your document with the following YAML frontmatter pattern. Use the metadata gathered in step 1:

```markdown
---
date: [Current date and time with timezone in ISO format]
author: [Author name from spec-metadata]
git_commit: [Current commit hash]
branch: [Current branch name]
repository: [Repository name]
topic: "[Brief topic description]"
tags: [note, relevant-keywords]
status: complete
last_updated: [Current date in YYYY-MM-DD format]
last_updated_by: [Author name]
---

# [Topic]

## Context

[What prompted this note - the question, task, or goal]

## Content

[The actual content - preserved exactly as provided without summarization or transformation]

## Sources

[Links, file paths, or references - if applicable, omit section if none]

## Related

[Links to related notes, research, or plans in thoughts/ - if applicable, omit section if none]
```

### 4. Sync and Present

Run `thoughts-sync` to save the document.

Once complete, respond with:

```
Note captured at: ./thoughts/shared/notes/YYYY-MM-DD/description.md

You can reference this in future sessions or as input to other RPI commands.
```

## Additional Notes & Instructions

- **Preserve content exactly**: The value of this note is capturing content losslessly. Do not summarize, synthesize, or transform the content unless explicitly asked.
- **Include all links**: If content came from web research, documentation lookups, or file analysis, preserve all URLs and file:line references.
- **Topic from context**: Derive the topic from the content being captured. Only ask the user if genuinely ambiguous.
- **Sections are flexible**: The Content section is required. Sources and Related sections should be included when applicable, omitted when not.
- **Follow-up notes**: If adding to an existing topic, consider updating the existing note rather than creating a duplicate. Update `last_updated` and `last_updated_by` fields.
