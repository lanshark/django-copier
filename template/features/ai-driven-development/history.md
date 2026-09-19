# Feature History: AI-Driven Development Workflow

This append-only record preserves prompts, implementation summaries, and verification
results. Current normative behavior remains in `feature.md`.

## Prompt and Implementation History

### YYYY-MM-DD - Initialize Document-First Development

Prompt:

> Scaffolded from the project template with the document-first workflow enabled.

Intent:

- Provide root-level `vision.md` and `architecture.md` documents.
- Provide conventions for feature folders, feature-specific `SKILL.md` files, feature
  `history.md` records, and feature-scoped ADR folders.
- Make feature skills discoverable by both Codex and Claude Code.
- Record this setup as the first feature in the repository.

Affected documents:

- `AGENTS.md`
- `vision.md`
- `architecture.md`
- `features/_template/feature.md`
- `features/_template/SKILL.md`
- `features/_template/history.md`
- `features/_template/adr/0001-template.md`
- `features/ai-driven-development/feature.md`
- `features/ai-driven-development/SKILL.md`
- `features/ai-driven-development/history.md`
- `features/ai-driven-development/adr/0001-adopt-document-first-ai-development.md`

Implementation summary:

- Scaffolded the document-first development structure: root project documents, feature
  templates (`feature.md`, `SKILL.md`, `history.md`, `adr/`), this workflow feature and
  its ADR, and `.agents/skills` + `.claude/skills` discovery symlinks.

Verification:

- Reviewed the repository file layout and confirmed both skill symlinks resolve to the
  feature folder.

### 2026-09-19 - Move vision.md and architecture.md into docs/

Prompt:

> I want to update the ai-driven-development feature of the template. Make a top-level
> /docs directory, and move architecture.md, vision.md to that directory.

Intent:

- Move the root-level `vision.md` and `architecture.md` documents into a top-level
  `docs/` directory to reduce root clutter.
- Keep all workflow references (agent instructions, feature docs, skill templates)
  consistent with the new paths.

Affected documents:

- `AGENTS.md`
- `docs/vision.md`
- `docs/architecture.md`
- `features/_template/SKILL.md`
- `features/ai-driven-development/feature.md`
- `features/ai-driven-development/SKILL.md`
- `features/ai-driven-development/history.md`

Implementation summary:

- Moved `vision.md.jinja` and `architecture.md.jinja` to `template/docs/` so generated
  projects render them at `docs/vision.md` and `docs/architecture.md`.
- Updated all references to these documents in `AGENTS.md.jinja`, the moved
  `architecture.md.jinja`'s own repository-layout diagrams and development-flow steps,
  `features/ai-driven-development/feature.md`, and `features/_template/SKILL.md`.
- Left this feature's ADR and the top-level `CHANGELOG.md` untouched, per the user's
  instruction, since they are historical records.

Verification:

- Confirmed no remaining references to root-level `vision.md`/`architecture.md` paths
  in the template source.

### 2026-09-19 - Add top-level docs/adr directory

Prompt:

> now I want to create a top-level ADR directory for architecture decisions related to
> the entire project rather than a specific feature.
>
> stage these changes with them in docs/adr

Intent:

- Add a top-level `docs/adr/` directory for architecture decisions that span multiple
  features or the whole project, complementing the existing feature-scoped
  `features/<feature-slug>/adr/` directories.
- Update workflow documents and this feature's own documents to describe when to use
  each location.
- Record the decision to add this directory as a new ADR, since it revises part of
  ADR 0001 (which had rejected a global ADR folder).

Affected documents:

- `docs/adr/0001-template.md`
- `docs/architecture.md`
- `AGENTS.md`
- `features/ai-driven-development/feature.md`
- `features/ai-driven-development/SKILL.md`
- `features/ai-driven-development/adr/0002-add-top-level-adr-directory.md`
- `features/ai-driven-development/history.md`

Implementation summary:

- Created `docs/adr/0001-template.md`, seeded with the same fill-in-the-blank stub used
  by `features/_template/adr/0001-template.md`.
- Updated `architecture.md`'s repository-layout diagrams (both project types) and ADR
  Convention section to describe the two ADR locations and when to use each.
- Updated `AGENTS.md`'s Repository Documents list, workflow step 5, and Naming
  Conventions to cover both `docs/adr/` and feature-scoped ADRs.
- Updated this feature's `feature.md` requirements and `SKILL.md` Required Reading to
  reference `docs/adr/`.
- Added ADR 0002 documenting the decision itself, since it revises part of ADR 0001's
  original rationale; left ADR 0001 untouched as a historical record.

Verification:

- Reviewed all updated documents for consistent references to `docs/adr/` vs.
  `features/<feature-slug>/adr/`.

## Consolidated Implementation Notes

- The document-first workflow instructions live in `AGENTS.md` (imported by `CLAUDE.md`),
  so they load automatically for the AI coding agent.
- Reusable templates live in `features/_template/`.
- New features are scaffolded with `make new-feature name=<slug>`, which copies the
  template and creates both skill symlinks.

## Consolidated Verification Notes

- Confirmed the expected root documents and feature folders exist.
- Confirmed `AGENTS.md` describes the document-first workflow and source-of-truth order.
