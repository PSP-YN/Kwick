# HackGlobal 2026 — NexHelp Submission Brief

## Project title

**NexHelp — Diagnose. Match. Resolve.**

## One-line pitch

A trust-first home-services platform that uses AI to triage household repair issues, then connects customers with verified, available technicians through accountable dispatch workflows.

## Track

Open Innovation (primary), with strong Artificial Intelligence and Social Impact alignment.

## Problem

When a household faces a plumbing or electrical issue, the customer often does not know:
- Which trade is appropriate.
- Whether the issue is routine or potentially urgent.
- What information a technician needs before arriving.
- Whether a service provider is verified, qualified, and available.
- What happened to the request after it was submitted.

Existing informal discovery and booking flows leave diagnosis, provider trust, dispatch, and accountability fragmented.

## Solution

NexHelp combines a Flutter customer/provider application, a secure Supabase/PostgreSQL backend, and a Next.js operations console.

NexHelp Intelligence accepts a short issue description and returns a structured, cautious triage assessment: likely category, urgency, summary, safety alerts, follow-up questions, and a dispatcher note. The customer reviews the suggestion and decides whether to submit a booking. The operations team then assigns a verified provider with the correct trade skill and availability.

The service lifecycle is recorded through transactional database functions and an audit trail.

## What is differentiated

1. **Triage before dispatch:** AI structures the issue before a technician is assigned.
2. **Safety-first boundaries:** The model does not provide repair instructions or price promises; emergency warnings are conservative and explicit.
3. **Trust-aware dispatch:** Only approved, available providers with the required service category can be assigned.
4. **Operational accountability:** Booking state changes run through transactional RPCs and append-only event records.
5. **Security by design:** Supabase Auth, row-level security, column-level write privileges, server-side AI secrets, and a role-protected operations console.
6. **Practical fallback:** Booking remains usable when the AI provider is unavailable or the customer chooses not to use AI.

## Core user journey

1. Customer signs in and selects plumbing or electrical service.
2. Customer describes the issue.
3. NexHelp Intelligence suggests a category, urgency, safety guidance, and questions.
4. Customer reviews the advice and submits the request.
5. Operations sees the request and AI triage notes.
6. Dispatcher assigns a verified and available technician.
7. Provider accepts, progresses, and completes the job.
8. Customer submits a review.

## Technology

- Flutter / Dart — Android and iOS customer/provider application.
- Supabase Auth — identity and sessions.
- PostgreSQL — authoritative application state, constraints, RLS, transactional RPCs, and audit records.
- Supabase Edge Functions — authenticated server-side AI gateway.
- Gemini API — structured issue triage.
- Next.js / TypeScript — role-protected operations console.
- GitHub Actions — Flutter, database, admin build, and Edge Function validation.

## Security and responsible AI

- No Gemini API key in the client.
- The AI function requires an authenticated user.
- Raw issue descriptions are not stored in the AI usage audit table.
- The AI result is advisory and requires customer review.
- The model cannot book, dispatch, set prices, or change service status.
- Booking and dispatch remain controlled by server-side authorization and database constraints.

## Impact hypothesis

NexHelp aims to reduce misrouted service requests, improve the quality of information available to technicians, make provider selection more transparent, and provide customers with a traceable service journey.

Do not claim measured reductions or customer adoption until those outcomes are instrumented and observed in a real pilot.

## Three-minute demo plan

**0:00–0:30 — Problem**
Show a customer who has a leaking sink and is unsure what service to book.

**0:30–1:10 — AI triage**
Enter the issue description. Show the suggested trade, urgency, safety guidance, and follow-up questions. Emphasize that the customer remains in control.

**1:10–1:45 — Booking**
Submit the request and show the booking confirmation and stored dispatcher notes.

**1:45–2:25 — Dispatch**
Open the operations console, review the issue and triage notes, and assign a verified available plumber.

**2:25–2:50 — Resolution**
Show provider acceptance, job progression, completion, and customer review.

**2:50–3:00 — Differentiator**
Show RLS/transactional dispatch guarantees and the audit trail.

## Demo integrity

- Use clearly labelled demo accounts and demo requests.
- Do not present seeded/test records as real customers, real completed jobs, or market traction.
- Show the AI function working against the configured model; do not substitute a canned response and call it live AI.
- If Gemini is unavailable, explain the optional fallback and continue the non-AI booking flow.

## Final submission checklist

- Publicly accessible GitHub repository or approved public project link.
- Deployed demo URL with test credentials if required by the platform.
- Short demo video with no private credentials visible.
- Architecture diagram and concise problem/solution description.
- Clear installation and environment setup instructions.
- Confirm submission on Vultr Community before the HackGlobal deadline: 15 November 2026, 12:00 PM IST.
