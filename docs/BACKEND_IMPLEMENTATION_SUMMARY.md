

### Core project setup
- Django project initialized under `backend/config/`.
- Installed and configured:
  - Django REST Framework
  - CORS headers (`CORS_ALLOW_ALL_ORIGINS = True` for development)
  - Media file handling (`MEDIA_URL`, `MEDIA_ROOT`)
- Active apps in `INSTALLED_APPS`:
  - `artifacts`
  - `orders`
  - `ai_services`
  - `users`

### Artifacts domain (`backend/artifacts/`)
- Data models implemented:
  - `Country`
  - `Villa`
  - `Artifact`
  - `Story` (one-to-one with `Artifact`)
- API serializers implemented with nested output for country, villa, and story.
- API endpoints implemented:
  - `GET /api/artifacts/` with filtering (`country`, `villa`) and pagination.
  - `POST /api/scan/` with image upload or fallback `artifact_name` text mode.
- Scan endpoint behavior implemented:
  - Validates image type and size.
  - Attempts identification via AI helper functions.
  - Returns DB story if artifact exists.
  - Returns generated story payload if artifact is not found.
- Django admin is implemented for all artifacts models with helpful list filters and previews.
- Comprehensive tests exist in `artifacts/tests.py` covering artifacts list, scan flow, and order endpoints.

### Orders domain (`backend/orders/`)
- `Order` model implemented with status enum (`Pending`, `Processing`, `Completed`, `Cancelled`).
- Serializer validation implemented for artifact existence and quantity.
- API endpoints implemented:
  - `GET /api/orders/?email=...`
  - `POST /api/order/`
- Order listing supports case-insensitive email filtering.
- Order creation defaults to `Pending` status and supports quantity validation.
- Django admin registration implemented for order management.

### Users app (`backend/users/`)
- App is registered and scaffolded.
- `models.py`, `views.py`, and tests are placeholders.
- No user/auth API endpoints are implemented yet.

