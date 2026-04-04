"""
Chapa Payment Service for artifact orders.
Handles payment initiation and verification via Chapa API.
"""
import uuid
import logging
import time
import hmac
import hashlib
from decimal import Decimal
import requests
from django.conf import settings
from django.core.cache import cache

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
    
    # Get base URLs from settings
    base_url = getattr(settings, "SITE_URL", "http://localhost:8000")
    frontend_url = getattr(settings, "FRONTEND_URL", "http://localhost:33225")
    
    callback_url = getattr(settings, "CHAPA_CALLBACK_URL", f"{base_url}/api/chapa-webhook/")
    return_url = getattr(settings, "CHAPA_RETURN_URL", f"{frontend_url}/payment-status/{tx_ref}")

    payload = {
        "amount": str(total),
        "currency": "ETB",
        "email": order.user_email,
        "tx_ref": tx_ref,
        "callback_url": callback_url,
        "return_url": return_url,
        "customization[title]": "Kuriftu Artifact Purchase",
        "customization[description]": f"Order #{order.pk} - {order.artifact.name} x{order.quantity}",
        "customization[logo]": getattr(settings, "CHAPA_LOGO_URL", ""),
        "meta[order_id]": str(order.pk),
        "meta[user_email]": order.user_email,
    }

    secret_key = getattr(settings, "CHAPA_SECRET_KEY", "")
    if not secret_key:
        logger.error("[Chapa] Missing CHAPA_SECRET_KEY")
        raise Exception("Payment gateway is not configured properly.")

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
            
            # Store payment reference in cache for quick lookup (expires in 1 hour)
            cache.set(f"payment_{tx_ref}", order.pk, timeout=3600)
            
            order.tx_ref = tx_ref
            order.checkout_url = checkout_url
            order.payment_status = "pending"
            order.save(update_fields=["tx_ref", "checkout_url", "payment_status"])
            logger.info(f"[Chapa] Payment initialized for order #{order.pk}, tx_ref: {tx_ref}")
            return checkout_url, tx_ref
        else:
            error_msg = data.get("message", "Payment initialization failed")
            logger.error(f"[Chapa] Init failed: {error_msg}")
            raise Exception(error_msg)

    except requests.RequestException as e:
        logger.error(f"[Chapa] Network error: {e}")
        raise Exception("Payment service unavailable. Please try again.")


def verify_payment(tx_ref, expected_amount=None):
    """
    Verify a payment by transaction reference.
    Returns the payment data dict on success.
    Includes retry logic for network issues.
    """
    secret_key = getattr(settings, "CHAPA_SECRET_KEY", "")
    if not secret_key:
        logger.error("[Chapa] Missing CHAPA_SECRET_KEY")
        raise Exception("Payment gateway is not configured properly.")

    max_retries = 3
    retry_delay = 1  # seconds

    for attempt in range(max_retries):
        try:
            response = requests.get(
                f"{CHAPA_BASE_URL}/transaction/verify/{tx_ref}",
                headers=get_chapa_headers(),
                timeout=15,
            )
            data = response.json()

            if response.status_code == 200 and data.get("status") == "success":
                payment_data = data.get("data", {})
                
                # Verify amount if expected_amount is provided
                if expected_amount is not None:
                    actual_amount = Decimal(str(payment_data.get("amount", 0)))
                    expected_decimal = Decimal(str(expected_amount))
                    
                    if actual_amount != expected_decimal:
                        logger.error(f"[Chapa] Amount mismatch for {tx_ref}: expected {expected_amount}, got {actual_amount}")
                        raise Exception(f"Payment amount mismatch: expected {expected_amount}, got {actual_amount}")
                
                logger.info(f"[Chapa] Payment verified successfully for {tx_ref}")
                return payment_data
            else:
                error_msg = data.get("message", "Verification failed")
                logger.warning(f"[Chapa] Verify failed for {tx_ref} (attempt {attempt + 1}): {error_msg}")
                
                if attempt == max_retries - 1:
                    raise Exception(error_msg)
                time.sleep(retry_delay * (2 ** attempt))  # Exponential backoff

        except requests.RequestException as e:
            logger.error(f"[Chapa] Network error during verify (attempt {attempt + 1}): {e}")
            if attempt == max_retries - 1:
                raise Exception("Could not verify payment. Please try again.")
            time.sleep(retry_delay * (2 ** attempt))

    raise Exception("Payment verification failed after multiple attempts.")


def verify_webhook_signature(request):
    """
    Verify the webhook signature from Chapa for security.
    Returns True if signature is valid, False otherwise.
    """
    signature = request.headers.get("Chapa-Signature", "")
    if not signature:
        logger.warning("[Chapa] No signature provided in webhook")
        return False
    
    secret_key = getattr(settings, "CHAPA_SECRET_KEY", "")
    if not secret_key:
        logger.error("[Chapa] Missing CHAPA_SECRET_KEY for signature verification")
        return False
    
    # Get the raw body
    raw_body = request.body
    
    # Compute HMAC SHA256
    expected_signature = hmac.new(
        secret_key.encode('utf-8'),
        raw_body,
        hashlib.sha256
    ).hexdigest()
    
    is_valid = hmac.compare_digest(signature, expected_signature)
    if not is_valid:
        logger.warning("[Chapa] Invalid webhook signature")
    
    return is_valid