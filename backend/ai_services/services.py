"""
Core AI service functions for the Kuriftu Cultural Exploration Platform.

Two public functions (called by artifacts/views.py):
    identify_object(image_file)   → dict with artifact_name, country, confidence
    generate_story(name, country) → dict with title, story, materials, cultural_significance
"""
import logging

from google import genai
from google.genai import types
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
_CLIENT = None

if _API_KEY:
    print(f"Loaded GEMINI_API_KEY: {_API_KEY[:8]}...")
    _CLIENT = genai.Client(api_key=_API_KEY)
else:
    logger.warning("GEMINI_API_KEY is not set. AI features will return fallback responses.")


def _get_client():
    if not _CLIENT:
        raise ValueError("Gemini client not initialized. Ensure GEMINI_API_KEY is set.")
    return _CLIENT

# Job 1: Object Recognition 

def identify_object(image_file) -> dict:
    if not _CLIENT:
        logger.warning("No API key — returning fallback identification.")
        return _fallback_identification()

    try:
        image_file.seek(0)
        image_bytes = image_file.read()
        mime_type = getattr(image_file, "content_type", "image/jpeg")
        # Ensure we properly map .webp even if it comes through as octet-stream
        if image_file.name and image_file.name.lower().endswith(".webp"):
            mime_type = "image/webp"

        client = _get_client()

        identify_schema = {
            "type": "OBJECT",
            "properties": {
                "artifact_name": {"type": "STRING"},
                "country": {"type": "STRING"},
                "category": {"type": "STRING"},
                "confidence": {"type": "NUMBER"},
                "materials": {"type": "ARRAY", "items": {"type": "STRING"}},
            },
            "required": ["artifact_name", "country", "category", "confidence", "materials"],
        }

        try:
            response = client.models.generate_content(
                model="gemini-2.0-flash",
                contents=[
                    types.Part.from_bytes(data=image_bytes, mime_type=mime_type),
                    IDENTIFY_OBJECT_PROMPT,
                ],
                config=types.GenerateContentConfig(
                    temperature=0.1,
                    max_output_tokens=1024,
                    response_mime_type="application/json",
                    response_schema=identify_schema,
                ),
            )
            print(f"DEBUG AI TEXT: {response.text}")
        except Exception as e:
            logger.error(f"Gemini Vision API error: {e}")
            if "429" in str(e) or "ResourceExhausted" in str(e) or "Resource Exhausted" in str(e):
                return {
                    "artifact_name": "AI Cooling Down (Rate Limit)",
                    "country": "Unknown",
                    "category": "Other",
                    "confidence": 0.0,
                    "materials": []
                }
            return _fallback_identification()

        clean_text = response.text.replace("```json", "").replace("```", "").strip()
        result = parse_json_response(clean_text)

        if result is None:
            logger.info("First identification parse failed, retrying...")
            retry_response = client.models.generate_content(
                model="gemini-2.0-flash",
                contents=[
                    types.Part.from_bytes(data=image_bytes, mime_type=mime_type),
                    IDENTIFY_RETRY_PROMPT,
                ],
                config=types.GenerateContentConfig(
                    temperature=0.1,
                    max_output_tokens=1024,
                    response_mime_type="application/json",
                    response_schema=identify_schema,
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
    if not _CLIENT:
        logger.warning("No API key — returning fallback story.")
        return _fallback_story(object_name, country)

    try:
        prompt = GENERATE_STORY_PROMPT.format(
            object_name=object_name,
            country=country,
        )

        client = _get_client()
        story_schema = {
            "type": "OBJECT",
            "properties": {
                "title": {"type": "STRING"},
                "story": {"type": "STRING"},
                "materials": {"type": "STRING"},
                "cultural_significance": {"type": "STRING"},
                "fun_fact": {"type": "STRING"},
                "name": {"type": "STRING"} # Added for frontend compat
            },
            "required": ["title", "story", "materials", "cultural_significance", "fun_fact"],
        }
        
        try:
            response = client.models.generate_content(
                model="gemini-2.0-flash",
                contents=prompt,
                config=types.GenerateContentConfig(
                    temperature=0.7,
                    max_output_tokens=3000,
                    response_mime_type="application/json",
                    response_schema=story_schema,
                ),
            )
            print(f"DEBUG AI TEXT: {response.text}")
        except Exception as e:
            print(f"AI EXCEPTION GENERATE STORY: {e}")
            logger.error(f"Gemini Text API error: {e}")
            if "429" in str(e) or "ResourceExhausted" in str(e) or "Resource Exhausted" in str(e):
                return {
                    "title": "AI Cooling Down (Rate Limit)",
                    "story": "The AI is cooling down due to Google Gemini rate limits.",
                    "materials": "Unknown",
                    "cultural_significance": "Unknown",
                    "fun_fact": "Rate Limit",
                    "name": "AI Cooling Down (Rate Limit)",
                    "price": 150.0
                }
            return _fallback_story(object_name, country)

        # Clean the JSON from Markdown block delimiters
        clean_text = response.text.replace("```json", "").replace("```", "").strip()
        result = parse_json_response(clean_text)

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

        response_dict = {
            "artifact_name": artifact.name,
            "name": artifact.name,
            "materials": story_data.get("materials", "") if isinstance(story_data, dict) else "",
            "cultural_significance": story_data.get("cultural_significance", "") if isinstance(story_data, dict) else "",
            "country": artifact.country.name,
            "confidence": confidence,
            "category": category,
            "story": story_data,
            "price": str(artifact.price),
            "image_url": artifact.image_url,
            "source": "database",
        }
        print(f"AI_DEBUG_DATA: {response_dict}")
        return response_dict
    except Artifact.DoesNotExist:
        pass

    # Step 3: AI-Generated Story 
    story_data = generate_story(identified_name, identified_country)

    scan_log = _log_scan(image_file, identification, story_generated=True)

    if scan_log and scan_log.image:
        image_url = request.build_absolute_uri(scan_log.image.url)
    elif artifact_name_hint:
        image_url = "https://placehold.co/400x300/png?text=No+Image+Provided"
    else:
        image_url = "https://placehold.co/400x300/png?text=Unknown+Artifact"

    response_dict = {
        "artifact_name": identified_name,
        "name": identified_name,
        "materials": story_data.get("materials", "Traditional materials") if isinstance(story_data, dict) else "Traditional materials",
        "cultural_significance": story_data.get("cultural_significance", "Holds deep local significance.") if isinstance(story_data, dict) else "Holds deep local significance.",
        "country": identified_country,
        "confidence": confidence,
        "category": category,
        "story": story_data,
        "price": 150.0,
        "image_url": image_url,
        "source": "ai_generated",
        "note": "This artifact was not found in the database. Story was AI-generated.",
    }
    print(f"AI_DEBUG_DATA: {response_dict}")
    return response_dict

