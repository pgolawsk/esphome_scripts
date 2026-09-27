# Agent Communication Protocol

This file defines how AI agents in this repo (FLUX, ECHO, future agents) communicate with Larry (PKA orchestrator).
It is the repo copy of PKA `SOP006_agent_messaging` — Larry keeps it in sync across GATE, HAL and this repo; do not change the convention locally without telling Larry.

## Channel

All communication goes through `inbox/` at the repo root.

- `inbox/` is **gitignored** — it is a runtime communication channel, not repo content.
- It holds files in **both directions**; the filename prefix says who each file is for.
- Other agents use the same convention in their own inboxes: GATE `~/.homelab-ops/inbox/`, HAL `~/.homelab/inbox/` on each host. Larry has no inbox — he picks up `LARRY_*` files from here.

## Filenames

```
inbox/<TO>_<KIND>_<topic>.md
inbox/<TO>_TASK_<topic>__<attachment_name>.md
```

- `TO` — the addressee: `FLUX`, `ECHO`, `LARRY`.
- `KIND` — `TASK` (do this) · `DONE` (result of a TASK) · `QUESTION` (blocked, need an answer) · `NOTE` (unsolicited finding).
- `topic` — short, snake_case; a reply reuses the topic of the TASK it answers.

At session start, work only on files prefixed with **your own** agent name; `LARRY_*` files are waiting for Larry — leave them alone.

## Larry → Agent (incoming tasks)

Examples:
- `inbox/FLUX_TASK_echo.md`
- `inbox/FLUX_TASK_backlog_cleanup.md`

When you see a file matching your agent name, read it and execute.
Delete the file when the task is complete (last step before closing the session).

### Task briefs must be self-contained

Repo-local agents (FLUX, ECHO, future agents) **stay within the repo boundary**. They do not read from `~/Documents/PKA/` or any other path outside `~/dev/esphome_scripts/`.

Therefore, every `<AGENT>_TASK_<topic>.md` **must contain all material the agent needs to execute the task** — design docs, specs, decision context, prior discussion, acceptance criteria. Larry is responsible for inlining that content into the task file.

If a brief is too large to inline cleanly, Larry may drop **sibling attachment files** (`<AGENT>_TASK_<topic>__<attachment_name>.md`), e.g. `inbox/FLUX_TASK_echo__design_doc.md` alongside `inbox/FLUX_TASK_echo.md`. The agent deletes all related files (task + attachments) together on completion.

What is **never** acceptable: a task brief that points to a file in `~/Documents/PKA/`, `~/private/`, or any path outside the repo. If a brief contains such a reference, the agent responds with a `LARRY_QUESTION_<topic>.md` asking for the content to be inlined, and does not execute the task.

## Agent → Larry (outgoing responses)

When a task produces output that Larry needs to act on (decision, finding, question, deliverable summary), write a response file:

```
inbox/LARRY_<KIND>_<topic>.md
```

Examples:
- `inbox/LARRY_DONE_echo.md`
- `inbox/LARRY_QUESTION_backlog_35.md`

Keep response files short and actionable. Larry reads `inbox/` at PKA session start.

## Response file format

```markdown
# <topic>
**From:** <AGENT>@<host>
**To:** LARRY
**Date:** YYYY-MM-DD
**Re:** <original task file, or "—">

## Summary
<1–3 sentences: what was done, decided, or found>

## Action needed from Larry
<what Larry must do next — approve, route to PKA, update KANBAN, etc.>
<if no action needed, write: None — informational only>

## Files changed
<list of files created/modified, or "none">
```

## Archiving completed exchanges

Once Larry has consumed a `LARRY_*.md` response and the work is closed, **Larry moves the response (and the original task file, if still present) into `inbox/archive/`**, prepending the archival date to each filename:

```
inbox/archive/YYYY-MM-DD_<original_filename>.md
```

Examples:
- `inbox/LARRY_DONE_echo.md` → `inbox/archive/2026-05-12_LARRY_DONE_echo.md`
- `inbox/FLUX_TASK_echo.md` → `inbox/archive/2026-05-12_FLUX_TASK_echo.md`

Rules:
- **Archiving is Larry's responsibility.** Repo-local agents (FLUX, ECHO, future agents) never move files into `archive/`; they only create `LARRY_*.md` responses and delete the task brief they consumed (per "Larry → Agent" above).
- `inbox/archive/` is part of the gitignored `inbox/` tree — it is a local trail, not repo content.
- The session-start hook surfaces only the top-level `inbox/` (live work). Anything under `archive/` is hidden from session context by design.

## What does NOT go in inbox/

- Permanent deliverables (research notes, design docs) → `~/Documents/PKA/inbox/`
- Repo content (configs, docs, scripts) → committed to the repo
- Secrets, credentials → never anywhere

## Checking for pending responses

Larry checks `inbox/` for `LARRY_*.md` files at the start of every PKA session or when resuming after a repo agent session.
