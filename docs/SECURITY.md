# NexHelp Security & Row-Level Security (RLS) Specification

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

All stored procedures that bypass ordinary table constraints or modify critical multi-table invariants:
1. Specify `SECURITY DEFINER`.
2. Set `search_path` to the empty string and schema-qualify every application object.
3. Assert `auth.uid() IS NOT NULL` and check authorization explicitly before performing actions.
4. Record every administrative action in `public.admin_audit_logs`.
5. Revoke `EXECUTE` from `PUBLIC` and `anon` for privileged RPCs; grant only the authenticated role required by the client.
6. Keep lookup helpers scoped to `auth.uid()` or an administrator. Cross-user helper calls return no rows, and internal role/provider lookup helpers are not directly executable by clients.
7. Restrict column-level writes: providers can update availability only; profiles can update name and phone only; request and assignment state transitions, order events, and audit logs are changed through transactional RPCs.
8. The first-admin bootstrap is callable only by the trusted database owner through the SQL editor. It is not a Data API endpoint.
9. AI diagnosis requires a valid Supabase JWT, keeps the Gemini key server-side, stores only user/model/timestamp usage metadata, and never persists the raw issue description in the quota table.
