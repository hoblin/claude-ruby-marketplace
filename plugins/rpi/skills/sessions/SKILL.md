---
description: "Read an earlier Claude Code session — what was said, decided, tried or rejected in a past conversation, in this repository or another. Use when a decision's reasoning survives nowhere else: not in a note, a ticket, a commit message or a code comment, and the only record left is the conversation it was made in. Also use when asked what happened in an earlier session, or when a document states a reversal without saying why. Do not use it for the conversation you are in."
argument-hint: "[topic or decision to find]"
---

# Reading past sessions

Never read a session `.jsonl` directly and never dump one whole. `session2md` is on your PATH:

```
Usage: session2md <session.jsonl> [options]
       grep -Rn <term> ~/.claude/projects | session2md [options]

Renders a Claude Code session as the conversation it was — who spoke and what
they said — dropping tool calls, tool results and harness bookkeeping. A day of
work measures ~4.7M tokens raw, 38k in full, 9k as an index.

Sessions live in ~/.claude/projects/<cwd, every character but a letter or digit
replaced by ->/<uuid>.jsonl, named by uuid, so list them by recency:

  ls -t ~/.claude/projects/"${PWD//[^[:alnum:]]/-}"/*.jsonl

Examples:
  # index one session: every turn, with its line number in the file
  session2md ~/.claude/projects/-home-you-Work-repo/e16fa28d-....jsonl

  # read around a line the index or a grep pointed at
  session2md e16fa28d-....jsonl --from 1990 --to 2100 --full

  # find where something was said, across every session and every clone
  grep -Rn 'tool registry' ~/.claude/projects | session2md

  # widen the conversation kept around each match
  grep -Rn 'tool registry' ~/.claude/projects | session2md --context 5

grep must carry the file name, so pass -H (or -R, which does it for you). -R
rather than -r: it follows symlinks, and archives worth searching sit behind
them. The match itself usually lands in a tool result that is dropped, and what
reaches you is the surrounding turns.

A pause longer than an hour is marked, because a session spans days and a window
straddling a night otherwise reads as one conversation.

Options:
        --from N                     First line of the transcript to read
        --to N                       Last line of the transcript to read
        --full                       Print each turn whole instead of a preview
        --context N                  Turns to print around a match (default 2)
        --thinking                   Include the assistant's reasoning blocks
    -h, --help                       Print this message
```

Subagent transcripts sit under `<session-uuid>/subagents/` and render the same way.
