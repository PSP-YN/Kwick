# Kwick — Local Home Services Marketplace

Kwick connects customers with reviewed local service professionals. The product ships as two separately installable mobile apps backed by one shared platform:

- **Kwick** — customer discovery, booking, quote confirmation, order tracking and reviews.
- **Kwick Partner** — provider onboarding, private verification-document upload, availability, job handling and provider-owned pricing.

The initial seeded service area is HSR Layout, Bengaluru (560102). Plumbing and electrical are the only active service categories in the current pilot configuration. The target is 100 customers and 30 onboarded service partners, with a 2–3-neighbourhood launch; these are targets, not achieved metrics. Additional areas must not be advertised or activated until partner coverage is verified and configured.

## System components

1. **Customer app:** Flutter entrypoint `lib/main_customer.dart`; Android ID `com.kwick.customer`; iOS scheme `customer`.
2. **Partner app:** Flutter entrypoint `lib/main_provider.dart`; Android ID `com.kwick.provider`; iOS scheme `provider`.
3. **Shared mobile domain:** Flutter/Riverpod, shared auth/backend models, feature modules, role-locked routing and a common graphite/saffron brand system.
4. **Backend:** Supabase Auth, PostgreSQL with RLS, transactional RPCs, private Storage and Edge Functions.
5. **Operations console:** Next.js dashboard for provider verification, manual dispatch, disputes, fixed-price review and negotiated commission terms.
6. **Public landing page:** Static site in `landing/`; it must describe only currently configured coverage and services.
7. **Optional AI triage:** `supabase/functions/diagnose-service/`; advisory only, never creates bookings, sets prices or dispatches providers.

> **Status:** This is a pre-launch product build. A passing local build or database test is not proof of a live service, verified provider supply, million-user capacity or a production payment/settlement flow.

## Product and commercial rules

- Customer and partner apps have separate app IDs, entrypoints and role-locked route sets.
- Provider documents are stored in a private bucket. Uploading a document does not approve the provider; an authorized operator must review it.
- Do not collect Aadhaar biometrics, full Aadhaar numbers or Aadhaar e-KYC payloads. Confirm accepted alternative identity documents with legal counsel.
- Provider pricing is either a job-specific quote or an agreed fixed price. Fixed prices are customer-visible only after admin approval.
- Platform commission is a negotiated percentage per provider and service category, stored in basis points. No default rate is assumed; active terms require recorded provider agreement and admin approval.
- No monthly partner subscription is charged during the pilot. Commission recording is not payment collection or settlement; those flows are not yet implemented.
- All financial values are stored in integer paise. Provider commission rates use integer basis points (100 bps = 1%).

## Repository layout

```text
Kwick/
├── android/              # Customer/provider Android flavors
├── ios/                  # Customer/provider Xcode schemes
├── lib/                  # Shared Flutter source + two app entrypoints
├── assets/branding/      # Supplied Kwick logo assets
├── test/                 # Flutter tests
├── admin/                # Next.js operations console
├── landing/              # Public static website
├── supabase/             # Migrations, Edge Functions, database tests
├── scripts/load/         # Staging k6 smoke/load test
├── scripts/backup/       # Encrypted Supabase logical backup/export
└── docs/                 # Architecture, launch, commercial and scale plans
```

## Prerequisites

- Flutter 3.44+ / Dart 3.12+
- Java 17
- Node.js 22+
- Supabase CLI
- Docker Engine for isolated PostgreSQL database tests

## Local development

### 1. Start a local backend

```bash
supabase start
supabase db reset
```

Copy the local Supabase API URL and public anon key from `supabase status`. For Android Emulator use `http://10.0.2.2:54321`; for iOS Simulator use `http://127.0.0.1:54321`.

### 2. Run the customer app

```bash
flutter pub get
flutter run --flavor customer -t lib/main_customer.dart \
  --dart-define=SUPABASE_URL=http://10.0.2.2:54321 \
  --dart-define=SUPABASE_ANON_KEY=<local-anon-key>
```

### 3. Run the partner app

```bash
flutter run --flavor provider -t lib/main_provider.dart \
  --dart-define=SUPABASE_URL=http://10.0.2.2:54321 \
  --dart-define=SUPABASE_ANON_KEY=<local-anon-key>
```

Release builds require an HTTPS Supabase URL and a real public anon/publishable key. Never embed a service-role key or Gemini API key in either mobile app.

### 4. Validate mobile and database code

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
./supabase/tests/run_tests.sh
```

### 5. Run the operations console

```bash
cd admin
npm ci
npm run lint
npm run dev
```

Configure `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` before connecting it to a backend. Admin access requires an authorized operator session with TOTP/AAL2.

### 6. Preview the public landing page

```bash
cd landing
python3 -m http.server 4173
node validate.mjs
```

Open `http://localhost:4173` and validate responsive layout, accessibility and truthful coverage copy.

## Android build commands

```bash
# Customer APK and Play Store bundle
flutter build apk --release --flavor customer -t lib/main_customer.dart \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<public-key>
flutter build appbundle --release --flavor customer -t lib/main_customer.dart \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<public-key>

# Partner APK and Play Store bundle
flutter build apk --release --flavor provider -t lib/main_provider.dart \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<public-key>
flutter build appbundle --release --flavor provider -t lib/main_provider.dart \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<public-key>
```

Android package IDs are `com.kwick.customer` and `com.kwick.provider`. Both builds use the same private upload keystore but have independent app identities. Keep the keystore and passwords in a secure password manager/offline backup; never commit them.

## iOS

Shared Xcode schemes are `customer` and `provider`. Build with:

```bash
flutter build ios --flavor customer -t lib/main_customer.dart
flutter build ios --flavor provider -t lib/main_provider.dart
```

The project is developed on Linux; Xcode compilation, signing, provisioning and TestFlight acceptance must be verified on a macOS runner before claiming iOS release readiness.

## Documentation

- [Latest team decisions (14 Nov 2026)](docs/TEAM_DECISIONS_2026-11-14.md)
- [Launch playbook](docs/KWICK_LAUNCH_PLAYBOOK.md)
- [Commercial model and cost accounting](docs/COMMERCIAL_MODEL.md)
- [Provider verification procedure](docs/PROVIDER_VERIFICATION.md)
- [Scale readiness and capacity plan](docs/SCALE_READINESS.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Security and access control](docs/SECURITY.md)
- [Production security, backup and recovery operations](docs/PRODUCTION_SECURITY_OPERATIONS.md)
- [Database schema and invariants](docs/DATABASE.md)
- [AI triage safety and privacy](docs/AI_DIAGNOSIS.md)
- [Release guide](docs/RELEASE.md)
- [Operations runbook](docs/OPERATIONS.md)
- [Contributing](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security policy](SECURITY.md)
- [License](LICENSE)
