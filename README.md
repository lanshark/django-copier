# LANshark django-copier Template

A [copier](https://copier.readthedocs.io/) template for generating Django + django-shinobi
API projects: Python 3.13/3.14, Django 5.2 LTS, Postgres 17, JWT auth, django-tasks,
PyTest, uv, ruff, pyright, Docker, and GitHub Actions CI.

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
| `initial_app_name` | Name of the first Django app (`apps/<name>/`) |
| `author_name` / `author_email` | Populates `pyproject.toml` authors |
| `python_version` | `3.13` or `3.14` |
| `use_redis` | `true` → django-tasks on RQ/Redis with a `worker` compose service; `false` → synchronous `ImmediateBackend`, no Redis needed |
| `use_async` | `true` → serve via uvicorn/ASGI; `false` → gunicorn/WSGI |
| `open_source_license` | `MIT` or `None` |

## Updating an existing generated project

```bash
cd my-existing-project
copier update
```

Copier will re-apply the template's latest changes on top of the project, respecting any
local modifications where possible.

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

Every combination below has actually been rendered and run — not just written — against
a real Postgres 17-compatible Postgres and Redis: `migrate`, the pytest suite, `ruff
check`, and `pyright` all pass clean in each case.

- Default answers (`use_redis=true`, `use_async=false`)
- `use_redis=false` (synchronous task backend, no Redis/worker service generated)
- Custom `initial_app_name` + `use_async=true` (app directory renamed correctly, all
  internal imports follow, Dockerfile CMD switches to uvicorn)

## Known limitations

- `open_source_license=MIT` generates a standard MIT `LICENSE` file; `None` skips it.
  Other licenses aren't offered — add a `LICENSE.jinja` and a `copier.yml` choice if you
  need one.
- The `django-tasks-db` backend (Postgres-only, no Redis) mentioned in the original
  design spec was **not** used here in favor of the already-verified `ImmediateBackend`
  for the `use_redis=false` case — `django-tasks-db`'s exact API wasn't verified against
  a real install the way `django-tasks-rq` was, so it's left out rather than guessed at.
  Worth checking directly if you want durable (survives a restart) queuing without Redis.
