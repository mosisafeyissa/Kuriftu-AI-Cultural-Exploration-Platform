import random
import string

from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models
from django.utils import timezone

from .managers import UserManager


class User(AbstractBaseUser, PermissionsMixin):
    """Custom user model — email is the login credential, no username."""

    email = models.EmailField(unique=True, db_index=True)
    full_name = models.CharField(max_length=150, blank=True, default="")
    phone = models.CharField(max_length=20, blank=True, default="")

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(default=timezone.now)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []  # email is already required by USERNAME_FIELD

    class Meta:
        ordering = ["-date_joined"]

    def __str__(self):
        return self.email

    @property
    def display_name(self):
        return self.full_name or self.email.split("@")[0]


class PasswordResetCode(models.Model):
    """Stores a 6-digit reset code sent to the user's email."""

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="reset_codes")
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    used = models.BooleanField(default=False)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Reset code for {self.user.email}"

    @staticmethod
    def generate_code():
        return "".join(random.choices(string.digits, k=6))

    @property
    def is_expired(self):
        """Code expires after 15 minutes."""
        return timezone.now() > self.created_at + timezone.timedelta(minutes=15)

    @property
    def is_valid(self):
        return not self.used and not self.is_expired
