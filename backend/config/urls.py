"""
URL configuration for config project.
"""

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", include("artifacts.urls")),
    path("api/", include("orders.urls")),
    path("api/ai/", include("ai_services.urls")),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
