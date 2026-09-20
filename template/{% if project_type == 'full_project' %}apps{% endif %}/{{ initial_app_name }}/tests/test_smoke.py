import pytest
from django.core import mail

pytestmark = pytest.mark.django_db


def test_database_available(django_user_model):
    """Sanity check that the app and database are wired up."""
    user = django_user_model.objects.create_user(username="smoke", password="pw")
    assert user.pk is not None


def test_email_captured_not_sent(mailoutbox):
    """Mail is captured in-memory during tests, not delivered via mailpit's SMTP."""
    mail.send_mail("Subject", "Body", "from@example.com", ["to@example.com"])
    assert len(mailoutbox) == 1
    assert mailoutbox[0].subject == "Subject"
