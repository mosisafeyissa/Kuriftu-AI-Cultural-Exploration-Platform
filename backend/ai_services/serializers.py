from rest_framework import serializers
from .models import ScanLog


class ScanLogSerializer(serializers.ModelSerializer):
    """Read-only serializer for the ScanLog admin/analytics API."""
    class Meta:
        model = ScanLog
        fields = [
            "id",
            "result_object",
            "result_country",
            "result_category",
            "confidence",
            "matched_artifact",
            "story_generated",
            "error_message",
            "created_at",
        ]
        read_only_fields = fields
