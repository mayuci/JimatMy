# JimatMY

JimatMY is a university project for a Malaysian grocery price comparison mobile application.

## Architecture

```text
Flutter app -> Node.js/Express REST API -> PostgreSQL
PriceCatcher datasets -> backend import scripts -> PostgreSQL
```

## Project Structure

```text
mobile/              Flutter mobile application
backend/src/         Node.js/Express source code
database/            Migrations, seeds, and import assets
docs/                ERD, API notes, screenshots, and portfolio material
data/                Raw and processed project datasets
```

## Current Status

JimatMY is a working university prototype using real Malaysian PriceCatcher data. It includes:

- Flutter Web/Android browsing, grocery search, item details, price comparison, and price trends.
- Authenticated shopping lists and budgets with per-user JWT ownership.
- Login, registration, profile updates, favourite items, recent activity, and profile counts.
- Nearby premise browsing with optional Maps display and on-demand-only selected-store geocoding.
- Node.js/Express API, PostgreSQL migrations, and repeatable official CSV import tooling.

## Setup

Install Flutter, Node.js/npm, PostgreSQL, and `psql`. Apply the migrations in `database/README.md`, then configure the ignored `backend/.env` from `backend/.env.example` with PostgreSQL values, `JWT_SECRET`, and the backend-only `GOOGLE_GEOCODING_API_KEY` placeholder when map resolution is needed.

```powershell
cd backend
npm install
npm start
```

In another terminal:

```powershell
cd frontend
flutter pub get
flutter run -d chrome
```

For Android, run an emulator and use `flutter run -d <device-id>`. Google Maps keys are supplied only through ignored Android `local.properties` or Web `--dart-define`; see [Google Maps setup](docs/google_maps_setup.md).

## Import And Test

Use official PriceCatcher sources only. For example:

```powershell
cd backend
npm run import:pricecatcher -- --month 2026-07 --states "W.P. Kuala Lumpur,Selangor"
```

Run backend verification and Flutter checks:

```powershell
npm test
npm run verify:auth
npm run verify:planner
npm run verify:user-features
cd ..\frontend
flutter analyze
flutter test
flutter build web
```

See [Flutter setup](docs/flutter_setup.md), [API documentation](docs/api.md), and [Demo script](docs/demo_script.md) for the complete presentation workflow.
