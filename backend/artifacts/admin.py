from django.contrib import admin
from django.utils.html import format_html
from .models import Country, Villa, Artifact, Story


@admin.register(Country)
class CountryAdmin(admin.ModelAdmin):
    list_display = ["name", "code", "villa_count", "artifact_count"]
    search_fields = ["name", "code"]

    @admin.display(description="Villas")
    def villa_count(self, obj):
        return obj.villas.count()

    @admin.display(description="Artifacts")
    def artifact_count(self, obj):
        return obj.artifacts.count()


@admin.register(Villa)
class VillaAdmin(admin.ModelAdmin):
    list_display = ["name", "country", "location", "artifact_count"]
    list_filter = ["country"]
    search_fields = ["name", "location"]

    @admin.display(description="Artifacts")
    def artifact_count(self, obj):
        return obj.artifacts.count()


class StoryInline(admin.StackedInline):
    model = Story
    extra = 0
    fields = ["title", "story", "materials", "cultural_significance", "ai_generated"]
    readonly_fields = ["ai_generated"]


@admin.register(Artifact)
class ArtifactAdmin(admin.ModelAdmin):
    list_display = ["name", "country", "villa", "price", "has_story"]
    list_filter = ["country", "villa"]
    search_fields = ["name"]
    inlines = [StoryInline]

    @admin.display(boolean=True, description="Has Story")
    def has_story(self, obj):
        return hasattr(obj, "story")


@admin.register(Story)
class StoryAdmin(admin.ModelAdmin):
    list_display = ["title", "artifact", "ai_generated", "story_preview"]
    list_filter = ["ai_generated"]
    search_fields = ["title", "artifact__name"]
    readonly_fields = ["ai_generated", "story_preview_full"]
    fieldsets = [
        ("Identity", {"fields": ["artifact", "title", "ai_generated"]}),
        ("Content",  {"fields": ["story", "materials", "cultural_significance"]}),
        ("Preview",  {"fields": ["story_preview_full"]}),
    ]

    @admin.display(description="Story Preview")
    def story_preview(self, obj):
        return obj.story[:80] + "…" if len(obj.story) > 80 else obj.story

    @admin.display(description="Full Story (formatted)")
    def story_preview_full(self, obj):
        return format_html(
            "<div style='max-width:700px;line-height:1.6;white-space:pre-wrap;'>{}</div>",
            obj.story,
        )
