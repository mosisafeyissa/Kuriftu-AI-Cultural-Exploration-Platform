from django.conf import settings
from django.db import models
from artifacts.models import Artifact


class Order(models.Model):
    class Status(models.TextChoices):
        PENDING = "Pending", "Pending"
        PROCESSING = "Processing", "Processing"
        COMPLETED = "Completed", "Completed"
        CANCELLED = "Cancelled", "Cancelled"

    class PaymentStatus(models.TextChoices):
        UNPAID = "unpaid", "Unpaid"
        PENDING = "pending", "Payment Pending"
        PAID = "paid", "Paid"
        FAILED = "failed", "Failed"

    artifact = models.ForeignKey(Artifact, on_delete=models.CASCADE, related_name="orders")
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name="orders",
    )
    user_email = models.EmailField()
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    quantity = models.PositiveIntegerField(default=1)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    payment_status = models.CharField(
        max_length=20, choices=PaymentStatus.choices, default=PaymentStatus.UNPAID
    )
    tx_ref = models.CharField(max_length=100, blank=True, null=True, unique=True)
    checkout_url = models.URLField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Order #{self.pk} — {self.artifact.name} x{self.quantity} ({self.status})"

    def calculate_total(self):
        """Calculate total from artifact price * quantity."""
        self.total_amount = self.artifact.price * self.quantity
        return self.total_amount
