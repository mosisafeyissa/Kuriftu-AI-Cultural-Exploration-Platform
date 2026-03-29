from rest_framework import serializers

from .models import Artifact, Country, CulturalStory, Villa


class CountrySerializer(serializers.ModelSerializer):
    class Meta:
        model = Country
        fields = ["id", "name", "description", "flag_image"]


class VillaSerializer(serializers.ModelSerializer):
    country_name = serializers.CharField(source="country.name", read_only=True)

    class Meta:
        model = Villa
        fields = ["id", "name", "country", "country_name", "description"]


class CulturalStorySerializer(serializers.ModelSerializer):
    class Meta:
        model = CulturalStory
        fields = ["id", "title", "story", "materials", "cultural_significance"]


class ArtifactSerializer(serializers.ModelSerializer):
    story = CulturalStorySerializer(read_only=True)
    country_name = serializers.CharField(source="country.name", read_only=True)
    villa_name = serializers.CharField(source="villa.name", read_only=True)

    class Meta:
        model = Artifact
        fields = [
            "id",
            "name",
            "country",
            "country_name",
            "villa",
            "villa_name",
            "description",
            "price",
            "image",
            "story",
        ]
