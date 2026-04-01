"""
Management command to backfill embeddings for all artifacts with images.

Usage:
    python manage.py generate_embeddings
    python manage.py generate_embeddings --force   # re-generate even if exists
"""
from django.core.management.base import BaseCommand
from artifacts.models import Artifact


class Command(BaseCommand):
    help = "Generate MobileNetV2 embeddings for all artifacts with images."

    def add_arguments(self, parser):
        parser.add_argument(
            "--force",
            action="store_true",
            help="Re-generate embeddings even if they already exist.",
        )

    def handle(self, *args, **options):
        from ai_services.embedding_service import generate_embedding

        force = options["force"]

        if force:
            queryset = Artifact.objects.exclude(image="").exclude(image__isnull=True)
        else:
            queryset = Artifact.objects.filter(
                embedding__isnull=True
            ).exclude(image="").exclude(image__isnull=True)

        total = queryset.count()
        if total == 0:
            self.stdout.write(self.style.SUCCESS("No artifacts need embedding generation."))
            return

        self.stdout.write(f"Generating embeddings for {total} artifact(s)...")

        success = 0
        errors = 0

        for artifact in queryset.iterator():
            try:
                embedding = generate_embedding(artifact.image.path)
                Artifact.objects.filter(pk=artifact.pk).update(embedding=embedding)
                self.stdout.write(f"  ✓ {artifact.name}")
                success += 1
            except Exception as e:
                self.stderr.write(f"  ✗ {artifact.name}: {e}")
                errors += 1

        self.stdout.write(
            self.style.SUCCESS(f"\nDone! {success} succeeded, {errors} failed.")
        )
