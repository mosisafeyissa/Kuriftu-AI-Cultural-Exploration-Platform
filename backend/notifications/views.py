from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Notification
from .serializers import NotificationSerializer

@api_view(["GET"])
def notification_list(request):
    """
    GET /api/notifications/
    Returns all notifications for the authenticated user based on X-User-Email.
    """
    email = getattr(request, 'user_email', None)

    if not email:
        return Response(
            {"error": "Authentication required. Missing X-User-Email header."},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    notifications = Notification.objects.filter(user_email__iexact=email)
    serializer = NotificationSerializer(notifications, many=True)
    return Response(serializer.data)
