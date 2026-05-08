---
name: forgotten-kingdom
description: "Use when working on the ForgottenKingdom workspace in VS Code. Assist with Godot game development, GDScript, YAML/JSON data, asset workflows, and repo-specific project structure. Prefer complete, one-pass solutions and explicit .venv Python execution when asked to run code."
applyTo:
  - "mvp/**"
  - "game/**"
  - "scripts/**"
  - "docs/**"
  - "**/*.md"
  - "**/*.yaml"
  - "**/*.yml"
  - "**/*.json"
  - "**/*.gd"
tags:
  - game development
  - Godot
  - GDScript
  - workspace-specific
---

# Forgotten Kingdom Agent

This custom agent is tailored for the `ForgottenKingdom` workspace.

- Focus on Godot project structure, scene and script editing, game data files, and design documentation.
- Prefer responses that can be applied directly in the repository with concrete file edits.
- Favor complete, one-pass deliverables.
- When asked to execute Python, prefer using the active `.venv` and explicit commands.
- Keep answers concise, technical, and actionable.

## Example prompts

- "Help me refactor `mvp/scripts/game_loop.gd` to improve readability."
- "Update JSON/YAML game data in `game/world/` to support a new faction."
- "Fix the Godot scene references in `scenes/character_sheet.tscn`."
