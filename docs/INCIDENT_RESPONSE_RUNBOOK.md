# NexHelp Security Incident Response Runbook

**Status: PRE-LAUNCH DRAFT.** Assign named primary/alternate incident commanders and an India-based CERT-In point of contact before launch.

## 1. Trigger examples

Treat suspected credential exposure, unauthorized admin access, RLS bypass, cross-customer data access, private-storage exposure, ransomware, data exfiltration, lost admin device, payment fraud, malicious provider access and AI-secret exposure as security incidents.

## 2. First response

1. Open a restricted incident record with UTC and IST timestamps, reporter, affected systems and known facts.
2. Assign an incident commander and technical lead.
3. Preserve logs, request IDs, database audit events, deployment identifiers and evidence. Do not overwrite or publicly disclose evidence.
4. Contain safely: revoke/rotate exposed credentials, disable affected Edge Functions or user sessions, suspend compromised accounts, block affected origins and restrict access.
5. Do not destroy evidence or make unverified public claims.
6. Assess what data, users, providers, processors and locations are affected.
7. Keep a decision log, actions, approvals and timestamps.

## 3. India reporting obligations to operationalize

- CERT-In's 28 April 2022 Directions require covered entities to report specified cyber incidents within **six hours** of noticing them or being informed of them. Report with information available at the time and supplement as permitted by CERT-In guidance.
- The Directions require covered entities to enable ICT logs and retain them securely for a rolling **180 days within Indian jurisdiction**. Verify that the selected cloud providers and log exports can meet this requirement; do not assume a vendor dashboard alone is sufficient.
- The DPDP Rules 2025 Rule 7 data-breach notification requirements are scheduled to commence on **13 May 2027** under the notified timeline. Build the process now and re-check for later notifications. The rule specifies prompt notice to affected individuals and Board reporting, including detailed follow-up within 72 hours after awareness, subject to the rule's exact text and any Board direction.
- Other contractual, sectoral, consumer, law-enforcement or tax notification duties may also apply. Counsel must determine the exact trigger and recipient for each incident.

## 4. Customer/provider communications

Use a verified contact channel. Explain the nature and approximate time of the incident, affected information, likely consequences, protective steps, and a contact for questions. Do not disclose another user's information or speculate beyond confirmed facts.

## 5. Recovery and closure

1. Restore from a verified backup into a clean environment.
2. Rotate all credentials that may have been exposed.
3. Patch the root cause and add regression tests.
4. Verify RLS, Storage policies, Auth sessions, admin MFA, logs and secrets.
5. Notify affected parties and regulators as legally required.
6. Record root cause, impact, timeline, decisions, corrective actions and evidence retention.
7. Run a post-incident review and update the threat model.

## 6. Required contacts to fill before launch

- Incident commander: [NAME / PHONE / EMAIL]
- Technical lead: [NAME / PHONE / EMAIL]
- CERT-In point of contact: [NAME / DESIGNATION / INDIA ADDRESS / PHONE / EMAIL]
- Legal counsel: [NAME / PHONE / EMAIL]
- Supabase escalation contact: [ACCOUNT / SUPPORT ROUTE]
- Vercel escalation contact: [ACCOUNT / SUPPORT ROUTE]
- Google AI escalation contact: [ACCOUNT / SUPPORT ROUTE]
