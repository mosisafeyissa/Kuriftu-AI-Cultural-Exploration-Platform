"""
Management command to generate and display QR codes for all villas.

Usage:
    python manage.py generate_qr_codes          # Print QR code UUIDs for all villas
    python manage.py generate_qr_codes --images  # Generate QR code PNG images in media/qr_codes/
"""
import os
from django.core.management.base import BaseCommand
from django.conf import settings
from artifacts.models import Villa


class Command(BaseCommand):
    help = "Generate and display QR codes for all villas"

    def add_arguments(self, parser):
        parser.add_argument(
            "--images",
            action="store_true",
            help="Generate QR code PNG images in media/qr_codes/",
        )

    def handle(self, *args, **options):
        villas = Villa.objects.select_related("country").all()

        if not villas.exists():
            self.stdout.write(self.style.WARNING("No villas found. Run seed_data first."))
            return

        self.stdout.write(self.style.SUCCESS(f"\n{'='*70}"))
        self.stdout.write(self.style.SUCCESS("  KURIFTU VILLA QR CODES"))
        self.stdout.write(self.style.SUCCESS(f"{'='*70}\n"))

        for villa in villas:
            self.stdout.write(f"  Villa:    {self.style.MIGRATE_HEADING(villa.name)}")
            self.stdout.write(f"  Country:  {villa.country.name}")
            self.stdout.write(f"  QR Code:  {self.style.SUCCESS(str(villa.qr_code))}")
            self.stdout.write(f"  QR URL:   /api/villa-guide/{villa.qr_code}/")
            self.stdout.write(f"  {'-'*60}")

        if options["images"]:
            self._generate_images(villas)

        self.stdout.write(self.style.SUCCESS(
            f"\nTotal: {villas.count()} villas\n"
            f"Scan these QR codes in the app to open the guided tour for each villa.\n"
            f"The QR code content should be the UUID value shown above.\n"
        ))

    def _generate_images(self, villas):
        """Generate QR code PNG images using qrcode library."""
        try:
            import qrcode
        except ImportError:
            self.stdout.write(self.style.ERROR(
                "\n  'qrcode' package not installed. Run: pip install qrcode[pil]"
            ))
            return

        output_dir = os.path.join(settings.MEDIA_ROOT, "qr_codes")
        os.makedirs(output_dir, exist_ok=True)

        for villa in villas:
            qr = qrcode.QRCode(version=1, box_size=10, border=4)
            qr.add_data(str(villa.qr_code))
            qr.make(fit=True)

            img = qr.make_image(fill_color="black", back_color="white")
            filename = f"{villa.name.lower().replace(' ', '_')}_{villa.qr_code}.png"
            filepath = os.path.join(output_dir, filename)
            img.save(filepath)

            self.stdout.write(f"  ✅ Saved: {filepath}")

        self.stdout.write(self.style.SUCCESS(f"\n  QR images saved to: {output_dir}"))
