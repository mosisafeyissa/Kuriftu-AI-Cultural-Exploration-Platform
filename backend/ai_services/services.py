"""
Core AI service functions for the Kuriftu Cultural Exploration Platform.

Two public functions (called by artifacts/views.py):
    identify_object(image_file)   → dict with artifact_name, country, confidence
    generate_story(name, country) → dict with title, story, materials, cultural_significance
"""
import logging
import time
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
        _VISION_MODEL = genai.GenerativeModel("gemini-1.5-flash")
    return _VISION_MODEL


def _get_text_model():
    """Return (or create) the Gemini model used for story generation."""
    global _TEXT_MODEL
    if _TEXT_MODEL is None:
        _TEXT_MODEL = genai.GenerativeModel("gemini-1.5-flash")
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

        # Retry loop for 429 / Rate limit
        retry_count = 0
        max_retries = 3
        response = None
        
        while retry_count <= max_retries:
            try:
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
                break
            except Exception as e:
                if "429" in str(e) and retry_count < max_retries:
                    retry_count += 1
                    wait_time = 2 ** retry_count
                    logger.warning(f"Gemini 429 received. Retrying in {wait_time}s... ({retry_count}/{max_retries})")
                    time.sleep(wait_time)
                else:
                    raise e

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
        
        # Retry loop for 429 / Rate limit
        retry_count = 0
        max_retries = 3
        response = None
        
        while retry_count <= max_retries:
            try:
                response = model.generate_content(
                    prompt,
                    generation_config=genai.types.GenerationConfig(
                        temperature=0.7,
                        max_output_tokens=3000,
                        response_mime_type="application/json",
                    ),
                )
                break
            except Exception as e:
                if "429" in str(e) and retry_count < max_retries:
                    retry_count += 1
                    wait_time = 2 ** retry_count
                    logger.warning(f"Gemini 429 received. Retrying in {wait_time}s... ({retry_count}/{max_retries})")
                    time.sleep(wait_time)
                else:
                    raise e

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
    Image-similarity scan pipeline.

    Used by both:
      - artifacts.views.scan_artifact  (POST /api/scan/)
      - ai_services.views.ai_scan      (POST /api/ai/scan/)

    Steps:
      1. Validate the uploaded image
      2. Generate embedding from uploaded image (MobileNetV2)
      3. Compare against all artifact embeddings (cosine similarity)
      4. Return best match or "not found"

    Returns a dict ready to be wrapped in a Response().
    """
    from .utils import validate_image_file
    from .embedding_service import generate_embedding, find_best_match
    from artifacts.models import Artifact
    from artifacts.serializers import ArtifactSerializer

    # Step 1: Validate input
    if not image_file:
        return {
            "error": "An 'image' file is required for scanning.",
            "status": 400,
        }

    is_valid, error_msg = validate_image_file(image_file)
    if not is_valid:
        return {"error": error_msg, "status": 400}

    # Step 2: Generate embedding from uploaded image
    try:
        image_file.seek(0)
        scan_embedding = generate_embedding(image_file)
    except Exception:
        logger.exception("Failed to generate embedding for scanned image")
        return {
            "error": "Failed to process the uploaded image.",
            "status": 500,
        }

    # Step 3: Find the best matching artifact
    artifact, similarity = find_best_match(scan_embedding, threshold=0.75)

    # Step 4: Build response
    if artifact is not None:
        # ── MATCH FOUND ──
        story_data = None
        if hasattr(artifact, "story"):
            from artifacts.serializers import StorySerializer
            story_data = StorySerializer(artifact.story).data

        image_url = ""
        if artifact.image:
            name = getattr(artifact.image, "name", str(artifact.image))
            if name.startswith("assets/"):
                image_url = name
            else:
                image_url = request.build_absolute_uri(artifact.image.url)
        elif artifact.image_url:
            image_url = artifact.image_url

        _log_scan(
            image_file,
            {"artifact_name": artifact.name, "country": artifact.country.name,
             "category": "Matched", "confidence": similarity},
            matched_artifact=artifact,
        )

        return {
            "status": "success",
            "type": "artifact",
            "data": {
                "id": artifact.pk,
                "name": artifact.name,
                "price": str(artifact.price),
                "description": artifact.description,
                "country": artifact.country.name,
                "image_url": image_url,
                "story": story_data,
            },
            "similarity": round(similarity, 4),
        }
    else:
        # ── NOT FOUND ──
        _log_scan(
            image_file,
            {"artifact_name": "No match", "country": "Unknown",
             "category": "Unmatched", "confidence": similarity},
        )

        return {
            "status": "not_found",
            "message": "No matching artifact found",
            "similarity": round(similarity, 4),
        }


# ── Translation Service ──────────────────────────────────────────────────────

LANGUAGE_NAMES = {
    "en": "English",
    "am": "Amharic",
    "fr": "French",
    "ar": "Arabic",
    "sw": "Swahili",
    "om": "Oromo",
    "ti": "Tigrinya",
    "so": "Somali",
    "es": "Spanish",
    "zh": "Chinese",
    "ja": "Japanese",
}


def translate_content(text: str, target_lang: str) -> str:
    """
    Translate text to the target language using Gemini AI.

    Args:
        text: The text to translate.
        target_lang: Language code (e.g. 'am', 'fr', 'ar').

    Returns:
        Translated text string.
    """
    if not text or not text.strip():
        return text

    if target_lang == "en":
        return text

    lang_name = LANGUAGE_NAMES.get(target_lang, target_lang)

    if not _API_KEY:
        logger.warning("No API key — cannot translate.")
        return text

    try:
        model = _get_text_model()
        prompt = (
            f"Translate the following text to {lang_name}. "
            f"Return ONLY the translated text, no explanations or notes.\n\n"
            f"Text:\n{text}"
        )
        response = model.generate_content(prompt)

        if response and response.text:
            return response.text.strip()
        return text

    except Exception as e:
        logger.error(f"Translation error: {e}")
        return text
