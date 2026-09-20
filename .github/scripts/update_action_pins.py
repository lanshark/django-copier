"""Bump pinned `uses:` GitHub Actions versions to their latest release tag.

Scans `.github/workflows/` and `template/.github/workflows/` for `uses:
owner/repo@ref` lines and rewrites each ref to the highest semver tag
published by that action's repository, leaving local (`./`) and
`docker://` references untouched. Copier's conditionally-named template
workflow files (e.g. `{% if ... %}build.yml{% endif %}`) don't end in
`.yml`, so files are discovered by directory rather than by extension.

Used only by `.github/workflows/pre-commit-autoupdate.yml` in this repo;
not part of the generated template.
"""

from __future__ import annotations

import json
import logging
import os
import re
import urllib.request
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger(__name__)

USES_RE = re.compile(
    r"^(?P<prefix>\s*(?:-\s*)?uses:\s*)(?P<repo>[\w.-]+/[\w.-]+)@(?P<ref>\S+)"
)
TARGET_DIRS = [Path(".github/workflows"), Path("template/.github/workflows")]


def find_workflow_files() -> list[Path]:
    """Return every file under the target workflow directories."""
    files = []
    for directory in TARGET_DIRS:
        if not directory.is_dir():
            continue
        files.extend(sorted(p for p in directory.iterdir() if p.is_file()))
    return files


def find_pinned_repos(files: list[Path]) -> set[str]:
    """Return the set of `owner/repo` names pinned via `uses:` in files."""
    repos: set[str] = set()
    for file in files:
        for line in file.read_text().splitlines():
            match = USES_RE.match(line)
            if match is None:
                continue
            repo = match.group("repo")
            if repo.startswith("./") or repo.startswith("docker:"):
                continue
            repos.add(repo)
    return repos


def fetch_tags(repo: str, token: str | None) -> list[str]:
    """Fetch all tag names for a GitHub repo, following pagination."""
    tags: list[str] = []
    url = f"https://api.github.com/repos/{repo}/tags?per_page=100"
    while url:
        request = urllib.request.Request(url)
        request.add_header("Accept", "application/vnd.github+json")
        if token:
            request.add_header("Authorization", f"Bearer {token}")
        with urllib.request.urlopen(request) as response:
            tags.extend(entry["name"] for entry in json.load(response))
            link_header = response.headers.get("Link", "")
        url = ""
        for link in link_header.split(","):
            if 'rel="next"' in link:
                url = link.split(";")[0].strip().strip("<>")
    return tags


def highest_semver_tag(tags: list[str]) -> str | None:
    """Return the tag with the highest `vX.Y.Z`-style version, if any."""
    best_version: tuple[int, ...] | None = None
    best_tag: str | None = None
    for tag in tags:
        parts = tag.removeprefix("v").split(".")
        if not parts or not all(part.isdigit() for part in parts):
            continue
        version = tuple(int(part) for part in parts)
        if best_version is None or version > best_version:
            best_version, best_tag = version, tag
    return best_tag


def latest_versions(repos: set[str], token: str | None) -> dict[str, str]:
    """Resolve each repo's highest semver tag, skipping any with none found."""
    latest: dict[str, str] = {}
    for repo in sorted(repos):
        tag = highest_semver_tag(fetch_tags(repo, token))
        if tag is not None:
            latest[repo] = tag
        else:
            logger.warning("no semver tags found for %s, leaving as-is", repo)
    return latest


def update_files(files: list[Path], latest: dict[str, str]) -> None:
    """Rewrite each file's `uses:` lines to the resolved latest versions."""
    for file in files:
        lines = file.read_text().splitlines()
        changed = False
        for index, line in enumerate(lines):
            match = USES_RE.match(line)
            if match is None:
                continue
            repo = match.group("repo")
            new_ref = latest.get(repo)
            if new_ref is None or new_ref == match.group("ref"):
                continue
            logger.info("%s: %s@%s -> %s", file, repo, match.group("ref"), new_ref)
            lines[index] = (
                f"{match.group('prefix')}{repo}@{new_ref}{line[match.end() :]}"
            )
            changed = True
        if changed:
            file.write_text("\n".join(lines) + "\n")


def main() -> None:
    """Bump every pinned GitHub Action to its latest release tag."""
    token = os.environ.get("GITHUB_TOKEN")
    files = find_workflow_files()
    repos = find_pinned_repos(files)
    latest = latest_versions(repos, token)
    update_files(files, latest)


if __name__ == "__main__":
    main()
