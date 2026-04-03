from rest_framework import serializers
from .models import Country, Villa, VillaSection, Artifact, Story

class LocalAssetImageField(serializers.ImageField):
    def to_representation(self, value):
        if not value:
            return None
        name = getattr(value, 'name', str(value))
        if name and name.startswith("assets/"):
            return name
        return super().to_representation(value)


class CountrySerializer(serializers.ModelSerializer):
    image = LocalAssetImageField(read_only=True)

    class Meta:
        model = Country
        fields = ["id", "name", "code", "image"]


class StorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Story
        fields = ["id", "title", "story", "materials", "cultural_significance",
                  "ai_generated", "language", "audio_url"]


class SectionArtifactSerializer(serializers.ModelSerializer):
    """Lightweight artifact serializer for section context."""
    story = StorySerializer(read_only=True)
    image = LocalAssetImageField(read_only=True)

    class Meta:
        model = Artifact
        fields = ["id", "name", "description", "price", "image", "story"]


class VillaSectionSerializer(serializers.ModelSerializer):
    artifacts = serializers.SerializerMethodField()
    image = LocalAssetImageField(read_only=True)

    class Meta:
        model = VillaSection
        fields = ["id", "name", "order", "description", "narrative", "image", "artifacts"]

    def get_artifacts(self, obj):
        artifacts = obj.artifacts.select_related("story").all()
        return SectionArtifactSerializer(artifacts, many=True, context=self.context).data


class VillaSerializer(serializers.ModelSerializer):
    country = CountrySerializer(read_only=True)
    image = LocalAssetImageField(read_only=True)

    class Meta:
        model = Villa
        fields = ["id", "name", "country", "location", "image"]


class VillaGuideSerializer(serializers.ModelSerializer):
    """Full villa guide with sections, artifacts, and narratives."""
    country = CountrySerializer(read_only=True)
    sections = serializers.SerializerMethodField()
    image = LocalAssetImageField(read_only=True)

    class Meta:
        model = Villa
        fields = ["id", "name", "country", "location", "image",
                  "qr_code", "welcome_story", "cultural_highlights",
                  "design_philosophy", "sections"]

    def get_sections(self, obj):
        sections = obj.sections.prefetch_related("artifacts", "artifacts__story").all()
        return VillaSectionSerializer(sections, many=True, context=self.context).data


class ArtifactSerializer(serializers.ModelSerializer):
    country = CountrySerializer(read_only=True)
    villa = VillaSerializer(read_only=True)
    story = StorySerializer(read_only=True)
    image = LocalAssetImageField(read_only=True)

    class Meta:
        model = Artifact
        fields = ["id", "name", "country", "villa", "description", "price", "image", "is_featured", "story"]
