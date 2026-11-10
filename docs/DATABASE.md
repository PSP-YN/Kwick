# NexHelp Database Specification & Invariants

## 1. Schema Overview

The NexHelp database is implemented in PostgreSQL and managed through versioned Supabase migrations in `supabase/migrations/`:

- `20261023000001_initial_schema.sql`: Core tables, check constraints, foreign keys, and indexes.
- `20261023000002_rls_policies.sql`: Row-Level Security policies for Customer, Provider, Admin, and Public access.
- `20261023000003_rpc_functions.sql`: Transactional `SECURITY DEFINER` functions enforcing order state transitions, provider assignment, and verification.
- `20261023000004_seed_pilot_data.sql`: Seed data for Bengaluru pilot service area, plumbing/electrical categories, and private storage buckets.
- `20261111000005_harden_admin_bootstrap.sql`: Restricts first-admin bootstrap execution to trusted database operators.
- `20261111000006_auth_provisioning_and_write_privileges.sql`: Provisions profiles and allowlisted roles from Auth events and narrows direct table writes.
- `20261111000007_dispatch_provider_invariants.sql`: Enforces one active offer/job per provider and matching service-area eligibility.
- `20261111000008_ai_diagnosis_usage.sql`: Stores private per-user AI usage metadata without storing customer issue descriptions.

---

## 2. Tables and Relationships

```
 auth.users
     │
     ├──< profiles (1:1)
     ├──< user_roles (1:N)
     ├──< providers (1:1 via profile_id)
     │       ├──< provider_services (1:N) >── service_categories
     │       └──< provider_documents (1:N)
     │
     ├──< service_requests (1:N as customer)
     │       ├──> service_categories
     │       ├──> service_areas
     │       ├──< assignments (1:N) >── providers
     │       ├──< order_events (1:N)
     │       ├──< reviews (1:1)
     │       └──< support_tickets (1:N)
     │
     ├──< notifications (1:N)
     ├──< device_tokens (1:N)
     └──< admin_audit_logs (1:N as actor)
```

---

## 3. Critical Invariants

### 3.1 Single Active Assignment Invariant
A partial unique index guarantees that at any instant, a service request can have at most one active (`offered` or `accepted`) assignment:
```sql
CREATE UNIQUE INDEX idx_assignments_single_active 
    ON public.assignments(request_id) 
    WHERE status IN ('offered', 'accepted');
```
Attempts to assign a second provider while an assignment is offered or accepted will abort with a unique violation, preventing dual-dispatch race conditions.

### 3.2 Financial Pricing Precision
All financial values (`quoted_price_minor`, `final_price_minor`, `base_price_minor`) are stored as `BIGINT` representing integer paise (1 INR = 100 paise). Check constraints enforce non-negative values. No floating-point rounding errors exist in the database.

### 3.3 Strict State Machine
Order status is governed by strict sequential transitions:
`requested` → `reviewing` → `assigned` → `accepted` → `travelling` → `in_progress` → `completed`
Cancellation is only allowed in pre-service states (`requested`, `reviewing`, `assigned`). Disputing is supported during or after service (`in_progress`, `completed`).

### 3.4 Provider Eligibility Enforcement
An assignment cannot be created unless:
1. Provider `verification_status = 'approved'`
2. Provider `availability_status <> 'unavailable'`
3. Provider has an active record in `provider_services` matching the request's `category_id`.

---

## 4. Storage Buckets

1. `provider-documents`: Private bucket for verification proof (ID cards, trade certificates). Size limit: 10MB.
2. `service-request-photos`: Private bucket for issue diagnosis images. Size limit: 5MB.
