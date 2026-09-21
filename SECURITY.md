# Security Policy

## Supported Versions

Use this section to tell people about which versions of your project are
currently being supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 0.x     | :white_check_mark: |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to:
- **Email**: ssharkey@lanshark.com (monitored by maintainers)
- **Subject**: django-copier Security Issue
  
Include the following information:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### What to expect

- **Initial response**: Within 48 hours
- **Status updates**: Every 72 hours until resolved
- **Fix timeline**: Critical issues within 7 days, others within 30 days
- **Credit**: Security researchers will be credited in release notes (unless you prefer to remain anonymous)

## Security Best Practices

django-copier generates projects with security best practices by default:

- ✅ HSTS and secure cookies enabled in production (CSP headers with `security_profile=strict`)
- ✅ `pip-audit` and `safety` shipped as dev dependencies for local dependency audits
- ✅ Container images scanned with Trivy in CI
- ✅ No secrets in repository (environment-based config)

For enhanced security, use `security_profile: strict` when generating your project.

## Disclosure Policy

When we receive a security report:

1. We confirm the vulnerability and determine severity
2. We develop and test a fix
3. We release a patch version
4. We publicly disclose the vulnerability 7 days after the patch release

## Security Hall of Fame

We recognize and thank security researchers who help keep Django Keel secure.

*No security reports yet - be the first!*

---

Thank you for helping keep django-copier and our community safe! 🛡️



