# LANshark django-copier Template

A [copier](https://copier.readthedocs.io/) template for generating Django projects:
Python 3.14, Django 5.2 LTS, Postgres 18, django-tasks, PyTest, uv, ruff, pyright,
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
| `initial_app_name` | *(full_project only)* Name of the first Django app (`apps/<name>/`); can't be `accounts` (reserved for the custom user model) |
| `author_name` / `author_email` | Populates `pyproject.toml` authors |
| `python_version` | `3.14` (default), `3.13`, or `3.12` — Python version to target |
| `postgres_version` | *(full_project only)* `18` (default), `17`, or `16` — PostgreSQL version to target |
| `django_version` | `5.2` LTS (default) or `6.1` — Django 6.1 is newer and not yet fully vetted here; the generated `docs/architecture.md` documents known caveats (`django-tasks`/`django-rq` vs. Django's built-in tasks framework, unverified email settings) when selected |
| `use_redis` | *(full_project only)* `true` → django-tasks on RQ/Redis with a `worker` compose service; `false` → synchronous `ImmediateBackend`, no Redis needed |
| `use_async` | *(full_project only)* `true` → serve via uvicorn/ASGI; `false` → gunicorn/WSGI |
| `use_shinobi` | `true` → include a django-shinobi (Django Ninja) API layer with JWT auth and an example health/token/me API; `false` → no API layer |
| `use_vite` | *(full_project only)* `true` → Pico.css + Vite frontend build pipeline (django-vite, HMR dev server) for the home page; `false` → no frontend tooling |
| `use_allauth` | *(full_project only)* `true` → django-allauth for session-based login/signup/logout (separate from the JWT API auth), with a login/logout link on the home page; `false` → no allauth |
| `task_runner` | `Makefile` (default) or `Justfile` — which tool wraps the dev commands (`up`/`migrate`/`test`/`lint`/`new-feature`/etc.) |
| `email_provider` | *(full_project only)* `Amazon SES` (default), `Postmark`, `Mailgun`, or `SendGrid` — production email backend via django-anymail (local dev defaults to localhost SMTP, with Docker wiring Mailpit automatically) |
| `user_identifier` | *(full_project only)* `Email address` (default) or `Username` — how the custom user model (`apps/accounts`) identifies users |
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

- **`full_project`** (default) — a runnable Django site: `apps/<initial_app_name>/`
  with a home page at `/`, a custom user model (`apps/accounts`, identified by
  email or username per `user_identifier`), optional django-allauth login
  (`use_allauth`), Docker/Docker Compose (including a `mailpit` dev SMTP
  catcher), a Makefile or Justfile (`task_runner`) wrapping `docker
  compose`/`manage.py`, and CI that migrates, tests, lints, and type-checks
  against a real Postgres (and Redis, if `use_redis=true`).
- **`reusable_app`** — a pip-installable Django app: a hatchling `src/<package_name>/`
  package (models/admin/migrations/`py.typed`, an optional shinobi `Router`,
  `templates/`+`static/`), `pytest-django` tests on sqlite, a runnable `example/`
  project, a uv-based Makefile or Justfile (`task_runner`, build/publish), an
  install-oriented README, and a Postgres-free CI plus a PyPI `release.yml`. The
  project-only questions (`initial_app_name`, `use_redis`, `use_async`) are hidden for
  this type.

## Custom user model

Every `full_project` generated project ships its own `apps/accounts` app and sets
`AUTH_USER_MODEL = "accounts.User"` from the start — swapping the user model later
is notoriously painful in Django, so every generated project gets a real one, even
when its fields end up identical to Django's default.

`user_identifier` controls how it's identified:

- **`email` (default)** — `username` is removed entirely; `email` is unique and is
  `USERNAME_FIELD`. `apps/accounts/forms.py` supplies admin create/change forms
  (Django's defaults reference `username`, which doesn't exist on this model).
- **`username`** — same fields as Django's default `AbstractUser`; no extra forms
  needed since the defaults already fit.

Both variants ship a real, generated (not hand-guessed) `migrations/0001_initial.py`
— `manage.py makemigrations --check` confirms it matches exactly. When
`use_shinobi=true`, the JWT token/`/me` endpoints and their request/response
schemas use whichever field `user_identifier` selected (e.g. `POST /api/v1/auth/token`
takes `email`+`password` rather than `username`+`password` for the email variant).

## Home page

Every `full_project` generated project ships a basic home page at `/`
(`apps/<initial_app_name>/views.py`, `urls.py`, `templates/<initial_app_name>/`)
— this doesn't depend on `use_vite` or `use_allauth`. Those two features layer
their own markup onto the same page rather than requiring it: `use_vite` adds the
Pico.css + Vite `<head>` tags, `use_allauth` adds a login/logout link and, when
signed in, "Logged in user: ...".

## Login (django-allauth)

When `use_allauth=true`, the generated project adds
[django-allauth](https://docs.allauth.org/)'s core account app — login, signup,
logout, password reset — mounted at `/accounts/...`, entirely separate from the
JWT API auth (`use_shinobi`): allauth manages browser sessions; the API issues its
own tokens. Only the core `allauth`/`allauth.account` apps are installed, no
social-login providers.

It's wired to match whichever `user_identifier` the project uses:

- **`email`** — `ACCOUNT_LOGIN_METHODS = {"email"}`, `ACCOUNT_SIGNUP_FIELDS` drops
  `username`, and `ACCOUNT_USER_MODEL_USERNAME_FIELD = None` tells allauth's forms
  not to look for a `username` field that doesn't exist on this model.
- **`username`** — allauth's own defaults already match `apps/accounts`'s fields;
  no extra `ACCOUNT_*` settings needed.

The home page (`apps/<initial_app_name>/templates/<initial_app_name>/index.html`)
shows a Login link when signed out, or "Logged in user: `<email or username>`"
plus a Logout link when signed in. Verification emails (default:
`ACCOUNT_EMAIL_VERIFICATION="optional"`, allauth's own default — left unchanged for
"core" functionality) go through the same `mailpit`/`django-anymail` email setup
as the rest of the project, so nothing extra needs configuring for them to work.

## Frontend (Pico.css + Vite)

When `use_vite=true`, the generated project ships a minimal frontend build pipeline:

- `package.json` / `vite.config.js` / `frontend/main.js` — a Vite project that imports
  `@picocss/pico` and builds a manifest to `static/dist/`.
- `django-vite` reads that manifest so `{% vite_asset %}`/`{% vite_hmr_client %}` in
  `apps/<initial_app_name>/templates/<initial_app_name>/base.html` resolve the right
  asset in both dev and prod, controlled by `DJANGO_VITE_DEV_MODE` (defaults to
  `DJANGO_DEBUG`).
- In prod, the Docker image builds the frontend in a `node:22-slim` stage and copies
  `static/dist/` into the runtime image, where whitenoise serves it.
- For local dev, copy `docker-compose.override.yml.example` to
  `docker-compose.override.yml`: it adds a `vite` service running the Vite dev server
  with HMR on `localhost:5173`. `make frontend-install` / `make frontend-build` (or
  `just frontend-install` / `just frontend-build`, depending on `task_runner`) run the
  equivalent commands against your local Node install.

## Email (Mailpit + django-anymail)

Every `full_project` generated project sends email via SMTP. For non-Docker local
runs, `config/settings/base.py` defaults `DJANGO_EMAIL_HOST`/`DJANGO_EMAIL_PORT` to
`localhost:1025`. In Docker Compose, the generated `web`/`worker` services override
`DJANGO_EMAIL_HOST` to `mailpit`, and the `mailpit` service publishes both its SMTP
port (`127.0.0.1:1025`) and web UI (`http://localhost:8025`) on localhost, so no real
mail is ever sent. `config/settings/test.py` uses Django's `locmem` backend instead,
so tests and CI don't need a running SMTP server.

`config/settings/prod.py` (only loaded when
`DJANGO_SETTINGS_MODULE=config.settings.prod`) overrides `EMAIL_BACKEND` to send
through [django-anymail](https://anymail.dev/) via the `email_provider` chosen at
generation time:

- **Amazon SES** — no `ANYMAIL` setting required; boto3 reads AWS credentials/region
  via its standard chain (env vars, an IAM role, or `~/.aws/credentials`).
- **Postmark** — requires `ANYMAIL_POSTMARK_SERVER_TOKEN`.
- **Mailgun** — requires `ANYMAIL_MAILGUN_API_KEY` and `ANYMAIL_MAILGUN_SENDER_DOMAIN`.
- **SendGrid** — requires `ANYMAIL_SENDGRID_API_KEY`.

These are only read in prod (see `.env.example` for the full list); local dev and CI
never need them.

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
`.claude/skills/<slug>` symlinks, and `make new-feature name=<slug>` (or `just
new-feature <slug>`, depending on `task_runner`) scaffolds a new feature with both
symlinks in place.

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

- Default answers (`use_redis=true`, `use_async=false`, `user_identifier=email`);
  the smoke test suite includes an email test confirming `config/settings/test.py`'s
  `locmem` backend captures mail instead of needing a live `mailpit` SMTP server in
  CI, and `apps/accounts` tests confirming the custom user manager
- `user_identifier=username` (custom user model with Django's default `AbstractUser`
  fields instead of the email-only variant; both variants' checked-in
  `migrations/0001_initial.py` are confirmed to exactly match
  `manage.py makemigrations --check`)
- `use_redis=false` (synchronous task backend, no Redis/worker service generated)
- Custom `initial_app_name` + `use_async=true` (app directory renamed correctly, all
  internal imports follow, Dockerfile CMD switches to uvicorn)
- `open_source_license=Apache-2.0`
- `use_shinobi=false` (no API layer; an always-present smoke test keeps the suite
  non-empty)
- `use_vite=true` (Pico.css + Vite build pipeline, django-vite, home page rendered
  and `collectstatic` run against a `npm run build` manifest)
- `task_runner=justfile` + `use_vite=true` (`migrate`, `collectstatic`, `test`, `lint`,
  `typecheck`, and the frontend recipes all run through `just` rather than directly)
- `use_allauth=true` (login/signup/logout wired for the default email identifier;
  the home page's login/logout link and "Logged in user" text are covered by a new
  test)

`reusable_app`:

- Default answers, and `use_shinobi=false` — both also verified to `uv build` cleanly
- `task_runner=justfile` (`test`, `lint`, `typecheck`, and `build` run through `just`)

## Known limitations

- The `django-tasks-db` backend (Postgres-only, no Redis) mentioned in the original
  design spec was **not** used here in favor of the already-verified `ImmediateBackend`
  for the `use_redis=false` case — `django-tasks-db`'s exact API wasn't verified against
  a real install the way `django-tasks-rq` was, so it's left out rather than guessed at.
  Worth checking directly if you want durable (survives a restart) queuing without Redis.
