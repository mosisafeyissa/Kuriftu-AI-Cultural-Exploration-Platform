"""
Chapa Payment Service for artifact orders.
Handles payment initiation and verification via Chapa API.
"""
import uuid
import logging
import requests
from django.conf import settings

logger = logging.getLogger(__name__)

CHAPA_BASE_URL = "https://api.chapa.co/v1"


def get_chapa_headers():
    """Return authorization headers for Chapa API."""
    secret_key = getattr(settings, "CHAPA_SECRET_KEY", "")
    return {
        "Authorization": f"Bearer {secret_key}",
        "Content-Type": "application/json",
    }


def generate_tx_ref():
    """Generate a unique transaction reference."""
    return f"kuriftu-order-{uuid.uuid4().hex[:12]}"


def initialize_payment(order):
    """
    Initialize a Chapa payment for the given order.
    Returns (checkout_url, tx_ref) on success, raises Exception on failure.
    """
    tx_ref = generate_tx_ref()
    total = float(order.calculate_total())

    payload = {
        "amount": str(total),
        "currency": "ETB",
        "email": order.user_email,
        "tx_ref": tx_ref,
        "callback_url": "",  # Backend webhook callback (optional)
        "return_url": "",    # Frontend return after payment
        "customization[title]": "Kuriftu Artifact Purchase",
        "customization[description]": f"Order #{order.pk} - {order.artifact.name} x{order.quantity}",
    }

    # Check if we are in mock/demo mode (no real Chapa key)
    mock_mode = getattr(settings, "CHAPA_MOCK_MODE", True)
    if mock_mode or not getattr(settings, "CHAPA_SECRET_KEY", ""):
        # Return a mock checkout URL for demo/hackathon purposes
        order.tx_ref = tx_ref
        order.checkout_url = f"https://checkout.chapa.co/checkout/mock/{tx_ref}"
        order.payment_status = "pending"
        order.save(update_fields=["tx_ref", "checkout_url", "payment_status"])
        logger.info(f"[Chapa Mock] Payment initialized for order #{order.pk}, tx_ref={tx_ref}")
        return order.checkout_url, tx_ref

    try:
        response = requests.post(
            f"{CHAPA_BASE_URL}/transaction/initialize",
            json=payload,
            headers=get_chapa_headers(),
            timeout=15,
        )
        data = response.json()

        if response.status_code == 200 and data.get("status") == "success":
            checkout_url = data["data"]["checkout_url"]
            order.tx_ref = tx_ref
            order.checkout_url = checkout_url
            order.payment_status = "pending"
            order.save(update_fields=["tx_ref", "checkout_url", "payment_status"])
            logger.info(f"[Chapa] Payment initialized for order #{order.pk}")
            return checkout_url, tx_ref
        else:
            error_msg = data.get("message", "Payment initialization failed")
            logger.error(f"[Chapa] Init failed: {error_msg}")
            raise Exception(error_msg)

    except requests.RequestException as e:
        logger.error(f"[Chapa] Network error: {e}")
        raise Exception("Payment service unavailable. Please try again.")


def verify_payment(tx_ref):
    """
    Verify a payment by transaction reference.
    Returns the payment data dict on success.
    """
    mock_mode = getattr(settings, "CHAPA_MOCK_MODE", True)
    if mock_mode or not getattr(settings, "CHAPA_SECRET_KEY", ""):
        # Simulate successful payment for demo
        logger.info(f"[Chapa Mock] Verifying tx_ref={tx_ref} => success")
        return {
            "status": "success",
            "data": {
                "tx_ref": tx_ref,
                "status": "success",
                "amount": "0",
                "currency": "ETB",
            },
        }

    try:
        response = requests.get(
            f"{CHAPA_BASE_URL}/transaction/verify/{tx_ref}",
            headers=get_chapa_headers(),
            timeout=15,
        )
        data = response.json()

        if response.status_code == 200 and data.get("status") == "success":
            return data
        else:
            error_msg = data.get("message", "Verification failed")
            logger.warning(f"[Chapa] Verify failed for {tx_ref}: {error_msg}")
            raise Exception(error_msg)

    except requests.RequestException as e:
        logger.error(f"[Chapa] Network error during verify: {e}")
        raise Exception("Could not verify payment. Please try again.")
