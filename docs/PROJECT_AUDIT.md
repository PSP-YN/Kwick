# Kwick — Initial Repository and Environment Audit

**Date:** 2026-10-23  
**Auditor:** Principal Software Architect & Lead Engineer  
**Branch:** `main` (initial commit pending)  
**Status:** In Progress — Phase 0

---

## 1. Environment & Toolchain Inspection

| Tool / Runtime | Installed Version | Target / Minimum Required | Verification Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **OS** | Fedora Linux 44 (Workstation Edition) 7.2.9 | Linux x86_64 | Verified (`uname -r`) | Primary development OS |
| **Flutter** | 3.44.0 (Channel stable, revision 559ffa3f75) | Flutter 3.x+ | Verified (`flutter --version`) | Dart 3.12.0 bundled |
| **Dart SDK** | 3.12.0 (stable) | Dart 3.x with sound null safety | Verified (`dart --version`) | Sound null safety active |
| **Java JDK** | OpenJDK 17.0.12 (Temurin-17.0.12+7) | Java 17 | Verified (`java -version`) | Controlled via SDKMAN, compatible with Gradle 8+ |
| **Android SDK** | 36.1.0 (`/home/psp/Android/Sdk`) | Android API 33-36 | Verified (`flutter doctor -v`) | Build-tools 36.1.0 available |
| **Node.js** | v24.15.0 | Node 18+ / 20+ | Verified (`node -v`) | Used for Next.js Admin & Supabase functions |
| **npm** | 11.12.1 | npm 9+ | Verified (`npm -v`) | Package manager for admin app |
| **Supabase CLI**| 2.90.0 | Supabase CLI 2.x | Verified (`supabase --version`) | Local migrations, RLS, functions |
| **Docker** | Docker CLI & daemon active | Docker Engine | Verified (`docker ps`) | Required for local Supabase emulator |
| **Disk Space** | 58 GB available on root mount | > 10 GB required | Verified (`df -h .`) | Sufficient for Android builds and Docker images |

---

## 2. Repository State Prior to Work

- **Initial State:** Empty directory with `.ai-memory/` (`PROJECT.md`, `TASKS.md`, `DECISIONS.md`), `AGENTS.md`, and `CLAUDE.md`.
- **Pre-existing Code:** None. No legacy baggage or uncommitted code to refactor.
- **Git Tree:** Clean, untracked initialized files.

---

## 3. Technology Selections & Rationale

1. **Mobile Application (Flutter):**
   - **Framework:** Flutter 3.44.0 with Dart 3.12.0.
   - **State Management:** Riverpod (`flutter_riverpod: ^2.6.1` / `^3.4.3`) for clean dependency injection, testability, and state immutability.
   - **Routing:** GoRouter (`go_router`) for declarative, deep-link capable, role-aware routing.
   - **Backend Client:** `supabase_flutter` for Supabase Auth, PostgreSQL PostgREST queries, and private Storage.
   - **Push Notifications:** Firebase Cloud Messaging (FCM) abstraction ready, with graceful fallback.
   - **Secure Storage:** `flutter_secure_storage` for session tokens and secure flags.

2. **Backend & Security (Supabase / PostgreSQL):**
   - **Database:** PostgreSQL with Row-Level Security (RLS) on all application tables.
   - **Authentication:** Supabase Auth (`auth.users`), linked to custom `profiles` and `user_roles`.
   - **State Invariants:** Database constraints, transactional PostgreSQL RPC functions (`SECURITY DEFINER` with search path controls and caller validation).
   - **Financial/Pricing:** Integer paise (minor currency units) for all pricing fields. No floating-point math.
   - **Document & Media Storage:** Supabase Storage private buckets for `provider-documents` and `service-request-photos`.

3. **Operations Dashboard (`admin/`):**
   - **Framework:** Next.js with TypeScript and Tailwind CSS.
   - **Role:** Protected internal tool for Kwick operators (provider review, manual dispatch, audit logs).

---

## 4. Identified Constraints & Gaps

1. **iOS Release Validation:** Development machine is Linux Fedora. While cross-platform Flutter code and iOS configuration are maintained in `ios/`, compilation and release signing for iOS require a macOS/Xcode runner. CI workflow will validate Flutter tests, linting, and Android builds locally.
2. **Push Notification Keys:** Firebase service account and Google Services JSON will use environment-driven configuration with mock/disabled safety fallbacks when credentials are not present.
3. **SMS OTP Gateway:** Real-world SMS OTP requires external gateway credentials (e.g., Twilio/MessageCentral). Initial auth uses email/password and Supabase Auth with SMS provider hooks ready for credentials.

---

## 5. Audit Conclusion

The local environment is fully qualified to build the Flutter mobile application, test the Supabase migrations and RLS policies, and run the Next.js admin dashboard. Proceeding with Phase 0 foundation setup and Phase 1 database implementation.
