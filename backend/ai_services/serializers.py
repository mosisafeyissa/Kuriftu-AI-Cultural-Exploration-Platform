from rest_framework import serializers
from .models import ScanLog


class ScanImageSerializer(serializers.Serializer):
    """Validates the incoming scan request (image upload)."""
    image = serializers.ImageField(
        required=False,
        help_text="The image of the artifact to identify.",
    )
    artifact_name = serializers.CharField(
        required=False,
        allow_blank=True,
        help_text="Optional text fallback — name of the artifact to look up.",
    )

    def validate(self, attrs):
        if not attrs.get("image") and not attrs.get("artifact_name", "").strip():
            raise serializers.ValidationError(
                "Provide either an 'image' file or 'artifact_name' text."
            )
        return attrs


class IdentificationResultSerializer(serializers.Serializer):
    """Formats the identification result returned by the AI."""
    artifact_name = serializers.CharField()
    country = serializers.CharField()
    category = serializers.CharField(default="Other")
    confidence = serializers.FloatField()
    materials = serializers.ListField(child=serializers.CharField(), default=list)


class StoryResultSerializer(serializers.Serializer):
    """Formats the story result returned by the AI."""
    title = serializers.CharField()
    story = serializers.CharField()
    materials = serializers.CharField()
    cultural_significance = serializers.CharField()
    fun_fact = serializers.CharField(required=False, default="")


class ScanResponseSerializer(serializers.Serializer):
    """Formats the complete scan response sent back to the client."""
    artifact_name = serializers.CharField()
    country = serializers.CharField()
    confidence = serializers.FloatField()
    category = serializers.CharField(default="Other")
    identification = IdentificationResultSerializer(required=False)
    story = StoryResultSerializer(required=False, allow_null=True)
    price = serializers.CharField(allow_null=True)
    image_url = serializers.CharField()
    source = serializers.CharField(help_text="'database' or 'ai_generated'")
    note = serializers.CharField(required=False, default="")


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
