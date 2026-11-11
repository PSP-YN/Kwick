# NexHelp — Trust-First Home Services Marketplace

NexHelp is a trust-first home-services marketplace connecting customers with local plumbing and electrical professionals. The initial pilot is planned for HSR Layout and Koramangala, Bengaluru South (560102).

## System components

1. **Flutter mobile application (`lib/`):** Customer and service-provider experiences in one Android/iOS codebase.
2. **Supabase and PostgreSQL (`supabase/`):** Authentication, RLS-protected data, transactional booking and assignment workflows, and private storage.
3. **Operations console (`admin/`):** Protected Next.js dashboard for provider verification, manual dispatch, request tracking, and disputes.
4. **NexHelp Intelligence (`supabase/functions/diagnose-service/`):** Optional Gemini-powered issue triage. Output is advisory; it cannot book, price, or dispatch.
5. **Public landing page (`landing/`):** Responsive static website, separate from the authenticated operations console.

> **Release status:** Automated tests and build jobs run in GitHub Actions. Check the latest workflow for the exact branch/commit before relying on a result. A successful CI build is not proof of a live backend, a signed production binary, or an operational service area. See [REMAINING_STEPS.md](REMAINING_STEPS.md).

## Product capabilities

- Customer and provider workflows in one mobile app.
- Plumbing and electrical service requests for the planned Bengaluru South pilot.
- Optional issue triage with category suggestions, urgency, safety notes, and follow-up questions.
- Customer review of AI suggestions; no silent booking changes.
- Provider verification and assignment constraints enforced by the database.
- Operations dashboard backed by live database queries, not fabricated metrics.
- RLS, least-privilege grants, private document storage, and server-side AI secrets.

## Repository layout

```
nexhelp/
├── android/              # Android shell and release signing configuration
├── ios/                  # iOS Runner
├── lib/                  # Flutter application
├── test/                 # Flutter tests
├── admin/                # Next.js operations console
├── landing/              # Public static website
├── supabase/             # Migrations, Edge Functions, database tests
└── docs/                 # Architecture, security, release and hackathon docs
```

## Prerequisites

- Flutter 3.44+ / Dart 3.12+
- Java 17
- Node.js 22+
- Supabase CLI 2.90+
- Docker Engine for local Supabase

## Local development

### 1. Start the local backend

```bash
supabase start
supabase db reset
```

Copy the local Supabase API URL and anon key from `supabase status`. For Android Emulator, use `http://10.0.2.2:54321` as the API URL; for iOS Simulator use `http://127.0.0.1:54321`.

### 2. Run the Flutter app

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=http://10.0.2.2:54321 \
  --dart-define=SUPABASE_ANON_KEY=<local-anon-key>
```

Local HTTP is accepted only in non-release builds. Production builds require an HTTPS hosted Supabase project URL and a real public anon/publishable key. If configuration is missing or invalid, the app shows a setup screen instead of crashing or silently using localhost.

### 3. Validate Flutter and database

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
./supabase/tests/run_tests.sh
```

### 4. Run the operations console

```bash
cd admin
npm ci
npm run lint
npm run dev
```

Configure `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` before connecting it to a real backend.

### 5. Preview the public landing page

```bash
cd landing
python3 -m http.server 4173
```

Open `http://localhost:4173`. Validate its structure and local links with:

```bash
node landing/validate.mjs
```

## Android builds

### CI debug APK

Every successful GitHub Actions run on the feature branch uploads `nexhelp-android-debug-apk` as a 14-day artifact. This is a test build, not a production-signed release and not connected to a live backend unless configured with actual project values.

### Signed production release

The repository includes a gated workflow at `.github/workflows/android-release.yml`. Before running it, configure these GitHub Actions secrets:

- `SUPABASE_URL` — the dedicated NexHelp HTTPS project URL.
- `SUPABASE_ANON_KEY` — the public anon/publishable key (never a service-role key).
- `ANDROID_KEYSTORE_BASE64` — base64-encoded private upload keystore.
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

The workflow validates the secrets, creates temporary signing files, runs Flutter format/analyze/tests, and builds a signed APK and AAB. Temporary signing material is removed at the end of the job. Never commit a keystore or `android/key.properties`.

## Deployment documentation

- [Production launch checklist](REMAINING_STEPS.md)
- [Public landing deployment](landing/README.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Security and access control](docs/SECURITY.md)
- [Database schema and invariants](docs/DATABASE.md)
- [AI triage safety and privacy](docs/AI_DIAGNOSIS.md)
- [Release guide](docs/RELEASE.md)
- [Operations runbook](docs/OPERATIONS.md)
- [HackGlobal submission brief](HACKGLOBAL_SUBMISSION.md)
- [Pitch deck prompt](docs/HACKGLOBAL_PITCH_DECK_PROMPT.md)
- [Demo video script](docs/HACKGLOBAL_DEMO_SCRIPT.md)

## Project documentation

- [Contributing](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security policy](SECURITY.md)
- [Changelog](CHANGELOG.md)
- [License](LICENSE)
- [Copyright](COPYRIGHT.md)
