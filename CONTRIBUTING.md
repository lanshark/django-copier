# Contributing to django-copier

Thank you for contributing to django-copier. This repository is a Copier
template: changes normally affect projects generated from `template/`, rather
than a Python package installed from this repository.

## Before You Start

- Check existing issues and pull requests before starting work.
- Discuss a substantial feature or a change to generated-project defaults in an
  issue first.
- Read `AGENTS.md`, `README.md`, and the relevant files under `template/`.

## Development Setup

You need Git, Python 3.12 or newer, and Copier. Docker is required to exercise
the generated full-project template in the same way as its CI.

```bash
git clone https://github.com/lanshark/django-copier.git
cd django-copier
uv tool install copier
```

If you already have Copier installed, use that command instead. The template
itself does not have a root Python package or a root `pyproject.toml`.

## Making a Change

1. Create a focused branch from `main`.
2. Change `copier.yml` and files under `template/` as needed.
3. Add a concise entry under `Next Release` in `CHANGELOG.md`.
4. Update generated-project documentation when the behavior or a prompt changes.
5. Render the affected configuration locally.

For example, render the default full project into a disposable directory:

```bash
copier copy --defaults --force . /tmp/django-copier-rendered
```

To exercise a non-default option, pass it explicitly:

```bash
copier copy --defaults --force --data use_shinobi=false . /tmp/django-copier-rendered
```

Follow the generated project's README for its Docker, migration, test, lint,
format, and type-check commands. The repository's GitHub Actions workflow is
the authoritative full validation: it renders representative configurations and
runs migrations, tests, Ruff, formatting, Pyright, and package builds.

## Pull Requests

Keep each pull request focused on one concern. In the description, include:

- What changed and why.
- Which Copier configurations are affected.
- How you verified the change locally.
- Any required update or migration guidance for existing generated projects.

Before requesting review, ensure the rendered project checks pass for the
configuration you changed and that the GitHub Actions checks are green.

## Code Style

Generated Python code follows the conventions in `AGENTS.md`: four-space
indentation, double quotes, type hints where practical, Google-style docstrings
for public APIs, and an 88-character target where the project configuration
requires it. Keep template conditionals small and make generated output easy to
review.

## Getting Help

Use GitHub Discussions for questions and ideas. Use issues for reproducible
bugs and well-defined feature requests. Do not report security vulnerabilities
in public issues; see `SECURITY.md` instead.

## License

By contributing, you agree that your contributions are licensed under the MIT
License.
