from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import User, PasswordResetCode


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Admin config for the custom User model (email-based)."""

    list_display = ("email", "full_name", "is_active", "is_staff", "date_joined")
    list_filter = ("is_staff", "is_active")
    search_fields = ("email", "full_name")
    ordering = ("-date_joined",)

    # Replace username-based fieldsets with email-based ones
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Personal Info", {"fields": ("full_name", "phone")}),
        (
            "Permissions",
            {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")},
        ),
        ("Dates", {"fields": ("date_joined", "last_login")}),
    )
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("email", "full_name", "password1", "password2"),
            },
        ),
    )
    readonly_fields = ("date_joined", "last_login")


@admin.register(PasswordResetCode)
class PasswordResetCodeAdmin(admin.ModelAdmin):
    list_display = ("user", "code", "created_at", "used")
    list_filter = ("used",)
    search_fields = ("user__email",)
    ordering = ("-created_at",)
