# Changelog for LANshark Django Project Copier Template

All notable changes to this project are documented in this file.

## Next Release

-

## 2026-08-06: Release-2026.08.06.01

- Add project license selection (MIT, BSD-3-Clause, Apache-2.0, GNU GPLv3, GNU AGPLv3, Proprietary, or None): renders a matching LICENSE from `template/licenses/`, sets pyproject license metadata, adds a README license section, and covers a licensed render in CI
- Ship the repo's AGENTS.md coding standards to generated projects, single-sourced from the root AGENTS.md via a Jinja `{% include %}`
- Add CLAUDE.md to generated projects, importing AGENTS.md via `@AGENTS.md`
- Add a generic CHANGELOG.md to generated projects, titled from the project name
- Add CLAUDE.md and CHANGELOG.md for the template repo itself
