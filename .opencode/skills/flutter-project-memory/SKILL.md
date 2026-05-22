---
name: flutter-project-memory
description: Use when managing Flutter project memory, context, or when asked about project status, decisions, conventions, architecture, or what has been done. Provides structured memory management with ADR tracking.
---

# Flutter Project Memory

This skill activates when the model needs to read or write project memory.

## Memory file locations
All memory files live in `.opencode/memory/`:
- `project.md` — High-level project overview (max 30 lines)
- `decisions.md` — Architecture Decision Records
- `conventions.md` — Project-specific coding patterns
- `status.md` — Current development status

## When to trigger
- User asks "what's the current state?" or "remind me about..."
- Starting a new feature or bug fix
- After completing a significant piece of work
- When the model needs context it doesn't have in conversation

## Protocol
1. Read the relevant file(s)
2. If reading for context, synthesize into a concise summary
3. If writing, only update the changed file — keep edits minimal
4. Enforce file size limits (trim old entries if needed)
