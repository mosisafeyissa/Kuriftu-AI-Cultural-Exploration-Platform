from django.contrib import admin
from .models import Order


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ["id", "artifact", "user_email", "quantity", "status", "created_at"]
    list_filter = ["status", "artifact__country"]
    search_fields = ["user_email", "artifact__name"]
    readonly_fields = ["created_at"]
    ordering = ["-created_at"]
    date_hierarchy = "created_at"
