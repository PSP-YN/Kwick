# NexHelp Public Landing Page

This is the public, static marketing site for NexHelp. It is intentionally separate from the authenticated operations console in `admin/`.

## Local preview

From the repository root:

```bash
cd landing
python3 -m http.server 4173
```

Open `http://localhost:4173`.

## Validate

Requires Node.js 20 or newer; no package installation is needed:

```bash
node landing/validate.mjs
```

## Deploy to Vercel

Create a separate Vercel project connected to `PSP-YN/NexHelp`:

- Root Directory: `landing`
- Framework Preset: Other
- Build Command: leave empty
- Output Directory: `. ` (the root of the selected directory; use `.`)
- Install Command: leave empty
- No environment variables are required for the static site.

The site is static HTML/CSS/JavaScript. It does not collect personal information, submit bookings, or claim that the pilot is live. Keep the published pilot status in sync with actual backend and operations readiness.

## Content and safety boundaries

- The first planned service area is HSR Layout and Koramangala, Bengaluru South (560102).
- The first service categories are plumbing and electrical.
- Provider verification is an operations process; do not imply that all providers are already verified or available.
- AI triage is optional and advisory. It cannot book, dispatch, set prices, or replace professional or emergency advice.
- Do not add fabricated reviews, partner logos, service statistics, pricing, or launch claims.
