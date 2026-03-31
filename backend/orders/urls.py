from django.urls import path
from . import views

urlpatterns = [
    path("orders/", views.order_list, name="order-list"),   # GET ?email=
    path("order/", views.create_order, name="create-order"), # POST
]
