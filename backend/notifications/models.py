from django.conf import settings
from django.db import models


class Notification(models.Model):
    """Backend-driven notifications for users."""

    NOTIFICATION_TYPES = (
        ("welcome", "Welcome"),
        ("order_confirmed", "Order Confirmed"),
        ("discovery", "Discovery"),
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notifications"
    )
    title = models.CharField(max_length=200)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    notification_type = models.CharField(
        max_length=50, choices=NOTIFICATION_TYPES, default="discovery"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.title} for {self.user.email}"
