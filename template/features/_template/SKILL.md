---
name: <feature-slug>
description: Use when modifying the <Feature Name> feature in this repository.
---

# <Feature Name> Skill

Use this skill when changing `features/<feature-slug>/` requirements or implementation
code for <Feature Name>.

## Before Editing Code

1. Read `AGENTS.md`, `vision.md`, `architecture.md`, and this feature's `feature.md`.
2. Record the user's modifying prompt in this feature's `history.md`.
3. Update requirements and acceptance criteria in `feature.md` before implementation.
4. Add or update ADRs in `adr/` for durable architectural choices.

## Implementation Guidance

- Keep changes scoped to this feature unless an ADR justifies a broader change.
- Follow established project conventions from `architecture.md` and `AGENTS.md`.
- Prefer explicit behavior and testable acceptance criteria.
- Preserve existing user work.

## Validation

- Run the smallest useful validation for the change.
- Record validation results in `history.md`.
- If validation cannot be run, document the reason.

## When to Ask the User

Ask before implementation when product behavior, data contracts, or architectural
choices are ambiguous enough that different reasonable answers would produce different
outcomes.
