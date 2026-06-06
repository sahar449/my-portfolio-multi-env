import os
import pytest
import requests

FRONTEND_URL = os.environ["STAGING_FRONTEND_URL"].rstrip("/")
BACKEND_URL = os.environ["STAGING_BACKEND_URL"].rstrip("/")


# ── Frontend ────────────────────────────────────────────────────────────────

def test_frontend_health():
    r = requests.get(f"{FRONTEND_URL}/health", timeout=10)
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_frontend_version():
    r = requests.get(f"{FRONTEND_URL}/health", timeout=10)
    assert r.json()["version"] == "7.0"


def test_frontend_index():
    r = requests.get(f"{FRONTEND_URL}/", timeout=10)
    assert r.status_code == 200


def test_frontend_image_not_found():
    r = requests.get(f"{FRONTEND_URL}/images/nonexistent.jpg", timeout=10)
    assert r.status_code == 404
    assert r.json()["error"] == "Image not found"


# ── Backend ─────────────────────────────────────────────────────────────────

def test_backend_health():
    r = requests.get(f"{BACKEND_URL}/health", timeout=10)
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_backend_health_db():
    r = requests.get(f"{BACKEND_URL}/health/db", timeout=10)
    assert r.status_code in [200, 503]
    body = r.json()
    assert "db" in body


def test_backend_profile_returns_valid_response():
    r = requests.get(f"{BACKEND_URL}/profile", timeout=10)
    assert r.status_code in [200, 503]
    if r.status_code == 200:
        body = r.json()
        assert "name" in body


def test_backend_certificates_returns_valid_response():
    r = requests.get(f"{BACKEND_URL}/certificates", timeout=10)
    assert r.status_code in [200, 503]
    if r.status_code == 200:
        assert isinstance(r.json(), list)
