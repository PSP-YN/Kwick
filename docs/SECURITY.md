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
| **Create Service Request** | - | Insert (Own) | - | - | Insert / Manage |
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
2. Hardcode `SET search_path = public, pg_temp;` to neutralize search-path injection vulnerabilities.
3. Assert `auth.uid() IS NOT NULL` and check authorization explicitly before performing actions.
4. Record every administrative action in `public.admin_audit_logs`.
