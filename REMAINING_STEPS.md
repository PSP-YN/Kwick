# Kwick — Remaining Launch and Submission Gates

This file records work that remains after the Kwick platform split and backend hardening. It is not a claim that every item below is complete.

## Current implementation baseline

- Repository: `PSP-YN/Kwick`, branch `kwick/platform-split`.
- Customer Android identity: `com.kwick.customer`.
- Partner Android identity: `com.kwick.provider`.
- Existing Supabase project: `hpfzhovriwpivtotoyxw`, Mumbai (`ap-south-1`). Kwick intentionally shares this project; do not create or relink a second project without an explicit decision.
- Migrations applied through `20261114172825`.
- Local validation results are recorded in `docs/PRODUCTION_SECURITY_OPERATIONS.md` and the current team decisions document.

## Required before public pilot

1. Select the first administrator from the existing registered accounts. Never share passwords or OTPs. Provision through the trusted bootstrap path and enroll TOTP/AAL2.
2. Verify remote Supabase dashboard settings: SSL enforcement, network restrictions, email confirmation, OTP expiry, custom SMTP, CAPTCHA, Auth rate limits, organization MFA, and redirect allowlists.
3. Configure off-site encrypted backups and complete an isolated restore drill. The current daily timer runs on the laptop and does not provide off-site disaster recovery.
4. Connect a physical Android device and test both customer and partner builds end-to-end: registration, confirmation, login, role mismatch, provider onboarding, document upload, booking, dispatch, status transitions, and cancellation.
5. Complete authenticated admin acceptance after provisioning the first administrator and enrolling MFA.
6. Resolve the GitHub Actions account/repository spending restriction, rerun CI, and confirm jobs actually execute and pass.
7. Produce signed release APK/AAB artifacts and verify signing identity. Existing debug APKs are not store-ready.
8. Complete staging load/soak/failover tests and record latency, error rates, connection saturation, resource utilization, and recovery objectives.
9. Complete provider verification operations, support/dispute handling, privacy/terms review, and pilot staffing.
10. Promote stable admin and landing deployments only after production environment configuration and smoke tests.

## Optional AI gate

The `diagnose-service` Edge Function is deployed with JWT verification and fails closed without its Kwick-specific AI key. Enable it only after a key is configured, data-processing terms are reviewed, consent is implemented, and live behavior is tested. AI must remain advisory and must not book, price, dispatch, or change job state.

## Vultr Showcase gate

The current deployed backend is Supabase in Mumbai; Vultr is not currently used by Kwick. Before claiming Vultr usage, deploy a real Kwick component to a Vultr service, test it, and document the exact service, region, network path, security controls, and operational role. Do not describe planned infrastructure as deployed infrastructure.

## Submission checklist

- [ ] Confirm repository visibility or reviewer access.
- [ ] Capture actual customer and partner app screenshots.
- [ ] Capture the Mermaid architecture diagram rendered from `README.md`.
- [ ] Add a verified demo URL if one is available.
- [ ] Disclose current deployment and Vultr status accurately.
- [ ] Remove private data and credentials from screenshots and video.
