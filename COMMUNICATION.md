# Agent Communication Protocol

This file defines how AI agents in this repo communicate with Larry (PKA orchestrator).

## Channel

All communication goes through `agents_inbox/` at the repo root.

- `agents_inbox/` is **gitignored** — it is a runtime communication channel, not repo content.
- Larry writes task briefs here for agents to pick up.
- Agents write responses here for Larry to read.

## Larry → Agent (incoming tasks)

Larry creates a file named:

```
agents_inbox/<AGENT>_TASK_<topic>.md
```

Examples:
- `agents_inbox/FLUX_TASK_ECHO.md`
- `agents_inbox/FLUX_TASK_BACKLOG_CLEANUP.md`

When you see a file matching your agent name, read it and execute.
Delete the file when the task is complete (last step before closing the session).

### Task briefs must be self-contained

Repo-local agents (FLUX, ECHO, future agents) **stay within the repo boundary**. They do not read from `~/Documents/PKA/` or any other path outside `~/dev/esphome_scripts/`.

Therefore, every `FLUX_TASK_<topic>.md` (and any other `<AGENT>_TASK_*.md`) **must contain all material the agent needs to execute the task** — design docs, specs, decision context, prior discussion, acceptance criteria. Larry is responsible for inlining that content into the task file.

If a brief is too large to inline cleanly, Larry may drop **sibling attachment files** under `agents_inbox/` using the naming convention:

```
agents_inbox/<AGENT>_TASK_<topic>__<attachment_name>.md
```

Example: `agents_inbox/FLUX_TASK_ECHO__design_doc.md` alongside `agents_inbox/FLUX_TASK_ECHO.md`. The agent deletes all related files (task + attachments) together on completion.

What is **never** acceptable: a task brief that points to a file in `~/Documents/PKA/`, `~/private/`, or any path outside the repo. If a brief contains such a reference, the agent responds with a `LARRY_*.md` asking for the content to be inlined, and does not execute the task.

## Agent → Larry (outgoing responses)

When a task produces output that Larry needs to act on (decision, finding, question, deliverable summary), write a response file:

```
agents_inbox/LARRY_<topic>.md
```

Examples:
- `agents_inbox/LARRY_ECHO_DONE.md`
- `agents_inbox/LARRY_QUESTION_BACKLOG_35.md`

Keep response files short and actionable. Larry reads `agents_inbox/` at PKA session start.

## Response file format

```markdown
# <topic>
**From:** <AGENT>
**Date:** YYYY-MM-DD
**Re:** <original task file, if any>

## Summary
<1–3 sentences: what was done, decided, or found>

## Action needed from Larry
<what Larry must do next — approve, route to PKA, update KANBAN, etc.>
<if no action needed, write: None — informational only>

## Files changed
<list of files created/modified, or "none">
```

## What does NOT go in agents_inbox/

- Permanent deliverables (research notes, design docs) → `~/Documents/PKA/inbox/`
- Repo content (configs, docs, scripts) → committed to the repo
- Secrets, credentials → never anywhere

## Checking for pending responses

Larry checks `agents_inbox/` for `LARRY_*.md` files at the start of every PKA session or when resuming after a repo agent session.
