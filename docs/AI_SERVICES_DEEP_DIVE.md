# AI Intelligence Layer — Deep Dive Guide

This document is a complete guide for the **AI Engineer** working on the `ai_services` app. It explains every detail about what the AI layer does, which AI provider to use, how the integration works, and answers all the "why" and "how" questions.

---

## Table of Contents
1. [What Does the AI Layer Do?](#1-what-does-the-ai-layer-do)
2. [Which AI Provider Should We Use?](#2-which-ai-provider-should-we-use)
3. [How Object Recognition Works](#3-how-object-recognition-works)
4. [How Story Generation Works](#4-how-story-generation-works)
5. [The Complete Flow (Step-by-Step)](#5-the-complete-flow-step-by-step)
6. [Integration Architecture](#6-integration-architecture)
7. [Prompt Engineering — The Secret Sauce](#7-prompt-engineering--the-secret-sauce)
8. [Caching Strategy — Why We Store Results](#8-caching-strategy--why-we-store-results)
9. [Error Handling](#9-error-handling)
10. [File Structure for ai_services App](#10-file-structure-for-ai_services-app)
11. [API Keys & Security](#11-api-keys--security)
12. [Testing the AI Layer](#12-testing-the-ai-layer)
13. [Cost & Rate Limits](#13-cost--rate-limits)

---

## 1. What Does the AI Layer Do?

The AI layer is the **brain** of the entire system. It has exactly **two jobs**:

### Job 1 — Object Recognition (Vision)

**Input**: A photo taken by the guest's phone camera
**Output**: What the object is + which country it belongs to + how confident the AI is

Example: A guest photographs a carved chair in the hotel lobby.

```
INPUT:  📷 [photo of a chair]

OUTPUT:
{
  "object_name":  "Handcrafted Ethiopian Mesob-Inspired Chair",
  "country":      "Ethiopia",
  "category":     "Furniture",
  "confidence":   0.93,
  "materials":    ["mahogany wood", "cotton weaving"]
}
```

The AI looks at the image and understands:
- **What** the object is (a specific type of cultural chair)
- **Where** it comes from (Ethiopia)
- **What category** it falls into (Furniture, Textile, Painting, Sculpture, etc.)
- **How sure** it is (93% confident)
- **What it's made of** (wood, cotton, etc.)

### Job 2 — Cultural Story Generation

**Input**: The object name + country (from Job 1)
**Output**: A rich, beautiful cultural narrative

```
INPUT:  object_name = "Handcrafted Ethiopian Mesob-Inspired Chair"
        country     = "Ethiopia"

OUTPUT:
{
  "title": "The Mesob Chair: Where Ethiopian Tradition Meets Modern Craft",
  "story": "Deep in the highlands of Ethiopia, where the ancient art of woodcarving 
            has been passed down through generations, artisans continue to create 
            furniture that tells the story of their people. This chair draws its 
            inspiration from the Mesob — the iconic woven basket table that sits 
            at the center of every Ethiopian family gathering...",
  "materials": "Hand-carved Ethiopian mahogany wood with traditional Habesha cotton 
                weaving patterns interlaced into the backrest",
  "cultural_significance": "In Ethiopian culture, the act of sitting together around 
                           a shared Mesob represents unity, family, and the communal 
                           spirit of 'gursha' — the tradition of feeding one another 
                           by hand as an expression of love and respect.",
  "fun_fact": "The weaving pattern on this chair takes a skilled artisan approximately 
              3 weeks to complete by hand."
}
```

**Why two separate jobs?** Because they require different AI capabilities:
- Job 1 needs **vision** (understanding images)
- Job 2 needs **text generation** (writing creative stories)

---

## 2. Which AI Provider Should We Use?

### The Top 3 Options

| Provider | Model | Vision? | Text? | Free Tier? | Best For |
|---|---|---|---|---|---|
| **Google Gemini** ✅ | `gemini-2.0-flash` | ✅ Yes | ✅ Yes | ✅ **60 req/min free** | Hackathons, startups |
| OpenAI | `gpt-4o` | ✅ Yes | ✅ Yes | ❌ Paid only | Production apps |
| Anthropic (Claude) | `claude-3.5-sonnet` | ✅ Yes | ✅ Yes | ❌ Paid only | Complex reasoning |

### ✅ Recommendation: **Google Gemini** — Here's Why

#### Reason 1: Both jobs in one API
Gemini can handle **both** image recognition AND text generation. You don't need two different APIs. One SDK does everything:
- Send an image → Gemini understands it (Job 1)
- Send a text prompt → Gemini writes a story (Job 2)

#### Reason 2: Generous free tier
Google gives you **60 requests per minute** for free with Gemini. For a hackathon demo, this is more than enough. OpenAI charges from the first request.

#### Reason 3: Easy Python SDK
Google provides a clean Python library called `google-generativeai` that works directly with Django:

```python
pip install google-generativeai
```

That's it. No complex setup, no OAuth flows, no cloud console configuration.

#### Reason 4: Excellent multimodal understanding
Gemini was built from the ground up to understand images + text together. It's not an "image feature bolted on" — it natively understands visual content.

### How to Get a Gemini API Key (5 minutes)
1. Go to: https://aistudio.google.com/apikey
2. Click **"Create API Key"**
3. Copy the key
4. Save it in your `.env` file as `GEMINI_API_KEY=your_key_here`

**That's all. No billing setup required for the free tier.**

---

## 3. How Object Recognition Works

### What happens under the hood

When the guest sends a photo, here's exactly what happens:

```
Guest's Phone                    Django Backend                    Google Gemini
     │                                │                                │
     │──── POST /api/scan/ ──────────▶│                                │
     │     (with image file)          │                                │
     │                                │── Send image + prompt ────────▶│
     │                                │   "Identify this African       │
     │                                │    cultural artifact..."       │
     │                                │                                │
     │                                │◀── JSON response ─────────────│
     │                                │   {object, country,            │
     │                                │    confidence, materials}      │
     │                                │                                │
     │◀─── JSON response ────────────│                                │
     │    {object details + story}    │                                │
```

### The Recognition Prompt

This is the **exact prompt** we send to Gemini to identify the object:

```python
prompt = """
You are an expert in African cultural artifacts, furniture, art, and handicrafts.
Analyze this image and identify:

1. object_name: The specific name of this cultural artifact
2. country: The African country this artifact originates from
3. category: One of [Furniture, Textile, Painting, Sculpture, Jewelry, Pottery, Musical Instrument, Other]
4. confidence: Your confidence level from 0.0 to 1.0
5. materials: A list of materials used to make this item

Context: This artifact is displayed at Kuriftu Resort & Spa in Ethiopia. 
The resort showcases handcrafted items from across Africa.

Respond ONLY in this exact JSON format:
{
  "object_name": "...",
  "country": "...",
  "category": "...",
  "confidence": 0.0,
  "materials": ["...", "..."]
}
"""
```

**Key details about this prompt:**
- We tell the AI it's an **expert** (this improves accuracy)
- We give it **context** (it's in a resort, it's African)
- We ask for **structured JSON** (so we can parse it programmatically)
- We include a **confidence score** (so we can warn the user if the AI is unsure)

### How Gemini Vision Actually Works

Gemini doesn't "see" like humans. Here's what it actually does:

1. **Receives the image** as raw bytes (JPEG/PNG)
2. **Converts it into tokens** — the image is broken into a grid of visual tokens that the model can understand
3. **Analyzes patterns** — it compares what it sees against its training data (millions of images of cultural artifacts, furniture, art)
4. **Generates text** — based on its understanding, it produces the JSON response

It's not "searching the internet" — it's using patterns it learned during training.

---

## 4. How Story Generation Works

### The Creative Part

Once we know WHAT the object is (from Job 1), we ask Gemini to **write a cultural story**.

### The Story Generation Prompt

```python
prompt = f"""
You are a master cultural storyteller specializing in African heritage and traditions.

Write a rich, engaging cultural story about this artifact:
- Object: {object_name}
- Country of Origin: {country}
- Materials: {materials}

Your response must include:

1. title: A captivating title for this artifact's story
2. story: A 150-200 word narrative covering:
   - The history and origin of this type of artifact
   - The artisans and communities who create it
   - How it is traditionally used
   - Its journey to Kuriftu Resort
3. cultural_significance: 2-3 sentences about what this item means culturally
4. fun_fact: One surprising or delightful fact about this artifact

Write in a warm, engaging tone — as if a knowledgeable guide is personally 
telling the guest about this treasure. Make the guest feel connected to the 
culture and the people behind the craft.

Respond ONLY in this exact JSON format:
{
  "title": "...",
  "story": "...",
  "cultural_significance": "...",
  "fun_fact": "..."
}
"""
```

**Why this prompt works well:**
- **Role assignment**: "master cultural storyteller" → produces richer output
- **Specific word count**: "150-200 words" → not too short, not overwhelming
- **Emotional direction**: "warm, engaging tone" → makes it feel personal
- **Structure**: Forces the AI to cover history, artisans, usage, and cultural meaning

---

## 5. The Complete Flow (Step-by-Step)

Here is the **entire journey** from camera click to story display:

```
┌──────────────────────────────────────────────────────────────────┐
│  STEP 1: Guest taps "Scan" and takes a photo                    │
│  → Phone camera captures image (JPEG)                           │
│  → App sends POST /api/scan/ with the image file                │
└──────────────────┬───────────────────────────────────────────────┘
                   ▼
┌──────────────────────────────────────────────────────────────────┐
│  STEP 2: Django backend receives the image                       │
│  → Saves image temporarily to /media/scans/                      │
│  → Passes the image to ai_services.identify_object()             │
└──────────────────┬───────────────────────────────────────────────┘
                   ▼
┌──────────────────────────────────────────────────────────────────┐
│  STEP 3: AI identifies the object (Job 1)                        │
│  → Sends image + prompt to Gemini Vision API                     │
│  → Receives: {object_name, country, confidence, materials}       │
│  → Logs the result in ScanLog table (for analytics)              │
└──────────────────┬───────────────────────────────────────────────┘
                   ▼
┌──────────────────────────────────────────────────────────────────┐
│  STEP 4: Backend checks — do we already know this artifact?      │
│                                                                  │
│  IF artifact exists in database:                                 │
│     → Return the stored story immediately (fast, no AI call)     │
│                                                                  │
│  IF artifact is NEW:                                             │
│     → Go to Step 5                                               │
└──────────────────┬───────────────────────────────────────────────┘
                   ▼
┌──────────────────────────────────────────────────────────────────┐
│  STEP 5: AI generates the cultural story (Job 2)                 │
│  → Sends object_name + country to Gemini Text API                │
│  → Receives: {title, story, cultural_significance, fun_fact}     │
│  → Saves new Artifact + Story in the database                    │
└──────────────────┬───────────────────────────────────────────────┘
                   ▼
┌──────────────────────────────────────────────────────────────────┐
│  STEP 6: Backend returns the complete result to the app          │
│  → JSON response with: artifact info + story + images + price    │
│  → Guest sees the cultural story on their screen                 │
└──────────────────────────────────────────────────────────────────┘
```

---

## 6. Integration Architecture

### How ai_services connects with other apps

```
                    ┌──────────────┐
                    │   Frontend   │
                    │  (Flutter)   │
                    └──────┬───────┘
                           │  POST /api/scan/  (image upload)
                           ▼
                    ┌──────────────┐
                    │  ai_services │  ← YOUR APP
                    │   views.py   │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
     ┌──────────────┐ ┌────────┐ ┌──────────┐
     │  services.py │ │ models │ │ artifacts│
     │ (AI logic)   │ │ScanLog │ │  app     │
     └──────┬───────┘ └────────┘ └──────────┘
            │                        ▲
            │  API call              │ creates/reads
            ▼                        │ Artifact + Story
     ┌──────────────┐               │
     │ Google Gemini│───────────────┘
     │   API        │  results used to
     └──────────────┘  create artifacts
```

### What your app talks to:

| Talks To | Why |
|---|---|
| **Google Gemini API** | To identify objects and generate stories (external HTTP calls) |
| **artifacts app** | To check if an artifact exists, to create new artifacts and stories |
| **countries app** | To look up or create the country from the AI result |
| **ScanLog model** (own) | To log every scan for analytics and debugging |

---

## 7. Prompt Engineering — The Secret Sauce

Prompt engineering is **the most important part** of your job. The same AI model can give terrible or amazing results depending on your prompt.

### Key Principles

#### 1. Give the AI a role
```
❌ Bad:  "What is this object?"
✅ Good: "You are an expert in African cultural artifacts. Identify this object."
```

#### 2. Provide context
```
❌ Bad:  "Describe this item."
✅ Good: "This artifact is displayed at Kuriftu Resort in Ethiopia. 
         The resort showcases handcrafted items from across Africa."
```

#### 3. Force structured output
```
❌ Bad:  "Tell me about this item."
✅ Good: "Respond ONLY in this exact JSON format: {object_name, country, ...}"
```

#### 4. Set boundaries
```
❌ Bad:  "Write a story." (could be 5 words or 5000 words)
✅ Good: "Write a 150-200 word narrative covering history, artisans, and usage."
```

#### 5. Handle edge cases in the prompt
```
"If you cannot identify the object, respond with:
{object_name: 'Unknown', confidence: 0.0}"
```

---

## 8. Caching Strategy — Why We Store Results

### The Problem
Every AI call costs time (~1-3 seconds) and potentially money. If 100 guests scan the same chair, we shouldn't call the AI 100 times.

### The Solution: Check Database First

```python
def handle_scan(image):
    # Step 1: AI identifies the object
    recognition = identify_object(image)
    
    # Step 2: Check if we already have this artifact
    existing = Artifact.objects.filter(
        name__icontains=recognition['object_name']
    ).first()
    
    if existing:
        # FAST PATH: Return stored data (no second AI call)
        return existing.story
    else:
        # SLOW PATH: Generate a new story with AI
        story = generate_story(recognition['object_name'], recognition['country'])
        # Save for next time
        artifact = Artifact.objects.create(...)
        Story.objects.create(artifact=artifact, ...)
        return story
```

### Benefits
- **Fast**: Stored results return in ~50ms vs ~2 seconds for AI
- **Consistent**: Same object always gets the same story
- **Cheap**: One AI call per unique artifact, not per scan
- **Reliable**: Works even if AI API is temporarily down (for known objects)

---

## 9. Error Handling

AI APIs can fail. Your code must handle this gracefully.

### What Can Go Wrong

| Error | Cause | How to Handle |
|---|---|---|
| API key invalid | Wrong key or expired | Return 500 + clear error message |
| Rate limit exceeded | Too many requests | Retry after delay, or return cached data |
| Image not recognized | Blurry photo, not an artifact | Return `confidence: 0.0` + message "Could not identify" |
| AI returns garbage | Malformed JSON | Try to parse, fallback to "Unknown artifact" |
| Network timeout | Slow connection to Google | Set timeout (10s), retry once, then fail gracefully |
| AI hallucination | Makes up incorrect info | Use confidence score to warn users |

### Example Error Response

```python
# If AI can't identify the object
{
    "success": false,
    "error": "Could not identify this artifact. Please try again with a clearer photo.",
    "suggestions": [
        "Make sure the object is well-lit",
        "Try to capture the full object",
        "Avoid blurry images"
    ]
}
```

---

## 10. File Structure for ai_services App

Here is exactly what files you need to create in `backend/ai_services/`:

```
ai_services/
├── __init__.py          # (exists) — empty
├── admin.py             # Register ScanLog model in Django admin
├── apps.py              # (exists) — app config
├── models.py            # ScanLog model — logs every scan
├── services.py          # ⭐ THE CORE — identify_object() + generate_story()
├── serializers.py       # DRF serializers for scan input/output
├── views.py             # ScanView — the POST /api/scan/ endpoint
├── urls.py              # URL routing for the app
├── prompts.py           # All AI prompts stored as constants (clean separation)
├── utils.py             # Helper functions (parse JSON from AI, validate image)
├── migrations/          # (exists) — Django migrations
└── tests.py             # (exists) — test cases
```

### What each file does:

| File | Purpose |
|---|---|
| **services.py** | Contains `identify_object(image_path)` and `generate_story(name, country)` — the two core AI functions. This is where you call the Gemini API. |
| **prompts.py** | Stores all prompt templates as string constants. Keeps prompts separate from logic so they're easy to tweak. |
| **views.py** | The `ScanView` — receives the image from the app, calls the services, checks the database, returns the result. |
| **models.py** | `ScanLog` model — records every scan (image, result, confidence, timestamp) for analytics. |
| **serializers.py** | Validates incoming image uploads and formats outgoing JSON responses. |
| **utils.py** | Helper functions like `parse_ai_json_response()`, `validate_image_format()`. |

---

## 11. API Keys & Security

### Never hardcode API keys

```python
# ❌ NEVER do this
API_KEY = "AIzaSyD..."

# ✅ ALWAYS do this
import os
API_KEY = os.environ.get('GEMINI_API_KEY')

# ✅ Even better — use python-decouple
from decouple import config
API_KEY = config('GEMINI_API_KEY')
```

### .env file setup

```env
# .env (in the project root)
GEMINI_API_KEY=AIzaSyD-your-actual-key-here
DEBUG=True
SECRET_KEY=your-django-secret-key
```

### .gitignore — never commit secrets

Make sure `.env` is in your `.gitignore`:
```
.env
```

---

## 12. Testing the AI Layer

### Test without the API (mock testing)

During development, you can mock the AI responses to avoid burning API credits:

```python
# For testing — a fake identify_object function
def identify_object_mock(image_path):
    return {
        "object_name": "Ethiopian Cultural Chair",
        "country": "Ethiopia",
        "category": "Furniture",
        "confidence": 0.95,
        "materials": ["mahogany wood", "cotton"]
    }
```

### Test with the API (integration testing)

```bash
# Test with curl
curl -X POST http://localhost:8000/api/scan/ \
  -F "image=@/path/to/test_image.jpg"

# Expected response:
{
  "success": true,
  "artifact": {
    "name": "Ethiopian Cultural Chair",
    "country": "Ethiopia",
    "story": { ... }
  }
}
```

### What to test:
- ✅ Valid image → correct identification
- ✅ Blurry image → graceful error
- ✅ Non-artifact image (e.g., a person) → "Could not identify"
- ✅ Already-known artifact → returns cached story (no AI call)
- ✅ API key missing → clear error message
- ✅ Network timeout → retry or graceful failure

---

## 13. Cost & Rate Limits

### Google Gemini Free Tier (as of 2025)

| Feature | Limit |
|---|---|
| Requests per minute | **60** |
| Requests per day | **1,500** |
| Input tokens per request | ~30,000 (images count as ~258 tokens) |
| Output tokens per request | ~8,192 |
| Price | **$0.00** (free tier) |

### What this means for your hackathon
- 60 scans per minute = **more than enough** for a demo
- 1,500 scans per day = plenty for testing
- You will not need to pay anything

### If you go to production later
- Gemini Pro pricing is ~$0.00025 per 1K input tokens
- A typical scan (image + prompt) costs about **$0.001** (one-tenth of a cent)
- 10,000 scans/month ≈ **$10/month** — very affordable

---

## Summary — Your Job as AI Engineer

Your primary responsibilities in the `ai_services` app are:

1. **Write `services.py`** — the core functions `identify_object()` and `generate_story()`
2. **Craft the prompts** in `prompts.py` — this is where the magic happens
3. **Build the scan endpoint** in `views.py` — receive image → run AI → return result
4. **Handle errors gracefully** — bad images, API failures, unknown objects
5. **Log every scan** — in the `ScanLog` model for debugging and analytics
6. **Coordinate with the backend engineer** — your app needs to read/write to the `artifacts` and `countries` apps

The AI layer is what makes this project **special**. Without it, it's just a catalog. With it, it's a **cultural experience**.
