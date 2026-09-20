from .base import *  # noqa: F401,F403

DEBUG = False

PASSWORD_HASHERS = ["django.contrib.auth.hashers.MD5PasswordHasher"]

# Tasks run inline/synchronously during tests — no Redis dependency in CI.
TASKS = {
    "default": {
        "BACKEND": "django_tasks.backends.immediate.ImmediateBackend",
    }
}

# Captured in django.core.mail.outbox instead of sent — no mailpit dependency in CI.
EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"
