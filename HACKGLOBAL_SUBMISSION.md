# HackGlobal 2026 — Kwick Submission Brief

## Project title

**Kwick — Trust-first home services, from request to resolution**

## One-line pitch

A hyperlocal home-services marketplace with separate customer and provider apps, database-enforced trust boundaries, and an operations workflow for provider verification and accountable dispatch.

## Track positioning

Open Innovation, with alignment to Social Impact and applied AI. AI-assisted issue triage is an optional extension, not a prerequisite for booking and not currently enabled in the live Kwick environment.

## Problem

When a household needs a plumber or electrician, customers often struggle to identify the right service, assess provider trust, explain the issue clearly, and understand what happens after requesting help. Informal discovery and messaging-based coordination fragment provider checks, job assignment, status updates, and accountability.

## Solution

Kwick provides two distinct mobile experiences backed by one role-isolated platform:

- **Kwick Customer:** service discovery, customer accounts, service requests, quote review, request tracking, and reviews.
- **Kwick Partner:** provider onboarding, service/pricing management, assigned-job visibility, and controlled job progression.
- **Kwick Operations:** provider verification, manual dispatch, dispute handling, fixed-price approval, and provider-specific commission agreements.

The backend uses Supabase Auth and PostgreSQL as the authority for identity, ownership, authorization, and transactional state. RLS, FORCE RLS, constraints, and transactional RPCs enforce the customer/provider boundary independently of the mobile UI.

## What is differentiated

1. **Two separate products:** customer and provider apps have distinct Android identities, build entrypoints, and role-specific navigation.
2. **Database-enforced trust:** customer/provider roles are mutually exclusive; customer booking creation, provider job access, and status transitions are checked at the database layer.
3. **Verification before dispatch:** a provider is not dispatch-eligible merely because they registered or uploaded information; an operator must approve them.
4. **Operational accountability:** booking, assignment, pricing, and audit events use server-side transactional workflows.
5. **Commercial flexibility:** provider quotes and approved negotiated fixed prices are supported; commission is provider/category-specific and requires recorded agreement.
6. **Optional AI with boundaries:** a future/optional triage function is designed to return advisory issue context only. It cannot book, dispatch, set prices, or change job status.

## Architecture

See the root [README architecture diagram](README.md#architecture) and [detailed architecture notes](docs/ARCHITECTURE.md). The implemented platform consists of Flutter customer/provider apps, a Next.js operations console, Supabase Auth, PostgreSQL/RLS, private Storage, and authenticated Edge Functions.

## Current implementation and honest status

- Customer and provider Flutter entrypoints and Android application IDs are implemented.
- The shared Supabase project is in Mumbai (`ap-south-1`); database migrations through `20261114172825` have been applied and live role/RLS checks were performed.
- All 18 public tables have RLS and FORCE RLS enabled. Public RPC entrypoints are SECURITY INVOKER wrappers; privileged implementation routines are in a non-exposed private schema.
- Local validation previously completed: Flutter analyzer (0 issues), 40 Flutter tests, 30 database tests, admin lint/build, dependency audit (0 vulnerabilities), landing validator (33 checks), and Edge Function type/redaction tests (3 tests). Re-run before final submission if the code changes.
- Android debug APKs were built for `com.kwick.customer` and `com.kwick.provider`; they are not signed store-release artifacts and have not passed physical-device acceptance.
- No Kwick administrator has been provisioned; admin MFA acceptance and stable production promotion remain open.
- AI diagnosis remains fail-closed until a Kwick-specific model key and explicit data-processing approval are configured.
- Encrypted local logical backups and a daily local timer exist; off-site backup and restore-drill gates remain open.
- GitHub Actions was previously blocked before job steps started by an account/repository spending restriction. Do not claim CI passed unless a new run completes successfully.
- The project has not completed production load/soak/failover tests or validated million-user capacity.
- **Vultr is not currently part of the deployed Kwick infrastructure.** Do not claim Vultr usage in a Vultr Showcase submission until an actual component is deployed there and verified.

## Initial pilot and impact hypothesis

The initial configured service zone is HSR Layout, Bengaluru (560102), with plumbing and electrical categories. The operating plan targets 2–3 neighbourhoods, 100 customers, and 30 service providers. These are future targets, not current users, verified providers, or traction metrics.

Kwick aims to make service requests clearer, reduce misrouted work, improve provider eligibility checks, and give customers a traceable service journey. No impact reduction or adoption outcome is claimed until measured in a real pilot.

## Three-minute demonstration

1. **0:00–0:25 — Product split:** show the Kwick Customer and Kwick Partner app identities.
2. **0:25–1:05 — Customer request:** demonstrate sign-in and a service request using a clearly labelled test account.
3. **1:05–1:40 — Operations:** show the operations queue and explain provider review and manual dispatch boundaries. Do not invent a live admin account if one is not provisioned.
4. **1:40–2:20 — Provider workflow:** show provider onboarding and assigned-job screens using test data, clearly labelled as test data.
5. **2:20–2:50 — Security:** show the architecture diagram and explain RLS, role separation, private storage, and transactional state changes.
6. **2:50–3:00 — Roadmap:** explain pilot coverage and the remaining deployment/device/operations gates.

If AI triage is not enabled in the environment being demonstrated, do not simulate a live model response or claim that AI is operational.

## Links

- Repository: https://github.com/PSP-YN/Kwick (currently private; make it public or grant reviewer access before relying on it for judging).
- Architecture: [README architecture section](README.md#architecture).
- Demo and deployment URLs: add only after confirming the live URL and testing the deployed experience.

## Submission integrity checklist

- [ ] Repository visibility/access checked for judges.
- [ ] Real customer and provider app screenshots captured from running builds.
- [ ] Architecture screenshot captured from the rendered Mermaid diagram.
- [ ] Live demo URL tested, or clearly label the project as a build/demo rather than a live service.
- [ ] No secrets, personal data, real identity documents, or private customer information visible in screenshots/video.
- [ ] All test accounts and seeded data labelled as test/demo data.
- [ ] Vultr services/region described only if actually used and verified.
