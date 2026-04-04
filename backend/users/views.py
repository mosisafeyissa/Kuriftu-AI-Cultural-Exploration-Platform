from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken

from .models import PasswordResetCode
from .serializers import (
    ChangePasswordSerializer,
    LoginSerializer,
    PasswordResetConfirmSerializer,
    PasswordResetRequestSerializer,
    RegisterSerializer,
    UserProfileSerializer,
)
import logging

logger = logging.getLogger(__name__)


def _create_welcome_notification(user, is_new=False):
    """Create a welcome notification for the user."""
    try:
        from notifications.models import Notification

        # Don't duplicate if one exists in the last hour
        from django.utils import timezone
        from datetime import timedelta
        cutoff = timezone.now() - timedelta(hours=1)
        exists = Notification.objects.filter(
            user=user, notification_type="welcome", created_at__gte=cutoff
        ).exists()
        if exists:
            return

        if is_new:
            Notification.objects.create(
                user=user,
                notification_type="welcome",
                title="Welcome to Afrilens!",
                message="Your journey into African heritage begins now. Explore our curated collection of cultural artifacts.",
            )
        else:
            Notification.objects.create(
                user=user,
                notification_type="welcome",
                title="Welcome Back!",
                message="Great to see you again. Check out what's new in our collection.",
            )
    except Exception as e:
        logger.warning(f"Failed to create welcome notification: {e}")


def _get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        "refresh": str(refresh),
        "access": str(refresh.access_token),
    }


# ── Registration ──────────────────────────────────────────────────────────────


@api_view(["POST"])
@permission_classes([AllowAny])
def register(request):
    """
    POST /api/auth/register/
    Body: { "email", "password", "password_confirm", "full_name"?, "phone"? }
    """
    serializer = RegisterSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    user = serializer.save()
    tokens = _get_tokens_for_user(user)
    _create_welcome_notification(user, is_new=True)
    return Response(
        {
            "user": UserProfileSerializer(user).data,
            "tokens": tokens,
        },
        status=status.HTTP_201_CREATED,
    )



# ── Login ─────────────────────────────────────────────────────────────────────


@api_view(["POST"])
@permission_classes([AllowAny])
def login(request):
    """
    POST /api/auth/login/
    Body: { "email", "password" }
    """
    serializer = LoginSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    user = serializer.validated_data["user"]
    tokens = _get_tokens_for_user(user)
    _create_welcome_notification(user, is_new=False)
    return Response(
        {
            "user": UserProfileSerializer(user).data,
            "tokens": tokens,
        },
    )


# ── Profile ───────────────────────────────────────────────────────────────────


@api_view(["GET", "PUT"])
@permission_classes([IsAuthenticated])
def profile(request):
    """
    GET  /api/auth/profile/  — return current user info
    PUT  /api/auth/profile/  — update full_name, phone
    """
    if request.method == "GET":
        serializer = UserProfileSerializer(request.user)
        return Response(serializer.data)

    serializer = UserProfileSerializer(request.user, data=request.data, partial=True)
    serializer.is_valid(raise_exception=True)
    serializer.save()
    return Response(serializer.data)


# ── Change Password ──────────────────────────────────────────────────────────


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def change_password(request):
    """
    POST /api/auth/change-password/
    Body: { "old_password", "new_password", "new_password_confirm" }
    """
    serializer = ChangePasswordSerializer(data=request.data, context={"request": request})
    serializer.is_valid(raise_exception=True)
    request.user.set_password(serializer.validated_data["new_password"])
    request.user.save()
    # Issue fresh tokens since old ones may reference the old password hash
    tokens = _get_tokens_for_user(request.user)
    return Response({"detail": "Password changed successfully.", "tokens": tokens})


# ── Password Reset (request code) ────────────────────────────────────────────


@api_view(["POST"])
@permission_classes([AllowAny])
def password_reset_request(request):
    """
    POST /api/auth/password-reset/
    Body: { "email" }

    In dev mode, returns the reset code in the response.
    In production, this should send the code via email (e.g., SendGrid).
    """
    serializer = PasswordResetRequestSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    email = serializer.validated_data["email"]
    user = getattr(serializer, "user", None)

    response_data = {"detail": "If an account with that email exists, a reset code has been sent."}

    if user:
        # Invalidate any existing unused codes
        PasswordResetCode.objects.filter(user=user, used=False).update(used=True)
        # Generate new code
        code = PasswordResetCode.generate_code()
        PasswordResetCode.objects.create(user=user, code=code)

        # DEV MODE: return the code in response (remove in production!)
        from django.conf import settings

        if settings.DEBUG:
            response_data["_dev_reset_code"] = code

    return Response(response_data)


# ── Password Reset (confirm) ─────────────────────────────────────────────────


@api_view(["POST"])
@permission_classes([AllowAny])
def password_reset_confirm(request):
    """
    POST /api/auth/password-reset/confirm/
    Body: { "email", "code", "new_password", "new_password_confirm" }
    """
    serializer = PasswordResetConfirmSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    user = serializer.validated_data["user"]
    reset_code = serializer.validated_data["reset_code"]

    user.set_password(serializer.validated_data["new_password"])
    user.save()

    reset_code.used = True
    reset_code.save()

    tokens = _get_tokens_for_user(user)
    return Response({"detail": "Password has been reset.", "tokens": tokens})
