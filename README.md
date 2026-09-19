# LANshark django-copier Template

A [copier](https://copier.readthedocs.io/) template for generating Django projects:
Python 3.14, Django 5.2 LTS, Postgres 17, django-tasks, PyTest, uv, ruff, pyright,
and GitHub Actions CI. It can produce either a full runnable site (Docker Compose,
optional django-shinobi API layer with JWT auth) or a pip-installable reusable Django
app (hatchling package, sqlite tests, PyPI release workflow). Every generated project
also ships a document-first AI-development scaffold (`docs/vision.md`,
`docs/architecture.md`,
per-feature docs and skills) for working with Claude Code or Codex.

## Usage

```bash
pip install copier
copier copy gh:YOUR_ORG/YOUR_TEMPLATE_REPO my-new-project
# or, from a local checkout of this repo:
copier copy /path/to/this/repo my-new-project
```

You'll be prompted for:

| Variable | Purpose |
|---|---|
| `project_name` | Human-readable name (used in README, API title, pyproject description) |
| `project_slug` | Package/image-safe slug, auto-derived from `project_name` |
| `project_type` | `full_project` (runnable site) or `reusable_app` (pip-installable Django app) |
| `package_name` | *(reusable_app only)* Python import package name, auto-derived from `project_slug` |
| `initial_app_name` | *(full_project only)* Name of the first Django app (`apps/<name>/`) |
| `author_name` / `author_email` | Populates `pyproject.toml` authors |
| `python_version` | `3.14` |
| `use_redis` | *(full_project only)* `true` → django-tasks on RQ/Redis with a `worker` compose service; `false` → synchronous `ImmediateBackend`, no Redis needed |
| `use_async` | *(full_project only)* `true` → serve via uvicorn/ASGI; `false` → gunicorn/WSGI |
| `use_shinobi` | `true` → include a django-shinobi (Django Ninja) API layer with JWT auth and an example health/token/me API; `false` → no API layer |
| `use_vite` | *(full_project only)* `true` → Pico.css + Vite frontend build pipeline (django-vite, HMR dev server, starter page); `false` → no frontend tooling |
| `open_source_license` | `MIT`, `BSD-3-Clause`, `Apache-2.0`, `GNU GPLv3`, `GNU AGPLv3`, `Proprietary`, or `None` |
| `copyright_holder` / `copyright_year` | *(shown for licenses needing a copyright notice)* Populates the rendered `LICENSE` |

## Updating an existing generated project

```bash
cd my-existing-project
copier update
```

Copier will re-apply the template's latest changes on top of the project, respecting any
local modifications where possible.

## Project types

- **`full_project`** (default) — a runnable Django site: `apps/<initial_app_name>/`,
  Docker/Docker Compose, a Makefile wrapping `docker compose`/`manage.py`, and CI that
  migrates, tests, lints, and type-checks against a real Postgres (and Redis, if
  `use_redis=true`).
- **`reusable_app`** — a pip-installable Django app: a hatchling `src/<package_name>/`
  package (models/admin/migrations/`py.typed`, an optional shinobi `Router`,
  `templates/`+`static/`), `pytest-django` tests on sqlite, a runnable `example/`
  project, a uv-based Makefile (build/publish), an install-oriented README, and a
  Postgres-free CI plus a PyPI `release.yml`. The project-only questions
  (`initial_app_name`, `use_redis`, `use_async`) are hidden for this type.

## Frontend (Pico.css + Vite)

When `use_vite=true`, the generated project ships a minimal frontend build pipeline:

- `package.json` / `vite.config.js` / `frontend/main.js` — a Vite project that imports
  `@picocss/pico` and builds a manifest to `static/dist/`.
- `django-vite` reads that manifest so `{% vite_asset %}`/`{% vite_hmr_client %}` in
  `apps/<initial_app_name>/templates/<initial_app_name>/base.html` resolve the right
  asset in both dev and prod, controlled by `DJANGO_VITE_DEV_MODE` (defaults to
  `DJANGO_DEBUG`).
- A starter page (`apps/<initial_app_name>/views.py` + `urls.py`) renders at `/`.
- In prod, the Docker image builds the frontend in a `node:22-slim` stage and copies
  `static/dist/` into the runtime image, where whitenoise serves it.
- For local dev, copy `docker-compose.override.yml.example` to
  `docker-compose.override.yml`: it adds a `vite` service running the Vite dev server
  with HMR on `localhost:5173`. `make frontend-install` / `make frontend-build` run the
  equivalent commands against your local Node install.

## Document-first AI development scaffold

Every generated project ships a workflow for developing with an AI coding agent
(Claude Code, Codex, etc.):

- `docs/vision.md` — project vision, goals, scope, success criteria, open product questions
- `docs/architecture.md` — architecture principles, repository layout, conventions
- `AGENTS.md` (with a `CLAUDE.md` that imports it via `@AGENTS.md`) — how the agent
  should work in the repo, including the document-first workflow and source-of-truth
  order
- `features/<feature-slug>/` — one folder per feature, each with `feature.md` (current
  state), `history.md` (append-only prompt log), `SKILL.md`, and `adr/`

Each feature folder is discoverable as a skill through `.agents/skills/<slug>` and
`.claude/skills/<slug>` symlinks, and `make new-feature name=<slug>` scaffolds a new
feature with both symlinks in place.

## Structure of this repo

```
copier.yml       # prompts and template configuration
template/        # the actual project template (this is what gets rendered)
```

Everything under `template/` is rendered through Jinja2. Files needing variable
substitution carry a `.jinja` suffix, which Copier strips on render (e.g.
`pyproject.toml.jinja` → `pyproject.toml`). Files without that suffix are copied
byte-for-byte with no substitution.

## What's been verified

CI (`.github/workflows/test-template.yml`) renders and runs each combination below —
not just writes it — against a real Postgres 17 (and Redis, where relevant): `migrate`,
the pytest suite, `ruff check`, and `pyright` all pass clean in each case.

`full_project`:

- Default answers (`use_redis=true`, `use_async=false`)
- `use_redis=false` (synchronous task backend, no Redis/worker service generated)
- Custom `initial_app_name` + `use_async=true` (app directory renamed correctly, all
  internal imports follow, Dockerfile CMD switches to uvicorn)
- `open_source_license=Apache-2.0`
- `use_shinobi=false` (no API layer; an always-present smoke test keeps the suite
  non-empty)
- `use_vite=true` (Pico.css + Vite build pipeline, django-vite, starter page rendered
  and `collectstatic` run against a `npm run build` manifest)

`reusable_app`:

- Default answers, and `use_shinobi=false` — both also verified to `uv build` cleanly

## Known limitations

- The `django-tasks-db` backend (Postgres-only, no Redis) mentioned in the original
  design spec was **not** used here in favor of the already-verified `ImmediateBackend`
  for the `use_redis=false` case — `django-tasks-db`'s exact API wasn't verified against
  a real install the way `django-tasks-rq` was, so it's left out rather than guessed at.
  Worth checking directly if you want durable (survives a restart) queuing without Redis.
