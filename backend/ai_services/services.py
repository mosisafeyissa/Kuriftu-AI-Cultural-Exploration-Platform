"""
AI Services Module
==================
All AI interactions are centralised here.
Swap the body of each function with real Gemini API calls when ready.
"""

import os
import random

# ─── Keyword → (artifact_name, country) mapping for mock identification ───────
_KEYWORD_MAP = {
    "coffee": ("Ethiopian Coffee Ceremony Table", "Ethiopia"),
    "mesob": ("Handwoven Mesob Basket", "Ethiopia"),
    "basket": ("Handwoven Mesob Basket", "Ethiopia"),
    "harari": ("Traditional Harari Chair", "Ethiopia"),
    "zellige": ("Moroccan Zellige Mosaic Table", "Morocco"),
    "mosaic": ("Moroccan Zellige Mosaic Table", "Morocco"),
    "lantern": ("Brass Hanging Lantern", "Morocco"),
    "brass": ("Brass Hanging Lantern", "Morocco"),
    "carpet": ("Berber Handwoven Carpet", "Morocco"),
    "berber": ("Berber Handwoven Carpet", "Morocco"),
    "mask": ("Yoruba Tribal Mask", "Nigeria"),
    "yoruba": ("Yoruba Tribal Mask", "Nigeria"),
    "stool": ("Carved Wooden Stool", "Nigeria"),
    "beaded": ("Beaded Royal Chair", "Nigeria"),
    "royal": ("Beaded Royal Chair", "Nigeria"),
}

_FALLBACK_ARTIFACTS = [
    ("Ethiopian Coffee Ceremony Table", "Ethiopia"),
    ("Handwoven Mesob Basket", "Ethiopia"),
    ("Traditional Harari Chair", "Ethiopia"),
    ("Moroccan Zellige Mosaic Table", "Morocco"),
    ("Brass Hanging Lantern", "Morocco"),
    ("Yoruba Tribal Mask", "Nigeria"),
    ("Carved Wooden Stool", "Nigeria"),
]


def identify_object(image_file) -> dict:
    """
    Identify a cultural artifact from an uploaded image.

    Mock implementation: uses the filename as a keyword hint.
    Production: replace with a Gemini Vision API call.

    Returns:
        {
            "artifact_name": str,
            "country": str,
            "confidence": float,  # 0.0 – 1.0
        }
    """
    filename = getattr(image_file, "name", "").lower()
    stem = os.path.splitext(filename)[0].replace("_", " ").replace("-", " ")

    for keyword, (artifact_name, country) in _KEYWORD_MAP.items():
        if keyword in stem:
            return {
                "artifact_name": artifact_name,
                "country": country,
                "confidence": round(random.uniform(0.88, 0.97), 2),
            }

    # No keyword match → plausible random fallback with lower confidence
    artifact_name, country = random.choice(_FALLBACK_ARTIFACTS)
    return {
        "artifact_name": artifact_name,
        "country": country,
        "confidence": round(random.uniform(0.55, 0.74), 2),
    }


def generate_story(artifact_name: str, country: str) -> dict:
    """
    Generate a cultural story for an artifact not yet in the database.

    Mock implementation: returns a template-based story.
    Production: replace with a Gemini text generation API call.

    Returns:
        {
            "title": str,
            "story": str,
            "materials": str,
            "cultural_significance": str,
        }
    """
    return {
        "title": f"The Story of {artifact_name}",
        "story": (
            f"The {artifact_name} is a remarkable piece of cultural heritage from {country}. "
            "Carefully crafted and passed down through generations, it embodies the artistic "
            "spirit and communal values of its people, standing as a testament to living tradition."
        ),
        "materials": "Locally sourced natural materials, hand-finished by skilled artisans",
        "cultural_significance": (
            f"This artifact holds deep meaning in {country}'s cultural identity, "
            "connecting communities to their ancestral traditions and serving as a bridge "
            "between past wisdom and modern expression."
        ),
    }
