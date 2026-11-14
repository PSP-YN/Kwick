# Kwick — India legal and compliance register

**Status: PRE-LAUNCH. This register is an engineering control plan, not legal advice or a legal opinion. Kwick is not legally cleared to accept public bookings or payments.** The company identity, registered address, grievance officer, contracts, insurance, tax treatment and final public policies are not yet supplied or approved.

Last reviewed: 11 November 2026. Re-check the Gazette, regulator directions and professional advice immediately before launch.

## 1. Business and operating model

Kwick is designed as a digital marketplace that introduces consumers to independent home-service providers for plumbing and electrical work. The platform currently supports request intake, manual operations review, provider verification status, manual dispatch, job status and optional AI-assisted triage.

The current pilot configuration is limited to pincode **560102 (HSR Layout focus)**. Koramangala is not in scope until a separate service area and provider roster are configured.

The current product does **not** have payment collection, provider payouts, wallet balances, subscriptions or an automated refund engine. Do not advertise or enable these until tax, consumer, RBI/payment and reconciliation controls are approved.

## 2. Applicable Indian requirements and implementation status

| Area | Relevance | Required launch control | Current status |
|---|---|---|---|
| Consumer Protection Act 2019 and Consumer Protection (E-Commerce) Rules 2020, as amended | The rules cover services and marketplace models | Display legal entity name, registered/head-office address, website details, customer-care and grievance contacts; publish complaint intake and tracking; acknowledge complaints within 48 hours and resolve within one month; disclose provider/seller details, charges, cancellation/refund terms and material ranking parameters; execute written provider/platform terms | **Open** — entity and grievance details missing; complaint SLA workflow and public disclosures not complete |
| Digital Personal Data Protection Act 2023 and DPDP Rules 2025 | Personal data in accounts, addresses, requests, provider profiles, documents and logs | Build clear purpose-specific notices, consent records, withdrawal, access/correction/erasure workflows, grievance handling, processor contracts, security controls and breach response | **Readiness in progress** — staged commencement; core operational duties scheduled for 13 May 2027; implement before then |
| IT Act 2000 and SPDI Rules 2011 | Sensitive personal data may be processed, including financial, health, password and biometric information | Publish privacy policy; collect only necessary information; obtain required consent; implement reasonable security practices and controlled disclosures | **Open** — final privacy notice and formal security audit required |
| CERT-In Directions under IT Act s.70B (28 Apr 2022) | Kwick's systems and service providers may fall within covered entities | Appoint an India-based point of contact; maintain covered ICT logs for at least 180 days within Indian jurisdiction; report listed cyber incidents within six hours of noticing them; retain evidence and respond to directions | **Open** — point of contact, log evidence and tested incident process not appointed/verified |
| Aadhaar Act and UIDAI regulations | Provider identity verification may involve government identity documents | Do not make Aadhaar mandatory; do not collect Aadhaar biometrics; avoid retaining full Aadhaar numbers or Aadhaar e-KYC payloads; provide an alternative identity route; obtain specialist advice before any UIDAI offline-verification workflow | **Policy required** — admin UI must not instruct staff to collect full Aadhaar |
| CEA Measures relating to Safety and Electric Supply Regulations 2023 and current amendments | Electrical work can create serious safety risks | Verify provider competence and any applicable electrical contractor/worker authorization; record credential review; define prohibited work and escalation; require safe isolation and no unsafe customer instructions | **Open** — provider-document upload and verified electrical credential workflow not implemented |
| GST and income-tax rules | Marketplace commissions, service invoices, provider payouts and collections may create tax obligations | Obtain a written tax opinion on GST registration, e-commerce operator/TCS treatment, invoices, provider tax status and section 194-O withholding before monetization | **Not activated** — no payment/commission flow in current pilot |
| RBI/payment-system rules | Relevant if Kwick collects, holds, routes or settles customer money | Use an appropriately authorized payment aggregator; do not create an unapproved wallet or hold funds; implement refunds, chargebacks, reconciliation and settlement controls | **Not activated** — no payment processor integrated |
| Labour, contractor and social-security law | Provider classification depends on actual control, economics and working practices, not contract labels alone | Obtain counsel review of provider classification, working conditions, social-security/gig-worker obligations, insurance and accident responsibility | **Open** — provider agreement is a draft only |
| Accessibility and app-store disclosures | Mobile and web users need accessible flows and transparent data disclosures | Target WCAG 2.2 AA; publish privacy/terms URLs; complete Google Play Data Safety and account/data deletion disclosures before store release | **Open** — final policies and store declarations not complete |

## 3. DPDP phased commencement — do not misstate the dates

The commencement notification G.S.R. 843(E) and the DPDP Rules 2025 G.S.R. 846(E) use staged commencement dates measured from 13 November 2025:

- **13 November 2025:** the provisions listed in the first commencement group and Rules 1, 2 and 17–21 took effect.
- **13 November 2026:** Section 6(9), Section 27(1)(d) and Rule 4 are scheduled to take effect.
- **13 May 2027:** the main data-fiduciary duties in Sections 3–17 (subject to the notification's exact sub-section exclusions), the remaining listed sections and Rules 3, 5–16, 22–23 are scheduled to take effect.

The schedule is not a reason to delay privacy engineering. Implement the full notice, consent, rights, processor, security and breach workflows before public launch, and re-check for later Gazette notifications and corrigenda.

## 4. AI data-processing gate

- AI triage is optional and must require a separate, affirmative, versioned consent action.
- The client sends only the issue description and selected category hint; it does not intentionally send the customer's account profile, phone, service address or photos.
- The Edge Function redacts obvious phone, email, Aadhaar-like and PAN-like patterns. This is best-effort only; it cannot reliably detect names or addresses.
- **Production AI is disabled unless `GEMINI_PAID_TIER_CONFIRMED=true` is set after an operator verifies that the API key belongs to a paid Gemini API project.** This is an operator attestation, not an automatic billing check.
- Do not send real customer content to Gemini unpaid/free-tier services. Google's terms state that unpaid-service content may be used to improve products and may be reviewed by humans; Google's paid-service terms state prompts and responses are not used to improve products and are handled under its data-processing terms.
- The AI must never dispatch a provider, set a price, confirm a booking, or change job status. Human operations and the customer remain in control.
- AI safety output is advisory, not emergency response or a substitute for a qualified professional.

## 5. Mandatory launch blockers

1. Choose and document the operating legal entity, legal name, registered address, jurisdiction and tax registrations.
2. Appoint a named India-resident grievance officer and a consumer-support contact; publish a monitored email/phone and complaint-tracking process.
3. Have Indian counsel approve the privacy policy, customer terms, provider agreement, cancellation/refund policy and liability allocation.
4. Decide the account age policy and implement it. Recommended pilot policy: adult account holders only; do not knowingly onboard children.
5. Complete provider onboarding and document verification. Do not accept electrical jobs from unverified or unqualified providers.
6. Do not require or retain full Aadhaar numbers or biometrics. Confirm an acceptable alternative ID process.
7. Confirm the data-processing agreements, regions, retention, access and subprocessors for Supabase, Vercel and Google.
8. Establish CERT-In point of contact, 180-day India log retention evidence, incident reporting process and tabletop exercise.
9. Implement account deletion, data access/correction, consent withdrawal, grievance and retention workflows.
10. Complete an independent security review, RLS negative tests, storage access tests, dependency scan, backup-restore drill and physical-device acceptance tests.
11. Do not activate payment collection until GST, income-tax, RBI/PA and refund controls are signed off.
12. Publish final, complete legal pages only after all placeholders are replaced and counsel approves them.

## 6. Official reference material

- [DPDP Rules 2025 — Gazette G.S.R. 846(E)](https://www.meity.gov.in/static/uploads/2025/11/53450e6e5dc0bfa85ebd78686cadad39.pdf)
- [DPDP Act commencement notification — G.S.R. 843(E)](https://www.meity.gov.in/static/uploads/2025/11/c56ceae6c383460ca69577428d36828b.pdf)
- [Consumer Protection (E-Commerce) Rules 2020 — Gazette](https://consumeraffairs.nic.in/sites/default/files/E%20commerce%20rules_0.pdf)
- [Consumer Protection (E-Commerce) Amendment Rules 2021](https://consumeraffairs.nic.in/sites/default/files/Consumer%20Protection%20%28E-Commerce%29%20%28Amendment%29%20Rules%2C%202021.pdf)
- [CERT-In Directions under section 70B](https://cert-in.org.in/PDF/CERT-In_Directions_70B_28.04.2022.pdf)
- [CERT-In FAQs on the 2022 Directions](https://cert-in.org.in/PDF/FAQs_on_CyberSecurityDirections_May2022.pdf)
- [UIDAI Regulations](https://www.uidai.gov.in/en/about-uidai/legal-framework/regulations.html)
- [UIDAI Aadhaar Authentication and Offline Verification Regulations](https://uidai.gov.in/images/The_Aadhaar_Authentication_and_Offline_Verifications_Regulations_2021-_Clean_copy-30122025.pdf)
- [CEA Regulations](https://cea.nic.in/cei-regulations/?lang=en)
- [Gemini API Additional Terms](https://ai.google.dev/gemini-api/terms)
- [Gemini API pricing and data-use distinction](https://ai.google.dev/gemini-api/docs/pricing)

This register must be maintained as a living control document. A checklist entry is not proof of compliance; retain evidence, owners, dates and review outcomes.
