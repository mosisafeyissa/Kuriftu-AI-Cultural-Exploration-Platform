from django.urls import path

from . import views

urlpatterns = [
    path("countries/", views.CountryListView.as_view(), name="country-list"),
    path("countries/<int:pk>/", views.CountryDetailView.as_view(), name="country-detail"),
    path("villas/", views.VillaListView.as_view(), name="villa-list"),
    path("villas/<int:pk>/", views.VillaDetailView.as_view(), name="villa-detail"),
    path("artifacts/", views.ArtifactListView.as_view(), name="artifact-list"),
    path("artifacts/<int:pk>/", views.ArtifactDetailView.as_view(), name="artifact-detail"),
]
