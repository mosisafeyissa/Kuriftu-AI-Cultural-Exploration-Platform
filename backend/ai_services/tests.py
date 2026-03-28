"""
Tests for the ai_services app.
"""
from unittest.mock import patch, MagicMock

from django.test import TestCase, override_settings
from rest_framework.test import APIClient
from rest_framework import status as http_status
from io import BytesIO
from PIL import Image

from .services import identify_object, generate_story
from .utils import parse_json_response, validate_identification, validate_story


class ParseJsonResponseTest(TestCase):
    """Test the JSON parsing utility that handles messy AI output."""

    def test_pure_json(self):
        text = '{"artifact_name": "Chair", "country": "Ethiopia"}'
        result = parse_json_response(text)
        self.assertEqual(result["artifact_name"], "Chair")

    def test_json_in_code_fence(self):
        text = '```json\n{"artifact_name": "Chair"}\n```'
        result = parse_json_response(text)
        self.assertEqual(result["artifact_name"], "Chair")

    def test_json_with_surrounding_text(self):
        text = 'Here is the result:\n{"artifact_name": "Chair"}\nDone.'
        result = parse_json_response(text)
        self.assertEqual(result["artifact_name"], "Chair")

    def test_empty_string(self):
        self.assertIsNone(parse_json_response(""))

    def test_no_json(self):
        self.assertIsNone(parse_json_response("This has no JSON at all."))


class ValidateIdentificationTest(TestCase):
    """Test the identification validator."""

    def test_valid_data(self):
        data = {
            "artifact_name": "Ethiopian Chair",
            "country": "Ethiopia",
            "category": "Furniture",
            "confidence": 0.93,
            "materials": ["wood"],
        }
        result = validate_identification(data)
        self.assertEqual(result["artifact_name"], "Ethiopian Chair")
        self.assertEqual(result["confidence"], 0.93)

    def test_missing_fields_get_defaults(self):
        result = validate_identification({})
        self.assertEqual(result["artifact_name"], "Unknown Artifact")
        self.assertEqual(result["confidence"], 0.0)

    def test_confidence_clamped(self):
        result = validate_identification({"confidence": 5.0})
        self.assertEqual(result["confidence"], 1.0)

        result = validate_identification({"confidence": -1.0})
        self.assertEqual(result["confidence"], 0.0)


class ValidateStoryTest(TestCase):
    """Test the story validator."""

    def test_valid_data(self):
        data = {
            "title": "The Mesob Chair",
            "story": "A great story...",
            "materials": "Wood and cotton",
            "cultural_significance": "Very significant",
            "fun_fact": "Takes 3 weeks to make",
        }
        result = validate_story(data)
        self.assertEqual(result["title"], "The Mesob Chair")

    def test_missing_fields_get_empty_strings(self):
        result = validate_story({})
        self.assertEqual(result["title"], "")
        self.assertEqual(result["story"], "")


class IdentifyObjectTest(TestCase):
    """Test identify_object() with mocked Gemini API."""

    @patch("ai_services.services._API_KEY", "fake-key")
    @patch("ai_services.services._get_vision_model")
    def test_successful_identification(self, mock_get_model):
        mock_model = MagicMock()
        mock_response = MagicMock()
        mock_response.text = '{"artifact_name": "Mesob Chair", "country": "Ethiopia", "category": "Furniture", "confidence": 0.95, "materials": ["wood"]}'
        mock_model.generate_content.return_value = mock_response
        mock_get_model.return_value = mock_model

        # Create a fake image file
        image = self._make_test_image()
        result = identify_object(image)

        self.assertEqual(result["artifact_name"], "Mesob Chair")
        self.assertEqual(result["country"], "Ethiopia")
        self.assertAlmostEqual(result["confidence"], 0.95)

    @patch("ai_services.services._API_KEY", None)
    def test_no_api_key_returns_fallback(self):
        image = self._make_test_image()
        result = identify_object(image)
        self.assertEqual(result["artifact_name"], "Unknown Artifact")
        self.assertEqual(result["confidence"], 0.0)

    def _make_test_image(self):
        """Create a minimal in-memory JPEG for testing."""
        img = Image.new("RGB", (100, 100), color="red")
        buf = BytesIO()
        img.save(buf, format="JPEG")
        buf.seek(0)
        buf.name = "test.jpg"
        buf.content_type = "image/jpeg"
        return buf


class GenerateStoryTest(TestCase):
    """Test generate_story() with mocked Gemini API."""

    @patch("ai_services.services._API_KEY", "fake-key")
    @patch("ai_services.services._get_text_model")
    def test_successful_generation(self, mock_get_model):
        mock_model = MagicMock()
        mock_response = MagicMock()
        mock_response.text = '{"title": "The Mesob", "story": "A tale...", "materials": "Wood", "cultural_significance": "Important", "fun_fact": "Fun"}'
        mock_model.generate_content.return_value = mock_response
        mock_get_model.return_value = mock_model

        result = generate_story("Mesob Chair", "Ethiopia")
        self.assertEqual(result["title"], "The Mesob")

    @patch("ai_services.services._API_KEY", None)
    def test_no_api_key_returns_fallback(self):
        result = generate_story("Chair", "Ethiopia")
        self.assertIn("Chair", result["title"])
        self.assertIn("Ethiopia", result["story"])


class AIScanEndpointTest(TestCase):
    """Test the POST /api/ai/scan/ endpoint."""

    def setUp(self):
        self.client = APIClient()

    def test_no_input_returns_400(self):
        response = self.client.post("/api/ai/scan/", {}, format="json")
        self.assertEqual(response.status_code, http_status.HTTP_400_BAD_REQUEST)

    @patch("ai_services.views.identify_object")
    @patch("ai_services.views.generate_story")
    def test_text_fallback_mode(self, mock_story, mock_identify):
        mock_story.return_value = {
            "title": "Test", "story": "Story", "materials": "Wood",
            "cultural_significance": "Sig", "fun_fact": "Fun",
        }
        response = self.client.post(
            "/api/ai/scan/",
            {"artifact_name": "Test Chair"},
            format="json",
        )
        self.assertEqual(response.status_code, http_status.HTTP_200_OK)
        self.assertEqual(response.data["artifact_name"], "Test Chair")
        self.assertEqual(response.data["source"], "ai_generated")


class GenerateStoryEndpointTest(TestCase):
    """Test the POST /api/ai/generate-story/ endpoint."""

    def setUp(self):
        self.client = APIClient()

    def test_missing_artifact_name_returns_400(self):
        response = self.client.post(
            "/api/ai/generate-story/",
            {"country": "Ethiopia"},
            format="json",
        )
        self.assertEqual(response.status_code, http_status.HTTP_400_BAD_REQUEST)

    def test_missing_country_returns_400(self):
        response = self.client.post(
            "/api/ai/generate-story/",
            {"artifact_name": "Chair"},
            format="json",
        )
        self.assertEqual(response.status_code, http_status.HTTP_400_BAD_REQUEST)

    @patch("ai_services.views.generate_story")
    def test_successful_generation(self, mock_story):
        mock_story.return_value = {
            "title": "Test Story",
            "story": "Once upon a time...",
            "materials": "Wood, cotton",
            "cultural_significance": "Very important",
            "fun_fact": "Interesting fact",
        }
        response = self.client.post(
            "/api/ai/generate-story/",
            {"artifact_name": "Chair", "country": "Ethiopia"},
            format="json",
        )
        self.assertEqual(response.status_code, http_status.HTTP_200_OK)
        self.assertEqual(response.data["title"], "Test Story")
