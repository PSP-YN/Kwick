# Kwick — Production Security & Operations Baseline

**Live backend:** Supabase project hpfzhovriwpivtotoyxw (Mumbai; dashboard name currently NexHelp).
**Important:** Kwick intentionally shares this project. Customer and provider identities are isolated by database roles and RLS, not by separate Supabase projects.

This is a verified baseline and deployment gate list, not a claim that every security setting is enabled or that the system is immune to every attack.

## 1. Implemented and verified

### Identity and data isolation

- Customer and provider app roles are mutually exclusive for one Auth identity.
- Customer-role accounts cannot create provider profiles or provider KYC records.
- Provider-role accounts cannot create customer bookings.
- Provider job progression requires the approved provider identity and its own accepted assignment.
- All 18 tables in the public schema have RLS enabled and FORCE RLS enabled after migration 20261114171124.
- Provider KYC and service-request-photo buckets are private. Current limits: 10 MiB for provider documents (JPG/PNG/PDF), 5 MiB for request photos (JPG/PNG/WebP).
- Provider documents are stored in user/provider-specific paths; admin access uses temporary signed URLs.
- The private schema holds SECURITY DEFINER authorization helpers. Public compatibility functions are SECURITY INVOKER wrappers. The repository API schema allowlist is only public and graphql_public; never add private to it.
- Admin RPCs use database-side administrator and AAL2/MFA checks. No admin role is currently provisioned.

### Database and functions

- Migrations are versioned and applied to the existing project through 20261114171737.
- Customer/provider ownership checks and assignment state invariants are enforced in PostgreSQL.
- Trigger-only pricing/audit functions have EXECUTE revoked from anon and authenticated.
- Commercial price proposals are audited; active commission requires provider agreement and administrator approval.
- The AI usage table has RLS and FORCE RLS with no client policies by design; it is server-only.
- Edge Function JWT verification is enabled. CORS uses exact allowed origins; no wildcard origin is configured.
- Public PostgREST functions are SECURITY INVOKER wrappers; authorization and transactional SECURITY DEFINER bodies are isolated in the non-exposed private schema. No SECURITY DEFINER functions are exposed in public and no anonymous execute grants remain for the transactional RPCs.
- The Security Advisor currently reports one WARN for leaked-password protection being disabled and one INFO for ai_diagnosis_usage. The INFO finding is intentional: no client policy means clients cannot read or write usage rows.

### Encryption and logging

- Supabase documents TLS 1.2/1.3 for project APIs and AES-256 encryption at rest for customer data. This is platform-managed encryption, not end-to-end encryption.
- Both mobile clients contain only the public Supabase key. Never embed a service-role key, database password, or Gemini key in an app bundle.
- Flutter now installs global error handlers. Production device logs contain sanitized event names only; raw exceptions and stack traces are restricted to debug builds.
- Admin and landing deployments set CSP, HSTS, frame denial, MIME sniffing protection, referrer policy and restrictive browser permissions.
- Do not log passwords, access/refresh tokens, OTPs, exact addresses, KYC document contents, or full request bodies.
- The app currently has no external crash-reporting sink. Local structured logs are not a substitute for a monitored, access-controlled production observability service.

## 2. Current live findings

At the last live audit:

- Auth users: 2; customer roles: 2; provider roles: 0; admin roles: 0.
- Provider profiles: 0; service requests: 0; Storage objects: 0.
- Security Advisor: 1 warning that leaked-password protection is disabled; 1 intentional INFO finding for the server-only AI usage table; no public SECURITY DEFINER warnings.
- Performance Advisor: no unindexed foreign-key or multiple-permissive-policy warnings after the commercial indexes/policy consolidation. Unused-index notices are expected on an empty pilot database; do not drop indexes until real query statistics justify it.
- Health Advisor: no findings.
- ai_diagnosis_usage RLS-without-policy INFO finding is intentional.

The live dashboard settings for SSL enforcement, network restrictions, Auth confirmation, CAPTCHA, SMTP, Auth rate limits, and organization MFA have not been verified through the Supabase Management API. Do not infer remote settings from the local supabase/config.toml; that file also contains local-development defaults.

## 3. Backups and recovery

### Snapshot already created

An encrypted pre-deployment snapshot was created before the Kwick commercial and role-isolation migrations:

- Local file: ~/.config/kwick/backups/kwick-pre-migration-20261114.tar.gz.gpg
- Encryption: GPG AES-256 symmetric.
- The archive was decrypted and its contents verified.
- The passphrase is stored in the local desktop keyring under service kwick-backup, account database-backup.

A current encrypted logical backup was generated after migration 20261114171737 with scripts/backup/export-encrypted-supabase.sh. A systemd user timer is enabled for daily 02:30 local exports with 30-day local retention. It runs only when this laptop/user session is available; no off-site rclone destination is configured.

**This is not yet a complete disaster-recovery system.** Supabase CLI logical dumps exclude Auth credentials/sessions and Storage binary payloads. The current Storage object count was zero at backup time. The backup currently exists only on this laptop; no off-site destination is configured and no restore drill has been run.

### Repeatable export

    scripts/backup/export-encrypted-supabase.sh

The script dumps public/storage schema and database rows, encrypts with GPG AES-256, verifies decryption/listing, applies local retention, and optionally copies the encrypted artifact to an rclone destination.

For off-site copies, configure an encrypted backup destination first, then set:

    export KWICK_BACKUP_RCLONE_DEST='remote-name:kwick-backups'

Keep the decryption passphrase in a separate password manager/offline recovery location. A backup stored only on the same laptop is not disaster recovery.

### Restore requirements before launch

1. Create an isolated recovery project.
2. Restore schema and data there; never test restoration over production.
3. Verify RLS, Auth re-registration/admin bootstrap, Storage bucket policies, Edge Function secrets and redirects.
4. Export and restore Storage binary objects separately when the first documents/photos are uploaded.
5. Record measured RPO/RTO and retain at least one off-site encrypted copy.
6. Run a restore drill after every material schema or storage change.

Supabase Free does not include automatic database backups or PITR. Supabase recommends regular CLI exports and off-site copies for Free projects. Pro includes daily backups retained for 7 days; PITR is a paid add-on. No billing or plan upgrade has been made.

## 4. Supabase Dashboard settings required before public launch

These are operator actions, not confirmed live settings:

- **Database → Settings → SSL Configuration:** enable SSL enforcement after confirming every operational connection uses SSL.
- **Database → Settings → Network Restrictions:** restrict direct Postgres/pooler access to known operations/CI egress addresses. Do not lock out Supabase managed services or the recovery path.
- **Authentication → Sign In / Providers:** require email confirmation for password signups; review allowed providers and redirect URLs; disable anonymous sign-in unless explicitly required.
- **Authentication → Rate Limits:** retain/tune signup, sign-in, OTP, token refresh and password recovery limits; enable CAPTCHA (Turnstile or hCaptcha) for public signup/sign-in/reset.
- **Authentication → Emails:** configure trusted custom SMTP, test confirmation/recovery flows and set OTP/link expiry to one hour or less.
- **Authentication → Security and Passwords:** enable leaked-password protection if the project plan supports it. Current Free plan does not include this feature.
- **Authentication → MFA:** enable TOTP enrollment/verification for administrator accounts and complete AAL2 enrollment before admin operations.
- **Organization → Team:** enable MFA for organization members where available, protect GitHub with 2FA, and maintain at least two trusted owners.
- Verify exact production Site URL and allowlisted redirect URLs; never use wildcard redirects.

The local supabase/config.toml is for development/test configuration. Its current email-confirmation and TOTP settings are local defaults, not evidence of production configuration. Do not blindly push local Auth settings to the live project.

## 5. Load balancing, capacity and availability

- Supabase provides managed API edge delivery and database infrastructure. Kwick does not currently own or operate a separate load balancer.
- The transactional database remains a single authoritative write primary. RLS, indexes, bounded queries and the managed pooler are the pilot baseline.
- The k6 script scripts/load/kwick-read-smoke.js is a read-only staging smoke/load test. It must not be pointed at production for high-volume tests.
- No 250-VU, 1,000-VU, soak, failover or million-concurrent-user test has been completed yet.
- Before growth: run realistic staged load tests; measure p50/p95/p99, database CPU/IO, connections, error rate, queue lag and cost per completed booking.
- At scale: add edge caching for public catalogue data, asynchronous durable queues for notifications/analytics, read replicas for eligible reads, connection pooling, backpressure, idempotency, and only later regional partitioning/sharding if measured.
- Millions of concurrent users require a paid capacity plan, support/limit review, representative infrastructure, and tested multi-region recovery. No code change alone can guarantee that capacity.

## 6. Launch blockers

- Provision the first trusted administrator through the approved bootstrap process, then enroll and test TOTP/AAL2. No administrator currently exists.
- Verify Supabase Dashboard security settings listed above.
- Configure off-site backup storage and complete a restore drill; include Storage binaries after providers begin uploading documents.
- Decide whether to upgrade from Free to a plan with automatic backups and leaked-password protection. Do not upgrade without budget approval.
- Complete physical-device acceptance for both mobile apps and authenticated admin MFA acceptance.
- Run staging load/soak tests and confirm operating capacity before advertising a service SLA.
- Obtain legal review for provider identity/document handling, retention, consent, agreements, consumer terms, tax and payment settlement.

## 7. References

- Supabase [production checklist](https://supabase.com/docs/guides/deployment/going-into-prod)
- Supabase [production security checklist](https://supabase.com/docs/guides/security/production-checklist)
- Supabase [password security](https://supabase.com/docs/guides/auth/password-security)
- Supabase [database backups](https://supabase.com/docs/guides/platform/backups)

## 8. Incident response minimum

1. Disable affected credentials or user sessions and rotate compromised secrets.
2. Pause dispatch/payment operations if customer or provider records may be exposed.
3. Preserve database/Auth/Edge Function logs and relevant audit rows; do not put sensitive payloads in issue trackers.
4. Assess affected records, time window, data categories and legal notification duties.
5. Restore from a verified backup only after identifying the failure point and testing recovery in isolation.
6. Record root cause, remediation, key rotation, user communication and follow-up security tests.
