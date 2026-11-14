# Kwick Security & Row-Level Security (RLS) Specification

See [Production Security & Operations](PRODUCTION_SECURITY_OPERATIONS.md) for the live project posture, recovery plan, settings still requiring dashboard verification, and launch gates.

## 1. Threat Model & Security Principles

1. **Defense-in-Depth:** Frontend screens reflect state, but never authorize state. All permission, access separation, and transitions are validated inside PostgreSQL and Supabase Auth.
2. **Zero Trust for Client Claims:** Role claims in JWTs are cross-referenced with `public.user_roles`. Users cannot arbitrarily assert `admin` or `provider` permissions without backend verification.
3. **Privacy by Design:**
   - Unassigned providers never receive customer addresses, phone numbers, or exact coordinates.
   - Private documents (KYC, trade certificates) and service photos reside in non-public Supabase Storage buckets with strict RLS policies.
   - Push notification payloads contain only IDs and status tags—never PII, phone numbers, or complete street addresses.

---

## 2. Role-Based Access Control (RBAC) Matrix

| Entity / Action | Anonymous | Customer | Provider (Pending) | Provider (Approved & Assigned) | Admin / Super Admin |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Service Categories (Active)** | Read | Read | Read | Read | Manage |
| **Service Areas (Active)** | Read | Read | Read | Read | Manage |
| **Customer Own Profile** | - | Read / Update | Read / Update | Read / Update | Read / Manage |
| **Create Service Request** | - | Execute (RPC) | - | - | Insert / Manage |
| **Read Unassigned Requests** | - | - | - | - | Read |
| **Read Assigned Request** | - | Read (Own) | - | Read (Assigned) | Read |
| **Customer Address / Phone** | - | Read (Own) | - | Read (Active Job Only) | Read |
| **Submit Job Review** | - | Insert (Completed) | - | - | Moderate |
| **Provider Availability Toggle**| - | - | Update (Own) | Update (Own) | Override |
| **Provider Verification Docs** | - | - | Upload (Own) | Upload (Own) | Read / Review |
| **Manual Dispatch / Assign** | - | - | - | - | Execute (RPC) |
| **Admin Audit Logs** | - | - | - | - | Read Only |

---

## 3. Privileged Functions (`SECURITY DEFINER`) Controls

Transactional SECURITY DEFINER implementations live in the non-PostgREST `private` schema. The public RPC names are SECURITY INVOKER wrappers, preserving client calls without exposing privileged function bodies. Trigger-only SECURITY DEFINER functions have no API-role EXECUTE grants.

For user-invoked privileged operations:
1. Specify `SECURITY DEFINER` only for the private implementation.
2. Set `search_path` to the empty string and schema-qualify every application object.
3. Assert `auth.uid() IS NOT NULL` and check authorization explicitly before performing actions. Trusted trigger/system functions may run with no end-user JWT but must remain non-executable through the Data API.
4. Record every administrative action in `public.admin_audit_logs`.
5. Revoke `EXECUTE` from `PUBLIC` and `anon` for privileged RPCs; grant only the authenticated role required by the client.
6. Keep lookup helpers scoped to `auth.uid()` or an AAL2 administrator. Cross-user helper calls return no rows. Private helper implementations are not in the PostgREST-exposed schema list.
7. Restrict column-level writes: providers can update availability only; profiles can update name and phone only; request and assignment state transitions, order events, and audit logs are changed through transactional RPCs.
8. The first-admin bootstrap is callable only by the trusted database owner through the SQL editor. It is not a Data API endpoint.
9. AI diagnosis requires a valid Supabase JWT and affirmative, versioned user consent; the Gemini key remains server-side; only usage metadata and the consent version are stored in the quota table; obvious identifiers are redacted best-effort; production requests are blocked unless the Gemini paid tier is operator-confirmed. Unpaid Gemini API services must not receive real customer data.
10. Provider verification must not routinely collect full Aadhaar numbers or biometrics. Offer alternative identity documents and obtain specialist approval before any UIDAI-based offline-verification flow.
11. All admin and super-admin database access requires a Supabase Auth JWT with `aal = 'aal2'`; the operations console supports TOTP enrollment and challenge. Client-side role hiding is not the authorization boundary.
