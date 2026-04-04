import uuid
from django.db import models


class Country(models.Model):
    name = models.CharField(max_length=100)
    code = models.CharField(max_length=10, unique=True)
    image = models.ImageField(upload_to="countries/", blank=True, null=True)

    class Meta:
        ordering = ["name"]
        verbose_name_plural = "Countries"

    def __str__(self):
        return self.name


class Villa(models.Model):
    name = models.CharField(max_length=200)
    country = models.ForeignKey(Country, on_delete=models.CASCADE, related_name="villas")
    location = models.CharField(max_length=300, blank=True)
    image = models.ImageField(upload_to="villas/", blank=True, null=True)
    # Tour Guide fields
    slug = models.SlugField(unique=True, blank=True, help_text="User-friendly URL identifier")
    qr_code = models.UUIDField(default=uuid.uuid4, unique=True, editable=False,
                               help_text="Unique ID for QR code scanning")
    qr_image = models.ImageField(upload_to="qr_codes/", blank=True, null=True,
                                 help_text="Generated QR code image")
    welcome_story = models.TextField(blank=True, default="",
                                     help_text="Narrative welcome text for guests")
    cultural_highlights = models.JSONField(default=list, blank=True,
                                           help_text="List of cultural highlight strings")
    design_philosophy = models.TextField(blank=True, default="",
                                         help_text="Explanation of villa architecture and decor")

    class Meta:
        ordering = ["country", "name"]

    def save(self, *args, **kwargs):
        from django.utils.text import slugify
        import qrcode
        import io
        from django.core.files.base import ContentFile

        # Track if slug is changing
        slug_changed = False
        if self.pk:
            old_villa = Villa.objects.get(pk=self.pk)
            if old_villa.slug != self.slug:
                slug_changed = True

        if not self.slug:
            self.slug = slugify(self.name)
            # Ensure unique slug
            original_slug = self.slug
            counter = 1
            while Villa.objects.filter(slug=self.slug).exclude(pk=self.pk).exists():
                self.slug = f"{original_slug}-{counter}"
                counter += 1
            slug_changed = True

        # Generate QR code if image doesn't exist or slug changed
        if not self.qr_image or slug_changed:
            qr = qrcode.QRCode(version=1, box_size=10, border=4)
            # Encode a URL (relative to frontend, but usually absolute for QRs)
            guide_url = f"https://kuriftu-village.app/guide/{self.slug}/"
            qr.add_data(guide_url)
            qr.make(fit=True)

            img = qr.make_image(fill_color="black", back_color="white")
            
            # Save to buffer
            buffer = io.BytesIO()
            img.save(buffer, format="PNG")
            
            # Save to ImageField
            filename = f"qr_{self.slug}.png"
            # Delete old image if it exists and slug changed
            if slug_changed and self.qr_image:
                self.qr_image.delete(save=False)
                
            self.qr_image.save(filename, ContentFile(buffer.getvalue()), save=False)

        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.name} ({self.country.name})"


class VillaSection(models.Model):
    """Represents a room or zone within a villa (e.g. Living Room, Bedroom, Garden)."""
    villa = models.ForeignKey(Villa, on_delete=models.CASCADE, related_name="sections")
    name = models.CharField(max_length=200)
    order = models.PositiveIntegerField(default=0, help_text="Display order within villa")
    description = models.TextField(blank=True, default="")
    narrative = models.TextField(blank=True, default="",
                                 help_text="Story-format guide text for this section")
    image = models.ImageField(upload_to="sections/", blank=True, null=True)

    class Meta:
        ordering = ["villa", "order"]
        unique_together = ["villa", "order"]

    def __str__(self):
        return f"{self.villa.name} — {self.name}"


class Artifact(models.Model):
    name = models.CharField(max_length=200)
    country = models.ForeignKey(Country, on_delete=models.CASCADE, related_name="artifacts")
    villa = models.ForeignKey(
        Villa, on_delete=models.SET_NULL, null=True, blank=True, related_name="artifacts"
    )
    section = models.ForeignKey(
        VillaSection, on_delete=models.SET_NULL, null=True, blank=True,
        related_name="artifacts", help_text="Room/zone where this artifact is displayed"
    )
    description = models.TextField(default="A beautiful cultural artifact.")
    price = models.DecimalField(max_digits=10, decimal_places=2)
    image_url = models.URLField(
        max_length=500, blank=True, default="https://placehold.co/400x300?text=Artifact"
    )
    image = models.ImageField(upload_to="villas/", blank=True, null=True)
    embedding = models.JSONField(null=True, blank=True, help_text="MobileNetV2 feature vector (auto-generated)")
    is_featured = models.BooleanField(default=False, help_text="Show in Featured Artifacts on home screen")

    class Meta:
        ordering = ["country", "name"]

    def __str__(self):
        return f"{self.name} ({self.country.name})"


class Story(models.Model):
    artifact = models.OneToOneField(Artifact, on_delete=models.CASCADE, related_name="story")
    title = models.CharField(max_length=200)
    story = models.TextField()
    materials = models.CharField(max_length=300)
    cultural_significance = models.TextField()
    ai_generated = models.BooleanField(default=False)
    language = models.CharField(max_length=10, default="en",
                                help_text="Language code (en, am, fr, ar, sw)")
    audio_url = models.URLField(max_length=500, blank=True, default="",
                                help_text="URL to audio narration file")

    class Meta:
        ordering = ["artifact"]
        verbose_name_plural = "Stories"

    def __str__(self):
        return self.title
