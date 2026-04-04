
# AfriLens
Scan the culture. Own the craft.

## 1. Project Overview

**Project Name:** Kuriftu Cultural Whisperer (Afrilens AI)  
**Description:** A gallery-grade cultural exploration platform integrating physical artifacts with digital storytelling. It allows guests to scan physical artifacts, receive AI-generated cultural stories, and securely purchase artisan replicas directly to their homes.  
**Purpose:** To elevate the guest experience at premium hospitality venues (such as Kuriftu Resorts) by transforming static decor into interactive, educational, and shoppable cultural touchpoints.  
**Target Users:** 
- **Guests & Tourists:** Individuals exploring the resort who want to learn about and purchase local cultural artifacts.
- **Resort Management (Staff):** Curators who update artifact data and manage orders.
- **System Operators:** Developers and IT administrators maintaining the platform.

**Key Features:**
- **AI-Powered Image Scanning:** Real-time object identification using Google Gemini Vision API.
- **Dynamic Storytelling:** Culturally rich, AI-generated backstories outlining history, materials, and significance.
- **Secure Purchases:** Integrated Chapa payment gateway for buying physical artifacts.
- **Cloud Media Hosted:** Scalable image handling via Cloudinary.
- **Offline / Mock Mode:** Built-in UI testing toggles to experience the app without network availability.

---

## 2. System Roles & Access

The platform supports three distinct levels of authority carefully segregated to protect data integrity and purchasing flows:

- **Guest User (Mobile App):**
  - *Access:* Frontend Flutter Application only.
  - *Permissions:* Can scan artifacts, read generated cultural stories, browse the curated catalog (by Country and Villa), and place orders via the Chapa payment gateway. They do not have access to the backend dashboards.

- **Super Admin (System Owner/IT):**
  - *Access:* Full unrestricted access to the Django Admin Panel.
  - *Permissions:* Has total control over the database. Can create/delete Admin accounts, view detailed `ScanLogs` for AI analytics, manage overarching app configurations, and directly modify the PostgreSQL database schema through migrations.

---

## 3. 🔐 Default Super Admin Account

> **IMPORTANT:** A default Super Admin account has been configured for initial setup and testing purposes. 

- **Login URL:** `http://localhost:8000/admin/](https://kuriftu-ai-cultural-exploration-platform-b7jj.onrender.com/admin/`
- **Email/Username:** `1234@gmail.com`
- **Password:** `ashu3079`

**How to log in:**
1. Start the backend server (see Installation Guide).
2. Open your web browser and navigate to `http://localhost:8000/admin/`.
3. Enter the credentials provided above into the username and password fields.
4. Click "Log in".

**What the Super Admin can do:**
Upon logging in, you will see the full Django backend interface. You can immediately begin creating new Artifact profiles, reviewing placed orders, creating lower-tier Admin roles for your staff, and monitoring the AI scan logs.

> [!CAUTION]  
> **SECURITY WARNING:** You MUST change these credentials immediately after your first successful login. Failing to do so in a production environment will expose your entire database, customer orders, and connected API keys to malicious actors. Navigate to the "Users" section in the admin panel and update the password.

---

## 4. Installation Guide

### Prerequisites
- **Docker & Docker Compose** installed on your machine.
- **Flutter SDK (^3.9)** installed for mobile compilation.
- Valid API Keys for: Google Gemini API, Chapa (Payment), and Cloudinary (Storage).

### Step-by-Step Setup (Backend & Infrastucture)

1. **Clone the Repository and Navigate to Backend:**
   ```bash
   git clone https://github.com/mosisafeyissa/Kuriftu-AI-Cultural-Exploration-Platform.git
   cd Kuriftu-AI-Cultural-Exploration-Platform/backend
   git checkout main
   ```

2. **Configure Environment Variables:**
   Create a `.env` file in the `backend` directory. Populate it with the following:
   ```env
   SECRET_KEY=your-secure-django-key
   DEBUG=True
   ALLOWED_HOSTS=localhost,127.0.0.1
   
   # Database (PostgreSQL inside Docker)
   POSTGRES_DB=afrilens_ai
   POSTGRES_USER=afrilens_ai_user
   POSTGRES_PASSWORD=secure_password
   
   # Third Party API Keys
   GEMINI_API_KEY=your_gemini_key
   CLOUDINARY_URL=cloudinary://API_KEY:API_SECRET@CLOUD_NAME
   CHAPA_SECRET_KEY=your_chapa_secret
   CHAPA_MOCK_MODE=True
   ```
   *(Note: Ensure CHAPA_MOCK_MODE is False for production environments).*

3. **Spin up the Docker Containers:**
   Our docker-compose file orchestrates the PostgreSQL database, the Django web server, and the Nginx reverse proxy.
   ```bash
   docker-compose up --build -d
   ```

4. **Verify the Backend:**
   The API should now be running at `http://localhost:8000/api/`.

### Running Locally (Frontend Flutter App)

1. **Navigate to Frontend:**
   ```bash
   cd ../frontend
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the Application:**
   Launch an iOS/Android emulator or connect a physical device.
   ```bash
   flutter run
   ```

---

## 5. 🚀 Step-by-Step Usage Guide

Below is the detailed expected journey for a guest user interacting with the platform.

### Step 1: Launch & Welcome
- **Action:** The user opens the AfriLens app on their mobile device or available tablet in the lobby.
- **Experience:** They are greeted by the dynamic, dark-themed `WelcomeScreen`. A subtle animation plays, prompting them to tap **"Start Exploring"**.

### Step 2: The Core Scanning Experience
- **Action:** The user taps the primary floating camera button located in the center of the bottom navigation bar.
- **Experience:** 
  1. The camera viewfinder opens (`ScanScreen`).
  2. The user points their camera at a physical artifact (e.g., a handwoven Mesob Basket) and taps the capture button.
  3. A loading indicator appears while the app securely sends the image to the Django AI backend (`/api/ai/scan/`).
  4. Once Gemini AI finishes analyzing, the screen transitions automatically to the `ResultScreen`/`ArtifactDetailScreen`.

### Step 3: Immersing in the Story
- **Action:** The user scrolls through the artifact detail page.
- **Experience:** They see the recognized title ("Handwoven Mesob Basket"), its origin country ("Ethiopia"), and read a beautifully generated story about its historical materials and cultural significance to Ethiopian hospitality.

### Step 4: Making a Purchase (Chapa)
- **Action:** Fascinated by the item, the user taps the **"Purchase Replica"** button at the bottom of the screen.
- **Experience:** 
  1. They are taken to the `PurchaseScreen`, outlining the price.
  2. The user enters their delivery details (Room Number or Home Address) and quantity.
  3. Clicking **"Proceed to Payment"** securely invokes the Chapa gateway. 
  4. Upon successful payment verification, the user receives an in-app `Notification` thanking them for their purchase, and an order is officially logged in the backend.

---

## 6. 🧭 Navigation & Pages Guide

*Note: Screenshots represent placeholders for visual documentation.*

### Home Page (Catalog)
- **Purpose:** The main hub displaying curated lists of Countries and specific Villas to explore manually.
- **Key Actions:** 
  - Top Search Bar to manually query artifact names.
  - Horizontal scrolling carousels for "Popular Artifacts".
  - Tapping an item navigates to its Detail Page.
- `[Insert Screenshot: Home Page]`

### AI Scan Viewfinder
- **Purpose:** The camera interface for artifact recognition.
- **Key Actions:** 
  - **Capture Button:** Takes the photo.
  - **Gallery Icon:** Allows user to upload an explicitly saved photo from their camera roll.
  - **Flash Toggle:** Toggles device flashlight for dim gallery rooms.
- `[Insert Screenshot: Scan Viewfinder Page]`

### Artifact Detail & Story Page
- **Purpose:** Presenting the AI-generated or cataloged deep-dive of a specific artifact.
- **Key Actions:** 
  - Rich text body containing the story.
  - Expandable accordions for "Materials" and "Fun Facts".
  - Prominent **"Purchase Replica / Order"** CTA button sticking to the bottom.
- `[Insert Screenshot: Artifact Detail Page]`

### Checkout / Payment Page
- **Purpose:** Handling the Chapa API transactional flow.
- **Key Actions:** 
  - Form fields for Name, Email, and Location.
  - **"Pay Safely with Chapa"** green checkout button.
- `[Insert Screenshot: Checkout Page]`

---

## 7. 🛠 Super Admin Guide

The Django Admin panel is the operational brain of the application. 

### Accessing the Panel
Navigate to `http://localhost:8000/admin/` and log in (using the credentials from Section 3).

### Managing Data/Content
- **Artifacts:** Click `Artifacts > Artifacts` to view the catalog. Here, you can manually add artifacts that Gemini AI might struggle with. You can assign them to specific `Villas` and `Countries`.
- **Media:** Because the backend is linked to Cloudinary, any image uploaded here is automatically offloaded to the cloud—saving server space.

### Managing Orders
- Navigate to `Orders > Orders`. 
- Here, backend staff can see every transaction verified by the Chapa API. 
- You can change the "Status" dropdown from `Pending` -> `Processing` -> `Shipped`.

### Managing AI Scans
- Navigate to `AI Services > Scan Logs`.
- Super Admins can audit what guests are scanning. If the AI hallucinates, the image and AI result are logged here so you can refine Prompts in the future.

### Permissions & Users
- Only **Super Admins** can access the `Users > Users` panel to grant `Staff Status`. 
- When creating a new Admin, explicitly check *only* the `artifacts` and `orders` permissions so they cannot accidentally delete essential Scan Logs or Users.

---

## 8. 🧩 Project Structure

```text
Kuriftu-Platform/
├── backend/                  # Python/Django Infrastructure
│   ├── ai_services/          # Google Gemini AI integrations & scanning logic
│   ├── artifacts/            # Models: Artifacts, Countries, Villas
│   ├── orders/               # Chapa transactions & order fulfillment tracking
│   ├── config/               # Django root application (URLs, Settings)
│   ├── users/                # JWT custom User models and auth
│   ├── docker-compose.yml    # Orchestrates Postgres, Django, and Nginx
│   ├── Dockerfile            # Blueprint for the Python backend container
│   ├── nginx.conf            # Reverse proxy configuration
│   └── requirements.txt      # Python dependencies (gunicorn, psycopg2, etc.)
├── frontend/                 # Flutter Application
│   ├── lib/                  
│   │   ├── models/           # Dart data schemas
│   │   ├── providers/        # State Management (ScanProvider, etc.)
│   │   ├── screens/          # UI Views (Home, Scan, Detail)
│   │   ├── services/         # API wrappers (ApiService, ScanService)
│   │   └── theme/            # Design system (KuriftuTheme)
│   ├── pubspec.yaml          # Flutter Dart packages
│   └── android/ios/web/      # Native platform wrappers
└── README.md                 
```

**Key Files Explained:**
- `backend/config/settings.py`: The nerve center for security, database, and JWT initialization.
- `backend/ai_services/services.py`: Contains the carefully crafted text prompts sent to Gemini to force it to output structured JSON stories.
- `frontend/lib/services/api_service.dart`: The main gateway the Flutter app uses to talk to the backend, complete with a `useMockData` toggle for offline developing.

---

## 9. 🌐 Informative Website (Landing Page)

[*(Visit our landing page).*](https://afri-lens-web.vercel.app/)

The Kuriftu Cultural Whisperer Landing Page serves as the public face of the platform.
- **What users see:** A cinematic, premium web experience featuring high-definition video of African artifacts. 
- **Hero Section:** A powerful tagline calling users to "Discover the Stories Behind the Craft" with an immediate QR code to download the mobile app.
- **Features Section:** Interactive mockups showing the AI scan in action, and highlighting how easy it is to purchase replicas via Chapa.
- **Download Section:** Direct links to the Apple App Store and Google Play Store, or a direct Web-App fallback.

---

## 10. API Documentation

The backend exposes a structured REST API. JWT Tokens (Bearer) are required for ordering.

### Endpoints
- `GET /api/countries/` - Fetches the list of available curated countries.
- `GET /api/artifacts/?villa=1` - Fetches artifacts, filterable by query parameters.
- `POST /api/ai/scan/` - The core AI vision endpoint.
- `POST /api/order/` - Submits a secure order to the system.

### Request/Response Example
**POST /api/ai/scan/**
*Request: (Multipart/Form-Data)*
- `image`: [binary .jpg/.png]

*Response (200 OK):*
```json
{
  "artifact_name": "Handwoven Mesob Basket",
  "country": "Ethiopia",
  "confidence": 0.96,
  "category": "Household",
  "price": "99.00",
  "source": "ai_generated",
  "story": {
    "title": "Woven Together",
    "materials": "Natural grass, woven reeds",
    "cultural_significance": "Embodies the Ethiopian philosophy of shared meals.",
    "story": "The Mesob is far more than a serving vessel..."
  }
}
```

---

## 11. Contribution Guide

We welcome contributions to make the cultural exploration experience even better.

**How to contribute:**
1. Fork the repository.
2. Create a new branch: `git checkout -b feature/your-feature-name`
3. Commit your changes logically: `git commit -m "feat: added new UI animations"`
4. Push the branch: `git push origin feature/your-feature-name`
5. Open a Pull Request detailing your changes.

**Coding Standards:**
- **Flutter:** Follow standard `flutter_lints` rules. Keep business logic strictly out of UI widget files. Use Provider safely.
- **Django:** Adhere to PEP-8. Ensure all new models have corresponding Django Admin configurations registered.

---

## 12. Security Notes

- **Credential Safety:** Never commit `.env` files. The repository uses `.gitignore` to prevent secret leakage. Ensure your API keys (Gemini, Chapa) are rotated if accidentally exposed.
- **Best Practices:** The Docker container maps PostgreSQL data to a secure volume. Do not expose port `5432` to the public internet in production (currently restricted to Docker's internal network).
- **Data Protection Tips:** The app relies on `X-Frame-Options`, `HSTS`, and `Strict-Transport-Security`. When deploying behind Nginx, ensure SSL/TLS certificates (e.g., Let's Encrypt) are actively passing secure headers. Payment data is never stored locally; the Chapa API heavily tokenizes all financial transactions.

---

## 13. Future Improvements

As the platform matures, we plan to implement the following enhancements:
- **Offline AI Processing:** Implementing on-device lightweight TensorFlow models for artifact recognition when resort WiFi is inadequate.
- **Audio Generation:** Integrating Google Cloud TTS (Text-to-Speech) so the app visibly "whispers" or reads the generated story out loud.
- **Multilingual Support:** Auto-translating stories into French, Mandarin, and Arabic to support international tourists.
- **AR View:** Adding an Augmented Reality layer allowing users to place a 3D model of the artifact in their hotel room before buying it.

---

