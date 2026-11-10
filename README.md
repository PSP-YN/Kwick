# NexHelp — Trust-First Home Services Marketplace

NexHelp is a curated, trust-first home-services marketplace connecting customers with verified local service professionals (initial pilot: Plumbing and Electrical in Bengaluru, Karnataka, India).

The system consists of:
1. **Flutter Mobile Application (`lib/`):** A single codebase providing role-aware customer and service provider experiences.
2. **PostgreSQL & Supabase (`supabase/`):** Authoritative backend engine with Row-Level Security (RLS), atomic stored procedures (`SECURITY DEFINER`), and private file storage.
3. **Internal Operations Dashboard (`admin/`):** A protected Next.js web application for manual provider verification, assignment dispatch, order tracking, and dispute management.
4. **NexHelp Intelligence (`supabase/functions/diagnose-service/`):** An authenticated Gemini-powered issue-triage function that returns structured, advisory guidance before a booking is submitted.

> **Verification status:** Automated Flutter, admin, and PostgreSQL test suites are included in this repository. Their current results must be confirmed by CI for the commit being evaluated; this README does not imply that unexecuted tests have passed. Production launch also requires the external configuration listed in **[REMAINING_STEPS.md](REMAINING_STEPS.md)**.

---

## Product Capabilities

- Customer and provider experiences in one Flutter application.
- Plumbing and electrical service booking for the Bengaluru South pilot.
- AI-assisted issue triage with urgency, safety alerts, follow-up questions, and dispatcher notes. AI is optional; customers can book without it.
- Verified-provider onboarding, availability controls, and transactional assignment lifecycle.
- Protected operations console with live database metrics, provider verification, dispatch, and audit-aware overrides.
- Row-level security, least-privilege column grants, server-side AI secrets, and a private AI usage quota log.

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
- **Node.js:** v22+
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
| **Database Migrations & RLS** | `./supabase/tests/run_tests.sh` or `supabase test db` |

---

## Documentation Index

- **[Production Launch Checklist (What's Left To Do)](REMAINING_STEPS.md)**
- [Repository & Environment Audit](docs/PROJECT_AUDIT.md)
- [System Architecture](docs/ARCHITECTURE.md)
- [Implementation Plan & Phase Gates](docs/IMPLEMENTATION_PLAN.md)
- [Deployment & Release Guide](docs/RELEASE.md)
- [Architectural Decisions Log (ADR)](docs/DECISIONS.md)
- [Known Issues & External Setup](docs/KNOWN_ISSUES.md)
- [Database Schema & Invariants](docs/DATABASE.md)
- [NexHelp Intelligence — AI Triage, Safety & Privacy](docs/AI_DIAGNOSIS.md)
- [HackGlobal 2026 Submission Brief & Demo Plan](HACKGLOBAL_SUBMISSION.md)
- [HackGlobal Pitch Deck Prompt](docs/HACKGLOBAL_PITCH_DECK_PROMPT.md)
- [HackGlobal Demo Video Script](docs/HACKGLOBAL_DEMO_SCRIPT.md)
- [Security & Access Control](docs/SECURITY.md)
- [Operations & Pilot Runbook](docs/OPERATIONS.md)


## Project documentation

- [Contributing](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security policy](SECURITY.md)
- [Changelog](CHANGELOG.md)
- [License](LICENSE)
- [Copyright and ownership](COPYRIGHT.md)
- [Project documentation](docs/)
