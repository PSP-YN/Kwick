# NexHelp Deployment & Release Guide

## 1. Pilot Architecture Overview
- **Pilot Location:** Bengaluru South, Karnataka (Pincode: `560102` — HSR Layout & Koramangala).
- **Initial Core Verticals:** Plumbing & Electrical home repairs.
- **Components:**
  1. **Mobile Application (Flutter):** Android primary target; unified binary supporting Customer and Provider roles.
  2. **Authoritative Backend (PostgreSQL 16 + Supabase):** 15 tables, `FORCE ROW LEVEL SECURITY`, `SECURITY DEFINER` RPC state transitions, immutable audit log.
  3. **Operations Console (`admin/` Next.js 16 + TypeScript):** Dispatch queue, provider verification with credential review, and authoritative emergency override tool.

---

## 2. Supabase Production Deployment Checklist

### 2.1 Database Migrations
Deploy migrations in chronological sequence:
```bash
# Push migrations to target Supabase project
supabase db push --linked
```
Files:
1. `supabase/migrations/20261023000001_initial_schema.sql` (Tables, constraints, bigints in paise, indexes)
2. `supabase/migrations/20261023000002_rls_policies.sql` (Row Level Security & lookup helpers)
3. `supabase/migrations/20261023000003_rpc_functions.sql` (Atomic transaction RPCs)
4. `supabase/migrations/20261023000004_seed_pilot_data.sql` (Area 560102, categories, storage buckets)
5. `supabase/migrations/20261111000005_harden_admin_bootstrap.sql` (privileged bootstrap hardening)
6. `supabase/migrations/20261111000006_auth_provisioning_and_write_privileges.sql` (Auth provisioning and least-privilege writes)
7. `supabase/migrations/20261111000007_dispatch_provider_invariants.sql` (provider assignment invariants)
8. `supabase/migrations/20261111000008_ai_diagnosis_usage.sql` (private AI usage quota log)
9. `supabase/migrations/20261111000009_harden_definer_helpers.sql` (SECURITY DEFINER helper hardening)

### 2.2 Storage Buckets & Policies
Verify the two private buckets are provisioned:
- `provider-documents`: Private bucket for Aadhaar/PAN cards and electrical trade certificates.
- `service-request-photos`: Bucket for customer issue photos and provider completion proof.

### 2.3 Authentication & SMS OTP
- In Supabase Dashboard > Authentication > Providers:
  - Configure SMS Provider (e.g., Twilio, MSG91, or Exotel for India).
  - Configure OTP expiry to 300 seconds (5 minutes).
  - Rate-limit OTP dispatches to 5 per IP / phone number per hour.

---

## 3. Android Mobile Application Release

### 3.1 Keystore Generation
Generate an upload signing key:
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -alias nexhelp-upload -keyalg RSA -keysize 2048 -validity 10000
```

### 3.2 Key Configuration (`android/key.properties`)
Create `android/key.properties` (never commit to version control):
```properties
storePassword=SECURE_STORE_PASSWORD
keyPassword=SECURE_KEY_PASSWORD
keyAlias=nexhelp-upload
storeFile=upload-keystore.jks
```

### 3.3 Release Bundle Build
```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://<your-project-id>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-publishable-key>
```
Output: `build/app/outputs/bundle/release/app-release.aab`

---

## 4. iOS Deployment Status & Pipeline
- **Local Development Environment:** Linux Fedora x86_64.
- **Platform Limitation:** Xcode and macOS SDK are not locally available on Linux.
- **CI/CD Build Pipeline:** iOS builds are automated via GitHub Actions using `macos-latest` runners in `.github/workflows/ci.yml`.
- **Certificates Required:** Apple Developer Program Certificate (Distribution), Provisioning Profile configured with Associated Domains for deep linking.

---

## 5. Operations Console (`admin/`) Deployment

### 5.1 Environment Variables
Set the following on Vercel, Cloudflare Pages, or Docker:
```env
NEXT_PUBLIC_SUPABASE_URL=https://<your-project-id>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<your-anon-publishable-key>
```

### 5.2 Build & Start
```bash
cd admin
npm ci
npm run build
npm run start
```
The console exposes:
- Real-time KPI cards for pending dispatch, active jobs, and verified partners.
- Manual Dispatch queue with provider allocation modal.
- Identity and trade license verification audit log.
- Emergency override tool with mandatory reason logging.


## AI Diagnosis Function

The optional customer issue-triage feature requires a server-side Gemini API key. Never place this key in Flutter, the web app, or source control.

```bash
supabase secrets set GEMINI_API_KEY=your_key
supabase secrets set GEMINI_MODEL=gemini-3.8-flash
supabase functions deploy diagnose-service
```

The function requires an authenticated Supabase user, applies a per-user hourly usage limit, does not persist raw issue descriptions, and returns advisory triage only. Customers can still submit bookings when AI is unavailable.
