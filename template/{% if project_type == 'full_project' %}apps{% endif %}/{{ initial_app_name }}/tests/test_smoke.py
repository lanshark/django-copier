import pytest

pytestmark = pytest.mark.django_db


def test_database_available(django_user_model):
    """Sanity check that the app and database are wired up."""
    user = django_user_model.objects.create_user(username="smoke", password="pw")
    assert user.pk is not None
