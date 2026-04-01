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
    """
    After saving an Artifact, generate its embedding if:
      - It has an image file
      - The embedding is missing or the image was just changed

    Uses update() to avoid re-triggering the signal.
    """
    if not instance.image:
        return

    if instance.embedding:
        # Embedding already exists — skip unless image changed.
        # (We can't easily detect image changes without tracking,
        #  so we only generate if embedding is empty.)
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
