import pytest
from model_bakery import baker

pytestmark = pytest.mark.django_db


def test_health(client):
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_token_and_me(client):
    user = baker.make("auth.User", username="scott")
    user.set_password("s3cret-pw")
    user.save()

    resp = client.post(
        "/api/v1/auth/token",
        data={"username": "scott", "password": "s3cret-pw"},
        content_type="application/json",
    )
    assert resp.status_code == 200
    access = resp.json()["access"]

    me_resp = client.get(
        "/api/v1/me",
        headers={"Authorization": f"Bearer {access}"},
    )
    assert me_resp.status_code == 200
    assert me_resp.json()["username"] == "scott"
