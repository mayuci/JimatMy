# JimatMY Flutter Setup

The Flutter app lives in `frontend/` and reads real PriceCatcher data through the local Express API. Start PostgreSQL before the backend.

## Start the backend

From the repository root:

```powershell
cd backend
npm start
```

The API should respond at `http://localhost:3000/api/health`.

Authentication is optional for public browsing. Login is required for Planner, shopping lists, budgets, favourites, and recent activity. The backend must have a local `JWT_SECRET` of at least 32 characters in the ignored `backend/.env`; never commit its value.

## Run on Chrome

Open another terminal from the repository root:

```powershell
cd frontend
flutter pub get
flutter run -d chrome
```

For a presentation build with Maps enabled, add the restricted Web key through `--dart-define` as described in [Google Maps setup](google_maps_setup.md). Do not put the key in source or screenshots.

Chrome uses `http://localhost:3000/api` by default.

## Run on an Android emulator

Start an Android emulator, then run:

```powershell
cd frontend
flutter devices
flutter run -d <android-device-id>
```

The Android emulator uses `http://10.0.2.2:3000/api`, which routes to the host machine's localhost. Android internet access and cleartext local HTTP are enabled in the app manifest for development.

## Change the API URL

The central defaults are in `frontend/lib/config/api_config.dart`. For a temporary override without editing source:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api
```

For a physical device, replace the host with the development computer's LAN address and ensure the API is reachable on that network.

## Verification commands

```powershell
cd backend
npm test
npm run verify:auth
npm run verify:planner
npm run verify:user-features
cd ..\frontend
flutter analyze
flutter test
flutter build web
```
