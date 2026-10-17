# JimatMY Development Plan

This plan keeps the project realistic for a university group project and follows the current repository rule: do not build UI, API endpoints, database tables, authentication, or install packages until the team explicitly starts those phases.

## Recommended Build Order

1. Confirm setup, roles, Git workflow, and project milestones.
2. Design the PostgreSQL schema and ERD before writing migrations.
3. Import a small PriceCatcher sample dataset before attempting the full dataset.
4. Build the Express API foundation and connect it to PostgreSQL.
5. Build the Flutter foundation with theme, navigation, API connection, and shared models.
6. Deliver core modules in this order: search, price comparison, shopping lists, nearby premises, profile features.
7. Finish testing, documentation, screenshots, demo setup, and portfolio evidence.

## Do Not Build Yet

- Payment, vouchers, loyalty-card integrations, or checkout.
- Real-time crowd reporting or user-submitted prices.
- Complex machine learning recommendations.
- Admin dashboards beyond basic data verification needs.
- Multi-country support.
- Full production authentication before the core grocery comparison workflow works.
- Large-scale cloud deployment before the local demo is stable.

## Phase 1: Project Setup and Git Workflow

**Objective:** Establish a clean collaboration process before implementation begins.

**Exact deliverables:**
- Confirm Flutter, Node.js, npm, Git, and PostgreSQL CLI availability on each member's machine.
- Create team roles for mobile, backend, database, documentation, and testing.
- Define branch naming, pull request review rules, and commit message style.
- Add a short setup checklist to project notes or portfolio records.

**Dependencies:** Initial repository structure.

**Acceptance checks:**
- Every member can clone/open the project.
- Every member understands how to create a branch and submit work for review.
- No generated app, backend, database, or package files are added during planning.

**Suggested Git branch name:** `docs/project-workflow-plan`

**Suggested commit message:** `docs: add project workflow plan`

## Phase 2: PostgreSQL Database Design and Migrations

**Objective:** Design the database around products, premises, prices, shopping lists, users, favourites, and alerts.

**Exact deliverables:**
- ERD draft in `docs/erd/`.
- Table list with primary keys, foreign keys, indexes, and data types.
- Migration plan for core tables.
- Seed-data plan for local demo records.

**Dependencies:** Confirmed app requirements and PriceCatcher dataset fields.

**Acceptance checks:**
- ERD supports product search, price comparison, price history, shopping lists, nearby premises, and user saved items.
- Team can explain how PriceCatcher rows map into the database.
- Migration order is clear before any migration file is created.

**Suggested Git branch name:** `database/schema-design`

**Suggested commit message:** `docs: define database schema plan`

## Phase 3: PriceCatcher Sample-Data Import First, Then Full Import

**Objective:** Prove the import process safely with a small dataset before handling full PriceCatcher files.

**Exact deliverables:**
- Small sample dataset stored outside ignored raw-data paths or documented as manually downloaded.
- Import-field mapping document.
- Validation checklist for row counts, duplicate handling, missing values, date parsing, and price format.
- Full import strategy for batching, logging, and repeatable runs.

**Dependencies:** Database design and known PriceCatcher file format.

**Acceptance checks:**
- Sample import can be repeated without creating duplicate records.
- Invalid rows are reported clearly.
- Full import approach is documented before large files are used.

**Suggested Git branch name:** `data/pricecatcher-import-plan`

**Suggested commit message:** `docs: plan PriceCatcher import workflow`

## Phase 4: Express REST API Foundation

**Objective:** Prepare the backend structure for stable REST API development.

**Exact deliverables:**
- Backend setup plan for Express, environment configuration, database connection, logging, validation, and error handling.
- API route grouping plan for products, prices, premises, shopping lists, profile, favourites, history, and alerts.
- Draft API response format and error format.

**Dependencies:** Database schema plan and agreed backend conventions.

**Acceptance checks:**
- API foundation design supports all core modules.
- Environment variables are identified without committing secrets.
- No endpoint implementation starts until the foundation is approved.

**Suggested Git branch name:** `backend/api-foundation-plan`

**Suggested commit message:** `docs: outline backend api foundation`

## Phase 5: Flutter Application Foundation

**Objective:** Prepare the mobile app foundation before feature screens are added.

**Exact deliverables:**
- App architecture plan for theme, navigation, API client, shared models, loading states, error states, and reusable widgets.
- Folder structure proposal for screens, services, models, state, and widgets.
- API connection strategy for emulator, device, and demo environment.

**Dependencies:** Flutter availability and backend API response format.

**Acceptance checks:**
- Mobile foundation supports all core modules without duplicating API logic.
- App can switch API base URL by environment.
- Shared models match backend response shapes.

**Suggested Git branch name:** `mobile/app-foundation-plan`

**Suggested commit message:** `docs: plan Flutter app foundation`

## Phase 6: Core Module 1 - Product Search, Categories, Filters, Product Detail

**Objective:** Let users find grocery products and inspect product information.

**Exact deliverables:**
- Product search API and mobile search screen plan.
- Category and filter behaviour for product name, category, brand, location, and price range.
- Product detail plan showing latest prices and available premises.

**Dependencies:** Database tables, imported sample data, API foundation, Flutter foundation.

**Acceptance checks:**
- Users can search by product name.
- Filters return predictable results.
- Product detail clearly shows product identity and current price options.

**Suggested Git branch name:** `feature/product-search`

**Suggested commit message:** `feat: add product search module`

## Phase 7: Core Module 2 - Price Comparison, Cheapest Premise, Price Trends

**Objective:** Help users compare prices and identify cheaper shopping options.

**Exact deliverables:**
- Price comparison logic plan by product, premise, location, and date.
- Cheapest premise calculation plan.
- Price trend display plan using historical PriceCatcher records.

**Dependencies:** Product module, price records, premise records, date-aware queries.

**Acceptance checks:**
- Cheapest premise is calculated from valid recent prices.
- Price trend uses historical data, not only the latest price.
- Results explain date and premise context clearly.

**Suggested Git branch name:** `feature/price-comparison`

**Suggested commit message:** `feat: add price comparison module`

## Phase 8: Core Module 3 - Shopping Lists, Estimated Total, Budgets

**Objective:** Let users plan grocery spending before visiting a premise.

**Exact deliverables:**
- Shopping-list data model and API plan.
- Mobile list creation, edit, quantity, and remove-flow plan.
- Estimated total and budget comparison logic.

**Dependencies:** Product search, price comparison, user/session strategy.

**Acceptance checks:**
- Users can create and update a list.
- Estimated total updates when quantities change.
- Budget warning appears when estimated total exceeds budget.

**Suggested Git branch name:** `feature/shopping-lists`

**Suggested commit message:** `feat: add shopping list planning`

## Phase 9: Core Module 4 - Nearby Premises and Google Maps

**Objective:** Help users locate nearby stores and compare travel-aware shopping options.

**Exact deliverables:**
- Premise location data plan with latitude, longitude, address, and state/district.
- Google Maps integration plan for mobile.
- Nearby premise ranking plan using user location and available product prices.

**Dependencies:** Premise data, price comparison, mobile permission handling, Google Maps setup.

**Acceptance checks:**
- Nearby premise list can be produced from user location.
- Map markers match premise records.
- App handles denied location permission gracefully.

**Suggested Git branch name:** `feature/nearby-premises`

**Suggested commit message:** `feat: add nearby premises module`

## Phase 10: Core Module 5 - Profile, Favourites and History

**Objective:** Add personalisation after the main grocery comparison workflow is working.

**Exact deliverables:**
- Profile data plan.
- Favourite products and premises plan.
- Search/history tracking plan.

**Dependencies:** Product search, price comparison, shopping lists, authentication decision.

**Acceptance checks:**
- Users can save favourites.
- History improves repeat searches without exposing private data.
- Alerts have clear trigger rules and can be tested with sample data.

**Suggested Git branch name:** `feature/profile-alerts`

**Suggested commit message:** `feat: add profile favourites history and alerts`

## Phase 11: Testing, Screenshots, API Documentation, Deployment/Demo Preparation

**Objective:** Prepare the project for grading, demonstration, and handover.

**Exact deliverables:**
- Backend API tests for core routes.
- Import validation tests.
- Flutter smoke tests for main flows.
- API documentation in `docs/api/`.
- Screenshots in `docs/screenshots/`.
- Demo script covering search, compare, shopping list, map, and alerts.
- Deployment notes for local demo and optional hosted demo.

**Dependencies:** Completed core modules.

**Acceptance checks:**
- Demo can be run from a clean setup guide.
- API documentation matches implemented endpoints.
- Screenshots show each major module.
- Known limitations are documented honestly.

**Suggested Git branch name:** `docs/demo-preparation`

**Suggested commit message:** `docs: prepare testing api docs and demo evidence`

## Phase 12: Weekly Portfolio Evidence to Capture

**Objective:** Keep steady proof of progress for university assessment.

**Exact deliverables:**
- Weekly screenshots of implemented features.
- ERD and schema evolution notes.
- API request/response examples.
- Import logs or validation screenshots.
- Git commit history summary.
- Meeting notes with decisions and task ownership.
- Short reflection on problems solved and remaining risks.

**Dependencies:** Ongoing project work.

**Acceptance checks:**
- Every week has visible evidence in `docs/portfolio/`.
- Evidence connects directly to project requirements.
- Each team member has traceable contributions.

**Suggested Git branch name:** `docs/weekly-portfolio`

**Suggested commit message:** `docs: add weekly portfolio evidence`

## Short Summary

This file defines a dependency-ordered plan for JimatMY from setup through database design, data import, backend foundation, Flutter foundation, five core modules, testing, documentation, demo preparation, and weekly portfolio evidence. It also lists what should not be built yet to keep the university project focused and achievable.

The important changes to the plan:

Do sample PriceCatcher data first, then only import enough real records for a convincing demo.
Store core app data remotely in PostgreSQL; use shared_preferences locally for guest mode, preferences, recent search/history or cache. This directly supports the rubric’s local + remote data requirement.
Make every proposed module actually work and validate user input. Five polished modules score better than ten half-finished ones.
Google Maps + location permission is your strongest “mobile unique feature” for the originality criterion.
Capture screenshots and Git evidence as you build, but do not stop development for weekly-plan paperwork.