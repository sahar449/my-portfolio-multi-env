import os
import pytest
from playwright.sync_api import Page, expect

FRONTEND_URL = os.environ["STAGING_FRONTEND_URL"].rstrip("/")


def test_homepage_loads(page: Page):
    page.goto(FRONTEND_URL)
    expect(page).to_have_title(lambda t: len(t) > 0)
    expect(page.locator("body")).to_be_visible()


def test_profile_section_visible(page: Page):
    page.goto(FRONTEND_URL)
    expect(page.locator("text=sahar", case_sensitive=False)).to_be_visible(timeout=10000)


def test_certificates_section_visible(page: Page):
    page.goto(FRONTEND_URL)
    page.get_by_role("link", name="Certificates").click()
    expect(page.locator("[data-testid='certificates']")).to_be_visible(timeout=10000)


def test_404_page(page: Page):
    response = page.goto(f"{FRONTEND_URL}/nonexistent-page-xyz")
    assert response.status == 404
