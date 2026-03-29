from rest_framework import serializers

from .models import Order


class OrderSerializer(serializers.ModelSerializer):
    guest_email = serializers.EmailField(source="guest.email", read_only=True)
    artifact_name = serializers.CharField(source="artifact.name", read_only=True)

    class Meta:
        model = Order
        fields = [
            "id",
            "guest",
            "guest_email",
            "artifact",
            "artifact_name",
            "quantity",
            "status",
            "created_at",
        ]
        read_only_fields = ["created_at"]
