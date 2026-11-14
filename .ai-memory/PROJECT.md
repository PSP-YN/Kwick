# Project overview
- **Purpose:** Production-ready home-services marketplace (Plumbing, Electrical) in Bengaluru pilot area.
- **Stack detected:** Flutter 3.44.0 (Dart 3.12.0) mobile app, PostgreSQL + Supabase backend, Next.js (TypeScript) admin dashboard.
- **Libraries/services detected:** Riverpod, GoRouter, Supabase Flutter, Flutter Secure Storage, FCM, Tailwind CSS.
- **Package manager:** `flutter pub` (mobile) / `npm` (admin dashboard)
- **Entry points:** `lib/main.dart` (mobile), `admin/src/app/page.tsx` (admin web), `supabase/migrations/` (database)
- **Users and environments:** Customers (homeowners, tenants), Service Providers (plumbers, electricians), Kwick Dispatch Operators (internal admin). Local (Docker/Supabase emulator), Staging, Production.

## Commands
- Flutter analyze: `flutter analyze`
- Flutter test: `flutter test`
- Flutter format: `dart format --output=none --set-exit-if-changed .`
- Admin lint & build: `npm --prefix admin run lint && npm --prefix admin run build`
- Supabase migrations: `supabase db reset`

## Structure
- `lib/`: Flutter client (core, shared, features: auth, profiles, customer, provider, support)
- `admin/`: Protected operations dashboard (Next.js TypeScript)
- `supabase/`: Migrations, RLS policies, PostgreSQL RPC functions, DB tests
- `test/`: Flutter unit and widget tests
- `docs/`: Technical specifications, ADRs, audit, runbooks

## Conventions and constraints
- Integer paise (`BIGINT`) for all prices.
- PostgreSQL is authoritative for state and permissions (RLS on all tables).
- One active assignment per request invariant enforced via partial unique index.
- Clean feature architecture in Flutter with immutable state models.
