import pytest
from unittest.mock import patch
from app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok", "version": "3.0"}


def test_index(client):
    response = client.get("/")
    assert response.status_code == 200


def test_image_not_found(client):
    response = client.get("/images/nonexistent.jpg")
    assert response.status_code == 404
    assert response.get_json()["error"] == "Image not found"


def test_image_found(client):
    with patch("os.path.exists", return_value=True), \
         patch("app.send_file", return_value=app.response_class(status=200)):
        response = client.get("/images/me.jpg")
        assert response.status_code == 200
