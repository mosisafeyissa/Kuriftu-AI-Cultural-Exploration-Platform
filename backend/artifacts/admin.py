from django.contrib import admin
from django.utils.html import format_html
from .models import Country, Villa, VillaSection, Artifact, Story


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


class VillaSectionInline(admin.TabularInline):
    model = VillaSection
    extra = 0
    fields = ["name", "order", "description", "image"]
    ordering = ["order"]


@admin.register(Villa)
class VillaAdmin(admin.ModelAdmin):
    list_display = ["name", "country", "slug", "qr_preview_list", "section_count", "artifact_count"]
    list_filter = ["country"]
    search_fields = ["name", "location", "slug"]
    readonly_fields = ["qr_code", "qr_preview"]
    prepopulated_fields = {"slug": ("name",)}
    inlines = [VillaSectionInline]
    fieldsets = [
        ("Basic", {"fields": ["name", "slug", "country", "location", "image", "qr_code"]}),
        ("QR Code", {"fields": ["qr_image", "qr_preview"]}),
        ("Tour Guide", {"fields": ["welcome_story", "design_philosophy", "cultural_highlights"]}),
    ]

    @admin.display(description="QR Preview")
    def qr_preview(self, obj):
        if obj.qr_image:
            return format_html(
                '<img src="{}" width="200" height="200" style="border: 1px solid #ccc; border-radius: 8px;"/>',
                obj.qr_image.url
            )
        return "No QR image generated"

    @admin.display(description="QR")
    def qr_preview_list(self, obj):
        if obj.qr_image:
            return format_html(
                '<img src="{}" width="40" height="40" style="border-radius: 4px;"/>',
                obj.qr_image.url
            )
        return "-"

    @admin.display(description="Sections")
    def section_count(self, obj):
        return obj.sections.count()

    @admin.display(description="Artifacts")
    def artifact_count(self, obj):
        return obj.artifacts.count()


@admin.register(VillaSection)
class VillaSectionAdmin(admin.ModelAdmin):
    list_display = ["name", "villa", "order", "artifact_count"]
    list_filter = ["villa"]
    search_fields = ["name"]

    @admin.display(description="Artifacts")
    def artifact_count(self, obj):
        return obj.artifacts.count()


class StoryInline(admin.StackedInline):
    model = Story
    extra = 0
    fields = ["title", "story", "materials", "cultural_significance", "language", "audio_url", "ai_generated"]
    readonly_fields = ["ai_generated"]


@admin.register(Artifact)
class ArtifactAdmin(admin.ModelAdmin):
    list_display = ["name", "country", "villa", "section", "price", "has_story", "has_embedding"]
    list_filter = ["country", "villa", "section"]
    search_fields = ["name"]
    readonly_fields = ["embedding"]
    inlines = [StoryInline]

    @admin.display(boolean=True, description="Has Story")
    def has_story(self, obj):
        return hasattr(obj, "story")

    @admin.display(boolean=True, description="Has Embedding")
    def has_embedding(self, obj):
        return obj.embedding is not None


@admin.register(Story)
class StoryAdmin(admin.ModelAdmin):
    list_display = ["title", "artifact", "language", "ai_generated", "story_preview"]
    list_filter = ["ai_generated", "language"]
    search_fields = ["title", "artifact__name"]
    readonly_fields = ["ai_generated", "story_preview_full"]
    fieldsets = [
        ("Identity", {"fields": ["artifact", "title", "language", "ai_generated"]}),
        ("Content",  {"fields": ["story", "materials", "cultural_significance", "audio_url"]}),
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
