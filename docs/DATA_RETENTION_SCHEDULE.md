# NexHelp Data Retention and Deletion Schedule

**Status: PRE-LAUNCH DRAFT.** Final periods require Indian legal, tax and operational approval. Do not invent retention periods or retain identity documents indefinitely.

| Data class | Purpose | Proposed handling | Deletion / review trigger |
|---|---|---|---|
| Account profile and contact details | Authentication and service coordination | Retain while account is active; restrict access by role | Verified account-deletion request, subject to legal holds and active jobs |
| Service request, quote, job status and dispute records | Contract/service fulfilment, complaints, safety and legal evidence | Keep only as long as required for service, dispute, consumer and tax obligations | End of approved statutory/contractual retention period |
| Exact service address and contact data | Dispatch and job fulfilment | Show only to the customer, authorized operations staff and the provider assigned to the active job | Remove from routine provider access after job completion; retain only where justified |
| Provider identity and trade documents | Identity, qualification and safety verification | Private storage, least-privilege access, short-lived signed URLs; never public | Delete when no longer needed for verification, appeals, legal or insurance purposes |
| AI diagnosis usage metadata | Quota, abuse prevention and consent evidence | Store user ID, model, timestamp and consent notice version; do not store raw prompt in this table | Review periodically; retain only for the approved security/consent purpose |
| AI issue description | Optional one-time Gemini triage | Do not copy raw text into AI usage logs; use only with explicit consent and paid-tier processing | Not retained by the AI usage table; service-request description remains subject to booking-record retention |
| Security and access logs | Incident investigation and compliance | Secure, access-controlled, exportable logs | At least 180 days within India where CERT-In Directions apply; align with DPDP Rule 6 one-year security-log requirement when it commences |
| Backups | Recovery and continuity | Encrypted, access-controlled, restore-tested | Expire according to documented backup rotation; deletion requests propagate through backup lifecycle where legally and technically feasible |
| Support tickets | Complaint resolution and audit | Restrict access; redact unnecessary sensitive details | End of approved consumer/dispute retention period |

## Controls

- Define an owner and approved retention period for every data class before public launch.
- Implement scheduled deletion jobs with dry-run mode, audit logs and exception/hold handling.
- Do not delete records subject to active legal holds, fraud investigations, safety claims or mandatory tax/consumer retention.
- Account deletion must remove or de-identify data that no longer has a lawful retention purpose, while retaining only records legally required.
- Verify deletion from primary database, Storage objects, search indexes, logs and backups according to the approved lifecycle.
- Never store full Aadhaar numbers, Aadhaar biometrics, passwords or payment-card data in NexHelp application tables.
- Reassess this schedule whenever a new processor, payment flow, identity-verification method or data category is introduced.
