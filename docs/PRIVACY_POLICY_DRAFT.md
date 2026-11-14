# Kwick Privacy Notice — Draft for Legal Review

**DRAFT — NOT APPROVED FOR PUBLICATION.** Replace every bracketed field, verify the actual deployment and data flows, and obtain Indian legal review before publishing.

**Effective date:** [DATE]  
**Data fiduciary / platform operator:** [FULL LEGAL ENTITY NAME]  
**Registered office:** [FULL POSTAL ADDRESS]  
**Privacy and grievance contact:** [MONITORED EMAIL]  
**Grievance officer:** [NAME, DESIGNATION, EMAIL, PHONE]

## 1. Who we are

Kwick is a proposed digital marketplace that helps customers request plumbing and electrical services from independent service providers. The platform coordinates request intake, manual review, provider verification and job status. It is not itself a licensed electrical contractor or emergency service.

## 2. Personal data we may process

Depending on how you use Kwick, we may process:

- Account and contact details: name, email address, phone number and account identifiers.
- Service details: issue description, selected category, service address, pincode, preferred appointment time, optional notes and booking/job history.
- Location data: address and, only if the feature is enabled and permission is granted, approximate or precise device location.
- Customer support and dispute data: messages, issue category, complaint status and resolution records.
- Reviews and ratings submitted after a completed service.
- Provider information: contact details, service categories, experience, verification status and permitted identity/trade documents.
- Technical and security data: device/app version, authentication events, IP/network logs and security/audit events.
- AI consent records: whether you opted into a particular version of the optional AI triage notice, the model identifier and the timestamp of the request.

Do not submit passwords, payment-card data, full Aadhaar numbers, biometrics, health information or unrelated sensitive information in free-text fields.

## 3. Why we use the data

We use data only for defined operational purposes, including account creation and authentication, receiving and managing service requests, checking service-area coverage, coordinating an assigned provider, customer support, complaints and disputes, fraud/security prevention, audit, legal compliance and improving service reliability.

Optional AI triage is a separate purpose and is not required to submit a booking.

## 4. Optional AI triage and Google Gemini

If you actively select the AI consent checkbox, Kwick sends the issue description and selected service-category hint to Google Gemini to generate an advisory category, urgency, safety alerts, follow-up questions and a dispatcher note.

- AI triage is optional. You can submit a booking without using it.
- Kwick does not intentionally send your account profile, phone number, service address or booking photos to Gemini.
- The service attempts to redact obvious phone-number, email, Aadhaar-like and PAN-like patterns. Automated redaction is not guaranteed; do not include names, addresses, identity details, health or financial information in the issue description.
- Production AI must use a verified paid Gemini API project. Do not enable AI for real customer data on unpaid/free-tier Gemini services.
- Google may process the submitted description under its applicable Gemini API terms and data-processing terms. Review the current terms at [Gemini API Additional Terms](https://ai.google.dev/gemini-api/terms).
- AI output may be inaccurate. It does not diagnose, price, book, dispatch or override a human decision.

The consent notice version currently recorded by the application is `2026-11-11-v1`. Update this notice and the version identifier together whenever the purpose, data sent or processor changes.

## 5. Who may receive data

Data may be shared only as needed with:

- The assigned service provider, limited to the information needed to fulfil the job.
- Authorized Kwick operations and support personnel.
- Supabase for authentication, database and storage services.
- Vercel for website/operations-console hosting.
- Google for optional AI triage when you consent.
- Professional advisers, regulators, law-enforcement authorities or courts where disclosure is legally required.

The current product does not integrate a payment processor. If payments are introduced, this notice must be updated before collection begins.

## 6. Hosting and transfers

The intended Supabase database region for the pilot is Mumbai, India. This does not by itself prove that every service, support log, backup, AI request or third-party processing operation remains in India. Kwick must verify and disclose the actual locations and contractual safeguards of every processor before launch. No blanket India-only data-residency promise is made in this draft.

## 7. Retention

We retain information only for the period needed for the stated purpose, dispute handling, security, accounting/tax requirements and other applicable legal obligations. The final schedule must be published after legal review. Security logs must be configured to meet applicable CERT-In retention requirements and the DPDP Rules when their relevant provisions commence. Provider identity documents should be access-restricted and deleted when no longer required, subject to lawful retention and dispute needs.

## 8. Your choices and requests

Subject to applicable law and verification of identity, you may request access to, correction of or deletion of eligible personal data, withdraw consent for future optional AI triage, raise a grievance or ask about processing. Withdrawing AI consent prevents future AI calls but does not automatically erase booking records or records that must be retained for legal, safety, fraud or dispute purposes.

Request channel: [PRIVACY REQUEST EMAIL / IN-APP FLOW].  
Expected acknowledgement and resolution timelines: [LEGAL-APPROVED TIMELINES].

## 9. Security

Kwick is implementing role-based access, row-level security, private storage, least-privilege access, server-side secrets, audit events, encrypted transport, backup and incident-response controls. No online service can guarantee absolute security. Security claims in the final notice must match independently verified controls.

## 10. Children

[DECIDE AND IMPLEMENT AGE POLICY.] Recommended pilot policy is to allow account holders aged 18 or older only. Do not knowingly collect children's personal data unless a compliant, legally reviewed parental-consent and age-verification process has been implemented.

## 11. Changes and contact

Material changes will be communicated through [APP / EMAIL / WEBSITE]. For privacy questions or grievances, contact [PRIVACY CONTACT] or [GRIEVANCE OFFICER CONTACT].

**Publication gate:** This draft must not be published until all placeholders are completed, data flows and processors are verified, age policy is implemented, and counsel approves it.
