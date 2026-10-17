# JimatMY API

Base URL for local development: `http://localhost:3000/api`

Successful responses use `{ "success": true, "data": ... }`. Errors use `{ "success": false, "error": { "code": "...", "message": "..." } }`.

## Authentication

Authentication uses short-lived Bearer JWTs. Generate a local secret manually, place it in `backend/.env`, and never commit it:

```powershell
[Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(48))
```

Then set `JWT_SECRET=<generated-value>` in `backend/.env`.

### `POST /auth/register`

Creates an account and returns an access token plus a safe user object. Names are trimmed; emails are lowercased. Passwords must contain 10 to 72 characters with uppercase, lowercase, and a number.

```json
{ "name": "Aina Rahman", "email": "aina@example.com", "password": "StrongPass9" }
```

### `POST /auth/login`

Returns the same token and safe-user shape. Invalid email/password combinations return `401 INVALID_CREDENTIALS` without identifying which field failed.

```json
{ "email": "aina@example.com", "password": "StrongPass9" }
```

Successful registration and login response:

```json
{
  "success": true,
  "data": {
    "token": "<JWT>",
    "user": {
      "userId": "00000000-0000-4000-8000-000000000000",
      "name": "Aina Rahman",
      "email": "aina@example.com",
      "createdAt": "2026-08-16T00:00:00.000Z",
      "updatedAt": "2026-08-16T00:00:00.000Z"
    }
  }
}
```

### `GET /auth/me`

Requires `Authorization: Bearer <token>` and returns the current safe user object.

### `PATCH /auth/me`

Requires a Bearer token and updates only the display name:

```json
{ "name": "Aina Z. Rahman" }
```

The same route selects or removes a built-in avatar with an allowlisted ID:

```json
{ "avatarType": "preset", "avatarValue": "basket_green" }
```

Use `{ "avatarType": "initial" }` to restore the initial-letter avatar. Safe user responses include `avatarType` (`initial`, `preset`, or `upload`) and a nullable `avatarValue`.

### `POST /auth/me/avatar`

Requires a Bearer token and one multipart field named `avatar`. JPEG, PNG, and WebP images up to 5 MB are accepted after file-signature validation. The response is the updated safe user object.

### `DELETE /auth/me/avatar`

Requires a Bearer token, removes the authenticated user's uploaded picture when applicable, and restores the initial-letter fallback.

Avatar files are stored under the server's dedicated ignored upload directory and served only through `/media/avatars/:filename`. This is appropriate for the assignment's single-server deployment; production deployments should use durable object storage.

### Authenticated User Features

The following endpoints require `Authorization: Bearer <token>` and always scope data to the authenticated user:

- `GET /auth/me/summary` returns `favoriteItemCount`, `historyCount`, and `shoppingListCount`.
- `GET /auth/me/favorites/items` lists the user's favourite items with one aggregated latest-lowest price and premise count where available.
- `GET /auth/me/favorites/items/:itemCode` returns `{ "itemCode": 1, "isFavorite": true }`.
- `PUT /auth/me/favorites/items/:itemCode` adds an item. Repeating the request is safe and returns `200` with `alreadyFavorite: true`.
- `DELETE /auth/me/favorites/items/:itemCode` removes an item and returns its removal status.
- `POST /auth/me/history` records a viewed product using `{ "itemCode": 1 }`. Repeated views update `lastViewedAt` instead of creating duplicates.
- `GET /auth/me/history` returns up to 50 recent products, newest first, with official item metadata.
- `DELETE /auth/me/history` clears the authenticated user's recent product views.

Public item detail remains available without login. When a user is logged in, Flutter records the stable item code after a successful detail load and can read or change favourites.

Tokens expire after one hour. Missing, malformed, invalid, expired, unsupported-format, and unknown-user tokens return safe `401` errors. Refresh tokens, password reset, email verification, and OAuth are outside this phase.

## Health

### `GET /health`

Checks whether the API is available and PostgreSQL is reachable.

```json
{
  "success": true,
  "data": { "api": "available", "database": "connected" }
}
```

## Items

### `GET /items`

Parameters:

- `q` - optional case-insensitive item-name search, up to 200 characters.
- `category` - optional grocery category key: `fresh-food`, `chicken`, `vegetables`, `fruits`, `eggs`, `meat`, `drinks`, `dry-goods`, `baby`, or `household`. `chicken` maps to the official `item_category = AYAM` field.
- `state` - optional official premise state; limits price availability and summaries to that state.
- `district` - optional official premise district; limits price availability and summaries to that district.
- `pricedOnly` - optional `true`/`false`; when true, returns only items with a current imported price in the selected location.
- `limit` - optional result count from 1 to 100; defaults to 20.
- `offset` - optional non-negative pagination offset; defaults to 0.
- `includePreparedFood` - optional `true`/`false`; defaults to `false` and excludes items whose official `item_group` is `MAKANAN SIAP MASAK`. `true` exposes all official items for data inspection.

Example: `GET /items?q=beras&limit=10&offset=0`

Default grocery filtering uses only the official `item_group` field. Rows where `UPPER(TRIM(item_group)) = 'MAKANAN SIAP MASAK'` are excluded. This filtering affects list/search only; direct item detail, comparison, and trend endpoints remain available by item code.

```json
{
  "success": true,
  "data": [
    {
      "itemCode": 1,
      "itemName": "Example item name from PriceCatcher",
      "unit": "1 kg",
      "itemGroup": "Example group",
      "itemCategory": "Example category",
      "lowestPrice": 8.99,
      "premiseCount": 12
    }
  ],
  "meta": { "total": 1, "limit": 10, "offset": 0 }
}
```

### `GET /items/:itemCode`

Returns one item and the latest imported price for each premise where it is available. `itemCode` must be a positive integer.

```json
{
  "success": true,
  "data": {
    "itemCode": 1,
    "itemName": "PriceCatcher item name",
    "unit": "1 kg",
    "itemGroup": "Group",
    "itemCategory": "Category",
    "latestPrices": [
      {
        "premiseCode": 100,
        "premiseName": "Premise name",
        "address": "Premise address",
        "state": "Selangor",
        "district": "Petaling Jaya",
        "price": 10.5,
        "recordDate": "2026-08-01"
      }
    ]
  }
}
```

### `GET /items/:itemCode/comparison`

Optional parameters `state` and `district` perform case-insensitive exact filtering. Results contain the latest imported price per premise and are ordered from cheapest to most expensive. `cheapestOption` is `null` when no matching price exists.

Example: `GET /items/1/comparison?state=Selangor&district=Petaling%20Jaya`

```json
{
  "success": true,
  "data": {
    "item": { "itemCode": 1, "itemName": "PriceCatcher item name" },
    "filters": { "state": "Selangor", "district": "Petaling Jaya" },
    "cheapestOption": {
      "premiseCode": 100,
      "premiseName": "Premise name",
      "price": 10.5,
      "recordDate": "2026-08-01"
    },
    "prices": []
  }
}
```

### `GET /items/:itemCode/trends`

Optional `from` and `to` parameters use `YYYY-MM-DD`. The endpoint returns daily average, minimum, and maximum prices. A valid query with no matching observations returns `"trends": []`.

Example: `GET /items/1/trends?from=2026-08-01&to=2026-08-31`

```json
{
  "success": true,
  "data": {
    "item": { "itemCode": 1, "itemName": "PriceCatcher item name" },
    "filters": { "from": "2026-08-01", "to": "2026-08-31" },
    "trends": [
      {
        "recordDate": "2026-08-01",
        "averagePrice": 10.5,
        "minimumPrice": 9.5,
        "maximumPrice": 11.5
      }
    ]
  }
}
```

## Errors

Invalid parameters return HTTP `400`, unknown items return `404`, unknown routes return `404`, and unexpected server errors return `500`.

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "limit must be between 1 and 100"
  }
}
```

## Development Planner Ownership

Planner and budget routes require `Authorization: Bearer <token>`. The authenticated user's `user_id` is resolved server-side and clients never send a user ID. Each account sees only its own shopping lists and budgets. Public item, premise, comparison, trend, and map-resolution routes remain available without login.

All owned shopping lists are currently considered active because the schema has no archive field. Estimated totals use the cheapest latest imported premise price for each list item. Items without an imported price remain in the list with `null` estimates.

## Planner

### `GET /planner/overview`

Returns active lists, item counts, aggregate estimated spending, the current monthly budget, remaining budget, and `overBudget` status.

## Shopping Lists

### `GET /shopping-lists`

Requires a Bearer token and returns only the authenticated user's lists with `itemCount`, `completedItemCount`, `unavailableItemCount`, and `estimatedTotal`.

### `POST /shopping-lists`

```json
{ "name": "Weekly groceries" }
```

### `GET /shopping-lists/:listId`

Returns list details and items. Priced items include `bestPrice`, `estimatedLineTotal`, and `cheapestPremise`; unavailable prices return `null` and `availabilityStatus: "price_unavailable"`.

### `GET /shopping-lists/:listId/best-places`

Requires a Bearer token and list ownership. It compares 1-10 active (non-completed) items across premises using the latest price for each unique item and premise. Requested quantities come only from `shopping_list_items`; missing items are never priced as zero.

Query parameters:

| Parameter | Values | Default |
| --- | --- | --- |
| `coverage` | `all`, `complete`, `incomplete` | `all` |
| `sort` | `price_asc`, `price_desc`, `coverage` | `price_asc` |
| `state` | Exact imported state | none |
| `district` | Exact imported district | none |
| `maxTotal` | Positive RM amount, up to 2 decimals | none |
| `latitude` | Malaysian latitude; requires `longitude` | none |
| `longitude` | Malaysian longitude; requires `latitude` | none |
| `radiusKm` | `10`, `25`, or `50`; requires coordinates | none |
| `page` | Positive integer | `1` |
| `limit` | `1`-`50` | `20` |

When a location and radius are supplied, only premises with valid cached coordinates inside that radius are compared. No geocoding is triggered by this endpoint. Complete shops always rank before incomplete shops unless `coverage=incomplete`; basket total remains the primary ranking and distance breaks otherwise equal results. `maxTotal` applies only to complete basket totals, never an incomplete partial total. Invalid parameters return `400 VALIDATION_ERROR`.

```json
{
  "success": true,
  "data": {
    "listId": "uuid",
    "listName": "Weekly groceries",
    "itemCount": 2,
    "requestedItems": [
      {
        "itemCode": 1,
        "itemName": "AYAM BERSIH - STANDARD",
        "unit": "1 kg",
        "requestedQuantity": 1
      }
    ],
    "summary": {
      "totalPremises": 100,
      "completePremises": 12,
      "incompletePremises": 88,
      "lowestCompleteTotal": 10.85,
      "highestCompleteTotal": 15.40
    },
    "stores": [
      {
        "premiseCode": 10,
        "premiseName": "AEON BIG",
        "premiseType": "HYPERMARKET",
        "address": "JALAN SUBANG",
        "state": "Selangor",
        "district": "Subang Jaya",
        "coveredItemCount": 2,
        "totalItemCount": 2,
        "isComplete": true,
        "basketTotal": 10.85,
        "partialTotal": null,
        "latestPriceDate": "2026-07-31",
        "items": [
          {
            "itemCode": 1,
            "itemName": "AYAM BERSIH - STANDARD",
            "unit": "1 kg",
            "requestedQuantity": 1,
            "unitPrice": 7.95,
            "lineTotal": 7.95,
            "priceDate": "2026-07-31",
            "available": true
          }
        ],
        "missingItems": []
      }
    ],
    "twoStoreCombination": null,
    "pagination": {
      "page": 1,
      "limit": 20,
      "totalResults": 12,
      "totalPages": 1
    }
  }
}
```

Incomplete stores return `basketTotal: null`, a `partialTotal`, and explicit `missingItems`. The optional `twoStoreCombination` is returned only when two premises cover the complete basket and improve on the best complete single shop, or when no complete single shop exists.

### `PATCH /shopping-lists/:listId`

```json
{ "name": "Family groceries" }
```

### `DELETE /shopping-lists/:listId`

Deletes the owned list and its list items.

### `POST /shopping-lists/:listId/items`

```json
{ "itemCode": 1, "quantity": 2 }
```

Duplicate items return HTTP `409` with code `DUPLICATE_LIST_ITEM`.

### `PATCH /shopping-lists/:listId/items/:listItemId`

Supports either or both fields:

```json
{ "quantity": 3, "isChecked": true }
```

### `DELETE /shopping-lists/:listId/items/:listItemId`

Deletes the owned list item.

## Budget

### `GET /budget`

Requires a Bearer token and returns the authenticated user's current Malaysia-calendar monthly budget, planner estimate, remaining amount, and over-budget status.

### `PUT /budget`

Creates or updates one standalone monthly budget. The current schema has no budget-history table, so history is not generated.

```json
{ "month": "2026-08", "amount": 500.00 }
```

## Premises

### `GET /premises`

Returns official imported PriceCatcher premises. Parameters:

- `q` - optional case-insensitive premise-name or address search, up to 200 characters.
- `state` - optional case-insensitive exact state, up to 100 characters.
- `district` - optional case-insensitive exact district, up to 100 characters.
- `coordinatesOnly` - optional `true` or `false`; defaults to `false`.
- `limit` - optional result count from 1 to 100; defaults to 20.
- `offset` - optional non-negative pagination offset; defaults to 0.

`postcode` is extracted only when a five-digit postcode exists in the official address. Coordinates remain `null` unless they have been added to the existing nullable premise fields.

```json
{
  "success": true,
  "data": [
    {
      "premiseCode": 22063,
      "premiseName": "Official premise name",
      "address": "Official PriceCatcher address",
      "postcode": "47301",
      "premiseType": "Pasar Raya / Supermarket",
      "district": "Petaling Jaya",
      "state": "Selangor",
      "latitude": null,
      "longitude": null,
      "hasCoordinates": false
    }
  ],
  "meta": { "total": 1, "limit": 20, "offset": 0 }
}
```

### `GET /premises/nearby`

Returns imported PriceCatcher premises ordered by straight-line distance across
the complete fresh coordinate candidate pool before pagination. A premise does
not need price transactions, but it must have a valid current coordinate cache
entry to participate in distance ranking.
Parameters:

- `latitude` and `longitude` - required valid Malaysian origin coordinates.
- `q` - optional premise-name/address search.
- `state` and `district` - optional exact filters.
- `radiusKm` - optional radius from 0.1 to 200 km.
- `limit` - 1 to 50; the app requests 10 initially and five on load-more.
- `offset` - non-negative pagination offset.

Each premise includes `distanceKm` and `coordinateAccuracy`. The endpoint does
not call Google and never geocodes during a user request.

```json
{
  "success": true,
  "data": [
    {
      "premiseCode": 22063,
      "premiseName": "Official premise name",
      "address": "Official PriceCatcher address",
      "district": "Petaling Jaya",
      "state": "Selangor",
      "latitude": 3.1073,
      "longitude": 101.6067,
      "hasCoordinates": true,
      "distanceKm": 1.24,
      "coordinateAccuracy": "high"
    }
  ],
  "meta": { "total": 42, "limit": 10, "offset": 0 }
}
```

### `GET /premises/filters`

Returns real state and district values currently available in imported premises.

```json
{
  "success": true,
  "data": {
    "states": [
      { "state": "Selangor", "districts": ["Petaling Jaya", "Sepang"] }
    ]
  }
}
```

### `GET /premises/:premiseCode`

Returns one official premise. `premiseCode` must be a positive integer. Unknown codes return HTTP `404` with `PREMISE_NOT_FOUND`.

### `POST /premises/:premiseCode/resolve-location`

Performs one user-initiated, server-side Google Geocoding request for the selected official premise. The request body must be empty. It uses the premise name and official address, extracted postcode when available, district, state, and Malaysia with a Malaysia country restriction and regional bias.

The result is transient: it is not written to PostgreSQL, files, logs, or client storage. The endpoint performs no retries.

```json
{
  "success": true,
  "data": {
    "resolutionStatus": "resolved",
    "latitude": 3.1073,
    "longitude": 101.6067,
    "formattedAddress": "Resolved address, Malaysia",
    "matchConfidence": "high",
    "partialMatch": false,
    "locationType": "ROOFTOP"
  }
}
```

No match returns HTTP `200` with `resolutionStatus: "no_results"` and null location fields. Configuration, timeout, upstream, and quota failures use `GEOCODING_NOT_CONFIGURED`, `GEOCODING_CONFIGURATION_ERROR`, `GEOCODING_TIMEOUT`, `GEOCODING_UNAVAILABLE`, or `GEOCODING_RATE_LIMITED` as appropriate.

## Value Features

Existing item detail, comparison, favourite, and planner price objects include a backward-compatible `reliability` object with `latestRecordDate`, `ageDays`, `premiseCount`, `freshnessStatus`, and `coverageStatus`.

### Basket templates

- `GET /planner/templates` lists the four reviewed weekly baskets with real current estimates.
- `POST /planner/templates/:templateKey/create` creates an authenticated editable shopping list. Supported keys are `student`, `couple`, `family-4`, and `family-6`.


