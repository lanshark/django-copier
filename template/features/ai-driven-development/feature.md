# Feature: AI-Driven Development Workflow

## Purpose

Establish a document-first workflow for developing this repository with an AI coding
agent (for example, Claude Code or Codex). The workflow makes prompts, intent,
architecture, feature behavior, and implementation rationale traceable before code
changes are made.

## Status

Accepted

## Requirements

- `AGENTS.md` defines how the AI coding agent works in this repository, including the
  document-first workflow and the source-of-truth order.
- `vision.md` contains project vision, goals, scope, success criteria, and open product
  questions.
- `architecture.md` contains architecture principles, repository layout, conventions,
  and open architecture questions.
- Feature documents live under `features/<feature-slug>/`.
- Each feature folder contains `feature.md`, `SKILL.md`, `history.md`, and an `adr/`
  folder.
- Each concrete feature is discoverable as a skill through `.agents/skills/<slug>` and
  `.claude/skills/<slug>` symlinks to its folder.
- Every prompt that modifies code or shipped behavior is recorded in the feature's
  `history.md` before implementation.
- Code changes are generated from documented requirements rather than chat-only
  instructions.

## Acceptance Criteria

- The repository has `AGENTS.md`, `vision.md`, and `architecture.md`.
- The repository has a reusable feature template folder with `feature.md`, `SKILL.md`,
  and `history.md`.
- The AI-driven development workflow is captured as a feature and an ADR.
- The documents state when the agent should ask the user for clarification.
- Feature skills are discoverable by both Codex (`.agents/skills/`) and Claude Code
  (`.claude/skills/`).

## Constraints

- Do not invent product scope, data models, or integrations before requirements justify
  them.
- Keep conventions easy to follow for short future prompts.
- Keep feature-specific instructions close to each feature.

## Open Questions

- What is the first product feature for this project?
