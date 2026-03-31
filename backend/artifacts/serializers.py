from rest_framework import serializers
from .models import Country, Villa, Artifact, Story


class CountrySerializer(serializers.ModelSerializer):
    class Meta:
        model = Country
        fields = ["id", "name", "code", "image_url"]


class VillaSerializer(serializers.ModelSerializer):
    country = CountrySerializer(read_only=True)

    class Meta:
        model = Villa
        fields = ["id", "name", "country", "location", "image_url"]


class StorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Story
        fields = ["id", "title", "story", "materials", "cultural_significance", "ai_generated"]


class ArtifactSerializer(serializers.ModelSerializer):
    country = CountrySerializer(read_only=True)
    villa = VillaSerializer(read_only=True)
    story = StorySerializer(read_only=True)

    class Meta:
        model = Artifact
        fields = ["id", "name", "country", "villa", "description", "price", "image_url", "story"]
