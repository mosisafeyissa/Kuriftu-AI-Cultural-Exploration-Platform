"""
Utility helpers for the ai_services app.
"""
import json
import logging
import re

logger = logging.getLogger(__name__)


def parse_json_response(text: str) -> dict | None:
    """
    Extract and parse a JSON object from an AI response string.

    Gemini sometimes wraps JSON in markdown code fences or adds extra text.
    This function handles all common formats:
      - Pure JSON
      - ```json ... ```
      - Text before/after the JSON block
    """
    if not text:
        return None

    # 1. Try direct parse first (fastest path)
    try:
        return json.loads(text.strip())
    except json.JSONDecodeError:
        pass

    # 2. Try extracting from markdown code fences: ```json { ... } ```
    fence_match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.DOTALL)
    if fence_match:
        try:
            return json.loads(fence_match.group(1))
        except json.JSONDecodeError:
            pass

    # 3. Try finding the first { ... } block in the text
    brace_match = re.search(r"\{.*\}", text, re.DOTALL)
    if brace_match:
        try:
            return json.loads(brace_match.group(0))
        except json.JSONDecodeError:
            pass

    logger.warning("Could not parse JSON from AI response: %s", text[:200])
    return None


def validate_identification(data: dict) -> dict:
    """
    Validate and normalise the identification result from the AI.
    Returns a clean dict with guaranteed keys.
    """
    return {
        "artifact_name": str(data.get("artifact_name", "Unknown Artifact")).strip(),
        "country": str(data.get("country", "Unknown")).strip(),
        "category": str(data.get("category", "Other")).strip(),
        "confidence": _clamp(float(data.get("confidence", 0.0)), 0.0, 1.0),
        "materials": data.get("materials", []),
    }


def validate_story(data: dict) -> dict:
    """
    Validate and normalise the story result from the AI.
    Returns a clean dict with guaranteed keys.
    """
    return {
        "title": str(data.get("title", "")).strip(),
        "story": str(data.get("story", "")).strip(),
        "materials": str(data.get("materials", "")).strip(),
        "cultural_significance": str(data.get("cultural_significance", "")).strip(),
        "fun_fact": str(data.get("fun_fact", "")).strip(),
    }


def _clamp(value: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, value))
