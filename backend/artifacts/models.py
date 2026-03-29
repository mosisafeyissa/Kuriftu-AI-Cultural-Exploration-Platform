from django.db import models


class Country(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    flag_image = models.ImageField(upload_to="flags/", blank=True, null=True)

    class Meta:
        verbose_name_plural = "countries"
        ordering = ["name"]

    def __str__(self):
        return self.name


class Villa(models.Model):
    name = models.CharField(max_length=200)
    country = models.ForeignKey(
        Country, on_delete=models.CASCADE, related_name="villas"
    )
    description = models.TextField(blank=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return f"{self.name} ({self.country.name})"


class Artifact(models.Model):
    name = models.CharField(max_length=200)
    country = models.ForeignKey(
        Country, on_delete=models.CASCADE, related_name="artifacts"
    )
    villa = models.ForeignKey(
        Villa, on_delete=models.CASCADE, related_name="artifacts"
    )
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    image = models.ImageField(upload_to="artifacts/", blank=True, null=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class CulturalStory(models.Model):
    artifact = models.OneToOneField(
        Artifact, on_delete=models.CASCADE, related_name="story"
    )
    title = models.CharField(max_length=300)
    story = models.TextField()
    materials = models.TextField(blank=True)
    cultural_significance = models.TextField(blank=True)

    class Meta:
        verbose_name_plural = "cultural stories"

    def __str__(self):
        return self.title
