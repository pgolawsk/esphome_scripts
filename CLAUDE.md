@AGENTS.md

## Claude Code subagents

This repo registers two subagents under `.claude/agents/`, auto-discovered by Claude Code (invokable via `subagent_type: <id>`; the lowercase id matches the filename per Claude Code convention). The subagent files are Claude-Code dispatch hooks; repo conventions and the cross-tool persona summary live in `AGENTS.md` so other AI agents (Cursor, Aider, Copilot, etc.) adopt the same identities, while the full profiles live in `.claude/agents/flux.md` and `echo.md`.

### FLUX (`subagent_type: flux`)

Execution agent. See `AGENTS.md` → "Persona: FLUX" and `.claude/agents/flux.md` for the full profile.

### ECHO (`subagent_type: echo`)

Read-only consistency reviewer. FLUX must call ECHO after staging and before committing whenever the change matches one of the triggers in ECHO's profile (PROD device rename/add/delete, `.dir_aliases` edit, shell-script edit, mid-session convention change, batch of 3+ files). The full trigger list, heuristic checklist (H1–H6), satellite file map, and output format live in `.claude/agents/echo.md`; the cross-tool summary is in `AGENTS.md` → "AI Agents" → "ECHO — Consistency Reviewer".
