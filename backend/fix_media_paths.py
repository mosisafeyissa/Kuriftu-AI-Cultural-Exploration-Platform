import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from artifacts.models import Artifact, Villa
from django.conf import settings

def fix_paths():
    media_root = settings.MEDIA_ROOT
    
    print("Fixing Artifact paths...")
    for artifact in Artifact.objects.all():
        if artifact.image and str(artifact.image).startswith('assets/images/'):
            filename = os.path.basename(str(artifact.image))
            new_path = f"villas/{filename}"
            
            # Check if file exists in villas/
            full_new_path = os.path.join(media_root, 'villas', filename)
            if os.path.exists(full_new_path):
                print(f"  Artifact {artifact.id}: {artifact.image} -> {new_path}")
                artifact.image = new_path
                artifact.save()
            else:
                # Check if it exists in scans/
                full_scan_path = os.path.join(media_root, 'scans', filename)
                if os.path.exists(full_scan_path):
                    new_scan_path = f"scans/{filename}"
                    print(f"  Artifact {artifact.id}: {artifact.image} -> {new_scan_path} (found in scans)")
                    artifact.image = new_scan_path
                    artifact.save()
                else:
                    print(f"  Warning: File {filename} not found in villas/ or scans/ for Artifact {artifact.id}")

    print("\nFixing Villa paths...")
    for villa in Villa.objects.all():
        if villa.image and str(villa.image).startswith('assets/images/'):
            filename = os.path.basename(str(villa.image))
            new_path = f"villas/{filename}"
            
            full_new_path = os.path.join(media_root, 'villas', filename)
            if os.path.exists(full_new_path):
                print(f"  Villa {villa.id}: {villa.image} -> {new_path}")
                villa.image = new_path
                villa.save()
            else:
                 print(f"  Warning: File {filename} not found in villas/ for Villa {villa.id}")

if __name__ == "__main__":
    fix_paths()
