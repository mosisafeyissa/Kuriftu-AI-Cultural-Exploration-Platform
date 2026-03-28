"""
API views for the ai_services app.

Provides:
    POST /api/ai/scan/         — direct AI scan endpoint (standalone)
    POST /api/ai/generate-story/ — generate a story from name + country
    GET  /api/ai/scan-logs/    — list recent scan logs (analytics)
"""
import logging

from rest_framework.decorators import api_view, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response
from rest_framework import status
from rest_framework.pagination import PageNumberPagination

from artifacts.models import Artifact
from artifacts.serializers import StorySerializer

from .models import ScanLog
from .serializers import ScanLogSerializer
from .services import identify_object, generate_story

logger = logging.getLogger(__name__)


#  Pagination 

class ScanLogPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100


#  Constants 

_ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
_MAX_IMAGE_SIZE_MB = 10


#  POST /api/ai/scan/ 

@api_view(["POST"])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def ai_scan(request):
    """
    Standalone AI scan endpoint.

    Accepts an image upload, identifies the artifact using Gemini Vision,
    checks the database for a match, and returns the result with story.

    Request:
        - multipart/form-data with field 'image' (JPEG/PNG/WebP)
        - OR JSON body with field 'artifact_name' (text fallback)

    Response:
        {
            "artifact_name": "...",
            "country": "...",
            "confidence": 0.93,
            "category": "Furniture",
            "story": { "title": "...", "story": "...", ... },
            "price": "150.00" or null,
            "image_url": "...",
            "source": "database" or "ai_generated"
        }
    """
    image_file = request.FILES.get("image")
    artifact_name_hint = request.data.get("artifact_name", "").strip()

    # ── Step 1: Identify the object 
    if image_file:
        # Validate image
        if image_file.content_type not in _ALLOWED_IMAGE_TYPES:
            return Response(
                {
                    "error": f"Unsupported image type '{image_file.content_type}'.",
                    "allowed": sorted(_ALLOWED_IMAGE_TYPES),
                },
                status=status.HTTP_400_BAD_REQUEST,
            )
        if image_file.size > _MAX_IMAGE_SIZE_MB * 1024 * 1024:
            return Response(
                {"error": f"Image too large. Maximum size is {_MAX_IMAGE_SIZE_MB} MB."},
                status=status.HTTP_400_BAD_REQUEST,
            )

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
        return Response(
            {"error": "Provide either an 'image' file or 'artifact_name' text."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    identified_name = identification["artifact_name"]
    identified_country = identification["country"]
    confidence = identification["confidence"]
    category = identification.get("category", "Other")

    # ── Step 2: Check database for existing artifact 
    matched_artifact = None
    try:
        artifact = Artifact.objects.select_related("country", "villa", "story").get(
            name__iexact=identified_name
        )
        matched_artifact = artifact
        story_data = (
            StorySerializer(artifact.story).data
            if hasattr(artifact, "story")
            else None
        )

        # Log the scan
        _log_scan(image_file, identification, matched_artifact=artifact)

        return Response({
            "artifact_name": artifact.name,
            "country": artifact.country.name,
            "confidence": confidence,
            "category": category,
            "story": story_data,
            "price": str(artifact.price),
            "image_url": artifact.image_url,
            "source": "database",
        })
    except Artifact.DoesNotExist:
        pass

    # ── Step 3: Generate a new story with AI 
    story_data = generate_story(identified_name, identified_country)

    # Log the scan
    scan_log = _log_scan(image_file, identification, story_generated=True)
    
    if scan_log and scan_log.image:
        image_url = request.build_absolute_uri(scan_log.image.url)
    else:
        image_url = "https://placehold.co/400x300?text=Scan+Image"

    return Response({
        "artifact_name": identified_name,
        "country": identified_country,
        "confidence": confidence,
        "category": category,
        "story": story_data,
        "price": None,
        "image_url": image_url,
        "source": "ai_generated",
        "note": "This artifact was not found in the database. Story was AI-generated.",
    })


# ─── POST /api/ai/generate-story/ 

@api_view(["POST"])
@parser_classes([JSONParser])
def ai_generate_story(request):
    """
    Generate a cultural story for a given artifact name and country.

    Request body (JSON):
        {
            "artifact_name": "Ethiopian Cultural Chair",
            "country": "Ethiopia"
        }

    Response:
        {
            "title": "...",
            "story": "...",
            "materials": "...",
            "cultural_significance": "...",
            "fun_fact": "..."
        }
    """
    artifact_name = request.data.get("artifact_name", "").strip()
    country = request.data.get("country", "").strip()

    if not artifact_name:
        return Response(
            {"error": "'artifact_name' is required."},
            status=status.HTTP_400_BAD_REQUEST,
        )
    if not country:
        return Response(
            {"error": "'country' is required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    story_data = generate_story(artifact_name, country)
    return Response(story_data)


# ─── GET /api/ai/scan-logs/ 

@api_view(["GET"])
def scan_log_list(request):
    """
    List recent scan logs for analytics / debugging.
    """
    qs = ScanLog.objects.all()
    paginator = ScanLogPagination()
    page = paginator.paginate_queryset(qs, request)
    serializer = ScanLogSerializer(page, many=True)
    return paginator.get_paginated_response(serializer.data)


# ─── Helpers ───

def _log_scan(image_file, identification, matched_artifact=None, story_generated=False):
    """
    Create a ScanLog entry. Non-critical — failures are logged but don't
    break the scan response.
    """
    try:
        log = ScanLog(
            result_object=identification.get("artifact_name", "Unknown"),
            result_country=identification.get("country", "Unknown"),
            result_category=identification.get("category", "Other"),
            confidence=identification.get("confidence", 0.0),
            matched_artifact=matched_artifact,
            story_generated=story_generated,
        )
        # Save the image if provided
        if image_file:
            image_file.seek(0)
            log.image.save(image_file.name, image_file, save=False)
        log.save()
        return log
    except Exception:
        logger.exception("Failed to save scan log (non-critical)")
        return None
