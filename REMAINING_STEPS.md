# Kwick — Remaining Work & Production Launch Checklist

> **Status:** The public landing page is deployed. The mobile app, database, AI function, and operations console are not yet a live customer service. A successful CI build does not by itself authorize a public pilot.

## Current status

- Public landing page: [https://nexhelp-landing.vercel.app/](https://nexhelp-landing.vercel.app/)
- Repository: [PSP-YN/Kwick](https://github.com/PSP-YN/Kwick)
- Working branch: `hackglobal/nexhelp-intelligence`
- Draft PR: [#2](https://github.com/PSP-YN/Kwick/pull/2)
- Backend: **Not provisioned.** Supabase rejected the $0/month Kwick project creation because the organization reached its two-project free-tier limit. CareerOS is inactive and JanaSetu is active. Neither project was deleted or upgraded.
- Android: CI has compiled a debug APK on an earlier commit. The current CI workflow is configured to upload a debug APK artifact after its run completes. This is a test build, not a signed production release.
- Android production release: A gated workflow exists at `.github/workflows/android-release.yml`; it requires a dedicated Supabase project and private Android signing secrets.
- Operations console: Build passes in an earlier completed CI run, but it is not deployed or connected to a live Kwick backend.
- iOS: Not compiled or signed by the current CI pipeline.
- Provider document upload: Not implemented in mobile onboarding. The pilot must use a secure, documented manual verification process before provider approval.

## 1. Resolve the Supabase project limit

A dedicated Kwick project is required. Create it in `ap-south-1` (Mumbai) under the selected Supabase organization.

The $0/month project creation was explicitly approved, but Supabase refused because the organization has reached its free-project limit. To proceed, choose one of these actions in Supabase:
- Delete the inactive CareerOS project (destructive; do this only if its data is no longer needed).
- Upgrade an existing project or organization plan to a tier that permits another project (may incur recurring cost).

Do not reuse JanaSetu or CareerOS for Kwick. Do not delete or upgrade either without a separate explicit decision.

Once the project exists:
1. Save the project URL, project reference, database password, and public anon/publishable key securely.
2. From the repository root, run:
   ```bash
   supabase login
   supabase link --project-ref <nexhelp-project-ref>
   supabase db push --yes --remote
   ```
3. Apply all 13 ordered migrations.
4. Verify all application tables have RLS enabled, both private storage buckets exist, and the restricted quota RPC is executable only by `service_role`.
5. Run Supabase database advisors and resolve warnings before real user data is introduced.

## 2. Configure authentication and storage

The current mobile authentication flow uses email/password. Registration also collects a phone number as profile information; SMS OTP is **not** the current sign-in flow.

Before pilot:
- Configure production email delivery, confirmation, recovery, redirect URLs, password policy, and abuse/rate limits.
- Enroll TOTP for every admin/super-admin and verify that AAL1 sessions cannot read admin data or call admin RPCs.
- Test fresh registration, confirmation, sign-in, sign-out, session refresh, and password recovery.
- Keep `provider-documents` and `service-request-photos` private.
- Test upload/read/signed URL expiry and cross-user access denial with separate customer, provider, and admin accounts.
- Do not store identity or trade documents in public buckets.

## 3. Deploy Kwick Intelligence

Set the Gemini key only as a Supabase Edge Function secret:

```bash
supabase secrets set GEMINI_API_KEY=<secret> --yes
supabase secrets set GEMINI_MODEL=<supported-model-id> --yes
supabase functions deploy diagnose-service --yes
```

Verify the configured model against the current Gemini API account. Test authentication, invalid payloads, model errors, rate-limit exhaustion, timeout behavior, safety alerts, and the non-AI booking fallback. Never expose the Gemini key in the mobile app, browser, GitHub, or any `NEXT_PUBLIC_*` variable.

## 4. Deploy the operations console

Create a separate Vercel project for repository `PSP-YN/Kwick` with root directory `admin`.

Set:
```env
NEXT_PUBLIC_SUPABASE_URL=https://<nexhelp-project-ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<public-anon-or-publishable-key>
```

Then:
- Deploy and verify unauthenticated visitors cannot access operations data.
- Bootstrap only the designated first admin through the restricted database procedure.
- Test provider review, dispatch, status transitions, dispute handling, and audit logging against live data.
- Verify all admin-only RPCs reject ordinary authenticated users.

The admin console is not live until this deployment and these checks are complete.

## 5. Prepare Android production signing

Generate a dedicated upload keystore and keep a secure backup:

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -alias nexhelp-upload -keyalg RSA -keysize 2048 -validity 10000
```

Copy `android/key.properties.example` to `android/key.properties` and enter the alias, keystore path, and passwords. Both files containing private signing material are excluded from Git.

The signed release workflow requires these GitHub Actions secrets:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

After the backend and signing secrets are ready, run the `Android Release` workflow manually or push a `v*` tag. It runs formatting, analysis, Flutter tests, builds a signed APK and AAB, and uploads artifacts.

**Do not submit the ordinary CI debug APK to Google Play.** It is only for development/device testing.

## 6. Android device acceptance

Before releasing a signed build, test on physical Android devices:
- Fresh install, upgrade install, and relaunch.
- Registration, email confirmation, sign-in, recovery, and session expiry.
- Customer booking, validation, duplicate submission, cancellation, and history.
- AI unavailable, quota exhausted, invalid response, and safety alert behavior.
- Provider onboarding, pending review, approval/rejection, availability, and assignment lifecycle.
- Offline/slow network, retry behavior, keyboard handling, text scaling, and TalkBack accessibility.

## 7. iOS release

The current CI workflow does not build or sign iOS. Add a macOS/Xcode workflow, configure Apple Developer signing certificates and provisioning profiles, then test installation and the same core workflows before calling iOS release-ready.

## 8. Provider onboarding and pilot operations

The current provider onboarding flow collects trade and experience details but does not upload identity or trade documents.

For the initial 560102 service-zone pilot (HSR Layout focus):
1. Define a documented checklist for identity, trade competence, contact details, and service-area eligibility.
2. Collect and inspect evidence through an approved secure process.
3. Record the verification outcome and audit notes in the operations console.
4. Approve a provider only after checks are complete.
5. Confirm provider availability and service-area eligibility before assignment.
6. Staff a support and dispute escalation path before accepting customer bookings.

Do not present self-declared provider details as verified evidence.

## 9. Legal, privacy, and launch operations

Before opening the service to the public:
- Publish an accurate privacy policy and terms of service reviewed by the project owner/legal adviser.
- Document data purposes, retention, deletion, processor/subprocessor handling, user rights, and breach response.
- Confirm user consent and disclosures for AI-assisted triage.
- Define customer support, refunds/disputes, provider conduct, and incident escalation.
- Verify all claims on the landing page match actual service readiness and available coverage.
- Confirm the pilot area and service categories with the operations owner.

## 10. Google Play submission

After the signed AAB and legal documents are ready:
1. Create the app in [Google Play Console](https://play.google.com/console).
2. Use the final app name, package ID `com.nexhelp.nexhelp`, and version/build number.
3. Complete store listing, content rating, target audience, data safety, privacy policy, and app access declarations accurately.
4. Upload the signed AAB to internal testing.
5. Test the release with real accounts and a production-like backend before staged rollout.

---

## Go-live gate

Kwick is not production-ready as a full service until the dedicated Supabase project is provisioned, migrations and RLS are verified in the cloud, the AI and operations services are deployed, provider verification/support are staffed, a signed Android release passes physical-device acceptance, and privacy/terms are published. Keep the draft PR unmerged until current CI checks are green and the production blockers are resolved.
