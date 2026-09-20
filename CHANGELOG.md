# Changelog for LANshark Django Project Copier Template

All notable changes to this project are documented in this file.

## Next Release

- Add `mailpit` to the generated full-project `web` and Redis `worker`
  `depends_on` blocks, and pass `DJANGO_EMAIL_HOST=mailpit` through a
  compose-only env file, so Docker local email delivery does not race the SMTP
  container startup or clobber sibling service environment mappings
- Set a dummy `DJANGO_DEFAULT_FROM_EMAIL` in the template CI's `email-*`
 production-settings check so those jobs validate provider config with an
 explicit sender address
- Install the matching `django-anymail` extras for full-project Postmark and
 Mailgun renders, while keeping reusable-app renders free of the full-project-
 only `django-anymail` dependency selection, default missing or empty
 production `email_provider` values to SES, fail fast on unsupported provider
 values, and install `boto3` for Amazon SES renders, so generated production
 email backends have their provider dependencies out of the box
- Clarify the full-project generated README's non-Docker dev instructions so local
 `uv run ... runserver` users know to run `docker compose up mailpit`, which publishes
  Mailpit's SMTP listener on `localhost:1025` and its web UI on `localhost:8025`
- Make the full-project Mailpit SMTP defaults work for both documented local-dev paths by defaulting `DJANGO_EMAIL_HOST` to `localhost` for non-Docker runs, publishing Mailpit's SMTP port on `127.0.0.1:1025`, and overriding Docker `web`/`worker` services to use the `mailpit` hostname
- Add an `email_provider` question (full_project only: `Amazon SES` default, `Postmark`, `Mailgun`, or `SendGrid`) wiring production email through `django-anymail`. `config/settings/prod.py` (converted to `prod.py.jinja`) sets `EMAIL_BACKEND` to the chosen provider's anymail backend and, for Postmark/Mailgun/SendGrid, a required `ANYMAIL` dict sourced from env (`ANYMAIL_POSTMARK_SERVER_TOKEN`, `ANYMAIL_MAILGUN_API_KEY`/`ANYMAIL_MAILGUN_SENDER_DOMAIN`, or `ANYMAIL_SENDGRID_API_KEY`); SES needs no `ANYMAIL` setting since boto3 reads AWS credentials via its standard chain. `pyproject.toml` picks the right `django-anymail` extra (`amazon-ses`/`sendgrid`) per provider. Local dev (`mailpit`) and tests (`locmem`) are unaffected — this only changes `config.settings.prod`. CI gains `email-ses`/`email-postmark`/`email-mailgun`/`email-sendgrid` matrix entries running `manage.py check` under `config.settings.prod` with dummy provider secrets, since nothing previously exercised `prod.py` at all
- Add a `mailpit` service to every full_project's `docker-compose.yml` (dev-only SMTP catcher, web UI at `localhost:8025`) with `config/settings/base.py` pointing `EMAIL_HOST`/`EMAIL_PORT` at it by default (env-overridable for a real relay in prod); `config/settings/test.py` uses Django's `locmem` backend instead, so tests and CI never need a live SMTP server. Documented in `README.md` and `docs/architecture.md`, and covered by a new smoke test asserting mail lands in `mailoutbox` during tests
- Add a `task_runner` question (`Makefile`/`Justfile`, default `Makefile`) so generated projects can choose their dev-command runner. Both project types get a Justfile mirroring their Makefile's targets (full_project: Docker/Django/database/quality/document-first, plus `use_vite` frontend recipes when enabled; reusable_app: quality/Django/packaging/document-first, including the interactive `publish` confirmation), using `just`'s native doc-comments and `just --list` instead of `make help`'s hand-rolled parser. `README.md`, `docs/architecture.md`, `AGENTS.md`, the module-level `apps/<app>/AGENTS.md`/`src/<package>/AGENTS.md`, and the reusable_app's generated `README.md` reference whichever runner was chosen. CI gains `with-justfile`/`app-justfile` matrix entries that install `just` and run the rendered project's `migrate`/`collectstatic`/`test`/`lint`/`typecheck`/`build`/frontend recipes through it, rather than just checking that the Justfile renders
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
