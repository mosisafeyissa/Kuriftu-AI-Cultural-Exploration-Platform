from rest_framework import serializers

from .models import Guest


class GuestSerializer(serializers.ModelSerializer):
    class Meta:
        model = Guest
        fields = ["id", "email", "created_at"]
        read_only_fields = ["created_at"]
