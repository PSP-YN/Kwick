# NexHelp Third-Party Processor and Data-Flow Register

**Status: PRE-LAUNCH.** Verify current contracts, DPAs, data locations, sub-processors, retention and security evidence before launch.

| Provider | Intended function | Data potentially processed | Required checks before production |
|---|---|---|---|
| Supabase | Auth, Postgres database, private Storage, Edge Functions | Account identifiers, contact data, service requests, provider records, uploaded documents, audit/security logs | Mumbai region for the new project; DPA and subprocessor terms; backups/restore; support access; Storage region; logs; retention; access controls |
| Vercel | Landing page and operations-console hosting | Website requests, admin session/browser metadata, logs and any data rendered in the admin console | Hosting/log region, DPA, access controls, environment secret isolation, retention, preview protection, deployment access |
| Google Gemini API | Optional AI issue triage | User-provided issue description and category hint after affirmative consent; obvious phone/email/ID patterns are redacted best-effort | Production must use paid API tier; verify active billing and applicable DPA; confirm region/retention; do not use unpaid tier with real customer data |
| GitHub / GitHub Actions | Source control and CI builds | Source code, build logs, dependency metadata; never production data or secrets in logs | Repository access review, secret scanning, branch protection, Actions permissions, artifact retention, dependency pinning |

## Data minimization rules

- Do not send customer profile, phone, service address, photos or full request records to Gemini.
- Do not place service-role keys, database passwords, Gemini keys or signing keys in Flutter assets, client-side JavaScript or Git.
- Keep Supabase service-role keys server-side only.
- Admin UI must rely on database RLS and verified user sessions; client-side route hiding is not authorization.
- Use private Storage buckets and short-lived signed URLs for identity documents.
- Do not claim that all NexHelp data remains in India merely because the Supabase database is in Mumbai. Verify every processor and data flow separately.
