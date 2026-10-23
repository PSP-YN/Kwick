# NexHelp Implementation Plan

This document tracks all phases, tasks, completion status, and verification evidence for NexHelp.

---

## Phase Overview & Status

| Phase | Description | Status | Gate Verification |
| :--- | :--- | :--- | :--- |
| **Phase 0** | Audit and Foundation | **In Progress** | Flutter toolchain, Admin app, CI config, memory docs verified |
| **Phase 1** | Database and Security | **In Progress** | Schema migrations, RLS policies, RPC functions, DB tests |
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
- [ ] Supabase configuration & migrations setup (`supabase/migrations/`)
- [ ] Table definitions:
  - [ ] `profiles`
  - [ ] `user_roles` (`customer`, `provider`, `admin`, `super_admin`)
  - [ ] `service_areas` (Bengaluru pilot area)
  - [ ] `service_categories` (Plumbing and Electrical seeded)
  - [ ] `providers` (status: pending, approved, rejected, suspended; availability: available, busy, unavailable)
  - [ ] `provider_services` (pricing in integer paise)
  - [ ] `provider_documents` (private storage references)
  - [ ] `service_requests` (strict state machine)
  - [ ] `assignments` (one active assignment per request invariant)
  - [ ] `order_events` (immutable audit trail)
  - [ ] `reviews` (one per completed request)
  - [ ] `support_tickets`
  - [ ] `notifications` & `device_tokens`
  - [ ] `admin_audit_logs`
- [ ] Row-Level Security (RLS) policies on all tables
- [ ] Storage Buckets & Policies (`provider-documents`, `service-request-photos`)
- [ ] Transactional RPC Functions with `SECURITY DEFINER` and safe `search_path`:
  - [ ] `create_service_request`
  - [ ] `cancel_service_request`
  - [ ] `assign_provider_to_request`
  - [ ] `respond_to_assignment`
  - [ ] `progress_service_request`
  - [ ] `admin_verify_provider`
  - [ ] `bootstrap_admin`
- [ ] Database automated tests (`supabase/tests/`) verifying isolation, role permissions, and invariants
- [ ] Verification Gate: clean migration execution, RLS tests pass, zero privilege leaks

---

*This document is updated continuously as each phase is executed.*
