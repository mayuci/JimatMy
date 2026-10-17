# JimatMY Demo Script

Use a running PostgreSQL database, backend, and Flutter app. Do not display `.env`, API keys, database credentials, or JWT secrets during the demo.

## 1. Public grocery browsing

1. Open Home and search `ayam`.
2. Select `AYAM BERSIH - STANDARD` (item code `1`).
3. Show the item unit/category, latest imported premise prices, and the `Compare prices` and `View price trend` actions.

Expected result: real PriceCatcher data loads without login. Grocery browsing hides prepared-food categories by default.

## 2. Comparison and trend

1. Open `Compare prices` for item `1`.
2. Show the unfiltered result, then choose `Selangor` or `W.P. Kuala Lumpur`.
3. Point out the cheapest premise and the difference from the highest currently shown price.
4. Return to Item Detail and open `View price trend`.
5. Show `3 Months`, then `All Available`.

Expected result: item `1` has many premise prices, a visible cheapest option, and daily history from 2026-05-02 through 2026-08-01 in the current imported database.

## 3. Account and planner

1. Open Profile and choose `Create an account`.
2. Use a presentation-only account and a strong password. Never display the password.
3. Open Planner and create `Demo weekly groceries`.
4. Add `AYAM BERSIH - STANDARD`, set quantity to `2`, and mark it complete.
5. Set a monthly budget below the estimated total, such as RM 10.

Expected result: the list, quantity, estimated total, and obvious over-budget warning belong to the logged-in account.

## 4. Favourites and history

1. Return to item `1` and tap `Add to favourites`.
2. Open Profile and show the Favourites count and item.
3. Show Recent activity containing the viewed item.
4. Log out and show the login-required state in Profile and Planner.

Expected result: public browsing remains available while authenticated features are hidden behind login.

## 5. Nearby stores

1. From Home, open Nearby stores and search `99 SPEED MART`.
2. Open the official Seputeh / W.P. Kuala Lumpur premise example, code `21238`.
3. Show the full official address and the unavailable-coordinate state.
4. If restricted Maps keys are configured, demonstrate the map using a premise with official coordinates; otherwise explain that PriceCatcher does not supply coordinates and the app does not invent them.

Expected result: official premise data is visible, no fabricated distance or marker appears, and selected-store geocoding remains user initiated only.

## 6. Closing checks

Mention that the app uses official PriceCatcher CSV data, PostgreSQL, a Node.js/Express API, Flutter, authenticated per-user planner ownership, and no cached or bulk-geocoded locations.
