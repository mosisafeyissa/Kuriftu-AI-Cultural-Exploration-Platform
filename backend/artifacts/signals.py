"""
Django signals for the artifacts app.

Auto-generates MobileNetV2 embeddings whenever an Artifact with an image is saved.
"""
import logging
from django.db.models.signals import post_save
from django.dispatch import receiver

logger = logging.getLogger(__name__)


@receiver(post_save, sender="artifacts.Artifact")
def generate_artifact_embedding(sender, instance, **kwargs):
    # NO-OP: MobileNetV2 embeddings are deprecated in favor of Gemini Vision.
    return

    try:
        from ai_services.embedding_service import generate_embedding

        logger.info("Generating embedding for artifact: %s (id=%d)", instance.name, instance.pk)

        image_path = instance.image.path
        embedding = generate_embedding(image_path)

        # Use update() to avoid re-triggering this signal
        from artifacts.models import Artifact
        Artifact.objects.filter(pk=instance.pk).update(embedding=embedding)

        logger.info("Embedding saved for artifact: %s", instance.name)
    except Exception:
        logger.exception("Failed to generate embedding for artifact: %s", instance.name)
