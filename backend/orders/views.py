import re

from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status

from .models import Order
from .serializers import OrderSerializer

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

    Creates a new order with status Pending.
    Returns 201 on success, 400 on validation error.
    """
    serializer = OrderSerializer(data=request.data)
    if serializer.is_valid():
        order = serializer.save()
        return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
