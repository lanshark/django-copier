# Changelog for LANshark Django Project Copier Template

All notable changes to this project are documented in this file.

## Next Release

- Add a `task_runner` question (`Makefile`/`Justfile`, default `Makefile`) so generated projects can choose their dev-command runner. Both project types get a Justfile mirroring their Makefile's targets (full_project: Docker/Django/database/quality/document-first, plus `use_vite` frontend recipes when enabled; reusable_app: quality/Django/packaging/document-first, including the interactive `publish` confirmation), using `just`'s native doc-comments and `just --list` instead of `make help`'s hand-rolled parser. `README.md`, `docs/architecture.md`, and `AGENTS.md` reference whichever runner was chosen. CI gains `with-justfile`/`app-justfile` matrix entries that install `just` and run the rendered project's `migrate`/`collectstatic`/`test`/`lint`/`typecheck`/`build`/frontend recipes through it, rather than just checking that the Justfile renders
- Add a `use_vite` question (full_project only) for a Pico.css + Vite frontend build pipeline: django-vite settings wiring, a starter page (`apps/<initial_app_name>/views.py`, `templates/`), a Docker multi-stage frontend build, a `vite` docker-compose service for HMR in local dev, `make frontend-install`/`frontend-build` targets, and a CI matrix entry that builds assets and runs `collectstatic` against the real manifest
- Require every repo change to be recorded as a bullet under this "Next Release" heading before it's considered complete, per a new `AGENTS.md` guideline (inherited by generated projects via the existing `{% include "AGENTS.md" %}`)
- Make the django-shinobi API layer optional via a `use_shinobi` question (default yes); when disabled the project ships with no API layer (admin site only) — dropping django-shinobi/pyjwt, the JWT settings and env vars, the `api`/`auth`/`schemas` modules, and the API tests, with an always-present smoke test keeping the suite non-empty
- Add a document-first / AI-driven development scaffold to every generated project: `vision.md`, a Django-tailored `architecture.md`, an `apps/<app>/AGENTS.md` module doc, and a `features/` folder (each feature has `feature.md` for current state, `history.md` for the append-only prompt log, `SKILL.md`, and `adr/`). Feature skills are discoverable by both Codex (`.agents/skills/`) and Claude Code (`.claude/skills/`) via symlinks; the workflow and a source-of-truth order are merged into `AGENTS.md`, and `make new-feature name=<slug>` scaffolds a feature with both symlinks
- Add a `project_type` question so the template can produce either a full Django project (unchanged default) or a pip-installable reusable Django app. The reusable app uses a `src/<package_name>/` hatchling package (models/admin/migrations/`py.typed`, plus a shinobi `Router` when enabled, and `templates/`+`static/`), ships `pytest-django` tests on sqlite, a runnable `example/` project, a uv-based Makefile (build/publish), an install-oriented README, a postgres-free CI plus a PyPI `release.yml`, and the shared docs/quality/document-first core. Project-only questions (`initial_app_name`, `use_redis`, `use_async`) are hidden for the app type

## 2026-08-06: Release-2026.08.06.01

- Add project license selection (MIT, BSD-3-Clause, Apache-2.0, GNU GPLv3, GNU AGPLv3, Proprietary, or None): renders a matching LICENSE from `template/licenses/`, sets pyproject license metadata, adds a README license section, and covers a licensed render in CI
- Ship the repo's AGENTS.md coding standards to generated projects, single-sourced from the root AGENTS.md via a Jinja `{% include %}`
- Add CLAUDE.md to generated projects, importing AGENTS.md via `@AGENTS.md`
- Add a generic CHANGELOG.md to generated projects, titled from the project name
- Add a generic Makefile to generated projects wrapping `docker compose` and `manage.py` (build/up/down, runserver, migrations, superuser, psql, tests, lint, typecheck, help)
- Add CLAUDE.md and CHANGELOG.md for the template repo itself, and remove the example root Makefile
