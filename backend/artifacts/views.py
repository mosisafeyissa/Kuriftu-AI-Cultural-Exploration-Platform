from rest_framework.decorators import api_view, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response
from rest_framework import status
from rest_framework.pagination import PageNumberPagination

from .models import Country, Villa, Artifact
from .serializers import (
    CountrySerializer, VillaSerializer, ArtifactSerializer,
    VillaGuideSerializer,
)

from ai_services.services import process_scan_pipeline


# Pagination
class ArtifactPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = "page_size"
    max_page_size = 50


# ── Country & Villa list views ────────────────────────────────────────────────


@api_view(["GET"])
def country_list(request):
    """GET /api/countries/ — Returns all countries."""
    qs = Country.objects.all()
    serializer = CountrySerializer(qs, many=True, context={"request": request})
    return Response(serializer.data)


@api_view(["GET"])
def villa_list(request):
    """GET /api/villas/ — Returns all villas with nested country info."""
    qs = Villa.objects.select_related("country").all()
    serializer = VillaSerializer(qs, many=True, context={"request": request})
    return Response(serializer.data)


# ── Villa Guide (Tour Experience) ─────────────────────────────────────────────


@api_view(["GET"])
def villa_guide(request, qr_code):
    """
    GET /api/villa-guide/<qr_code>/

    Look up a villa by its QR UUID and return the full guided tour experience:
    villa info, welcome story, cultural highlights, sections with narratives,
    and artifacts within each section.
    """
    try:
        villa = Villa.objects.select_related("country").prefetch_related(
            "sections__artifacts__story"
        ).get(qr_code=qr_code)
    except Villa.DoesNotExist:
        return Response(
            {"error": "Villa not found. Please scan a valid QR code."},
            status=status.HTTP_404_NOT_FOUND,
        )

    serializer = VillaGuideSerializer(villa, context={"request": request})
    return Response(serializer.data)


@api_view(["POST"])
def villa_guide_translate(request, qr_code):
    """
    POST /api/villa-guide/<qr_code>/translate/
    Body: { "lang": "am" }

    Returns the villa guide content translated to the requested language
    using Gemini AI.
    """
    try:
        villa = Villa.objects.select_related("country").prefetch_related(
            "sections__artifacts__story"
        ).get(qr_code=qr_code)
    except Villa.DoesNotExist:
        return Response(
            {"error": "Villa not found."},
            status=status.HTTP_404_NOT_FOUND,
        )

    target_lang = request.data.get("lang", "en").strip()
    if target_lang == "en":
        # No translation needed, return original
        serializer = VillaGuideSerializer(villa, context={"request": request})
        return Response(serializer.data)

    # Import AI translation service
    try:
        from ai_services.services import translate_content
    except ImportError:
        return Response(
            {"error": "Translation service not available."},
            status=status.HTTP_503_SERVICE_UNAVAILABLE,
        )

    # Translate key content fields
    guide_data = VillaGuideSerializer(villa, context={"request": request}).data

    try:
        # Translate welcome story
        if guide_data.get("welcome_story"):
            guide_data["welcome_story"] = translate_content(
                guide_data["welcome_story"], target_lang
            )

        # Translate design philosophy
        if guide_data.get("design_philosophy"):
            guide_data["design_philosophy"] = translate_content(
                guide_data["design_philosophy"], target_lang
            )

        # Translate cultural highlights
        if guide_data.get("cultural_highlights"):
            translated_highlights = []
            for h in guide_data["cultural_highlights"]:
                translated_highlights.append(translate_content(h, target_lang))
            guide_data["cultural_highlights"] = translated_highlights

        # Translate each section narrative
        for section in guide_data.get("sections", []):
            if section.get("narrative"):
                section["narrative"] = translate_content(
                    section["narrative"], target_lang
                )
            if section.get("description"):
                section["description"] = translate_content(
                    section["description"], target_lang
                )
            # Translate artifact stories within sections
            for artifact in section.get("artifacts", []):
                story = artifact.get("story")
                if story:
                    if story.get("story"):
                        story["story"] = translate_content(story["story"], target_lang)
                    if story.get("cultural_significance"):
                        story["cultural_significance"] = translate_content(
                            story["cultural_significance"], target_lang
                        )

        guide_data["language"] = target_lang
    except Exception as e:
        return Response(
            {"error": f"Translation failed: {str(e)}"},
            status=status.HTTP_503_SERVICE_UNAVAILABLE,
        )

    return Response(guide_data)


# ── Artifact views ────────────────────────────────────────────────────────────


@api_view(["GET"])
def artifact_list(request):
    """
    GET /api/artifacts/
    Optional query params: ?country=<id>, ?villa=<id>, ?page=<n>, ?page_size=<n>
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
    serializer = ArtifactSerializer(page, many=True, context={"request": request})
    return paginator.get_paginated_response(serializer.data)


@api_view(["GET"])
def artifact_detail(request, pk):
    """GET /api/artifacts/<pk>/ — Returns a single artifact."""
    try:
        artifact = Artifact.objects.select_related("country", "villa", "story").get(pk=pk)
    except Artifact.DoesNotExist:
        return Response(
            {"error": f"Artifact with id={pk} not found."},
            status=status.HTTP_404_NOT_FOUND,
        )
    serializer = ArtifactSerializer(artifact, context={"request": request})
    return Response(serializer.data)


@api_view(["POST"])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def scan_artifact(request):
    """
    POST /api/scan/
    Accepts multipart/form-data with an 'image' file field.
    """
    image_file = request.FILES.get("image")
    artifact_name_hint = request.data.get("artifact_name", "").strip()

    result = process_scan_pipeline(image_file, artifact_name_hint, request)

    if "error" in result:
        return Response(
            {"error": result["error"]},
            status=result.get("status", 400),
        )

    if result.get("status") == "not_found":
        return Response(result, status=status.HTTP_404_NOT_FOUND)

    return Response(result)
