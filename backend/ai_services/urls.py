from django.urls import path

from . import views

urlpatterns = [
    path("scan/", views.ArtifactScanView.as_view(), name="artifact-scan"),
]
