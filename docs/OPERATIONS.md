# Kwick Pilot Operations & Dispatch Runbook

## 1. Pilot Scope & Configuration

- **Pilot Region:** The configured 560102 service zone (HSR Layout focus). Koramangala is not covered until a separate service-area record and eligible provider roster are configured.
- **Active Pincodes:** `560102`
- **Active Service Categories:**
  - Plumbing (Tap & faucet, pipe leaks, drain blocks, toilet repairs)
  - Electrical (Switches, sockets, fan/lighting fixtures, fault diagnosis)
- **Pilot Operating Hours:** 08:00 AM – 08:00 PM IST
- **Internal dispatch target:** 15 minutes for operator review. This is an operational target, not a customer-facing SLA; measure it before publishing a guarantee.

---

## 2. Provider Onboarding & Verification Procedures

1. **Application Submission:**
   - Provider signs up, fills out experience and selects category (`plumbing` or `electrical`), then uploads supported evidence in Kwick Partner. The provider remains pending until an operator completes the approved manual verification process.
   - Initial status: `pending`. Provider cannot view requests or receive assignments.
2. **Operator Document Review:**
   - Operator logs into Admin Dashboard (`/admin/providers`).
   - Reviews permitted identity and trade evidence through the approved secure process, checks trade background and verifies contact details. Do not routinely collect or retain full Aadhaar numbers or biometrics; offer an alternative identity document.
3. **Approval / Rejection:**
   - Operator records verification evidence and triggers `admin_verify_provider(provider_id, 'approved', notes)`. Any UIDAI-based offline-verification workflow requires separate legal approval and applicable consent and safeguards.
   - Provider verification changes to `approved`.
   - Provider becomes eligible for manual job dispatch.

---

## 3. Manual Dispatch & Assignment Workflow

1. **Incoming Request Notification:**
   - New customer booking appears in `/admin/requests` with status `requested`.
2. **Review & Provider Matching:**
   - Operator verifies request location is within active pilot area (`560102`).
   - Operator views candidate providers filtered by:
     - `verification_status = 'approved'`
     - `availability_status = 'available'`
     - Matching service category.
3. **Assignment Execution:**
   - Operator selects candidate provider, enters quoted price in paise (e.g. ₹350 = `35000`), and confirms.
   - Backend transaction checks provider availability and atomic invariant (no existing active assignment).
   - Assignment status set to `offered`; request status set to `assigned`.
4. **Provider Acceptance / Decline:**
   - Provider receives push and in-app alert.
   - No automatic offer-expiry job is currently implemented. Operators must monitor outstanding offers and use the authorized withdrawal/reassignment workflow; do not promise an automatic 15-minute expiry.
   - **Accept:** Provider availability changes to `busy`; request status becomes `accepted`.
   - **Decline:** Assignment marked `declined` with reason; request automatically reverts to `requested` for operator reassignment.

---

## 4. Job Progression & Completion

1. **Travelling:** Provider taps "On the Way". Request moves to `travelling`. Customer sees provider is en route.
2. **Service Started:** Provider arrives and taps "Start Service". Request moves to `in_progress`.
3. **Completion:** Provider finishes work, reviews final bill with customer, and taps "Complete Service".
   - Provider enters final price in paise.
   - Request moves to `completed`.
   - Provider availability automatically resets to `available`.
   - Customer receives prompt to rate and review service.

---

## 5. Cancellation & Dispute Resolution

1. **Cancellation Policy:**
   - Customer can cancel anytime while status is `requested`, `reviewing`, or `assigned` without fee.
   - If cancelled while assignment is `offered`, assignment is automatically withdrawn.
   - Once job is `in_progress`, cancellation is disabled; customer must use "Raise Issue / Dispute".
2. **Dispute Handling:**
   - Customer or provider can submit a support ticket.
   - Operator reviews order event history and audit logs.
   - If required, operator performs documented status correction via `admin_override_request_status`.
