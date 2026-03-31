from django.urls import path
from . import views

urlpatterns = [
    path("scan/", views.ai_scan, name="ai-scan"),
    path("generate-story/", views.ai_generate_story, name="ai-generate-story"),
    path("scan-logs/", views.scan_log_list, name="scan-log-list"),
]
