import re
import logging

from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status

from .models import Order
from .serializers import OrderSerializer
from . import chapa_service

logger = logging.getLogger(__name__)

_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def _is_valid_email(email: str) -> bool:
    return bool(_EMAIL_RE.match(email))


@api_view(["GET"])
def order_list(request):
    """
    GET /api/orders/?email=<guest_email>

    Returns all orders placed by the given email address.
    Email is case-insensitive.
    """
    email = request.query_params.get("email", "").strip()

    if not email:
        return Response(
            {"error": "Query param 'email' is required."},
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


@api_view(["POST"])
def create_order(request):
    """
    POST /api/order/
    Body: { "artifact": <id>, "user_email": "...", "quantity": <int> }

    Creates a new order, calculates the total, and initiates Chapa payment.
    Returns the order data including checkout_url for the frontend to redirect.
    """
    serializer = OrderSerializer(data=request.data)
    if serializer.is_valid():
        order = serializer.save()
        order.calculate_total()
        order.save(update_fields=["total_amount"])

        # Initiate Chapa payment
        try:
            checkout_url, tx_ref = chapa_service.initialize_payment(order)
            order.refresh_from_db()
        except Exception as e:
            logger.warning(f"Payment init failed for order #{order.pk}: {e}")
            # Order is still created, just without immediate payment

        return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)
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

    if order.payment_status == "paid":
        return Response({"message": "Payment already verified.", "order": OrderSerializer(order).data})

    try:
        result = chapa_service.verify_payment(tx_ref)
        payment_data = result.get("data", {})

        if payment_data.get("status") == "success":
            order.payment_status = "paid"
            order.status = "Completed"
            order.save(update_fields=["payment_status", "status"])
            return Response({
                "message": "Payment verified successfully!",
                "order": OrderSerializer(order).data,
            })
        else:
            order.payment_status = "failed"
            order.save(update_fields=["payment_status"])
            return Response(
                {"error": "Payment was not successful.", "order": OrderSerializer(order).data},
                status=status.HTTP_402_PAYMENT_REQUIRED,
            )
    except Exception as e:
        return Response(
            {"error": str(e)},
            status=status.HTTP_503_SERVICE_UNAVAILABLE,
        )
