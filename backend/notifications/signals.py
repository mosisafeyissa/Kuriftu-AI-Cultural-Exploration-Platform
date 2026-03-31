import logging
from django.db.models.signals import post_save
from django.dispatch import receiver
from orders.models import Order
from artifacts.models import Artifact
from notifications.models import Notification
from django.conf import settings

try:
    from google import genai
    from google.genai import types
except ImportError:
    genai = None

logger = logging.getLogger(__name__)

@receiver(post_save, sender=Order)
def generate_recommendation_notification(sender, instance, created, **kwargs):
    if not created:
        return
        
    try:
        ordered_artifact = instance.artifact
        country = ordered_artifact.country
        
        # Find another artifact from the same country
        recommended_artifact = Artifact.objects.filter(country=country).exclude(id=ordered_artifact.id).order_by('?').first()
        
        if not recommended_artifact:
            # If no other artifacts from this country, pick any other artifact
            recommended_artifact = Artifact.objects.exclude(id=ordered_artifact.id).order_by('?').first()
            
        if not recommended_artifact:
            return  # No other artifacts available in db
            
        message = f"Thank you for purchasing the {ordered_artifact.name}! Since you enjoy art from {country.name}, we strongly recommend you explore the beautiful {recommended_artifact.name}."
        
        # Try to use Gemini to make it dynamic
        api_key = getattr(settings, "API_KEY", None)
        if genai and api_key:
            client = genai.Client(api_key=api_key)
            prompt = (
                f"A user just bought an artifact named '{ordered_artifact.name}' from {country.name}. "
                f"Write a very short, engaging, 1-2 sentence recommendation notification telling them to "
                f"check out the '{recommended_artifact.name}' next."
            )
            try:
                response = client.models.generate_content(
                    model="gemini-2.0-flash",
                    contents=prompt,
                    config=types.GenerateContentConfig(temperature=0.7, max_output_tokens=100),
                )
                if response and response.text:
                    message = response.text.strip()
            except Exception as e:
                logger.error(f"GenAI recommendation error: {e}")
        
        Notification.objects.create(
            user_email=instance.user_email,
            title="New Inspiration Awaits",
            message=message
        )
    except Exception as e:
        logger.error(f"Signal failed: {e}")
