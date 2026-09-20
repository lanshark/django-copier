# Changelog for LANshark Django Project Copier Template

All notable changes to this project are documented in this file.

## Next Release

- Add a `pre-commit-autoupdate.yml` GitHub Actions workflow (this repo's own
  `.github/workflows/`, not part of the generated template) that runs
  `pre-commit autoupdate --config template/.pre-commit-config.yaml` nightly
  and opens a PR via `peter-evans/create-pull-request` if any hook revs
  changed — modeled on cookiecutter-django's
  `.github/workflows/pre-commit-autoupdate.yml`. Gated to
  `github.repository_owner == 'lanshark'` so a fork doesn't get scheduled
  auto-PRs against itself; also runnable manually via `workflow_dispatch`.
  Opens a normal PR for review rather than auto-merging. Drops the `labels:
  update` input the cookiecutter-django original uses — neither this repo nor
  a fresh repo has an `update` label, and GitHub's API 404s when you apply a
  label that doesn't exist, which would have failed the PR-creation step on
  its first real run. Closes #33
- Update pinned GitHub Actions versions across this repo's own
  `test-template.yml` and the four workflow templates it generates
  (`build.yml`, both `ci.yml` variants, `release.yml`) — `astral-sh/setup-uv`
  `v10.0.1` → `v10.1.0`, `docker/build-push-action` `v7.3.0` → `v7.4.0`,
  `actions/setup-node` `v4` → `v7.0.0`, and `extractions/setup-just` `v3` →
  `v4.0.0` (the latter two were previously pinned to unpinned major tags;
  now patch-pinned like the rest). `actions/checkout` and
  `docker/login-action` were already current. Closes #30
- Add a `storage_backend` question (full_project only, default `local`) wiring
  `django-storages` for user-uploaded media, alongside the existing static-file
  handling — choices are `local` (Django's built-in `FileSystemStorage`, no
  extra infra, the same package-free default full_project has always had),
  `s3` (`django-storages[s3]`, reading `AWS_STORAGE_BUCKET_NAME`; AWS
  credentials go through boto3's standard chain, mirroring how the SES email
  backend already handles them), and `azure` (`django-storages[azure]`,
  reading `AZURE_ACCOUNT_NAME`/`AZURE_ACCOUNT_KEY`/`AZURE_CONTAINER`).
  `config/settings/base.py` always defaults `STORAGES["default"]` to local
  `FileSystemStorage` regardless of the choice (so `manage.py migrate`/pytest
  need no cloud credentials in dev/test); `config/settings/prod.py` overrides
  it to S3/Azure when selected — the same split `EMAIL_BACKEND` already uses
  between base.py's mailpit default and prod.py's provider-specific override.
  New CI matrix entries `storage-s3`/`storage-azure` (`local` covered by
  `defaults`), and the existing "Check prod settings" step now also validates
  these. Closes #11
- Replace the README's placeholder Copier source with this repository's actual
  GitHub path, document `--vcs-ref=HEAD` for the latest template revision, and
  add a release-tag example for reproducible project creation
- Make `django_version` selectable between `5.2` (LTS, default) and `6.1` —
  parameterizes the hardcoded `django>=5.2,<5.3` dependency pin and
  `Framework :: Django :: 5.2` classifier in `pyproject.toml`, and the "Django
  5.2 LTS" mentions in the generated README/`docs/architecture.md`. Per issue
  #21, does NOT update the `django-tasks`/`django-tasks-rq` packages or touch
  `EMAIL_HOST` handling — Django 6.0+ ships its own built-in `django.tasks`
  framework that may overlap with the third-party packages this project uses,
  and email settings haven't been re-verified against Django 6's adoption of
  Python's modern email API. When `django_version == '6.1'`, the generated
  `docs/architecture.md` documents both as known, unaddressed caveats. Closes #21
- Make `postgres_version` selectable among `16`, `17`, and `18` (default `18`,
  full_project only) — parameterizes the hardcoded `postgres:17` image in
  `docker-compose.yml` and `ci.yml`, plus the Postgres mentions in the generated
  README and `docs/architecture.md`. New CI matrix entries `postgres-16`/
  `postgres-17` (18 covered by `defaults`) run the template's own `postgres`
  service container at the selected version, not just the rendered project's
  compose/CI config. Closes #13
- Make `python_version` selectable among `3.12`, `3.13`, and `3.14` (default
  `3.14`) — every template file already parameterized off this question
  (`pyproject.toml`'s `requires-python`/ruff/pyright config, the Dockerfile base
  image, both `ci.yml` variants), so this only widens `copier.yml`'s `choices`.
  New CI matrix entries `python-3.12`/`python-3.13` (full_project) and
  `app-python-3.12` (reusable_app) actually pin `uv sync --python` to the
  selected version rather than letting it silently resolve to whatever's already
  installed, so CI verifies the project really runs under the selected
  interpreter, not just that `requires-python`'s lower bound is satisfied
- Fix the `use_allauth` comment/doc wording (`config/settings/base.py`,
  `docs/architecture.md`) that referenced "the JWT API auth above" even when
  `use_shinobi=false`, when there's no JWT section to refer to — condition that
  clause on `use_shinobi` as well
- Fix `from django.urls import reverse` being imported unconditionally in
  `apps/<initial_app_name>/tests/test_views.py` — it's only used by the
  allauth-specific tests, so every non-allauth render failed `ruff check` with an
  unused-import (`F401`) error. Made the import conditional on `use_allauth`
- Add generated allauth view tests that exercise the real `/accounts/login/`,
  `/accounts/signup/`, and POST `/accounts/logout/` flows for both supported user
  identifier variants, so CI validates the allauth URL wiring and variant-specific
  account settings instead of only checking home-page markup after `force_login`
- Add a `use_allauth` question (full_project only, default `false`) wiring django-allauth's core account app (login/signup/logout, no social providers) at `/accounts/...`, entirely separate from the JWT API auth — `AUTHENTICATION_BACKENDS` must include both `django.contrib.auth.backends.ModelBackend` and `allauth.account.auth_backends.AuthenticationBackend` to keep Django admin permissions and allauth account auth working together. For the email identifier, also sets `ACCOUNT_LOGIN_METHODS`, `ACCOUNT_SIGNUP_FIELDS`, and `ACCOUNT_USER_MODEL_USERNAME_FIELD = None` (without it, allauth's signup form crashes looking for a `username` field that doesn't exist — found by testing the actual signup flow, not just reading docs); the username identifier needs no extra `ACCOUNT_*` settings since allauth's own defaults already match. No `django.contrib.sites`/`SITE_ID` needed for core functionality. Restructures the home page (`apps/<initial_app_name>/{views,urls}.py`, `templates/`, its test) to always exist instead of only under `use_vite` — `use_vite` and `use_allauth` now independently layer their own markup (Vite's `<head>` tags; a login/logout link and, when signed in, "Logged in user: ...") onto the same always-present page. New CI matrix entry `with-allauth`
- Add a `Ruff format` step to `test-template.yml` (both jobs) so CI validates that rendered projects are actually formatted, not just lint-clean — `ruff check` and `ruff format --check` catch different things, and only the former was checked before. Fixes two pre-existing formatting issues this surfaced: collapsed two over-wrapped calls in `apps/<initial_app_name>/auth.py`, and a missing blank line after the module docstring in the reusable_app's `example/manage.py`. Every *generated* project's own CI already covers this via `pre-commit run --all-files` (which includes the `ruff-format` hook); this only closes the gap in the template's own validation of its committed source files
- Add a `user_identifier` question (full_project only: `Email address` default or
  `Username`) that generates a custom `apps/accounts` user model
  (`AUTH_USER_MODEL = "accounts.User"`) from the start, since swapping the user
  model later is notoriously painful in Django. Email variant removes `username`
  entirely and makes `email` the `USERNAME_FIELD`, with its own admin
  create/change forms (Django's defaults reference `username`); username variant
  keeps `AbstractUser`'s fields as-is. Both ship a real, generated (not
  hand-guessed) `migrations/0001_initial.py`, verified against
  `manage.py makemigrations --check`. When `use_shinobi=true`, the JWT
  token/`/me` endpoints and schemas track whichever field was chosen.
  `initial_app_name` can no longer be `accounts` (a copier `validator:` rejects
  the collision). Also fixes `apps/<initial_app_name>/tests/test_smoke.py`,
  which previously hardcoded `username=` and would have broken for the email
  variant
- Add `mailpit` to the generated full-project `web` and Redis `worker`
  `depends_on` blocks, and pass `DJANGO_EMAIL_HOST=mailpit` through a
  compose-only env file, with a `readyz` healthcheck gating those
  dependencies, so Docker local email delivery does not race the SMTP
  container startup or clobber sibling service environment mappings
- Set a dummy `DJANGO_DEFAULT_FROM_EMAIL` in the template CI's `email-*`
 production-settings check so those jobs validate provider config with an
 explicit sender address
- Fix `pyproject.toml.jinja` referencing `django-anymail[postmark]`/`django-anymail[mailgun]` — extras that don't exist in the package (verified against its PyPI metadata; only `amazon-ses`, `postal`, `resend`, `sendgrid`, and `uts46` are real) — back to plain `django-anymail` for those two providers, drop the now-redundant standalone `boto3` dependency (already pulled in by the `amazon-ses` extra), and remove the `email_provider` "unsupported provider" guards added across `pyproject.toml.jinja`/`prod.py.jinja`/`architecture.md.jinja`, which were unreachable dead code since copier's own `choices:` validation already rejects an invalid `email_provider` before any template renders; also fix a README code span split across a line wrap (rendered as `config.settings. prod` with a stray space)
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
