---
name: ai-driven-development
description: Use when changing the repository's document-first AI development workflow, agent instructions, feature documentation conventions, or ADR process.
---

# AI-Driven Development Skill

Use this skill when modifying the repository workflow for AI-assisted development.

## Required Reading

- `AGENTS.md`
- `vision.md`
- `architecture.md`
- `features/ai-driven-development/feature.md`
- Relevant ADRs in `features/ai-driven-development/adr/`

## Workflow

1. Record the user's modifying prompt in `features/ai-driven-development/history.md`.
2. Update the root workflow documents before implementation when conventions change.
3. Add or update an ADR when the change affects durable process, repository layout,
   documentation rules, or architectural governance.
4. Apply the smallest documentation or code change that satisfies the requirement.
5. Validate by checking document consistency and repository structure.
6. Record implementation and verification notes in `history.md`.

## Guardrails

- Do not choose product scope, framework, or storage technology from workflow-only
  prompts.
- Keep this skill focused on the AI development process and documentation architecture.
- Preserve the separation between root project guidance and feature-specific guidance.
