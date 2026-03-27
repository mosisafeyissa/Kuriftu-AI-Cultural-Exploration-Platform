from django.urls import path
from . import views

urlpatterns = [
    path("artifacts/", views.artifact_list, name="artifact-list"),
    path("scan/", views.scan_artifact, name="scan-artifact"),
]
