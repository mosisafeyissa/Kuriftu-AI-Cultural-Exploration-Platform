import logging
from datetime import timedelta

from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Notification
from .serializers import NotificationSerializer

logger = logging.getLogger(__name__)


def _ensure_discovery_notification(user):
    """
    If the user has no 'discovery' notification in the past 24 hours,
    create one automatically.
    """
    cutoff = timezone.now() - timedelta(hours=24)
    recent = Notification.objects.filter(
        user=user, notification_type="discovery", created_at__gte=cutoff
    ).exists()

    if not recent:
        Notification.objects.create(
            user=user,
            notification_type="discovery",
            title="New Artifacts Discovered",
            message="Explore the latest additions to our cultural collection!",
        )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def notification_list(request):
    """GET /api/notifications/ — Returns all notifications for the authenticated user."""
    # Ensure a discovery notification exists
    _ensure_discovery_notification(request.user)

    notifications = Notification.objects.filter(user=request.user)
    serializer = NotificationSerializer(notifications, many=True)
    return Response(serializer.data)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def mark_read(request):
    """
    POST /api/notifications/mark-read/
    Body: { "ids": [1, 2, 3] } — mark specific notifications as read.
    If no ids provided, marks ALL notifications as read.
    """
    ids = request.data.get("ids")
    qs = Notification.objects.filter(user=request.user, is_read=False)
    if ids:
        qs = qs.filter(id__in=ids)
    updated = qs.update(is_read=True)
    return Response({"marked_read": updated})


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def unread_count(request):
    """GET /api/notifications/unread-count/ — Returns unread count."""
    count = Notification.objects.filter(user=request.user, is_read=False).count()
    return Response({"unread_count": count})
