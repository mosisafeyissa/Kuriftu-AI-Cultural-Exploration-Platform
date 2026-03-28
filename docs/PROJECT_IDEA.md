# Kuriftu AI Cultural Exploration Platform

## The Problem

Kuriftu Resort & Spa is known for showcasing handcrafted African cultural artifacts — chairs, beds, paintings, sculptures, textiles, and more — throughout its properties. However, guests often walk past these beautiful items without knowing their story, where they come from, or what they mean culturally.

There is no easy way for a guest to:
- Learn the cultural background of an object they see
- Understand who made it and what materials were used
- Purchase the item if they fall in love with it

---

## The Solution

**Kuriftu AI Cultural Exploration Platform** is a mobile app that turns every artifact in the resort into a living cultural story.

A guest simply **points their phone camera at any object** — a handcrafted Ethiopian chair, a Moroccan rug, a Nigerian painting — and the app instantly:

1. **Identifies the object** using AI-powered image recognition
2. **Tells its cultural story** — where it comes from, what it means, how it was made
3. **Lets the guest buy it** — directly from the app, delivered to their room

It transforms a passive hotel stay into an **interactive cultural journey**.

---

## How It Works (Guest Experience)

### Step 1 — Scan
The guest opens the app and taps **"Scan an Artifact"**. They point their camera at an item — say, a carved wooden chair in the lobby.

### Step 2 — Discover
Within seconds, the app displays:
- **Object name**: "Handcrafted Ethiopian Mesob-Inspired Chair"
- **Country of origin**: Ethiopia 🇪🇹
- **Cultural story**: A rich narrative about the item's history, the artisans who made it, and its cultural significance
- **Materials**: Hand-carved mahogany wood with traditional Habesha weaving patterns
- **Confidence**: How certain the AI is about the identification

### Step 3 — Order
If the guest loves it, they tap **"Buy This Item"**, enter their room number, and the order is placed. The item can be delivered to their room or shipped to their home.

---

## System Architecture (4 Layers)

```
┌─────────────────────────────────────┐
│         📱 Mobile App (Flutter)      │
│  Scan · Discover · Learn · Order     │
└──────────────┬──────────────────────┘
               │ REST API
┌──────────────▼──────────────────────┐
│      🧠 Backend API (Django + DRF)   │
│  Receives images · Stores data       │
│  Handles orders · Returns results    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      🤖 AI Intelligence Layer        │
│  Job 1: Object Recognition (Vision)  │
│  Job 2: Cultural Story Generation    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      💾 Data Layer (Database)        │
│  Artifacts · Countries · Stories     │
│  Orders · Images                     │
└─────────────────────────────────────┘
```

---

## What the AI Does

The AI is the core of what makes this platform special. It performs **two jobs**:

### Job 1 — Object Recognition
When a guest scans an item, the AI analyzes the image and returns:
```json
{
  "object": "Handcrafted Ethiopian Cultural Chair",
  "country": "Ethiopia",
  "confidence": 0.93
}
```

### Job 2 — Cultural Story Generation
Once the object is identified, the AI generates a rich cultural narrative:
```json
{
  "title": "The Mesob Chair: A Seat of Ethiopian Tradition",
  "story": "This chair draws inspiration from the Mesob, the traditional Ethiopian...",
  "materials": "Hand-carved mahogany wood, Habesha cotton weaving",
  "cultural_significance": "In Ethiopian culture, seating arrangements reflect..."
}
```

The system is smart — if the artifact has been scanned before, it returns the **stored story** instantly. If it's new, it **generates a fresh story** using AI.

---

## App Screens

| Screen | What the Guest Sees |
|---|---|
| **Home** | A gallery of all cultural artifacts in the resort, filterable by country |
| **Camera** | A camera viewfinder with a "Scan" button to capture the artifact |
| **Result** | The AI's identification — object name, country, confidence score |
| **Artifact Detail** | The full cultural story, images, materials, and a "Buy" button |
| **Order** | A simple form — guest name, room number, quantity — to purchase the item |

---

## Backend Apps

The Django backend is organized into **5 clean apps**:

| App | Responsibility |
|---|---|
| **countries** | Stores African countries and their metadata (name, flag, description) |
| **artifacts** | Stores artifact info (name, materials, price, images) and their cultural stories |
| **ai_services** | Handles the AI pipeline — receives images, identifies objects, generates stories |
| **orders** | Manages guest orders (what they bought, room number, delivery status) |
| **users** | Guest profiles linked to room numbers and stay dates |

---

## API Endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/api/scan/` | Guest uploads an image → AI identifies the object and returns the story |
| `GET` | `/api/artifacts/` | List all artifacts (with stories and images) |
| `GET` | `/api/artifacts/{id}/` | Get full detail of a single artifact |
| `GET` | `/api/countries/` | List all countries represented in the resort |
| `POST` | `/api/orders/` | Place an order for an artifact |
| `GET` | `/api/orders/{id}/` | Check order status |

---

## Database Tables

| Table | Key Fields |
|---|---|
| **countries** | name, code (ISO), description, flag_emoji |
| **artifacts** | name, description, category, materials, price, country (FK), is_available |
| **artifact_images** | artifact (FK), image file, is_primary |
| **stories** | artifact (1:1), title, narrative, cultural_significance, is_ai_generated |
| **orders** | guest_name, room_number, status (pending/confirmed/delivered), total_price |
| **order_items** | order (FK), artifact (FK), quantity, price |

---

## Technology Stack

| Layer | Technology |
|---|---|
| Mobile App | **Flutter** (cross-platform — Android & iOS) |
| Backend API | **Django** + **Django REST Framework** |
| AI Engine | **Google Gemini** (Vision API for recognition, Text API for story generation) |
| Database | **SQLite** (development) / **PostgreSQL** (production) |
| Image Storage | Django media files (local) / Cloud storage (production) |

---

## What Makes This Project Unique

1. **AI-powered cultural storytelling** — Not just object detection, but rich narrative generation
2. **Scan-to-buy experience** — Seamless journey from discovery to purchase
3. **African cultural preservation** — Every scan teaches guests about African heritage
4. **Resort integration** — Room-number-based ordering, no account needed
5. **Learning AI** — The system gets smarter as more artifacts are scanned and stories are stored

---

## Target Users

- **Resort guests** who want to explore and understand the cultural items around them
- **Gift shoppers** who see something beautiful and want to take it home
- **Cultural enthusiasts** interested in African art, craftsmanship, and traditions

---

## Future Enhancements

- 🌍 **Multi-language support** — Stories in Amharic, French, Arabic, Swahili
- 🗺️ **AR experience** — Point camera at an artifact and see its story overlaid in augmented reality
- 📊 **Analytics dashboard** — Most scanned items, popular countries, order trends
- 🎵 **Audio narration** — Listen to the cultural story instead of reading
- 🤝 **Artisan profiles** — Connect guests directly with the craftspeople who made the items
