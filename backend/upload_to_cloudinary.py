import os
import django
from pathlib import Path
import cloudinary.uploader
from django.conf import settings

from dotenv import load_dotenv

backend_dir = Path(__file__).resolve().parent
load_dotenv(backend_dir / ".env")

import re

# FORCING environment variable for the library to pick up
cloudinary_url_str = os.getenv('CLOUDINARY_URL')
if cloudinary_url_str:
    match = re.match(r"cloudinary://([^:]+):([^@]+)@(.+)", cloudinary_url_str)
    if match:
        api_key, api_secret, cloud_name = match.groups()
        import cloudinary
        cloudinary.config(
            cloud_name=cloud_name,
            api_key=api_key,
            api_secret=api_secret,
            secure=True
        )

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

import cloudinary.uploader

def upload_local_media():
    media_root = Path(settings.BASE_DIR) / "media"
    
    if not media_root.exists():
        print(f"Media directory not found at {media_root}")
        return

    print(f"Starting upload from {media_root} to Cloudinary...")

    # Iterate through all files in media directory
    for root, dirs, files in os.walk(media_root):
        for file in files:
            local_path = Path(root) / file
            # Relative path to media_root (e.g., 'villas/image.jpg')
            try:
                relative_path = local_path.relative_to(media_root)
            except ValueError:
                continue
            
            # The 'public_id' in Cloudinary should match the relative path
            # We want to keep folder structure
            folder = str(relative_path.parent)
            if folder == ".":
                folder = ""
            
            public_id = relative_path.stem
            
            print(f"Uploading {relative_path} (Folder: '{folder}', ID: '{public_id}')...")
            try:
                result = cloudinary.uploader.upload(
                    str(local_path),
                    public_id=public_id,
                    folder=folder,
                    overwrite=True,
                    resource_type="auto"
                )
                print(f"  Successfully uploaded! URL: {result.get('secure_url')}")
            except Exception as e:
                print(f"  Failed to upload {relative_path}: {str(e)}")

if __name__ == "__main__":
    upload_local_media()
    print("Migration complete!")
