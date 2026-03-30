from rest_framework import generics

from .models import Artifact, Country, Villa
from .serializers import ArtifactSerializer, CountrySerializer, VillaSerializer


# ── Countries ────────────────────────────────────────────────────────────────

class CountryListView(generics.ListCreateAPIView):
    queryset = Country.objects.all()
    serializer_class = CountrySerializer


class CountryDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Country.objects.all()
    serializer_class = CountrySerializer


# ── Villas ───────────────────────────────────────────────────────────────────

class VillaListView(generics.ListCreateAPIView):
    serializer_class = VillaSerializer

    def get_queryset(self):
        qs = Villa.objects.select_related("country").all()
        country_id = self.request.query_params.get("country")
        if country_id is not None:
            qs = qs.filter(country_id=country_id)
        return qs


class VillaDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Villa.objects.select_related("country").all()
    serializer_class = VillaSerializer


# ── Artifacts ────────────────────────────────────────────────────────────────

class ArtifactListView(generics.ListCreateAPIView):
    serializer_class = ArtifactSerializer

    def get_queryset(self):
        qs = Artifact.objects.select_related("country", "villa", "story").all()
        villa_id = self.request.query_params.get("villa")
        if villa_id is not None:
            qs = qs.filter(villa_id=villa_id)
        return qs


class ArtifactDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Artifact.objects.select_related("country", "villa", "story").all()
    serializer_class = ArtifactSerializer