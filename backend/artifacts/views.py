from rest_framework.decorators import api_view, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response
from rest_framework import status
from rest_framework.pagination import PageNumberPagination

from .models import Country, Villa, Artifact
from .serializers import CountrySerializer, VillaSerializer, ArtifactSerializer

from ai_services.services import process_scan_pipeline


# Pagination 
class ArtifactPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = "page_size"
    max_page_size = 50


# ── Country & Villa list views ────────────────────────────────────────────────


@api_view(["GET"])
def country_list(request):
    """
    GET /api/countries/
    Returns all countries.
    """
    qs = Country.objects.all()
    serializer = CountrySerializer(qs, many=True)
    return Response(serializer.data)


@api_view(["GET"])
def villa_list(request):
    """
    GET /api/villas/
    Returns all villas with nested country info.
    """
    qs = Villa.objects.select_related("country").all()
    serializer = VillaSerializer(qs, many=True)
    return Response(serializer.data)


# ── Artifact views ────────────────────────────────────────────────────────────


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


@api_view(["GET"])
def artifact_detail(request, pk):
    """
    GET /api/artifacts/<pk>/
    Returns a single artifact with nested country, villa, and story.
    """
    try:
        artifact = Artifact.objects.select_related("country", "villa", "story").get(pk=pk)
    except Artifact.DoesNotExist:
        return Response(
            {"error": f"Artifact with id={pk} not found."},
            status=status.HTTP_404_NOT_FOUND,
        )
    serializer = ArtifactSerializer(artifact)
    return Response(serializer.data)


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

    result = process_scan_pipeline(image_file, artifact_name_hint, request)

    if "error" in result:
        return Response(
            {"error": result["error"]},
            status=result.get("status", 400),
        )

    return Response(result)
