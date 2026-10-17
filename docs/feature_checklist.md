# JimatMY Assignment Feature Checklist

| Requirement area | Implemented evidence |
| --- | --- |
| Project architecture | Flutter -> Express REST API -> PostgreSQL documented in README and API docs |
| Official data integration | Repeatable Item Lookup, Premise Lookup, and monthly Transactional Records importer |
| Grocery browsing | Search, pagination, grocery-focused default filtering, categories, and item detail |
| Price comparison | Latest premise prices, state/district filters, cheapest option, and savings difference |
| Price trends | Daily average/min/max chart, date ranges, summary metrics, and neutral trend label |
| Authentication | Register, login, JWT session restoration, logout, profile name update |
| Planner and budget | Authenticated lists, quantities, completion, estimates, budget, and over-budget state |
| Favourites/history | Per-user favourite items, recent activity, and profile summary counts |
| Nearby stores | Official premise search/filtering, location permission states, map configuration states |
| Geocoding policy | One user-initiated selected-store lookup, transient result, no caching or database write |
| Testing | Backend unit/verification scripts, Flutter widget/provider tests, analyzer and web build |
| Security evidence | Ignored `.env`, Android `local.properties`, secret config, raw datasets, and no committed key values |

Known scope limits: PriceCatcher does not provide coordinates for premises, so some stores can show address details without a map. Password reset, email verification, and OAuth are outside this prototype phase.
