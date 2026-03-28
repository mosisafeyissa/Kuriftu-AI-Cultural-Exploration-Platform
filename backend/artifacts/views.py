from rest_framework.decorators import api_view, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response
from rest_framework import status
from rest_framework.pagination import PageNumberPagination
from rest_framework.exceptions import ValidationError

from .models import Artifact
from .serializers import ArtifactSerializer, StorySerializer
from ai_services.services import identify_object, generate_story


# ─── Constants ────────────────────────────────────────────────────────────────
_ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
_MAX_IMAGE_SIZE_MB = 10


# ─── Pagination ───────────────────────────────────────────────────────────────
class ArtifactPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = "page_size"
    max_page_size = 50


# ─── Views ────────────────────────────────────────────────────────────────────

@api_view(["GET"])
def artifact_list(request):
    """
    GET /api/artifacts/

    Optional query params:
      ?country=<id>     filter by country pk
      ?villa=<id>       filter by villa pk
      ?page=<n>         page number
      ?page_size=<n>    results per page (max 50)
    """
    qs = Artifact.objects.select_related("country", "villa", "story").all()

    country_id = request.query_params.get("country")
    villa_id = request.query_params.get("villa")

    if country_id:
        if not country_id.isdigit():
            return Response(
                {"error": "Query param 'country' must be a numeric ID."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        qs = qs.filter(country_id=country_id)
        if not qs.exists():
            return Response(
                {"error": f"No artifacts found for country id={country_id}."},
                status=status.HTTP_404_NOT_FOUND,
            )

    if villa_id:
        if not villa_id.isdigit():
            return Response(
                {"error": "Query param 'villa' must be a numeric ID."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        qs = qs.filter(villa_id=villa_id)
        if not qs.exists():
            return Response(
                {"error": f"No artifacts found for villa id={villa_id}."},
                status=status.HTTP_404_NOT_FOUND,
            )

    paginator = ArtifactPagination()
    page = paginator.paginate_queryset(qs, request)
    serializer = ArtifactSerializer(page, many=True)
    return paginator.get_paginated_response(serializer.data)


@api_view(["POST"])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def scan_artifact(request):
    """
    POST /api/scan/

    Accepts multipart/form-data with an 'image' file field.
    Falls back to plain 'artifact_name' text for backwards compatibility.

    Flow:
      1. Validate image (type, size)
      2. Call AI identify_object() → artifact_name, country, confidence
      3. Lookup artifact in DB
         - Found  → return artifact + nested story
         - Missing → call AI generate_story() and return generated content
    """
    image_file = request.FILES.get("image")
    artifact_name_hint = request.data.get("artifact_name", "").strip()

    # ── Step 1: identify ──────────────────────────────────────────────────────
    if image_file:
        _validate_image(image_file)
        
        from django.core.files.storage import default_storage
        from config.settings import SCAN_UPLOAD_DIR
        import os
        
        # Store uploaded scan images temporarily for AI processing
        filename = default_storage.save(f"{SCAN_UPLOAD_DIR}{image_file.name}", image_file)
        file_path = default_storage.path(filename)
        
        try:
            identification = identify_object(image_file)
        finally:
            # Clean up the temporary file after processing
            if os.path.exists(file_path):
                os.remove(file_path)
    elif artifact_name_hint:
        # Backwards-compatible text mode (used by the original scan endpoint)
        identification = {
            "artifact_name": artifact_name_hint,
            "country": "Unknown",
            "confidence": 1.0,
        }
    else:
        return Response(
            {"error": "Provide either an 'image' file or 'artifact_name' text."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    identified_name = identification["artifact_name"]
    identified_country = identification["country"]
    confidence = identification["confidence"]

    # ── Step 2: DB lookup ─────────────────────────────────────────────────────
    try:
        artifact = Artifact.objects.select_related("country", "villa", "story").get(
            name__iexact=identified_name
        )
        story_data = (
            StorySerializer(artifact.story).data
            if hasattr(artifact, "story")
            else None
        )
        return Response({
            "artifact_name": artifact.name,
            "country": artifact.country.name,
            "confidence": confidence,
            "story": story_data,
            "price": str(artifact.price),
            "image_url": artifact.image_url,
        })
    except Artifact.DoesNotExist:
        pass

    # ── Step 3: not in DB → AI-generated story ───────────────────────────────
    story_data = generate_story(identified_name, identified_country)
    
    # Optional: Log this scan in ai_services too if you want to track it
    from ai_services.views import _log_scan
    scan_log = _log_scan(image_file, identification, story_generated=True)
    
    if scan_log and scan_log.image:
        image_url = request.build_absolute_uri(scan_log.image.url)
    elif artifact_name_hint:
        image_url = "https://placehold.co/400x300?text=No+Image+Provided"
    else:
        image_url = "https://placehold.co/400x300?text=Unknown+Artifact"

    return Response({
        "artifact_name": identified_name,
        "country": identified_country,
        "confidence": confidence,
        "story": story_data,
        "price": None,
        "image_url": image_url,
        "source": "ai_generated",
        "note": "This artifact was not found in the database. Story was AI-generated.",
    }, status=status.HTTP_200_OK)


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _validate_image(image_file):
    """Raise ValidationError if the uploaded file is not an acceptable image."""
    if image_file.content_type not in _ALLOWED_IMAGE_TYPES:
        raise ValidationError(
            f"Unsupported image type '{image_file.content_type}'. "
            f"Allowed: {', '.join(sorted(_ALLOWED_IMAGE_TYPES))}"
        )
    if image_file.size > _MAX_IMAGE_SIZE_MB * 1024 * 1024:
        raise ValidationError(
            f"Image too large. Maximum size is {_MAX_IMAGE_SIZE_MB} MB."
        )
