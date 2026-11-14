# Kwick Operations Console

The Kwick Operations Console is the internal Next.js application used to review service providers, coordinate job dispatch, handle disputes, and approve fixed pricing and provider-specific commission terms.

## Local development

```bash
npm ci
cp .env.local.example .env.local
```

Set the following values in `.env.local` using the intended Supabase environment:

```env
NEXT_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<public-anon-or-publishable-key>
```

Then run:

```bash
npm run dev
npm run lint
npm run build
```

Open `http://localhost:3000`.

## Access and security

- This is an operator interface, not a customer-facing dashboard.
- Only a provisioned administrator may perform administrative actions.
- Administrative database operations require AAL2/TOTP MFA and database-side authorization.
- The browser receives only the public Supabase key. Never add a service-role key, database password, or AI-provider key to `NEXT_PUBLIC_*` variables.
- Provider documents remain in private Storage; use short-lived authorized access rather than public URLs.
- Production logs must not include tokens, OTPs, identity-document contents, or raw request payloads.

## Current status

The application passes local lint and production-build checks. A first Kwick administrator has not yet been provisioned, MFA acceptance has not been completed, and the stable production deployment has not been promoted. Do not treat a successful local build as evidence of production readiness.

See the root [architecture](../docs/ARCHITECTURE.md), [security operations](../docs/PRODUCTION_SECURITY_OPERATIONS.md), and [release guide](../docs/RELEASE.md).
