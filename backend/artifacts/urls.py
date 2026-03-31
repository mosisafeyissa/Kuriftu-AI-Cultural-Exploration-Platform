from django.urls import path
from . import views

urlpatterns = [
    path("countries/", views.country_list, name="country-list"),
    path("villas/", views.villa_list, name="villa-list"),
    path("artifacts/", views.artifact_list, name="artifact-list"),
    path("artifacts/<int:pk>/", views.artifact_detail, name="artifact-detail"),
    path("scan/", views.scan_artifact, name="scan-artifact"),
]

