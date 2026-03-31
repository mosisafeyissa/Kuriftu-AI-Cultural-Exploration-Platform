"""
Core AI service functions for the Kuriftu Cultural Exploration Platform.

Two public functions (called by artifacts/views.py):
    identify_object(image_file)   → dict with artifact_name, country, confidence
    generate_story(name, country) → dict with title, story, materials, cultural_significance
"""
import logging

import google.generativeai as genai
from django.conf import settings

from .prompts import (
    GENERATE_STORY_PROMPT,
    IDENTIFY_OBJECT_PROMPT,
    IDENTIFY_RETRY_PROMPT,
)
from .utils import parse_json_response, validate_identification, validate_story

logger = logging.getLogger(__name__)

# Configure Gemini 

_API_KEY = getattr(settings, "API_KEY", None)

if _API_KEY:
    genai.configure(api_key=_API_KEY)
else:
    logger.warning(
        "GEMINI_API_KEY is not set. AI features will return fallback responses."
    )

# Model instances (lazy — created once, reused across requests)
_VISION_MODEL = None
_TEXT_MODEL = None


def _get_vision_model():
    """Return (or create) the Gemini model used for image recognition."""
    global _VISION_MODEL
    if _VISION_MODEL is None:
        _VISION_MODEL = genai.GenerativeModel("gemini-flash-latest")
    return _VISION_MODEL


def _get_text_model():
    """Return (or create) the Gemini model used for story generation."""
    global _TEXT_MODEL
    if _TEXT_MODEL is None:
        _TEXT_MODEL = genai.GenerativeModel("gemini-flash-latest")
    return _TEXT_MODEL


# Job 1: Object Recognition 

def identify_object(image_file) -> dict:
    """
    Identify a cultural artifact from an uploaded image file.

    Args:
        image_file: A Django UploadedFile (InMemoryUploadedFile or
                    TemporaryUploadedFile) with .read() and .content_type.

    Returns:
        dict with keys: artifact_name, country, category, confidence, materials
    """
    if not _API_KEY:
        logger.warning("No API key — returning fallback identification.")
        return _fallback_identification()

    try:
        # Read the image bytes from the uploaded file
        image_file.seek(0)  # ensure we read from the start
        image_bytes = image_file.read()
        mime_type = getattr(image_file, "content_type", "image/jpeg")

        model = _get_vision_model()

        # Build the multimodal content: [image, prompt]
        response = model.generate_content(
            [
                {"mime_type": mime_type, "data": image_bytes},
                IDENTIFY_OBJECT_PROMPT,
            ],
            generation_config=genai.types.GenerationConfig(
                temperature=0.1,
                max_output_tokens=1024,
                response_mime_type="application/json",
            ),
        )

        result = parse_json_response(response.text)

        if result is None:
            # Retry once with a clearer prompt
            logger.info("First identification parse failed, retrying…")
            retry_response = model.generate_content(
                [
                    {"mime_type": mime_type, "data": image_bytes},
                    IDENTIFY_RETRY_PROMPT,
                ],
                generation_config=genai.types.GenerationConfig(
                    temperature=0.1,
                    max_output_tokens=1024,
                    response_mime_type="application/json",
                ),
            )
            result = parse_json_response(retry_response.text)

        if result is None:
            logger.error("AI identification failed after retry.")
            return _fallback_identification()

        validated = validate_identification(result)
        logger.info(
            "Identified: %s (%s) — confidence %.2f",
            validated["artifact_name"],
            validated["country"],
            validated["confidence"],
        )
        return validated

    except Exception:
        logger.exception("Error during object identification")
        return _fallback_identification()


# Job 2: Cultural Story Generation 

def generate_story(object_name: str, country: str) -> dict:
    """
    Generate a rich cultural story for the identified artifact.

    Args:
        object_name: The name of the artifact (from identify_object).
        country:     The country of origin.

    Returns:
        dict with keys: title, story, materials, cultural_significance, fun_fact
    """
    if not _API_KEY:
        logger.warning("No API key — returning fallback story.")
        return _fallback_story(object_name, country)

    try:
        prompt = GENERATE_STORY_PROMPT.format(
            object_name=object_name,
            country=country,
        )

        model = _get_text_model()
        response = model.generate_content(
            prompt,
            generation_config=genai.types.GenerationConfig(
                temperature=0.7,
                max_output_tokens=3000,
                response_mime_type="application/json",
            ),
        )

        result = parse_json_response(response.text)

        if result is None:
            logger.error("AI story generation returned unparseable response.")
            return _fallback_story(object_name, country)

        validated = validate_story(result)
        logger.info("Generated story: %s", validated["title"])
        return validated

    except Exception:
        logger.exception("Error during story generation")
        return _fallback_story(object_name, country)


# Fallbacks 

def _fallback_identification() -> dict:
    """Return a safe default when AI identification is unavailable."""
    return {
        "artifact_name": "Unknown Artifact",
        "country": "Unknown",
        "category": "Other",
        "confidence": 0.0,
        "materials": [],
    }


def _fallback_story(object_name: str, country: str) -> dict:
    """Return a placeholder story when AI generation is unavailable."""
    return {
        "title": f"The Story of {object_name}",
        "story": (
            f"This beautiful artifact originates from {country}. "
            f"It represents the rich cultural heritage and master craftsmanship "
            f"of the region. Detailed story generation is temporarily unavailable."
        ),
        "materials": "Information currently unavailable.",
        "cultural_significance": (
            f"This artifact holds deep cultural significance in {country}, "
            f"representing traditions passed down through generations."
        ),
        "fun_fact": "Every handcrafted artifact is unique — no two are exactly alike.",
    }


# Shared Scan Pipeline

def _log_scan(image_file, identification, matched_artifact=None, story_generated=False):
    """
    Create a ScanLog entry. Non-critical — failures are logged but don't
    break the scan response.
    """
    from .models import ScanLog

    try:
        log = ScanLog(
            result_object=identification.get("artifact_name", "Unknown"),
            result_country=identification.get("country", "Unknown"),
            result_category=identification.get("category", "Other"),
            confidence=identification.get("confidence", 0.0),
            matched_artifact=matched_artifact,
            story_generated=story_generated,
        )
        if image_file:
            image_file.seek(0)
            log.image.save(image_file.name, image_file, save=False)
        log.save()
        return log
    except Exception:
        logger.exception("Failed to save scan log (non-critical)")
        return None


def process_scan_pipeline(image_file, artifact_name_hint, request) -> dict:
    """
    The single source of truth for the scan flow.

    Used by both:
      - artifacts.views.scan_artifact  (POST /api/scan/)
      - ai_services.views.ai_scan      (POST /api/ai/scan/)

    Steps:
      1. Validate & identify (via image or text fallback)
      2. Check the database for a known artifact
      3. If not found, generate a story with AI

    Returns a dict ready to be wrapped in a Response().
    """
    from .utils import validate_image_file
    from artifacts.models import Artifact
    from artifacts.serializers import StorySerializer

    # Step 1: Identify
    if image_file:
        is_valid, error_msg = validate_image_file(image_file)
        if not is_valid:
            return {"error": error_msg, "status": 400}

        identification = identify_object(image_file)
    elif artifact_name_hint:
        identification = {
            "artifact_name": artifact_name_hint,
            "country": "Unknown",
            "category": "Other",
            "confidence": 1.0,
            "materials": [],
        }
    else:
        return {
            "error": "Provide either an 'image' file or 'artifact_name' text.",
            "status": 400,
        }

    identified_name = identification["artifact_name"]
    identified_country = identification["country"]
    confidence = identification["confidence"]
    category = identification.get("category", "Other")

    # Step 2: Database Lookup
    try:
        artifact = Artifact.objects.select_related(
            "country", "villa", "story"
        ).get(name__iexact=identified_name)

        story_data = (
            StorySerializer(artifact.story).data
            if hasattr(artifact, "story")
            else None
        )

        _log_scan(image_file, identification, matched_artifact=artifact)

        return {
            "artifact_name": artifact.name,
            "country": artifact.country.name,
            "confidence": confidence,
            "category": category,
            "story": story_data,
            "price": str(artifact.price),
            "image_url": artifact.image_url,
            "source": "database",
        }
    except Artifact.DoesNotExist:
        pass

    # Step 3: AI-Generated Story 
    story_data = generate_story(identified_name, identified_country)

    scan_log = _log_scan(image_file, identification, story_generated=True)

    if scan_log and scan_log.image:
        image_url = request.build_absolute_uri(scan_log.image.url)
    elif artifact_name_hint:
        image_url = "https://placehold.co/400x300?text=No+Image+Provided"
    else:
        image_url = "https://placehold.co/400x300?text=Unknown+Artifact"

    return {
        "artifact_name": identified_name,
        "country": identified_country,
        "confidence": confidence,
        "category": category,
        "story": story_data,
        "price": None,
        "image_url": image_url,
        "source": "ai_generated",
        "note": "This artifact was not found in the database. Story was AI-generated.",
    }

