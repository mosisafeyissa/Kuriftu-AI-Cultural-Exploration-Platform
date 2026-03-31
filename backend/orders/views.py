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
    GET /api/orders/

    Returns all orders placed by the current authenticated user (based on X-User-Email).
    """
    email = getattr(request, 'user_email', None)

    if not email:
        return Response(
            {"error": "Authentication required. Missing X-User-Email header."},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    orders = Order.objects.filter(user_email=email).select_related(
        "artifact", "artifact__country"
    )
    serializer = OrderSerializer(orders, many=True)
    return Response(serializer.data)


import logging

logger = logging.getLogger(__name__)

@api_view(["POST"])
def create_order(request):
    """
    POST /api/order/
    Body: { "artifact": <id>, "user_email": "...", "quantity": <int> }
    """
    if not request.data:
        return Response({"error": "Empty request body"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        serializer = OrderSerializer(data=request.data)
        if serializer.is_valid():
            order = serializer.save()
            return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)
        else:
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        print("ORDER ERROR:", str(e))
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
