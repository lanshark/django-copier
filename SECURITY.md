# Security Policy

## Supported Versions

Security fixes are made on the current `main` branch. When release tags are
published, the latest release is the supported released version.

## Reporting a Vulnerability

Please do not report security vulnerabilities through public GitHub issues.

Report them privately by email to [ssharkey@lanshark.com](mailto:ssharkey@lanshark.com)
with the subject `django-copier security report`.

Include, where possible:

- A description of the vulnerability and its impact.
- Steps to reproduce it or a minimal proof of concept.
- The affected template version, commit, or generated-project configuration.
- Any suggested mitigation.

Maintainers will acknowledge the report, investigate it, and coordinate a fix
and disclosure with the reporter. Please allow time for a fix before sharing
details publicly.

## Scope

Reports are in scope when they concern this repository's template, its
automation, or insecure defaults it generates. A generated application may also
have security issues caused by its own code, deployment, dependencies, or
configuration; report those to the maintainers of that application.

## Disclosure

After a fix is available, maintainers will document the impact and remediation
in the repository's changelog or release notes as appropriate. Reporters may be
credited with their permission.
