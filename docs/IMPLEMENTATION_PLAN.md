# NexHelp Implementation Plan

This document tracks all phases, tasks, completion status, and verification evidence for NexHelp.

---

## Phase Overview & Status

| Phase | Description | Status | Gate Verification |
| :--- | :--- | :--- | :--- |
| Phase | Description | Status | Gate Verification |
| :--- | :--- | :--- | :--- |
| **Phase 0** | Audit and Foundation | **Completed** | Flutter toolchain, Admin app, CI config, memory docs verified |
| **Phase 1** | Database and Security | **Completed** | 4 SQL migrations applied; 10/10 automated tests passed in isolated Postgres |
| **Phase 2** | Authentication and Navigation | Pending | Registration, login, profile bootstrap, role-based routing |
| **Phase 3** | Customer Booking Journey | Pending | Discovery, booking flow, order history, cancellation, review |
| **Phase 4** | Provider Workflows | Pending | Onboarding, availability toggle, assignment accept/decline/progress |
| **Phase 5** | Admin Operations Dashboard | Pending | Protected Next.js portal, provider approvals, manual dispatch, audit |
| **Phase 6** | Notifications & Alerts | Pending | FCM token management, server notification records, in-app alerts |
| **Phase 7** | Hardening & Quality Assurance| Pending | Automated unit, widget, and integration test suite; edge cases |
| **Phase 8** | Android Pilot Readiness | Pending | Android build configuration, app signing setup, release checks |
| **Phase 9** | iOS Readiness & Pilot Setup | Pending | Shared codebase iOS configuration, docs for Apple signing & APNs |

---

## Detailed Task Checklist

### Phase 0: Audit and Foundation
- [x] Environment & Toolchain Audit (`docs/PROJECT_AUDIT.md`)
- [x] Initial Architecture Specification (`docs/ARCHITECTURE.md`)
- [x] Decision Log (`docs/DECISIONS.md`)
- [x] Known Issues Tracker (`docs/KNOWN_ISSUES.md`)
- [x] Flutter Application Scaffolding & Dependencies (`pubspec.yaml`, `analysis_options.yaml`)
- [x] Admin Dashboard Scaffolding (`admin/package.json`)
- [x] CI Workflow Foundation (`.github/workflows/ci.yml`)
- [x] Environment Template (`.env.example`)
- [x] Root Documentation (`README.md`, `.ai-memory/PROJECT.md`, `TASKS.md`)
- [x] Verification Gate: `flutter analyze` clean, `flutter test` clean, admin compile check

### Phase 1: Database and Security
- [x] Supabase configuration & migrations setup (`supabase/migrations/`)
- [x] Table definitions:
  - [x] `profiles`
  - [x] `user_roles` (`customer`, `provider`, `admin`, `super_admin`)
  - [x] `service_areas` (Bengaluru pilot area: HSR Layout/Koramangala 560102)
  - [x] `service_categories` (Plumbing and Electrical seeded)
  - [x] `providers` (status: pending, approved, rejected, suspended; availability: available, busy, unavailable)
  - [x] `provider_services` (pricing in integer paise)
  - [x] `provider_documents` (private storage references)
  - [x] `service_requests` (strict state machine)
  - [x] `assignments` (one active assignment per request invariant)
  - [x] `order_events` (immutable audit trail)
  - [x] `reviews` (one per completed request)
  - [x] `support_tickets`
  - [x] `notifications` & `device_tokens`
  - [x] `admin_audit_logs`
- [x] Row-Level Security (RLS) policies on all tables with FORCE ROW LEVEL SECURITY
- [x] Storage Buckets & Policies (`provider-documents`, `service-request-photos`)
- [x] Transactional RPC Functions with `SECURITY DEFINER` and safe `search_path`:
  - [x] `create_service_request`
  - [x] `cancel_service_request`
  - [x] `assign_provider_to_request`
  - [x] `respond_to_assignment`
  - [x] `progress_service_request`
  - [x] `admin_verify_provider`
  - [x] `bootstrap_admin`
  - [x] `admin_override_request_status`
- [x] Database automated tests (`supabase/tests/database_test.sql`) verifying isolation, role permissions, and invariants
- [x] Verification Gate: 10/10 automated tests executed and passing via `./supabase/tests/run_tests.sh`

---

*This document is updated continuously as each phase is executed.*
