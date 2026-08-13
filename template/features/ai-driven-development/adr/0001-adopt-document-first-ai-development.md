# ADR 0001: Adopt Document-First AI Development

## Status

Accepted

## Date

YYYY-MM-DD

## Context

This repository is intended to be developed with an AI coding agent through short,
iterative prompts. Without a durable source of truth, implementation details can drift
from product intent, architectural rationale, and prior decisions.

## Decision

Use a document-first AI development workflow:

- Store project vision in `vision.md`.
- Store project architecture and conventions in `architecture.md`.
- Store agent working instructions in `AGENTS.md`.
- Store feature requirements in `features/<feature-slug>/feature.md`.
- Store feature-specific agent guidance in `features/<feature-slug>/SKILL.md`.
- Store append-only prompt and implementation history in `features/<feature-slug>/history.md`.
- Store feature-scoped ADRs in `features/<feature-slug>/adr/`.
- Record future code-modifying prompts in the feature's `history.md` before
  implementation.

### Note on dual skill discovery

Each concrete feature's `SKILL.md` is the single canonical source, kept next to the
feature's `feature.md`, `history.md`, and `adr/`. It is made discoverable to two
agents through symlinks that both point at the feature folder:

- `.agents/skills/<slug>` — the open Agent Skills standard location used by Codex.
- `.claude/skills/<slug>` — the location Claude Code scans; Claude Code follows the
  symlink and reads `SKILL.md` from the target, so the feature becomes an auto-loadable,
  `/`-invokable skill.

The filename must be `SKILL.md` (uppercase); both standards require it. When creating a
new feature, run `make new-feature name=<slug>` (or copy `features/_template/` and add
the two symlinks) so both agents discover it.

## Consequences

- Future code changes are traceable from prompt to requirements to implementation.
- Feature-specific context stays close to the feature it governs.
- The workflow adds documentation overhead to every code-modifying prompt.
- The project must keep documents updated to avoid stale instructions.

## Alternatives Considered

- Chat-only development: rejected because intent and decisions would be hard to recover.
- Root-only documentation: rejected because feature-specific context and ADRs would
  become harder to maintain as the project grows.
- Global ADR folder only: rejected because feature-scoped ADR folders keep decisions
  close to the code they affect.
