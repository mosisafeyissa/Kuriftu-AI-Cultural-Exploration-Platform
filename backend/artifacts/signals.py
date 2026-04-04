from django.db.models.signals import post_delete
from django.dispatch import receiver
from .models import Artifact, Villa, Country
import cloudinary.uploader

@receiver(post_delete, sender=Artifact)
def delete_artifact_image(sender, instance, **kwargs):
    if instance.image:
        # instance.image.name contains the public_id/path in Cloudinary
        try:
            cloudinary.uploader.destroy(instance.image.name)
        except Exception:
            pass

@receiver(post_delete, sender=Villa)
def delete_villa_image(sender, instance, **kwargs):
    if instance.image:
        try:
            cloudinary.uploader.destroy(instance.image.name)
        except Exception:
            pass

@receiver(post_delete, sender=Country)
def delete_country_image(sender, instance, **kwargs):
    if instance.image:
        try:
            cloudinary.uploader.destroy(instance.image.name)
        except Exception:
            pass
