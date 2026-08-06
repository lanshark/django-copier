To ensure all assistant-generated code and suggestions are consistent with our project's standards, please follow these rules:

## Working Principles

- Preserve the user's understanding of the codebase. Favor changes that are easy to review, explain, and reason about locally.
- Default to supervised work: propose the next step, get approval, implement only that step, then stop.
- Keep concerns separate and changes reviewable. Do not combine unrelated changes or multiple layers of change in one step when they can be reviewed independently.
- Prefer the smallest useful change over broader restructuring. Avoid adding abstractions or infrastructure unless they are clearly needed for the approved step.
- Do not take irreversible workflow actions without explicit approval. Do not stage, commit, or conclude merges unless the user explicitly asks.

## Code Change Behavior Guidelines

- Always present a proposed plan or patch summary first and wait for approval.
- Do not begin implementation until the user has approved the proposed plan or patch summary.
- After staging changes, stop and wait for review/approval before committing.
- Make small, isolated commits that change one concern at a time.
- Do not bundle merge conflict resolution, architectural changes, and follow-up cleanup into one commit.
- Make changes that are easy to verify and easy to revert.
- After each small change, remove dead code only if it is directly related to that change.
- If a requested change is broad, break it into a sequence of smaller steps and implement the smallest useful step first.
- When in doubt, optimize for debuggability over speed of refactor.
- If the correct solution spans multiple logical steps, stop after the first approved step unless the user explicitly asks you to continue through the rest.

## General Python Style

- Use 4 spaces for indentation.
- Limit lines to 88 characters.
- Use double quotes for docstrings and double quotes for strings, unless single quotes are required.
- Use f-strings for string interpolation.
- Use type hints for all function arguments and return values where possible.
- Use snake_case for function and variable names.
- Use PascalCase for class names.
- Always include a docstring for public functions and classes.
- Use explicit imports; avoid wildcard imports.
- Place standard library imports first, then third-party, then local imports, separated by blank lines as required by `isort`.
- Avoid unnecessary else/elif after return or raise.
- Use logging instead of print statements.
- Use is not None and is None for None checks.
- Use if x: and if not x: for truthy checks, unless explicit comparison is needed.
- use the top-level .venv python environment

## Formatting and Linting

- Code must not introduce new lint errors under `ruff` or `pre-commit` with the
current config.
- Use docstrings in Google style.
- Do not suppress linter warnings unless absolutely necessary.
