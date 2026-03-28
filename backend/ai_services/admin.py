from django.contrib import admin
from .models import ScanLog


@admin.register(ScanLog)
class ScanLogAdmin(admin.ModelAdmin):
    list_display = [
        "id",
        "result_object",
        "result_country",
        "confidence_display",
        "story_generated",
        "matched_artifact",
        "created_at",
    ]
    list_filter = ["result_country", "story_generated", "created_at"]
    search_fields = ["result_object", "result_country"]
    readonly_fields = [
        "result_object",
        "result_country",
        "result_category",
        "confidence",
        "matched_artifact",
        "story_generated",
        "error_message",
        "created_at",
    ]
    ordering = ["-created_at"]

    @admin.display(description="Confidence")
    def confidence_display(self, obj):
        return f"{obj.confidence:.0%}"
