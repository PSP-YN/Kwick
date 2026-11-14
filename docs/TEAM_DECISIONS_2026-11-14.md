# Kwick — Team Decisions (14 November 2026)

This note records the latest team discussion. It separates decisions from assumptions that still require provider interviews, operating data or legal review.

## Confirmed product and launch direction

- Brand: Kwick.
- Deliver two separate mobile applications backed by the same platform:
  - **Kwick:** customer discovery, booking, quote approval, order tracking and support.
  - **Kwick Partner:** provider registration, verification evidence, availability, job handling and provider pricing.
- Begin in HSR Layout, Bengaluru (560102). Add one or two adjacent neighbourhoods only after real provider coverage and operating capacity are confirmed.
- Initial targets: 100 customers and 30 onboarded service providers. Track onboarded, verified, active and dispatch-ready providers separately.
- Promote only after supply is ready, using apartment associations/residential communities, Instagram, WhatsApp and narrowly targeted local advertising.
- First-booking offers and referral rewards require a defined budget, expiry, per-user caps and abuse controls.
- Collect feedback after completed jobs; expand across Bengaluru only when fulfilment, safety, support and unit economics are stable.

## Pricing and revenue — no invented rates

1. A provider may submit a job-specific quote after assessing the work.
2. Alternatively, Kwick and a provider may negotiate a fixed catalogue price. The provider must agree; the proposal remains hidden from customers until an authorized operator reviews and approves it.
3. Kwick's commission is a **percentage**, negotiated with each provider and potentially by service category. No default percentage is approved. Record explicit provider agreement and evidence before activating a rate.
4. Provider service price and Kwick commission are separate commercial terms.
5. No fixed monthly provider subscription during the pilot. Revisit any subscription only after evidence that providers receive enough value and are willing to pay.
6. Do not charge or deduct commission until payment collection/settlement, contracts, tax treatment, refunds, reconciliation and payment-aggregator requirements are approved and implemented.

## Provider onboarding and trust

Registration and document upload do not mean a provider is verified. Keep the account unavailable for dispatch until an authorized reviewer records the checks and approves it.

The review should cover phone reachability, permitted identity evidence, trade competence (including an in-person practical assessment where certificates are unavailable), references or shop/employer history, service area, applicable licences, safety briefing and supervised initial jobs. Do not routinely collect full Aadhaar numbers, biometrics or Aadhaar e-KYC payloads. Confirm accepted identity evidence and retention policy with Indian legal counsel.

Use existing provider contacts and reputable local shops to source the first cohort. Do not display unverified providers as trusted or dispatch-ready.

## Cost and operating model

Before setting a commission, measure actual cost per completed booking: hosting/database/storage/bandwidth, OTP and notification usage, payment collection only if Kwick handles money, discounts/referrals, customer acquisition, provider verification, field operations, customer support, disputes, refunds/chargebacks where applicable, insurance, legal/accounting and taxes.

Contribution per booking must be calculated from collected platform revenue minus the costs Kwick actually incurs. Do not include payment-gateway costs if customers pay providers directly during the pilot. Use observed data, not an arbitrary commission estimate.

## Scale requirement

The long-term ambition is to support very large traffic, potentially millions of concurrent users. The current pilot implementation is not proven at that scale. Keep the transactional core simple for the first 100/30 cohort, instrument latency/error/queue/database metrics, then scale through measured capacity work, caching, asynchronous queues, connection pooling, read capacity and—only when justified—regional partitioning/sharding. Run staged load, soak, failover and restore tests in dedicated staging before making capacity claims.

## Open items — do not fabricate

- Final commission percentages and any category-specific differences.
- Whether a fixed catalogue price or provider quote is preferred by each provider.
- Final provider verification checklist, acceptable ID alternatives, insurance and agreement terms after legal review.
- Which two or three neighbourhoods are viable after provider conversations.
- Discounts/referral amounts and campaign budget.
- Payment collection and settlement model.
- Actual operating cost, unit economics and the evidence required for any later subscription.
