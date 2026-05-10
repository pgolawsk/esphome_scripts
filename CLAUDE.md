@AGENTS.md

## Claude Code subagent

This repo registers the **FLUX** subagent at `.claude/agents/flux.md`, auto-discovered by Claude Code (invokable via `subagent_type: flux` — lowercase id matches the filename per Claude Code convention). The subagent file is just the Claude-Code dispatch hook; the FLUX persona, conventions, and ESPHome knowledge are defined in `AGENTS.md` ("Persona: FLUX" and surrounding sections) so other AI agents (Cursor, Aider, Copilot, etc.) adopt the same identity.
