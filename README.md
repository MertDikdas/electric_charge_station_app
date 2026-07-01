# Electric Charge Station App

A full-stack electric vehicle charging station application. The project includes a FastAPI backend and a Flutter frontend for user authentication, station discovery, charger compatibility, reservations, charging sessions, payments, coupons, notifications, company management, and admin workflows.

## Tech Stack

- **Backend:** Python, FastAPI, SQLAlchemy, PostgreSQL, JWT authentication
- **Frontend:** Flutter, Dart, Google Maps
- **Testing:** Pytest, Flutter test

## Project Structure

```text
.
├── backend/
│   ├── app/
│   │   ├── application/      # Service layer
│   │   ├── core/             # Security, dependencies, scheduling, utilities
│   │   ├── domain/           # Domain models and business rules
│   │   ├── infrastructure/   # Database and repository implementations
│   │   └── presentation/     # FastAPI routers
│   ├── docs/                 # API and business rule documentation
│   ├── tests/                # Backend tests
│   ├── main.py               # FastAPI entry point
│   └── requirements.txt
└── frontend/
    ├── lib/
    │   ├── core/             # App shell, theme, navigation, shared UI helpers
    │   ├── data/             # API client, models, services, repositories
    │   ├── features/         # Screens and feature controllers
    │   └── widgets/          # Reusable widgets
    ├── assets/               # Logo, station markers, map styles
    └── pubspec.yaml
```

## Features

- User registration, login, logout, and authenticated profile access
- Vehicle management and compatible charger lookup
- Charging station and charger listing
- Charger availability and reservation management
- Charging session start and finish flows
- Payment records and payment status updates
- Coupon preview and coupon application
- User notifications and reservation reminders
- Admin company, station, member, coupon, and statistics screens
- Company panel for station-related management
- Map-based station discovery with Google Maps

## Requirements

- Python 3.11+
- PostgreSQL
- Flutter SDK compatible with Dart `^3.11.5`
- Android Studio, Xcode, or another Flutter-supported target environment

## Backend Setup

Go to the backend directory:

```bash
cd backend
```

Create and activate a virtual environment:

```bash
python -m venv .venv
.venv\Scripts\activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Create a `.env` file inside `backend/`:

```env
NEW_DATABASE_URL=postgresql://USER:PASSWORD@localhost:5432/DATABASE_NAME
OPENAI_API_KEY=your_openai_api_key
```

`NEW_DATABASE_URL` is required by the backend database configuration. `OPENAI_API_KEY` is used by the chatbot service.

Run the backend:

```bash
uvicorn main:app --reload
```

Default backend URLs:

- API: `http://localhost:8000`
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Frontend Setup

Go to the frontend directory:

```bash
cd frontend
```

Install Flutter dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

To provide a custom API URL or Google Maps API key:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
```

Default API URLs:

- Web, iOS, macOS, Windows, Linux: `http://localhost:8000`
- Android emulator: `http://10.0.2.2:8000`

For Flutter Web, you can also copy `frontend/web/config.example.js` to `frontend/web/config.js` and set:

```js
window.GOOGLE_MAPS_API_KEY = "YOUR_GOOGLE_MAPS_API_KEY";
```

## Testing

Run backend tests:

```bash
cd backend
pytest
```

Run frontend tests:

```bash
cd frontend
flutter test
```

## API Documentation

Detailed API documentation is available in:

```text
backend/docs/api-endpoints.md
```

Main endpoint groups:

- `/auth`
- `/users`
- `/vehicles`
- `/stations`
- `/chargers`
- `/reservations`
- `/charging-sessions`
- `/payments`
- `/coupons`
- `/notifications`
- `/statistics`
- `/admin/companies`
- `/admin/company-members`

## Business Rules

Detailed business rules are available in:

```text
backend/docs/business_rules.md
```

The system validates:

- Vehicle and charger connector compatibility
- Vehicle and charger current type compatibility
- Charger availability before reservation
- Reservation time ranges and overlap conflicts
- Reservation limits for past and future dates
- Coupon ownership, validity dates, usage limits, and discount rules
- Reservation reminder notifications

## Development Notes

- Backend tables are created from SQLAlchemy metadata on application startup.
- CORS is currently open for development.
- JWT settings are defined in the backend security module.
- Frontend API and Google Maps configuration is handled in `frontend/lib/data/api/api_config.dart`.
