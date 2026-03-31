"""
Unit tests for /api/artifacts/, /api/scan/, and /api/orders/.

Run with:
    python manage.py test artifacts.tests
"""

import io
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient

from artifacts.models import Country, Villa, Artifact, Story
from orders.models import Order


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _make_country(name="Ethiopia", code="ET"):
    return Country.objects.create(name=name, code=code)


def _make_villa(country, name="Kuriftu Addis"):
    return Villa.objects.create(name=name, country=country, location="Addis Ababa")


def _make_artifact(country, villa=None, name="Coffee Table", price="99.99"):
    return Artifact.objects.create(
        name=name, country=country, villa=villa,
        description="A test artifact.", price=price,
    )


def _make_story(artifact, title="Test Story"):
    return Story.objects.create(
        artifact=artifact,
        title=title,
        story="Once upon a time in a cultural land...",
        materials="Wood and clay",
        cultural_significance="Very significant.",
        ai_generated=False,
    )


def _fake_image(filename="artifact.jpg", content_type="image/jpeg"):
    """Returns an in-memory image file suitable for multipart upload."""
    img = io.BytesIO(b"\xff\xd8\xff" + b"\x00" * 100)   # minimal JPEG magic bytes
    img.name = filename
    img.content_type = content_type
    return img


# ═══════════════════════════════════════════════════════════════════════════════
#  /api/artifacts/
# ═══════════════════════════════════════════════════════════════════════════════

class ArtifactListTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.et = _make_country("Ethiopia", "ET")
        self.ma = _make_country("Morocco", "MA")
        self.villa1 = _make_villa(self.et, "Kuriftu Addis")
        self.villa2 = _make_villa(self.ma, "Riad Al Fez")
        self.a1 = _make_artifact(self.et, self.villa1, "Coffee Table")
        self.a2 = _make_artifact(self.et, self.villa1, "Mesob Basket", "74.99")
        self.a3 = _make_artifact(self.ma, self.villa2, "Zellige Table", "349.00")
        _make_story(self.a1, "Heart of the Ceremony")

    def test_list_all_artifacts(self):
        res = self.client.get("/api/artifacts/")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["count"], 3)

    def test_filter_by_country(self):
        res = self.client.get(f"/api/artifacts/?country={self.et.pk}")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["count"], 2)

    def test_filter_by_villa(self):
        res = self.client.get(f"/api/artifacts/?villa={self.villa2.pk}")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["count"], 1)
        self.assertEqual(res.data["results"][0]["name"], "Zellige Table")

    def test_filter_country_invalid_id(self):
        res = self.client.get("/api/artifacts/?country=abc")
        self.assertEqual(res.status_code, 400)

    def test_filter_villa_invalid_id(self):
        res = self.client.get("/api/artifacts/?villa=xyz")
        self.assertEqual(res.status_code, 400)

    def test_filter_country_not_found(self):
        res = self.client.get("/api/artifacts/?country=9999")
        self.assertEqual(res.status_code, 404)

    def test_nested_story_returned(self):
        res = self.client.get(f"/api/artifacts/?country={self.et.pk}")
        results = res.data["results"]
        coffee = next(r for r in results if r["name"] == "Coffee Table")
        self.assertIsNotNone(coffee["story"])
        self.assertEqual(coffee["story"]["title"], "Heart of the Ceremony")

    def test_artifact_without_story_returns_null_story(self):
        res = self.client.get(f"/api/artifacts/?country={self.et.pk}")
        results = res.data["results"]
        mesob = next(r for r in results if r["name"] == "Mesob Basket")
        self.assertIsNone(mesob["story"])


# ═══════════════════════════════════════════════════════════════════════════════
#  /api/scan/
# ═══════════════════════════════════════════════════════════════════════════════

class ScanArtifactTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.et = _make_country("Ethiopia", "ET")
        self.artifact = _make_artifact(
            self.et, name="Ethiopian Coffee Ceremony Table", price="189.99"
        )
        _make_story(self.artifact, "The Heart of the Ceremony")

    def test_scan_with_image_returns_200(self):
        img = _fake_image("coffee_ceremony.jpg")
        res = self.client.post("/api/scan/", {"image": img}, format="multipart")
        self.assertEqual(res.status_code, 200)
        self.assertIn("artifact_name", res.data)
        self.assertIn("country", res.data)
        self.assertIn("confidence", res.data)
        self.assertIn("story", res.data)

    def test_scan_artifact_name_fallback(self):
        """Backwards-compatible: artifact_name text still works."""
        res = self.client.post(
            "/api/scan/",
            {"artifact_name": "Ethiopian Coffee Ceremony Table"},
            format="multipart",
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["artifact_name"], "Ethiopian Coffee Ceremony Table")

    def test_scan_no_payload_returns_400(self):
        res = self.client.post("/api/scan/", {}, format="multipart")
        self.assertEqual(res.status_code, 400)

    def test_scan_confidence_is_float(self):
        img = _fake_image("berber_carpet.jpg")
        res = self.client.post("/api/scan/", {"image": img}, format="multipart")
        self.assertIsInstance(res.data["confidence"], float)

    def test_scan_known_artifact_returns_price(self):
        img = _fake_image("coffee_ceremony_table.jpg")
        res = self.client.post("/api/scan/", {"image": img}, format="multipart")
        # The mock may or may not return the exact artifact; check structure
        self.assertIn("price", res.data)
        self.assertIn("image_url", res.data)

    def test_scan_unknown_artifact_returns_note(self):
        res = self.client.post(
            "/api/scan/",
            {"artifact_name": "Completely Unknown Object XYZ"},
            format="multipart",
        )
        self.assertEqual(res.status_code, 200)
        # Artifact not in DB → AI-generated story with a note
        self.assertIn("note", res.data)

    def test_scan_image_wrong_type_returns_400(self):
        bad_file = io.BytesIO(b"not an image")
        bad_file.name = "file.txt"
        bad_file.content_type = "text/plain"
        res = self.client.post("/api/scan/", {"image": bad_file}, format="multipart")
        self.assertEqual(res.status_code, 400)


# ═══════════════════════════════════════════════════════════════════════════════
#  /api/orders/ and /api/order/
# ═══════════════════════════════════════════════════════════════════════════════

class OrderTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.et = _make_country("Ethiopia", "ET")
        self.artifact = _make_artifact(self.et, name="Coffee Table", price="99.99")

    # ── GET /api/orders/ ──────────────────────────────────────────────────────

    def test_list_orders_requires_email(self):
        res = self.client.get("/api/orders/")
        self.assertEqual(res.status_code, 400)

    def test_list_orders_invalid_email_returns_400(self):
        res = self.client.get("/api/orders/?email=notanemail")
        self.assertEqual(res.status_code, 400)

    def test_list_orders_valid_email_no_orders(self):
        res = self.client.get("/api/orders/?email=nobody@example.com")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data, [])

    def test_list_orders_returns_matching_orders(self):
        Order.objects.create(
            artifact=self.artifact,
            user_email="guest@example.com",
            quantity=2,
            status=Order.Status.PENDING,
        )
        res = self.client.get("/api/orders/?email=guest@example.com")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(len(res.data), 1)
        self.assertEqual(res.data[0]["quantity"], 2)

    def test_list_orders_case_insensitive_email(self):
        Order.objects.create(
            artifact=self.artifact,
            user_email="Guest@Example.COM",
            quantity=1,
        )
        res = self.client.get("/api/orders/?email=guest@example.com")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(len(res.data), 1)

    # ── POST /api/order/ ──────────────────────────────────────────────────────

    def test_create_order_success(self):
        payload = {
            "artifact": self.artifact.pk,
            "user_email": "buyer@example.com",
            "quantity": 1,
        }
        res = self.client.post("/api/order/", payload, format="json")
        self.assertEqual(res.status_code, 201)
        self.assertEqual(res.data["status"], "Pending")
        self.assertEqual(res.data["quantity"], 1)

    def test_create_order_default_quantity_is_1(self):
        payload = {
            "artifact": self.artifact.pk,
            "user_email": "buyer@example.com",
        }
        res = self.client.post("/api/order/", payload, format="json")
        self.assertEqual(res.status_code, 201)
        self.assertEqual(res.data["quantity"], 1)

    def test_create_order_invalid_email(self):
        payload = {
            "artifact": self.artifact.pk,
            "user_email": "not-an-email",
            "quantity": 1,
        }
        res = self.client.post("/api/order/", payload, format="json")
        self.assertEqual(res.status_code, 400)

    def test_create_order_missing_artifact_returns_400(self):
        payload = {"user_email": "buyer@example.com", "quantity": 1}
        res = self.client.post("/api/order/", payload, format="json")
        self.assertEqual(res.status_code, 400)

    def test_create_order_nonexistent_artifact_returns_400(self):
        payload = {
            "artifact": 9999,
            "user_email": "buyer@example.com",
            "quantity": 1,
        }
        res = self.client.post("/api/order/", payload, format="json")
        self.assertEqual(res.status_code, 400)

    def test_create_order_zero_quantity_returns_400(self):
        payload = {
            "artifact": self.artifact.pk,
            "user_email": "buyer@example.com",
            "quantity": 0,
        }
        res = self.client.post("/api/order/", payload, format="json")
        self.assertEqual(res.status_code, 400)

    def test_create_order_status_defaults_to_pending(self):
        payload = {
            "artifact": self.artifact.pk,
            "user_email": "buyer@example.com",
            "quantity": 3,
        }
        res = self.client.post("/api/order/", payload, format="json")
        order = Order.objects.get(pk=res.data["id"])
        self.assertEqual(order.status, Order.Status.PENDING)
