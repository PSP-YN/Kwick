# NexHelp Implementation Plan

This document tracks all phases, tasks, completion status, and verification evidence for NexHelp.

---

## Phase Overview & Status

| Phase | Description | Status | Gate Verification |
| :--- | :--- | :--- | :--- |
| **Phase 0** | Audit and Foundation | **Completed** | Flutter toolchain, Admin app, CI config, memory docs verified |
| **Phase 1** | Database and Security | **Completed** | 4 SQL migrations applied; 10/10 automated tests passed in isolated Postgres |
| **Phase 2** | Authentication and Navigation | **Completed** | Registration, login, profile bootstrap, role-based GoRouter |
| **Phase 3** | Customer Booking Journey | **Completed** | Discovery, booking flow, order history, cancellation, review |
| **Phase 4** | Provider Workflows | **Completed** | Onboarding, availability toggle, assignment accept/decline/progress |
| **Phase 5** | Admin Operations Dashboard | **Completed** | Next.js 16 portal, provider audits, dispatch queue, status override |
| **Phase 6** | Notifications & Alerts | **Completed** | Device token schema, Supabase service client alerts, status badges |
| **Phase 7** | Hardening & Quality Assurance| **Completed** | 40/40 Flutter unit & widget tests pass; 10/10 DB tests pass |
| **Phase 8** | Android Pilot Readiness | **Completed** | Android manifest permissions, cleartext local support, Gradle dry-run passed |
| **Phase 9** | iOS Readiness & Pilot Setup | **Completed** | Shared codebase iOS Runner setup, release and deployment checklist in `docs/RELEASE.md` |

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
  - [x] `assignments` (one active assignment per request invariant via partial unique index)
  - [x] `order_events` (immutable audit trail)
  - [x] `reviews` (one per completed request)
  - [x] `support_tickets`
  - [x] `notifications` & `device_tokens`
  - [x] `admin_audit_logs`
- [x] Row-Level Security (RLS) policies on all tables with `FORCE ROW LEVEL SECURITY`
- [x] Storage Buckets & Policies (`provider-documents`, `service-request-photos`)
- [x] Transactional RPC Functions with `SECURITY DEFINER` and safe `search_path`:
  - [x] `create_service_request`
  - [x] `cancel_service_request`
  - [x] `assign_provider_to_request`
  - [x] `respond_to_assignment`
  - [x] `progress_service_request`
  - [x] `admin_verify_provider`
  - [x] `admin_override_request_status`
  - [x] `bootstrap_admin`
- [x] Automated test runner (`supabase/tests/run_tests.sh`) executing in isolated PostgreSQL container (10/10 tests pass)

### Phase 2: Authentication and Navigation
- [x] Supabase Auth integration (Phone OTP / Email auth with fallback)
- [x] Riverpod `NotifierProvider` state management (`authControllerProvider`)
- [x] Profile bootstrapping into `public.profiles` and `public.user_roles`
- [x] Role-aware declarative routing with `GoRouter` (`/customer`, `/provider`, `/admin`, `/login`)
- [x] Login and Registration screens with Indian mobile validation (+91)

### Phase 3: Customer Booking Journey
- [x] Category & Service Discovery (Bengaluru South 560102)
- [x] Booking wizard: address input with validation, description, scheduled slot
- [x] Order history with status badges and live filtering
- [x] Real-time order details with 5-stage progress tracker
- [x] Order cancellation dialog with refund and cancellation reason
- [x] Post-service review submission screen with 5-star rating

### Phase 4: Provider Workflows
- [x] Provider onboarding form (service category selection, experience years, document upload)
- [x] Availability toggle (Available / Offline)
- [x] Real-time assignment feed (`offered`, `accepted`, `in_progress`)
- [x] Assignment action sheet: Accept / Decline with reason
- [x] Sequential order progression: Start Job -> Complete Job with notes
- [x] Earnings & Completed jobs ledger

### Phase 5: Admin Operations Dashboard
- [x] Next.js 16 + TypeScript + Tailwind CSS application in `admin/`
- [x] Supabase operations data layer with interactive mock fallback (`admin/src/lib/supabase.ts`)
- [x] Operations overview with live KPI metric cards (Awaiting dispatch, in-progress jobs, verified pros)
- [x] Manual Dispatch queue with provider allocation modal
- [x] Provider identity and credential audit review table with approval notes
- [x] Authoritative emergency status override tool with logged audit reason
- [x] Linting and static production build verification (`npm --prefix admin run lint && npm --prefix admin run build`)

### Phase 6: Notifications & Alerts
- [x] Notification data model and state providers
- [x] In-app notification center and alert badges
- [x] Push notification device token registration schema

### Phase 7: Hardening & Quality Assurance
- [x] Unit test suite: Currency formatter (paise to INR), Date formatter, Indian phone and pincode validators, Order state machine rules, Model serialization
- [x] Widget test suite: PrimaryButton, ConfirmationDialog, StatusBadge, EmptyStateView, ErrorStateView, AppTextField
- [x] Static analysis: `flutter analyze` zero issues, `dart format` 100% compliant

### Phase 8: Android Pilot Readiness
- [x] `android/app/src/main/AndroidManifest.xml` permissions: `INTERNET`, `ACCESS_NETWORK_STATE`, cleartext traffic support for local testing
- [x] Gradle 9.1.0 and AGP build configuration verified via `./gradlew tasks --dry-run` (`BUILD SUCCESSFUL in 25s`)
- [x] Release signing instructions and checklist in `docs/RELEASE.md`

### Phase 9: iOS Readiness & Final Delivery
- [x] Shared Flutter codebase iOS Runner setup
- [x] Comprehensive release and deployment guide (`docs/RELEASE.md`)
- [x] Memory files synchronized (`PROJECT.md`, `TASKS.md`, `DECISIONS.md`)
