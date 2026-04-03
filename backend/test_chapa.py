import os, django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from artifacts.models import Artifact
from orders.models import Order
from orders.chapa_service import initialize_payment
from django.contrib.auth import get_user_model

try:
    User = get_user_model()
    admin = User.objects.first()
    email = admin.email if admin else "test@example.com"
    artifact = Artifact.objects.first()
    if not artifact:
        print("No artifacts found to test with.")
        exit(1)
        
    order = Order.objects.create(
        user=admin,
        artifact=artifact,
        user_email=email,
        quantity=1,
    )
    checkout_url, tx_ref = initialize_payment(order)
    print(f"SUCCESS: {checkout_url}")
except Exception as e:
    print(f"ERROR: {e}")
