# Kwick Build and Release Guide

## 1. App identities

| App | Flutter entrypoint | Android application ID | iOS scheme |
|---|---|---|---|
| Customer | `lib/main_customer.dart` | `com.kwick.customer` | `customer` |
| Partner | `lib/main_provider.dart` | `com.kwick.provider` | `provider` |

The two apps share code and backend infrastructure but have separate install identities and role-locked navigation. The old NexHelp repository and deployment slugs may remain as historical infrastructure identifiers; all user-facing app branding is Kwick.

## 2. Local quality gates

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
./supabase/tests/run_tests.sh
cd admin && npm ci && npm run lint && npm run build
cd ../landing && node validate.mjs
```

## 3. Android debug builds

```bash
flutter build apk --debug --flavor customer -t lib/main_customer.dart
flutter build apk --debug --flavor provider -t lib/main_provider.dart
```

Expected APKs:
- `build/app/outputs/flutter-apk/app-customer-debug.apk`
- `build/app/outputs/flutter-apk/app-provider-debug.apk`

## 4. Android signed release builds

Configure these GitHub Actions secrets:

- `SUPABASE_URL` — dedicated Kwick HTTPS project URL.
- `SUPABASE_ANON_KEY` — public anon/publishable key only.
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

Build both apps from the repository root:

```bash
flutter build apk --release --flavor customer -t lib/main_customer.dart --build-number=2 \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<public-key>
flutter build appbundle --release --flavor customer -t lib/main_customer.dart --build-number=2 \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<public-key>

flutter build apk --release --flavor provider -t lib/main_provider.dart --build-number=2 \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<public-key>
flutter build appbundle --release --flavor provider -t lib/main_provider.dart --build-number=2 \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<public-key>
```

Never commit `android/key.properties`, the keystore, or any service-role/AI provider key. Keep the upload key and a verified encrypted backup in a password manager and offline storage.

## 5. iOS builds

The shared Xcode schemes and xcconfigs are defined for `customer` and `provider`:

```bash
flutter build ios --flavor customer -t lib/main_customer.dart
flutter build ios --flavor provider -t lib/main_provider.dart
```

The project is developed on Linux. The Xcode project, schemes, bundle identifiers, code signing and provisioning must be validated on a macOS runner before any iOS release is called ready.

## 6. CI workflows

- `.github/workflows/ci.yml` runs Flutter format/analyze/tests, builds both Android debug APK flavors, validates the landing page, builds/lints the admin app, runs isolated PostgreSQL migrations/RLS tests and type-checks the AI Edge Function.
- `.github/workflows/android-release.yml` builds signed APK and AAB outputs for both Android flavors. It removes temporary signing material in an `always()` cleanup step.

A GitHub Actions billing/spending restriction can prevent jobs from starting. Such a run is an infrastructure/account block, not a passing or failing code test. Use local test evidence and re-run CI when runners are available.

## 7. Backend and launch gates

Before production release:

1. Confirm the linked existing Supabase project ref `hpfzhovriwpivtotoyxw` (currently named NexHelp) and verify all migrations through `20261114171737_internalize_transactional_rpc_functions.sql` are applied. Do not create a second project or relink to a different project.
2. Run live database advisors and inspect RLS/storage policies.
3. Configure Auth email delivery, account recovery, rate limits and admin TOTP/AAL2.
4. Verify provider-document upload and admin signed-document review with separate test accounts.
5. Complete manual provider identity/trade/reference verification before dispatch approval.
6. Agree provider pricing and commission terms explicitly. The application does not assume a default percentage.
7. Complete payment collection, commission deduction, reconciliation, refund and provider settlement design before charging commission.
8. Install both signed Android apps on physical devices and complete end-to-end customer and partner acceptance tests.
9. Validate the iOS schemes on macOS if iOS release is in scope.
10. Do not claim million-concurrent-user capacity until staged load, soak, failover and recovery tests pass on a production-equivalent environment.

See [Launch Playbook](KWICK_LAUNCH_PLAYBOOK.md), [Commercial Model](COMMERCIAL_MODEL.md), [Provider Verification](PROVIDER_VERIFICATION.md) and [Scale Readiness](SCALE_READINESS.md).
