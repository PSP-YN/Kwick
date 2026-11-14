# Kwick — Pricing, Commission and Operating Costs

**Commercial terms are not yet agreed.** The application supports recording terms, but no commission rate, customer fee, payment collection or payout is assumed by default.

## 1. Provider pricing

Kwick supports two provider-service pricing modes:

- **Provider quote:** the provider assesses the job and gives a job-specific quote. The customer must approve the scope and amount before work begins.
- **Agreed fixed price:** the provider and Kwick negotiate a catalogue price. The provider can propose it in the Partner app; it remains pending and is not customer-visible until an operator reviews and approves it.

Provider prices are stored in integer paise. The provider's service price is separate from Kwick's platform commission. Any additional work or price change must be explained and accepted by the customer before proceeding.

## 2. Platform commission

- Commission is a percentage, stored as integer basis points (100 bps = 1%).
- The rate is negotiated per provider and service category; there is no global default rate.
- The operations console can save a draft proposal. It can activate a rate only after an operator records explicit provider agreement and evidence.
- A provider can read their own active commission terms. Customers cannot read provider commission agreements.
- A new active agreement supersedes the previous active agreement for that provider/category.
- No monthly provider subscription is charged during the pilot. A later subscription should not be introduced without evidence that providers value it and will pay for it.

The current feature records commercial terms only. It does **not** collect customer payments, hold provider funds, deduct commission, issue settlements or automate refunds. Do not charge a commission until payment collection/settlement, provider contracts, tax treatment, reconciliation, refunds and payment-aggregator requirements are approved and implemented.

## 3. Unit economics and platform costs

A commission rate must be selected from real provider discussions and measured operating costs, not guessed in code. For each completed job, calculate:

`Contribution per booking = commission revenue − payment/collection cost − notification cost − variable support cost − discount/referral cost − refund/chargeback reserve − allocated acquisition and verification cost`

If the customer pays the provider directly during a pilot, do not include payment-gateway fees that Kwick does not actually incur. If Kwick later collects payments, include the contracted payment-aggregator charges and settlement costs.

Monthly break-even volume is:

`Monthly fixed operating costs ÷ average contribution per completed booking`

Cost categories to measure:

- Hosting, database compute, backups, storage and bandwidth.
- SMS/OTP, email, push notifications, maps and third-party API usage.
- Payment gateway, reconciliation, refunds and chargebacks if enabled.
- Field visits, identity/trade verification and provider acquisition.
- Customer acquisition, apartment activations, first-booking discounts and referral rewards.
- Support staff, dispute handling, insurance, legal, accounting and taxes.

The pilot should be free of fixed monthly partner fees. Discounts and referral rewards must have caps and a recorded budget. Review contribution margin by area and service before increasing paid marketing.
