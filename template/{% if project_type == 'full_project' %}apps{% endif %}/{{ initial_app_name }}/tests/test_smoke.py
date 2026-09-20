import pytest
from django.core import mail

pytestmark = pytest.mark.django_db


def test_database_available(django_user_model):
    """Sanity check that the app and database are wired up.

    Uses USERNAME_FIELD rather than a hardcoded field name so this passes
    regardless of whether the custom user model is email- or username-identified.
    """
    user = django_user_model.objects.create_user(
        **{django_user_model.USERNAME_FIELD: "smoke@example.com"}, password="pw"
    )
    assert user.pk is not None


def test_email_captured_not_sent(mailoutbox):
    """Mail is captured in-memory during tests, not delivered via mailpit's SMTP."""
    mail.send_mail("Subject", "Body", "from@example.com", ["to@example.com"])
    assert len(mailoutbox) == 1
    assert mailoutbox[0].subject == "Subject"
