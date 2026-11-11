# NexHelp Deployment & Release Guide

## 1. Release scope and current boundaries

- **Planned pilot:** HSR Layout and Koramangala, Bengaluru South (560102).
- **Initial trades:** Plumbing and electrical.
- **Mobile:** Flutter Android app; iOS project files exist but this repository's current CI does not compile an iOS binary.
- **Backend:** Supabase PostgreSQL 17, Auth, private Storage, and the optional diagnosis Edge Function.
- **Operations:** Protected Next.js console in `admin/`.
- **Public website:** Static responsive site in `landing/`.

Do not describe NexHelp as live until the dedicated backend, operations console, provider verification process, and customer support process are operational.

## 2. Supabase production deployment

### 2.1 Provision a dedicated project

Create a new project named `NexHelp` in `ap-south-1` (Mumbai). Do not reuse CareerOS or JanaSetu. The connected Supabase organization currently has a two-project free-tier limit; if project creation is blocked, resolve the project quota before continuing. Do not delete or upgrade another project without an explicit decision.

Record the project URL, public anon/publishable key, database password, and project reference in an approved secrets manager. Never commit them.

### 2.2 Apply database migrations

From the repository root:

```bash
supabase login
supabase link --project-ref <nexhelp-project-ref>
supabase db push
```

The repository currently contains 10 ordered migrations. After deployment, verify:
- Every application table has RLS enabled and expected policies.
- Private buckets `provider-documents` and `service-request-photos` exist.
- `reserve_ai_diagnosis_slot` is executable only by `service_role`.
- The first-admin bootstrap procedure is restricted and used only for the designated operator.
- No sample/demo records are presented as real customer or provider activity.

Run database advisors and inspect all warnings before onboarding real users.

### 2.3 Configure Auth and Storage

The current mobile authentication flow uses email/password; registration also collects a phone number as profile information. SMS OTP is not implemented as the active sign-in flow. Configure production email delivery, password policy, redirect URLs, abuse protection, and account recovery before launch.

Provider identity and trade-document upload is not yet available in the mobile onboarding flow. For the initial pilot, use a documented manual verification process with secure access controls before approving any provider. Do not approve a provider based only on self-declared details.

Keep both storage buckets private. Verify upload, read, signed URL expiry, and unauthorized-access behavior with separate customer, provider, and admin accounts.

### 2.4 Deploy the AI Edge Function

Set the Gemini secret server-side only:

```bash
supabase secrets set GEMINI_API_KEY=<secret>
supabase secrets set GEMINI_MODEL=<supported-model-id>
supabase functions deploy diagnose-service
```

Use a model identifier confirmed against the current Gemini API account. Do not put the Gemini key in Flutter, Next.js public environment variables, GitHub source, or the landing page. Test quota enforcement, invalid output handling, timeout behavior, and the no-AI booking path.

## 3. Android release

### 3.1 Generate and protect the upload keystore

Generate the key once and back it up securely:

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -alias nexhelp-upload -keyalg RSA -keysize 2048 -validity 10000
```

Create `android/key.properties` from `android/key.properties.example`. The file and keystore are git-ignored. Never lose the keystore or its passwords; losing the upload key complicates future updates.

### 3.2 Build locally

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --release --obfuscate --split-debug-info=build/symbols \
  --dart-define=SUPABASE_URL=https://<nexhelp-project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<public-anon-or-publishable-key>
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols \
  --dart-define=SUPABASE_URL=https://<nexhelp-project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<public-anon-or-publishable-key>
```

Release builds require the dedicated release signing configuration. Cleartext HTTP is disabled for release variants; local Supabase HTTP is permitted only in non-release Android builds.

### 3.3 Automated release workflow

`.github/workflows/android-release.yml` can build signed APK and AAB artifacts after these GitHub Actions secrets are configured:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

The workflow checks required configuration, writes temporary signing files, runs format/analyze/tests, builds both release outputs, uploads artifacts, and removes temporary keystore files. Run it manually only after the backend is deployed and tested, or tag a release as `v*`.

The ordinary CI workflow creates a **debug APK test artifact**. It is not a production-signed binary and must not be submitted to Google Play.

### 3.4 Device acceptance tests

Before a public release, test on physical Android devices:
- Fresh install, upgrade install, and app relaunch.
- Sign up, email confirmation/recovery, sign in, sign out, expired session.
- Customer booking validation and duplicate-submit behavior.
- AI unavailable, quota exhausted, malformed response, and safety warning cases.
- Provider onboarding, pending approval, approval/rejection, availability, and assignment state transitions.
- Slow network, offline transitions, backend errors, and retry behavior.
- Accessibility text scaling, keyboard behavior, TalkBack labels, and small-screen layouts.

## 4. Public landing page deployment

The static public site lives in `landing/`. It does not require environment variables and does not collect user data.

Vercel project settings:
- Repository: `PSP-YN/NexHelp`
- Root directory: `landing`
- Framework preset: Other
- Build command: none
- Output directory: `.`
- Install command: none

Run `node landing/validate.mjs` before deployment. Confirm security headers, mobile navigation, links, metadata, and page rendering on mobile and desktop. Keep launch wording consistent with actual backend and pilot readiness.

## 5. Operations console deployment

Deploy `admin/` as a separate Vercel project with root directory `admin`.

Required environment variables:
```env
NEXT_PUBLIC_SUPABASE_URL=https://<nexhelp-project-ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<public-anon-or-publishable-key>
```

Never use a service-role key in `NEXT_PUBLIC_*` variables. After deployment:
- Confirm unauthenticated users cannot access operational data.
- Bootstrap the designated first admin through the restricted database procedure.
- Verify provider verification, dispatch, and dispute actions against live data.
- Test that admin-only RPCs reject ordinary authenticated users.

## 6. iOS release status

The current CI workflow does not compile or sign an iOS app. iOS release validation requires a macOS/Xcode runner, Apple signing certificates, provisioning profiles, bundle identifier configuration, and TestFlight acceptance testing. Treat iOS as not release-ready until that pipeline is added and executed.

## 7. Go-live gate

Do not open the pilot until all are complete:
1. Dedicated NexHelp Supabase project created in Mumbai and migrations applied.
2. Database advisors and RLS/security tests reviewed against the live project.
3. Production email/auth, recovery, rate limits, and privacy notices configured.
4. AI secret and Edge Function deployed and tested, with non-AI fallback verified.
5. Admin console deployed and restricted to designated operators.
6. Manual provider verification process, support escalation, and dispute process staffed.
7. Signed Android release built and installed on physical devices.
8. Privacy policy, terms, consent, data-retention, and incident-response procedures reviewed.
9. End-to-end customer, provider, and operator acceptance tests completed.
10. Public landing page wording and pilot availability confirmed by the operations owner.
