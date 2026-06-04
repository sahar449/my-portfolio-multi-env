import pytest
from unittest.mock import patch, MagicMock
import app as backend_app
from app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok", "version": "4.0"}


def test_health_db_not_configured(client):
    with patch.object(backend_app, "DB_AVAILABLE", False):
        response = client.get("/health/db")
        assert response.status_code == 503
        assert response.get_json()["db"] == "not configured"


def test_profile_no_db(client):
    with patch.object(backend_app, "DB_AVAILABLE", False):
        response = client.get("/profile")
        assert response.status_code == 503


def test_certificates_no_db(client):
    with patch.object(backend_app, "DB_AVAILABLE", False):
        response = client.get("/certificates")
        assert response.status_code == 503


def test_health_db_connected(client):
    mock_conn = MagicMock()
    with patch.object(backend_app, "DB_AVAILABLE", True), \
         patch("app.get_db", return_value=mock_conn):
        response = client.get("/health/db")
        assert response.status_code == 200
        assert response.get_json()["db"] == "connected"


def test_profile_with_db(client):
    mock_conn = MagicMock()
    mock_conn.cursor.return_value.__enter__.return_value.fetchone.return_value = {
        "id": 1, "name": "Sahar", "title": "DevOps Engineer"
    }
    with patch.object(backend_app, "DB_AVAILABLE", True), \
         patch("app.get_db", return_value=mock_conn):
        response = client.get("/profile")
        assert response.status_code == 200
        assert response.get_json()["name"] == "Sahar"
