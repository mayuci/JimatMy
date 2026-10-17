# PriceCatcher Import

The importer streams official PriceCatcher CSV files from data.gov.my into PostgreSQL. It imports the complete item lookup, premises from selected states, and matching records from one monthly transaction file. Re-running the same command updates existing lookup and price rows without creating duplicates.

Official sources:

- Item lookup: `https://storage.data.gov.my/pricecatcher/lookup_item.csv`
- Premise lookup: `https://storage.data.gov.my/pricecatcher/lookup_premise.csv`
- Monthly transactions: `https://storage.data.gov.my/pricecatcher/pricecatcher_YYYY-MM.csv`

## Setup

Apply all migrations in `database/migrations/` before importing. Then install the three required packages:

```powershell
cd backend
npm install
```

Create the local environment file from the provided template and replace its placeholder password:

```powershell
Copy-Item .env.example .env
```

The importer reads `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`, and `PGSSL` from `backend/.env`. Credentials must not be committed.

## Limited test import

This imports both lookups and at most 100 matching transaction rows:

```powershell
npm run import:pricecatcher -- --month 2026-07 --states "W.P. Kuala Lumpur,Selangor" --limit 100
```

## Normal filtered monthly import

Omit `--limit` to stream all matching rows for the selected month:

```powershell
npm run import:pricecatcher -- --month 2026-07 --states "W.P. Kuala Lumpur,Selangor"
```

`--month` is required. `--states` defaults to `W.P. Kuala Lumpur,Selangor`, and `--limit` accepts a positive integer. Invalid codes, dates, missing required lookup fields, and non-positive prices are logged and skipped. Rows for premises outside the selected states are ignored.
