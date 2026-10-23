# NexHelp — Production-Ready Home Services Marketplace

NexHelp is a curated, trust-first home-services marketplace connecting customers with verified local service professionals (initial pilot: Plumbing and Electrical in Bengaluru, Karnataka, India).

The system consists of:
1. **Flutter Mobile Application (`lib/`):** A single codebase providing role-aware customer and service provider experiences.
2. **PostgreSQL & Supabase (`supabase/`):** Authoritative backend engine with Row-Level Security (RLS), atomic stored procedures (`SECURITY DEFINER`), and private file storage.
3. **Internal Operations Dashboard (`admin/`):** A protected Next.js web application for manual provider verification, assignment dispatch, order tracking, and dispute management.

---

## Architecture Summary

```
nexhelp/
├── android/              # Android native shell & manifest
├── ios/                  # iOS Runner & configuration
├── lib/                  # Flutter application
│   ├── main.dart         # Entry point
│   ├── app.dart          # Root widget & routing
│   ├── core/             # Theme, routing, validation, error handling
│   ├── shared/           # Models, UI widgets, API clients
│   └── features/         # Auth, profiles, customer, provider, support
├── admin/                # Next.js TypeScript internal operations dashboard
├── supabase/             # PostgreSQL migrations, RLS policies, DB tests
├── test/                 # Flutter unit & widget tests
└── docs/                 # Architectural specifications, ADRs, audit
```

---

## Prerequisites

- **Flutter SDK:** 3.44.0+ (Dart 3.12.0+)
- **Java JDK:** OpenJDK 17
- **Node.js:** v20+ / v24+
- **Supabase CLI:** v2.90.0+
- **Docker:** Engine active for local Supabase emulator

---

## Local Development & Setup

### 1. Environment Configuration
Copy the template and configure your local keys:
```bash
cp .env.example .env
```

### 2. Supabase Backend
Start the local Supabase emulator and apply migrations:
```bash
supabase start
supabase db reset
```

### 3. Flutter Mobile Application
Install dependencies, analyze code, and run tests:
```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```
To run on a connected device or emulator:
```bash
flutter run
```

### 4. Admin Operations Dashboard
```bash
cd admin
npm install
npm run lint
npm run dev
```
Access the dashboard at `http://localhost:3000`.

---

## Testing Commands

| Component | Command |
| :--- | :--- |
| **Flutter Static Analysis** | `flutter analyze` |
| **Flutter Unit & Widget Tests**| `flutter test` |
| **Flutter Formatting Check** | `dart format --output=none --set-exit-if-changed .` |
| **Admin Lint & Typecheck** | `npm --prefix admin run lint && npm --prefix admin run build` |
| **Database Migrations & RLS** | `supabase db reset && supabase test db` |

---

## Documentation Index

- [Repository & Environment Audit](docs/PROJECT_AUDIT.md)
- [System Architecture](docs/ARCHITECTURE.md)
- [Implementation Plan & Phase Gates](docs/IMPLEMENTATION_PLAN.md)
- [Architectural Decisions Log (ADR)](docs/DECISIONS.md)
- [Known Issues & External Setup](docs/KNOWN_ISSUES.md)
- [Database Schema & Invariants](docs/DATABASE.md)
- [Security & Access Control](docs/SECURITY.md)
- [Operations & Pilot Runbook](docs/OPERATIONS.md)
