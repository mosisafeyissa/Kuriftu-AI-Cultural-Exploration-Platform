from django.db import models


class Country(models.Model):
    name = models.CharField(max_length=100)
    code = models.CharField(max_length=10, unique=True)
    image_url = models.URLField(max_length=500, blank=True, default="")

    class Meta:
        ordering = ["name"]
        verbose_name_plural = "Countries"

    def __str__(self):
        return self.name


class Villa(models.Model):
    name = models.CharField(max_length=200)
    country = models.ForeignKey(Country, on_delete=models.CASCADE, related_name="villas")
    location = models.CharField(max_length=300, blank=True)
    image_url = models.URLField(
        max_length=500, blank=True, default="https://placehold.co/400x300?text=Villa"
    )

    class Meta:
        ordering = ["country", "name"]

    def __str__(self):
        return f"{self.name} ({self.country.name})"


class Artifact(models.Model):
    name = models.CharField(max_length=200)
    country = models.ForeignKey(Country, on_delete=models.CASCADE, related_name="artifacts")
    villa = models.ForeignKey(
        Villa, on_delete=models.SET_NULL, null=True, blank=True, related_name="artifacts"
    )
    description = models.TextField(default="A beautiful cultural artifact.")
    price = models.DecimalField(max_digits=10, decimal_places=2)
    image_url = models.URLField(
        max_length=500, blank=True, default="https://placehold.co/400x300?text=Artifact"
    )
    image = models.ImageField(upload_to="artifacts/", blank=True, null=True)

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

    class Meta:
        ordering = ["artifact"]
        verbose_name_plural = "Stories"

    def __str__(self):
        return self.title
