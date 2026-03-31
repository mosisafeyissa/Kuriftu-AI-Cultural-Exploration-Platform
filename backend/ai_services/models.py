from django.db import models


class ScanLog(models.Model):
    """
    Logs every scan attempt for analytics and debugging.
    Records what image was scanned, what the AI identified,
    and the confidence level.
    """

    image = models.ImageField(
        upload_to="scans/",
        help_text="The uploaded image that was scanned.",
    )
    result_object = models.CharField(
        max_length=300,
        help_text="The artifact name returned by the AI.",
    )
    result_country = models.CharField(
        max_length=100,
        help_text="The country of origin returned by the AI.",
    )
    result_category = models.CharField(
        max_length=100,
        default="Other",
        help_text="The category returned by the AI.",
    )
    confidence = models.FloatField(
        default=0.0,
        help_text="AI confidence score (0.0 to 1.0).",
    )
    matched_artifact = models.ForeignKey(
        "artifacts.Artifact",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="scan_logs",
        help_text="The DB artifact this scan matched to (if any).",
    )
    story_generated = models.BooleanField(
        default=False,
        help_text="Whether a new story was AI-generated for this scan.",
    )
    error_message = models.TextField(
        blank=True,
        default="",
        help_text="Error details if the scan failed.",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Scan Log"
        verbose_name_plural = "Scan Logs"

    def __str__(self):
        return (
            f"Scan: {self.result_object} ({self.result_country}) "
            f"— {self.confidence:.0%} @ {self.created_at:%Y-%m-%d %H:%M}"
        )
