from rest_framework import status
from rest_framework.parsers import MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView


class ArtifactScanView(APIView):
    """
    POST /api/scan/
    Accepts an image upload and returns a mock scan result.
    In production this will call the AI vision model.
    """

    parser_classes = [MultiPartParser]

    def post(self, request, *args, **kwargs):
        image = request.FILES.get("image")
        if not image:
            return Response(
                {"error": "No image file provided. Send it as 'image' in form-data."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # ── MVP mock response ───────────────────────────────────────────
        return Response(
            {
                "artifact_name": "Handcrafted Ethiopian Cultural Chair",
                "country": "Ethiopia",
                "confidence": 0.94,
                "story": {
                    "title": "The Kuriftu Heritage Chair",
                    "story": (
                        "This handcrafted chair has been a staple of Ethiopian "
                        "cultural heritage for centuries. Carved from locally "
                        "sourced wood, it represents the craftsmanship passed "
                        "down through generations of artisans in the highlands."
                    ),
                    "materials": "Indigenous hardwood, natural leather, hand-forged iron nails",
                    "cultural_significance": (
                        "Symbolises community gathering and storytelling traditions. "
                        "Historically used by village elders during coffee ceremonies "
                        "and conflict-resolution councils."
                    ),
                },
            },
            status=status.HTTP_200_OK,
        )
