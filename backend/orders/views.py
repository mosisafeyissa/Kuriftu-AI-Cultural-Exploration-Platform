from rest_framework import generics, status
from rest_framework.response import Response

from users.models import Guest

from .models import Order
from .serializers import OrderSerializer


class OrderListCreateView(generics.ListCreateAPIView):
    """
    GET  /api/orders/?email=<email>  → list orders for a guest
    POST /api/orders/                → create a new order
    """

    serializer_class = OrderSerializer

    def get_queryset(self):
        qs = Order.objects.select_related("guest", "artifact").all()
        email = self.request.query_params.get("email")
        if email is not None:
            qs = qs.filter(guest__email=email)
        return qs

    def create(self, request, *args, **kwargs):
        """
        Accept either a guest PK or an email. If email is provided and the
        guest doesn't exist yet, create them on the fly so the frontend
        never has to call a separate registration endpoint.
        """
        email = request.data.get("email")
        guest_id = request.data.get("guest")

        if email and not guest_id:
            guest, _ = Guest.objects.get_or_create(email=email)
            request.data["guest"] = guest.pk  # noqa: WPS110

        return super().create(request, *args, **kwargs)
