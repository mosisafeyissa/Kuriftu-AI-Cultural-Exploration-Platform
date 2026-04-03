import re
import logging
from decimal import Decimal

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.db import transaction
from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import get_object_or_404

from .models import Order
from .serializers import OrderSerializer
from . import chapa_service

logger = logging.getLogger(__name__)

_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def _is_valid_email(email: str) -> bool:
    """Validate email format."""
    return bool(_EMAIL_RE.match(email))


def _create_order_notification(user, artifact_name, order_id):
    """Create an order-confirmed notification for the user."""
    try:
        from notifications.models import Notification

        Notification.objects.create(
            user=user,
            notification_type="order_confirmed",
            title="Order Confirmed! 🎉",
            message=f"Thank you for your purchase! Your {artifact_name} (Order #{order_id}) has been confirmed and is being processed.",
        )
        logger.info(f"Notification created for order #{order_id}")
    except Exception as e:
        logger.warning(f"Failed to create order notification: {e}")


@api_view(["GET"])
def order_list(request):
    """
    GET /api/orders/

    If the user is authenticated, returns all orders for that user.
    Otherwise, requires ?email=<guest_email> query param.
    """
    # Authenticated user: auto-filter by user
    if request.user and request.user.is_authenticated:
        orders = Order.objects.filter(user=request.user).select_related(
            "artifact", "artifact__country"
        )
        serializer = OrderSerializer(orders, many=True)
        return Response(serializer.data)

    # Fallback: email-based lookup
    email = request.query_params.get("email", "").strip()

    if not email:
        return Response(
            {"error": "Authentication required, or provide 'email' query param."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if not _is_valid_email(email):
        return Response(
            {"error": "Provided 'email' is not a valid email address."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    orders = Order.objects.filter(user_email__iexact=email).select_related(
        "artifact", "artifact__country"
    )
    serializer = OrderSerializer(orders, many=True)
    return Response(serializer.data)


@api_view(["GET"])
def order_detail(request, order_id):
    """
    GET /api/orders/{order_id}/
    
    Get detailed information about a specific order.
    """
    try:
        order = Order.objects.select_related("artifact", "artifact__country").get(pk=order_id)
    except Order.DoesNotExist:
        return Response(
            {"error": "Order not found."},
            status=status.HTTP_404_NOT_FOUND
        )
    
    # Authorization check
    if request.user and request.user.is_authenticated:
        if order.user != request.user:
            return Response(
                {"error": "You don't have permission to view this order."},
                status=status.HTTP_403_FORBIDDEN
            )
    else:
        # For guest users, require email query param
        email = request.query_params.get("email", "").strip()
        if not email or order.user_email.lower() != email.lower():
            return Response(
                {"error": "Email is required to view this order."},
                status=status.HTTP_403_FORBIDDEN
            )
    
    serializer = OrderSerializer(order)
    return Response(serializer.data)


@api_view(["POST"])
def create_order(request):
    """
    POST /api/order/
    Body: { "artifact": <id>, "quantity": <int>, "user_email"?: "..." }

    If authenticated, user and user_email are auto-filled from the token.
    """
    data = request.data.copy() if hasattr(request.data, "copy") else dict(request.data)

    # Auto-fill user_email from authenticated user if not provided
    if request.user and request.user.is_authenticated:
        if not data.get("user_email"):
            data["user_email"] = request.user.email

    serializer = OrderSerializer(data=data)
    if serializer.is_valid():
        # Create order with transaction to ensure consistency
        with transaction.atomic():
            # Attach user if authenticated
            if request.user and request.user.is_authenticated:
                order = serializer.save(user=request.user)
            else:
                # Validate guest email
                email = data.get("user_email", "")
                if not _is_valid_email(email):
                    return Response(
                        {"error": "Valid email is required for guest checkout."},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                order = serializer.save()

            order.calculate_total()
            order.save(update_fields=["total_amount"])

            # Initiate Chapa payment
            try:
                checkout_url, tx_ref = chapa_service.initialize_payment(order)
                order.refresh_from_db()
                
                return Response({
                    "order": OrderSerializer(order).data,
                    "checkout_url": checkout_url,
                    "tx_ref": tx_ref,
                    "message": "Order created successfully. Please complete payment."
                }, status=status.HTTP_201_CREATED)
                
            except Exception as e:
                logger.error(f"Payment init failed for order #{order.pk}: {e}")
                # Rollback order creation if payment fails
                order.delete()
                return Response(
                    {"error": f"Payment initialization failed: {str(e)}"},
                    status=status.HTTP_402_PAYMENT_REQUIRED
                )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["POST"])
def verify_payment(request):
    """
    POST /api/verify-payment/
    Body: { "tx_ref": "kuriftu-order-xxxx" }

    Verifies payment with Chapa and updates the order status.
    """
    tx_ref = request.data.get("tx_ref", "").strip()
    if not tx_ref:
        return Response(
            {"error": "tx_ref is required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        order = Order.objects.get(tx_ref=tx_ref)
    except Order.DoesNotExist:
        return Response(
            {"error": "Order not found for this transaction."},
            status=status.HTTP_404_NOT_FOUND,
        )

    # Prevent duplicate verification
    if order.payment_status == "paid":
        return Response({
            "message": "Payment already verified.",
            "order": OrderSerializer(order).data,
            "already_processed": True
        })

    try:
        # Verify payment with amount check
        payment_data = chapa_service.verify_payment(tx_ref, expected_amount=order.total_amount)

        if payment_data.get("status") == "success":
            with transaction.atomic():
                order.payment_status = "paid"
                order.status = Order.Status.COMPLETED
                order.save(update_fields=["payment_status", "status"])

                # Create notification for order owner
                if order.user:
                    _create_order_notification(order.user, order.artifact.name, order.pk)

            logger.info(f"Payment verified successfully for order #{order.pk}")
            return Response({
                "message": "Payment verified successfully!",
                "order": OrderSerializer(order).data,
                "payment_data": {
                    "amount": payment_data.get("amount"),
                    "currency": payment_data.get("currency"),
                    "reference": payment_data.get("reference"),
                }
            })
        else:
            with transaction.atomic():
                order.payment_status = "failed"
                order.save(update_fields=["payment_status"])
            
            return Response(
                {"error": "Payment was not successful. Please try again or contact support.", 
                 "order": OrderSerializer(order).data},
                status=status.HTTP_402_PAYMENT_REQUIRED,
            )
    except Exception as e:
        logger.error(f"Payment verification error for {tx_ref}: {e}")
        return Response(
            {"error": str(e)},
            status=status.HTTP_503_SERVICE_UNAVAILABLE,
        )


@api_view(["POST"])
@csrf_exempt
@permission_classes([AllowAny])
def chapa_webhook(request):
    """
    Webhook endpoint for Chapa to send payment confirmations.
    POST /api/chapa-webhook/
    
    This endpoint is called by Chapa asynchronously when payment is completed.
    """
    # Verify webhook signature for security
    if not chapa_service.verify_webhook_signature(request):
        return Response(
            {"error": "Invalid signature"},
            status=status.HTTP_401_UNAUTHORIZED
        )
    
    data = request.data
    tx_ref = data.get("tx_ref", "")
    event_type = data.get("event_type", "")
    status = data.get("status", "")
    
    logger.info(f"[Webhook] Received event: {event_type} for tx_ref: {tx_ref}")
    
    # Only process payment completion events
    if event_type != "payment.completed" or status != "success":
        return Response({"status": "ignored", "message": "Event not processed"})
    
    try:
        with transaction.atomic():
            order = Order.objects.select_for_update().get(tx_ref=tx_ref)
            
            # Prevent duplicate processing
            if order.payment_status == "paid":
                logger.info(f"[Webhook] Payment already processed for order #{order.pk}")
                return Response({"status": "already_processed"})
            
            # Verify amount from webhook
            amount_received = Decimal(str(data.get("amount", 0)))
            if amount_received != order.total_amount:
                logger.error(f"[Webhook] Amount mismatch for {tx_ref}: expected {order.total_amount}, got {amount_received}")
                order.payment_status = "failed"
                order.save(update_fields=["payment_status"])
                return Response(
                    {"error": "Amount mismatch"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Update order status
            order.payment_status = "paid"
            order.status = Order.Status.COMPLETED
            order.save(update_fields=["payment_status", "status"])
            
            # Create notification
            if order.user:
                _create_order_notification(order.user, order.artifact.name, order.pk)
            
            logger.info(f"[Webhook] Payment confirmed for order #{order.pk}")
            
            return Response({"status": "success", "order_id": order.pk})
            
    except Order.DoesNotExist:
        logger.warning(f"[Webhook] Order not found for tx_ref: {tx_ref}")
        return Response(
            {"error": "Order not found"},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"[Webhook] Error processing webhook: {e}")
        return Response(
            {"error": "Internal server error"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["GET"])
def payment_status(request, tx_ref):
    """
    GET /api/payment-status/{tx_ref}/
    
    Check payment status for a transaction.
    Optional query param: ?email=<guest_email> for authorization
    """
    try:
        order = Order.objects.get(tx_ref=tx_ref)
    except Order.DoesNotExist:
        return Response(
            {"error": "Transaction not found"},
            status=status.HTTP_404_NOT_FOUND
        )
    
    # Authorization check
    if request.user and request.user.is_authenticated:
        if order.user != request.user:
            return Response(
                {"error": "You don't have permission to view this transaction."},
                status=status.HTTP_403_FORBIDDEN
            )
    else:
        email = request.query_params.get("email", "").strip()
        if not email or order.user_email.lower() != email.lower():
            return Response(
                {"error": "Email is required to view this transaction."},
                status=status.HTTP_403_FORBIDDEN
            )
    
    return Response({
        "order_id": order.pk,
        "tx_ref": order.tx_ref,
        "payment_status": order.payment_status,
        "order_status": order.status,
        "total_amount": order.total_amount,
        "artifact_name": order.artifact.name,
        "created_at": order.created_at,
    })