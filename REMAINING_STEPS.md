# NexHelp — Remaining User Action Items & Production Launch Checklist

> **Purpose:** This checklist records external production setup and release tasks. It is not a claim that every feature has been independently verified. Review the latest CI results and the engineering audit before treating NexHelp as production-ready.

---

## Quick Reference Summary

| # | Action Item | Target Service | Est. Time |
| :--- | :--- | :--- | :--- |
| **1** | [Create Supabase Project & Push Migrations](#1-create-supabase-project--push-migrations) | Supabase Cloud (`ap-south-1`) | 10 mins |
| **2** | [Bootstrap the First Admin User](#2-bootstrap-the-first-admin-user) | Supabase SQL Editor | 2 mins |
| **3** | [Configure Indian SMS Gateway (OTP)](#3-configure-indian-sms-gateway-otp) | Twilio / MSG91 / Exotel | 15 mins |
| **4** | [Deploy Operations Dashboard](#4-deploy-operations-dashboard) | Vercel / Cloudflare Pages | 5 mins |
| **5** | [Create Android Release Keystore](#5-create-android-release-keystore) | Local Terminal | 5 mins |
| **6** | [Build Production Android App Bundle (`.aab`)](#6-build-production-android-app-bundle-aab) | Local Terminal | 5 mins |
| **7** | [Submit to Google Play Console](#7-submit-to-google-play-console) | Google Play Console | 30 mins |
| **8** | [Build iOS App via GitHub Actions](#8-build-ios-app-via-github-actions) | GitHub Actions (macOS) | 15 mins |
| **9** | [Onboard Initial Pilot Partners (560102)](#9-onboard-initial-pilot-partners-560102) | NexHelp Admin Portal | On-demand |

---

## 1. Create Supabase Project & Push Migrations

1. Go to [supabase.com](https://supabase.com) and create a new project (e.g. `nexhelp-prod`).
2. Select Region: **`ap-south-1` (Mumbai, India)** for lowest latency in Bengaluru.
3. Save your database password and retrieve your:
   - **Project URL:** `https://<project-ref>.supabase.co`
   - **Anon / Public Key:** `eyJhbGci...`
4. From your terminal in `/home/psp/projects/NexHelp`:
   ```bash
   # Login to your Supabase CLI account
   supabase login

   # Link to your remote project
   supabase link --project-ref <your-project-ref>

   # Push all 5 migrations to production PostgreSQL
   supabase db push
   ```
5. Verify in Supabase Dashboard:
   - All 15 tables appear under **Table Editor** with `RLS Enabled`.
   - The two private buckets (`provider-documents`, `service-request-photos`) appear under **Storage**.

---

## 2. Bootstrap the First Admin User

To gain access to the **Operations Console** (`admin/`):

1. Sign up a new user account with your email or phone number in Supabase (or via the NexHelp app).
2. Go to **Supabase Dashboard $\to$ Authentication $\to$ Users** and copy your `User UID` (a UUID like `e7f2c610-...`).
3. Open **SQL Editor** in Supabase Dashboard and run:
   ```sql
   -- Grants the user the admin role and logs to admin_audit_logs
   SELECT public.bootstrap_admin('PASTE_YOUR_USER_UUID_HERE');
   ```
4. Confirm by running:
   ```sql
   SELECT u.full_name, r.role
   FROM public.user_roles r
   JOIN public.profiles u ON u.id = r.user_id
   WHERE r.user_id = 'PASTE_YOUR_USER_UUID_HERE';
   ```
   It should return role `admin`.

---

## 3. Configure Indian SMS Gateway (OTP)

NexHelp authenticates Indian mobile numbers (+91). For production SMS OTP:

1. In Supabase Dashboard, go to **Authentication $\to$ Providers $\to$ Phone**.
2. Enable **Phone Provider**.
3. Choose your SMS vendor:
   - **Twilio / MSG91 / Exotel**: Enter Account SID, Auth Token, and Sender ID.
   - For India, ensure your SMS template is registered on DLT with template: `Your NexHelp verification code is {{ .Code }}. Valid for 5 minutes.`
4. Set OTP Expiry to **300 seconds (5 minutes)**.

*(For testing prior to SMS setup, you can add Test Phone Numbers in Supabase Dashboard $\to$ Authentication $\to$ Providers $\to$ Phone $\to$ "Phone numbers for testing" with fixed OTP codes like `123456`).*

---

## 4. Deploy Operations Dashboard

Deploy the protected internal Next.js console (`admin/`) to Vercel or Cloudflare:

1. Go to [vercel.com](https://vercel.com) $\to$ **Add New Project**.
2. Import repository `PSP-YN/NexHelp`.
3. Configure project settings:
   - **Root Directory:** Click Edit and select `admin`.
   - **Framework Preset:** Next.js.
4. Add Environment Variables:
   - `NEXT_PUBLIC_SUPABASE_URL`: `https://<your-project-ref>.supabase.co`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`: `<your-production-anon-key>`
5. Click **Deploy**.
6. Open your deployment URL (e.g., `https://nexhelp-ops.vercel.app`) to access the Operations Console.

---

## 5. Create Android Release Keystore

Generate an official upload key for the Google Play Store:

1. In your terminal, run:
   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks \
     -alias nexhelp-upload \
     -keyalg RSA \
     -keysize 2048 \
     -validity 10000
   ```
2. Store the password safely in your password manager.
3. Create `android/key.properties` (this file is git-ignored for security):
   ```properties
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=nexhelp-upload
   storeFile=upload-keystore.jks
   ```

---

## 6. Build Production Android App Bundle (`.aab`)

Build the release bundle pointing to your live Supabase instance:

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://<your-project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-production-anon-key>
```

- Output path: `build/app/outputs/bundle/release/app-release.aab`
- Size: ~18–25 MB (optimized release).

---

## 7. Submit to Google Play Console

1. Log in to [play.google.com/console](https://play.google.com/console).
2. Create App:
   - **App Name:** `NexHelp - Home Services`
   - **Default Language:** English (India)
   - **Category:** House & Home / Business
3. Upload `build/app/outputs/bundle/release/app-release.aab` to **Internal Testing** or **Closed Testing**.
4. Set App Content:
   - Privacy Policy URL (point to your deployed policy or website).
   - Target Audience: 18+.
   - Declarations: Location / Storage for service photos.
5. Release the pilot to testers in Bengaluru.

---

## 8. Build iOS App via GitHub Actions

Because this development workstation runs Linux Fedora, macOS/Xcode is not local. iOS builds are built via CI:

1. In your GitHub repository (`PSP-YN/NexHelp`), go to **Settings $\to$ Secrets and variables $\to$ Actions**.
2. Add the following repository secrets:
   - `SUPABASE_URL`: `https://<your-project-ref>.supabase.co`
   - `SUPABASE_ANON_KEY`: `<your-production-anon-key>`
3. The included GitHub Actions workflow `.github/workflows/ci.yml` validates builds on push.
4. For TestFlight distribution, add Apple Developer Team ID and Certificates to GitHub Secrets.

---

## 9. Onboard Initial Pilot Partners (560102)

For the initial launch in Bengaluru South (HSR Layout & Koramangala 560102):

1. Have 5–10 trusted plumbers and electricians download the app and sign up as **Partner**.
2. During onboarding, they select **Plumbing** or **Electrical**, input experience years, and upload government ID.
3. Open the **Operations Console** (`/admin` $\to$ **Provider Verifications** tab):
   - Review uploaded documents.
   - Click **Approve Partner** and enter audit verification notes.
4. Once approved, partners toggle their status to **Available** and can receive customer booking dispatches.

---

*This document is the single source of truth for all remaining manual human steps. Remaining engineering work and test status must be checked against the latest branch CI and audit notes before launch.*
