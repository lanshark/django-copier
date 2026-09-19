# ADR 0002: Add a Top-Level ADR Directory

## Status

Accepted

## Date

2026-09-19

## Context

ADR 0001 established feature-scoped ADRs only, stored in `features/<feature-slug>/adr/`,
and explicitly rejected a global ADR folder because feature-scoped folders keep
decisions close to the code they affect.

As the project grows, some decisions are not owned by a single feature: runtime or
framework choices, cross-cutting infrastructure, and project-wide security or privacy
posture affect the whole project rather than one feature's behavior. Filing these under
an arbitrary feature's `adr/` folder hides their rationale from anyone not already
looking at that feature.

## Decision

Add a top-level `docs/adr/` directory for project-wide architecture decision records,
alongside the existing feature-scoped `features/<feature-slug>/adr/` directories:

- `docs/adr/`: decisions that span multiple features or the whole project.
- `features/<feature-slug>/adr/`: decisions confined to that feature.

ADR numbering remains independent per folder; each `adr/` folder starts its own
`0001-...` sequence. `docs/adr/` is seeded with the same `0001-template.md` stub used
by `features/_template/adr/`.

## Consequences

- Project-wide decisions have a single, discoverable home instead of being attributed
  to whichever feature happened to prompt them.
- Contributors must judge whether a decision is project-wide or feature-scoped before
  filing an ADR; `docs/architecture.md`'s ADR Convention section gives the criteria.
- `docs/architecture.md`, `AGENTS.md`, and this feature's `feature.md`/`SKILL.md` now
  reference two ADR locations instead of one.

## Alternatives Considered

- Keep ADRs feature-scoped only, filing cross-cutting decisions under the
  most-related feature: rejected because it obscures project-wide rationale and makes
  it harder to find later.
- A bare root-level `/adr/` directory: rejected in favor of `docs/adr/`, since `docs/`
  already holds the other project-wide documents (`vision.md`, `architecture.md`).
