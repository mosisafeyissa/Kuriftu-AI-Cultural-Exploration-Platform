from django.urls import path
from . import views

urlpatterns = [
    path("countries/", views.country_list, name="country-list"),
    path("villas/", views.villa_list, name="villa-list"),
    path("artifacts/featured/", views.featured_artifacts, name="artifact-featured"),
    path("artifacts/", views.artifact_list, name="artifact-list"),
    path("artifacts/<int:pk>/", views.artifact_detail, name="artifact-detail"),
    path("scan/", views.scan_artifact, name="scan-artifact"),
    # Villa Tour Guide
    path("villa-guide/<uuid:qr_code>/", views.villa_guide, name="villa-guide"),
    path("villa-guide/<uuid:qr_code>/translate/", views.villa_guide_translate, name="villa-guide-translate"),
]
