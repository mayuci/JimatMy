# JimatMY Database

The PostgreSQL schema is divided into nine dependency-ordered migrations:

1. `001_create_users.sql` creates users and user preferences and enables UUID generation.
2. `002_create_pricecatcher_reference_data.sql` creates the PriceCatcher item and premise lookups and enables trigram item-name search.
3. `003_create_price_transactions.sql` creates repeatable PriceCatcher price records.
4. `004_create_shopping_and_budget.sql` creates shopping lists, list items, and budgets.
5. `005_create_user_features.sql` creates favourites and search history.
6. `006_add_user_avatars.sql` adds safe avatar source metadata to existing users.
7. `007_add_recent_item_views.sql` links recent views to stable PriceCatcher item codes and makes repeated views idempotent.
8. `008_add_premise_coordinate_cache.sql` adds policy-expiring coordinate-cache metadata for true nearest-premise queries.
9. `009_add_password_reset.sql` adds single-use password reset codes stored as server-side HMAC hashes.

The PostgreSQL role running the migrations must be permitted to enable the `pgcrypto` and `pg_trgm` extensions.

## Create the database

Run from PowerShell or another terminal with `psql` available:

```powershell
psql -U postgres -d postgres -c "CREATE DATABASE jimatmy_db;"
```

## Run the migrations

Run from the repository root, in order:

```powershell
psql -U postgres -d jimatmy_db -v ON_ERROR_STOP=1 -f database/migrations/001_create_users.sql
psql -U postgres -d jimatmy_db -v ON_ERROR_STOP=1 -f database/migrations/002_create_pricecatcher_reference_data.sql
psql -U postgres -d jimatmy_db -v ON_ERROR_STOP=1 -f database/migrations/003_create_price_transactions.sql
psql -U postgres -d jimatmy_db -v ON_ERROR_STOP=1 -f database/migrations/004_create_shopping_and_budget.sql
psql -U postgres -d jimatmy_db -v ON_ERROR_STOP=1 -f database/migrations/005_create_user_features.sql
psql -U postgres -d jimatmy_db -v ON_ERROR_STOP=1 -f database/migrations/006_add_user_avatars.sql
psql -U postgres -d jimatmy_db -v ON_ERROR_STOP=1 -f database/migrations/007_add_recent_item_views.sql
psql -U postgres -d jimatmy_db -v ON_ERROR_STOP=1 -f database/migrations/008_add_premise_coordinate_cache.sql
psql -U postgres -d jimatmy_db -v ON_ERROR_STOP=1 -f database/migrations/009_add_password_reset.sql
```

Add `-h localhost -p 5432` if the PostgreSQL connection defaults do not match the local server. These migrations create schema only and contain no sample data.

## Key relationships

```text
users
  |-- user_preferences
  |-- shopping_lists -- shopping_list_items -- items
  |-- budgets (optionally linked to a shopping list)
  |-- favorite_items -- items
  |-- favorite_premises -- premises
  `-- search_history -- items

items -- price_transactions -- premises
```

`items.item_code` and `premises.premise_code` are the PriceCatcher source keys. Application-owned tables use UUID primary keys, while imported transactions use a `BIGSERIAL` primary key and a composite unique constraint for repeatable imports.
