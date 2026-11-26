---
description: Initialize thoughts system for current repository
---

# Initialize Thoughts System

Initialize the thoughts system for the current repository. The thoughts tools (`thoughts-sync`, `thoughts-status`, `thoughts-init-repo`, `spec-metadata`) come with rpi, on your PATH; nothing needs installing.

## Process

### Step 1: Diagnostic Checks

Run these checks and collect results:

1. `~/thoughts` exists: `test -d "$HOME/thoughts"`
2. `~/thoughts` is git repo: `test -d "$HOME/thoughts/.git"`
3. `~/thoughts/global` structure exists: `test -d "$HOME/thoughts/global"`
4. Current dir is git repo: `test -d ".git"`
5. `./thoughts/shared` symlinked correctly: `test -L "./thoughts/shared" && readlink "./thoughts/shared" | grep -q "thoughts/repos/"`

### Step 2: Report or Fix

**If all checks pass:**
```
Thoughts system ready. RPI workflow commands will now work correctly.

- ~/thoughts: OK (with global/ structure)
- Repository: OK (thoughts/shared → ~/thoughts/repos/{repo}/shared)
```

**If any check fails:**
Build todo list of what needs fixing, present to user, wait for authorization.

### Step 3: Execute Fixes (after authorization)

**If ~/thoughts missing:**
```bash
mkdir -p "$HOME/thoughts/global/$(whoami)"
mkdir -p "$HOME/thoughts/global/shared"
mkdir -p "$HOME/thoughts/repos"
git -C "$HOME/thoughts" init
```

**If current repo not initialized:**
```bash
thoughts-init-repo
```

### Step 4: Verify and Report

After fixes, re-run checks and report final status.

## Important

- Never make changes without user authorization
- If current directory is not a git repo, report error and stop
