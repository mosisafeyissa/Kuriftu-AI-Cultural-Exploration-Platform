from rest_framework import serializers
from .models import Order
from artifacts.models import Artifact


class OrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Order
        fields = ["id", "artifact", "user_email", "quantity", "status", "created_at"]
        read_only_fields = ["status", "created_at"]

    def validate_artifact(self, value):
        """Ensure the artifact actually exists (belt-and-braces beyond FK)."""
        if not Artifact.objects.filter(pk=value.pk).exists():
            raise serializers.ValidationError("Artifact does not exist.")
        return value

    def validate_quantity(self, value):
        if value < 1:
            raise serializers.ValidationError("Quantity must be at least 1.")
        return value
