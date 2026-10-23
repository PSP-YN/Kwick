# Architectural & Engineering Decisions Log (ADR)

## ADR-001: Monorepo vs Multi-repo Structure
- **Decision:** Use a single monorepo containing the Flutter mobile application (`lib/`, `android/`, `ios/`), the admin web dashboard (`admin/`), and the database infrastructure (`supabase/`).
- **Rationale:** Simplifies version synchronization between database migrations, Flutter client models, and the admin dashboard during the initial pilot phase. Prevents repository fragmentation.
- **Tradeoff:** Slightly larger root directory; handled with clear subfolder boundaries and distinct CI matrix jobs.

## ADR-002: State Management & Navigation in Flutter
- **Decision:** Use `flutter_riverpod` (v2/v3) for dependency injection and state management, and `go_router` for navigation.
- **Rationale:** Riverpod offers compile-time safety, effortless testing without mocks of Flutter widgets, and predictable state transitions. GoRouter provides declarative route definitions with easy role-based redirect guards.
- **Tradeoff:** Requires discipline around provider scopes and watching providers.

## ADR-003: Backend Authority & PostgreSQL Row-Level Security
- **Decision:** All authorization, state transitions, and assignment concurrency rules are enforced directly in PostgreSQL via RLS policies, unique constraints, and `SECURITY DEFINER` RPC functions.
- **Rationale:** UI-level hiding of buttons is insufficient for security. Having PostgreSQL as the single source of truth prevents malicious clients or forged requests from altering order status, viewing private customer addresses, or creating duplicate assignments.
- **Tradeoff:** Requires writing and maintaining SQL functions and pgTAP / integration tests for database logic.

## ADR-004: Financial Storage in Minor Units (Paise)
- **Decision:** All prices (`quoted_price_minor`, `final_price_minor`, `base_price_minor`) are stored as `BIGINT` representing integer paise (1 INR = 100 paise).
- **Rationale:** Floating-point representations suffer from rounding errors in financial transactions.
- **Tradeoff:** Formatting logic is required at the presentation layer to convert paise to INR strings (e.g. ₹250.00).

## ADR-005: Assignment Invariant via Partial Unique Index
- **Decision:** A partial unique index on `assignments(request_id)` for rows where `status IN ('offered', 'accepted')` is used to enforce that no service request can ever have more than one active assignment simultaneously.
- **Rationale:** Prevents race conditions and duplicate dispatches even under concurrent admin operations.
- **Tradeoff:** Completed, declined, and withdrawn assignments remain in the table for full audit history.

## ADR-006: Dedicated Admin Web Application
- **Decision:** Implement the internal operations portal as a separate Next.js web application in `admin/`, rather than bundling admin screens into the mobile app.
- **Rationale:** Keeps the mobile app bundle slim, avoids exposing admin attack surface to mobile reverse-engineering, and provides desktop/tablet-optimized ergonomics for dispatch operators.
- **Tradeoff:** Requires maintaining a TypeScript/React toolchain alongside Flutter.
