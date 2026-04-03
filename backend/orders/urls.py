from django.urls import path
from . import views

app_name = 'orders'

urlpatterns = [
    # Order management
    path('orders/', views.order_list, name='order-list'),
    path('orders/<int:order_id>/', views.order_detail, name='order-detail'),
    path('order/', views.create_order, name='create-order'),
    
    # Payment endpoints
    path('verify-payment/', views.verify_payment, name='verify-payment'),
    path('chapa-webhook/', views.chapa_webhook, name='chapa-webhook'),
    path('payment-status/<str:tx_ref>/', views.payment_status, name='payment-status'),
]