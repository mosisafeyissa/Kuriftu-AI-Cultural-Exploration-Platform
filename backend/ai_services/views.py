"""
API views for the ai_services app.

Provides:
    POST /api/ai/scan/           — direct AI scan endpoint (standalone)
    POST /api/ai/generate-story/ — generate a story from name + country
    GET  /api/ai/scan-logs/      — list recent scan logs (analytics)
"""
import logging

from rest_framework.decorators import api_view, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response
from rest_framework import status
from rest_framework.pagination import PageNumberPagination

from .models import ScanLog
from .serializers import ScanLogSerializer
from .services import generate_story, process_scan_pipeline

logger = logging.getLogger(__name__)


# Pagination 

class ScanLogPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100


# POST /api/ai/scan/

@api_view(["POST"])
@parser_classes([MultiPartParser, FormParser])
def ai_scan(request):
    """
    Image similarity scan endpoint.

    Accepts an image upload, generates a MobileNetV2 embedding,
    and compares it against stored artifact embeddings.

    Request:
        - multipart/form-data with field 'image' (JPEG/PNG/WebP)

    Response (match found):
        {
            "status": "success",
            "type": "artifact",
            "data": { "id": 1, "name": "...", "price": "...", ... },
            "similarity": 0.82
        }

    Response (no match):
        {
            "status": "not_found",
            "message": "No matching artifact found",
            "similarity": 0.45
        }
    """
    image_file = request.FILES.get("image")
    artifact_name_hint = request.data.get("artifact_name", "").strip()

    result = process_scan_pipeline(image_file, artifact_name_hint, request)

    # Handle validation errors
    if "error" in result:
        return Response(
            {"error": result["error"]},
            status=result.get("status", 400),
        )

    # Handle not_found (return 404)
    if result.get("status") == "not_found":
        return Response(result, status=status.HTTP_404_NOT_FOUND)

    # Match found
    return Response(result)


# POST /api/ai/generate-story/

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


# GET /api/ai/scan-logs/

@api_view(["GET"])
def scan_log_list(request):
    """
    List recent scan logs for analytics / debugging.
    """
    qs = ScanLog.objects.all().order_by("-created_at")
    paginator = ScanLogPagination()
    page = paginator.paginate_queryset(qs, request)
    serializer = ScanLogSerializer(page, many=True)
    return paginator.get_paginated_response(serializer.data)
