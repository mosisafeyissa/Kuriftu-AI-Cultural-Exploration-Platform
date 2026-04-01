"""
MobileNetV2-based image embedding service for artifact matching.

Provides:
    generate_embedding(image_input) → list[float]  (1280-dim feature vector)
    compute_similarity(a, b)        → float         (cosine similarity)
    find_best_match(embedding)      → (artifact, similarity)
"""
import io
import logging

import numpy as np
from PIL import Image

logger = logging.getLogger(__name__)

# ── MobileNetV2 Model (lazy-loaded singleton) ────────────────────────────────

_MODEL = None


def _get_model():
    """Lazy-load MobileNetV2 without the classification head (feature extractor)."""
    global _MODEL
    if _MODEL is None:
        logger.info("Loading MobileNetV2 model (one-time)…")
        from tensorflow.keras.applications import MobileNetV2  # noqa: E402

        _MODEL = MobileNetV2(
            weights="imagenet",
            include_top=False,       # Remove classification layer
            pooling="avg",           # Global average pooling → 1280-dim vector
            input_shape=(224, 224, 3),
        )
        logger.info("MobileNetV2 loaded successfully.")
    return _MODEL


# ── Image Preprocessing ─────────────────────────────────────────────────────

def _preprocess_image(image_bytes: bytes) -> np.ndarray:
    """
    Convert raw image bytes into a preprocessed tensor for MobileNetV2.

    Steps:
        1. Open image with PIL (handles JPEG, PNG, WebP, etc.)
        2. Convert to RGB (drop alpha channel if present)
        3. Resize to 224×224
        4. Convert to float32 numpy array
        5. Apply MobileNetV2 preprocessing (scale to [-1, 1])

    Returns:
        np.ndarray of shape (1, 224, 224, 3)
    """
    from tensorflow.keras.applications.mobilenet_v2 import preprocess_input

    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img = img.resize((224, 224), Image.LANCZOS)

    arr = np.array(img, dtype=np.float32)  # shape: (224, 224, 3)
    arr = np.expand_dims(arr, axis=0)      # shape: (1, 224, 224, 3)
    arr = preprocess_input(arr)            # scale to [-1, 1]

    return arr


# ── Public API ───────────────────────────────────────────────────────────────

def generate_embedding(image_input) -> list[float]:
    """
    Generate a 1280-dimensional feature vector from an image.

    Args:
        image_input: One of:
            - Django UploadedFile (has .read() and .seek())
            - bytes
            - str file path

    Returns:
        list[float] — 1280-element feature vector.
    """
    # Read image bytes from various input types
    if isinstance(image_input, bytes):
        image_bytes = image_input
    elif isinstance(image_input, str):
        with open(image_input, "rb") as f:
            image_bytes = f.read()
    else:
        # Django UploadedFile
        image_input.seek(0)
        image_bytes = image_input.read()

    try:
        model = _get_model()
        tensor = _preprocess_image(image_bytes)
        features = model.predict(tensor, verbose=0)  # shape: (1, 1280)
        embedding = features[0].tolist()              # list of 1280 floats

        logger.info("Generated embedding (%d dimensions)", len(embedding))
        return embedding

    except Exception:
        logger.exception("Failed to generate MobileNetV2 embedding")
        return []


def compute_similarity(embedding_a: list[float], embedding_b: list[float]) -> float:
    """
    Compute cosine similarity between two embedding vectors.

    Returns a value between -1.0 and 1.0 (higher = more similar).
    Typical range for image embeddings: 0.0 to 1.0.
    """
    if not embedding_a or not embedding_b:
        return 0.0

    from sklearn.metrics.pairwise import cosine_similarity

    a = np.array(embedding_a).reshape(1, -1)
    b = np.array(embedding_b).reshape(1, -1)

    similarity = cosine_similarity(a, b)[0][0]
    return float(similarity)


def find_best_match(scan_embedding: list[float], threshold: float = 0.75):
    """
    Compare scan embedding against all artifact embeddings in the DB.

    Uses cosine similarity to find the closest match.

    Args:
        scan_embedding: 1280-dim feature vector from the scanned image.
        threshold: Minimum cosine similarity to consider a match (default 0.75).

    Returns:
        (artifact, similarity) if a match is found above threshold.
        (None, best_similarity) if no match above threshold.
    """
    from artifacts.models import Artifact

    artifacts = Artifact.objects.select_related(
        "country", "villa", "story"
    ).exclude(embedding__isnull=True)

    if not artifacts.exists():
        logger.warning("No artifacts with embeddings found in DB.")
        return None, 0.0

    best_artifact = None
    best_similarity = -1.0

    for artifact in artifacts:
        # Skip artifacts with empty or invalid embeddings
        if not artifact.embedding or not isinstance(artifact.embedding, list):
            continue

        sim = compute_similarity(scan_embedding, artifact.embedding)
        if sim > best_similarity:
            best_similarity = sim
            best_artifact = artifact

    logger.info(
        "Best match: %s (similarity=%.4f, threshold=%.2f)",
        best_artifact.name if best_artifact else "None",
        best_similarity,
        threshold,
    )

    if best_similarity >= threshold:
        return best_artifact, best_similarity
    return None, best_similarity
