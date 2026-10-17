# Google Maps and Location Setup

JimatMY uses separate restricted keys for Android and Web. Never place either key in Git, screenshots, issue descriptions, or shared logs.

Nearby Stores also uses a separate backend-only Geocoding API key. A controlled backend enrichment command resolves imported premises whether or not they currently have price transactions. Validated results are held in a shared PostgreSQL cache for at most 29 days; expired latitude/longitude values are removed while Google place IDs may be retained. Failed and ambiguous attempts are also delayed for 29 days so repeated app visits do not spend quota on the same address. The app itself never geocodes premise cards.

After location permission is granted, `GET /api/premises/nearby` calculates distance across that full fresh imported-premise pool in PostgreSQL, orders nearest first, and only then returns 10 rows. **See 5 more stores** retrieves the next five cached rows. Search, scrolling, filtering, and widget rebuilds never call Geocoding. Store Detail keeps its separate one-time, user-focused resolution behavior and does not persist that response.

Before public deployment, publish accessible Terms of Use and a Privacy Policy that meet Google Maps Platform requirements. Geocoding results are displayed only on the Google map, whose built-in attribution must remain visible and unobstructed.

## Backend Geocoding Key

Enable **Geocoding API** for a server-restricted key. Restrict the key to the Geocoding API and to the backend's appropriate server IP addresses where practical.

Add this value only to the ignored `backend/.env` file:

```properties
GOOGLE_GEOCODING_API_KEY=YOUR_BACKEND_GEOCODING_API_KEY
```

Do not add this key to Flutter, Android `local.properties`, Web `--dart-define` values, screenshots, logs, or committed files. Restart the backend after setting it:

```powershell
cd backend
npm start
```

Apply migration `008_add_premise_coordinate_cache.sql` once, then populate or
refresh active premises sequentially:

```powershell
psql -U postgres -d jimatmy_db -v ON_ERROR_STOP=1 -f database/migrations/008_add_premise_coordinate_cache.sql
cd backend
npm run enrich:premises -- --limit 10
npm run enrich:premises -- --all --delay-ms 120
```

Use the limited command first to confirm configuration. The full command is
resumable: recently attempted rows are skipped. It logs counts only and never
prints keys, request URLs, or coordinates. Run it again before the 29-day cache
expires if the demo needs a fresh complete candidate pool.

Safe backend diagnostics intentionally exclude the key, complete request URL, and raw Google response:

- `GEOCODING_NOT_CONFIGURED`: the backend process has no Geocoding key configured.
- `GEOCODING_TIMEOUT`: Google did not respond within the short request timeout.
- `GEOCODING_NETWORK_ERROR`: the backend could not establish the HTTPS request; check DNS, proxy, firewall, and outbound access.
- `GEOCODING_REQUEST_DENIED`: check that Geocoding API is enabled, billing is active, and the server key's API/application restrictions permit this backend.
- `GEOCODING_RATE_LIMITED` or `GEOCODING_DAILY_LIMIT`: check quota and billing limits.
- `no_results`: Google accepted the request but found no matching address.
- `GEOCODING_HTTP_CLIENT_ERROR`, `GEOCODING_HTTP_SERVER_ERROR`, or `GEOCODING_UPSTREAM_ERROR`: Google returned another HTTP or service failure.

## Android Key

1. Open `frontend/android/local.properties`. Keep its existing `sdk.dir` line.
2. Add the Android-restricted key locally:

   ```properties
   MAPS_API_KEY=YOUR_ANDROID_MAPS_API_KEY
   ```

3. Do not commit this file. The root `.gitignore` excludes every `android/local.properties` file.

The app-level Kotlin Gradle file reads `MAPS_API_KEY` from `local.properties` and supplies the `${MAPS_API_KEY}` manifest placeholder. `AndroidManifest.xml` uses the recommended `com.google.android.geo.API_KEY` metadata name. It also declares foreground coarse/fine location permissions; no background-location permission is requested.

Enable **Maps SDK for Android** for this key. Restrict it to Android apps using the JimatMY package name and the correct debug/release SHA-1 certificate fingerprints.

Run on an emulator or connected device:

```powershell
cd frontend
flutter run -d <android-device-id>
```

The Android emulator reaches the local API at `http://10.0.2.2:3000/api`.

## Web Key

Enable **Maps JavaScript API** for the Web key. Restrict it to HTTP referrers used for local development and the eventual deployed site. The key is supplied at build/run time and is not stored in source:

```powershell
cd frontend
flutter run -d chrome --dart-define=GOOGLE_MAPS_WEB_API_KEY=YOUR_WEB_MAPS_API_KEY
```

To override the API server at the same time:

```powershell
flutter run -d chrome --dart-define=GOOGLE_MAPS_WEB_API_KEY=YOUR_WEB_MAPS_API_KEY --dart-define=API_BASE_URL=http://localhost:3000/api
```

Browser geolocation requires a secure context. `localhost` is accepted for local development; deployed builds must use HTTPS. The app requests location only after **Use my location** is pressed.

The Web loader rejects an empty build-time key, inserts the Maps JavaScript script once, reuses an existing script, and reports script, authorization, and map-creation timeout failures in the map panel. If Google displays an authorization warning, verify that **Maps JavaScript API** is enabled, billing is active, and the key's Web referrer restrictions include the exact local or deployed origin. Do not add a second Maps script to `web/index.html`.

## Verification

1. Start the backend with `npm start` from `backend`.
2. Open Home and select the store icon to enter Nearby Stores.
3. Verify official premise search, state/district filters, reset, and load-more.
4. Press **Use my location**, respond to the browser or Android permission prompt, and verify the denied/service-disabled messages as applicable.
5. Confirm Nearby initially displays 10 stores globally ordered by distance from the fresh active coordinate pool. Opening the screen must make no Geocoding requests.
6. Press **See 5 more stores** once and confirm exactly five additional ranked records are loaded. Scrolling and widget rebuilds must not duplicate API requests.
7. Open one unresolved premise. Verify Store Detail performs only its required lookup, then displays either one precise transient marker or a clearly labelled general-area result without asking for confirmation. Google Maps attribution must remain visible.
8. Press **Navigate** only after a precise result succeeds. The action opens the standard Google Maps directions URL after the tap. Approximate results must offer store search instead of directions or distance.
9. A missing or invalid Maps or Geocoding key should show a configuration error. Check restrictions, enabled APIs, billing status, and logs without sharing any key.

PriceCatcher does not provide latitude or longitude. JimatMY stores separately sourced, validated location metadata only in the existing nullable premise columns and expires shared Google latitude/longitude values after 29 days. Distance calculations never use missing, stale, invalid, or `(0, 0)` coordinates.
