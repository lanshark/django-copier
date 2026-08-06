from datetime import UTC, datetime, timedelta

import jwt
from django.conf import settings
from django.contrib.auth import get_user_model
from ninja.security import HttpBearer

User = get_user_model()


def _make_token(user, lifetime: timedelta, token_type: str) -> str:
    now = datetime.now(tz=UTC)
    payload = {
        "sub": str(user.pk),
        "type": token_type,
        "iat": now,
        "exp": now + lifetime,
    }
    return jwt.encode(payload, settings.JWT_SIGNING_KEY, algorithm="HS256")


def make_access_token(user) -> str:
    return _make_token(
        user, timedelta(minutes=settings.JWT_ACCESS_TOKEN_LIFETIME_MIN), "access"
    )


def make_refresh_token(user) -> str:
    return _make_token(
        user, timedelta(days=settings.JWT_REFRESH_TOKEN_LIFETIME_DAYS), "refresh"
    )


class JWTAuth(HttpBearer):
    """Bearer-token auth for django-shinobi routers. Attach with `auth=JWTAuth()`."""

    def authenticate(self, request, token: str):
        try:
            payload = jwt.decode(token, settings.JWT_SIGNING_KEY, algorithms=["HS256"])
        except jwt.PyJWTError:
            return None

        if payload.get("type") != "access":
            return None

        try:
            user = User.objects.get(pk=payload["sub"])
        except User.DoesNotExist:
            return None

        request.user = user
        return user
