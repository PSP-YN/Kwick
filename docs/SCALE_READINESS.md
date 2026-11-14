# Kwick — Scalability and Capacity Plan

## Important distinction

The current codebase is a pilot-oriented implementation. It is **not load-tested or proven for one million simultaneous users**. Millions of concurrent users require capacity in the mobile/API edge, authentication, database, cache, queues, storage, notifications, observability and operations—not just a Flutter UI change. Do not advertise a million-user capacity claim until a representative production environment has passed staged load, soak, failover and recovery tests.

## Current baseline

- Two separately installable Flutter clients: Kwick customer and Kwick Partner.
- A protected Next.js operations console.
- Supabase Auth, PostgreSQL with RLS, private object storage and Edge Functions.
- Financial values in integer paise; provider/category commission terms in integer basis points.
- Database-enforced dispatch invariants and indexed foreign keys.
- Customer/provider queries are scoped by authenticated identity; high-volume history queries must remain paginated.

## Architecture path

### Pilot: first 100 customers / 30 providers

- Keep a modular application and one transactional relational database; do not introduce microservices before there is a measured bottleneck.
- Start with HSR Layout (560102). Activate one or two more contiguous Bengaluru areas only after supply is verified and service-area records are configured.
- Keep dispatch human-reviewed, provider verification manual and payment collection disabled until the operating model is approved.
- Use strict pagination, query limits, database indexes, rate limits and bounded file sizes.

### Growth: thousands to tens of thousands of active users

- Measure p50/p95/p99 latency, database CPU/IO, connection saturation, cache hit rate, queue lag, error rate and booking success.
- Use Supabase connection pooling for server-side workloads; keep clients on supported HTTPS APIs and never expose service-role credentials.
- Cache read-heavy public catalogue/area data at the edge with explicit invalidation. Keep customer-specific and provider-specific data behind RLS.
- Move notifications, image processing, analytics and non-critical audit fan-out to asynchronous queues so booking transactions remain short.
- Use read replicas for suitable read traffic when the managed database tier supports them. Keep booking/assignment writes on the authoritative primary.
- Add idempotency keys to booking/payment operations before introducing automatic retries.

### Large-scale / million-concurrent objective

- Run stateless API/edge workers horizontally behind a global edge/API gateway with per-user and per-IP rate limits, request budgets and backpressure.
- Separate read models from transactional write paths; introduce a durable event bus for notifications, search indexing, analytics and settlement workflows.
- Partition high-volume append-only tables (events, notifications, audit and telemetry) by time and/or region after query patterns justify it.
- Add regional read capacity and a deliberate geographic data partitioning strategy. A single Postgres primary is not a million-concurrent write architecture.
- Introduce database sharding or regional write ownership only when measured write throughput, hot rows or operational limits justify the complexity.
- Design multi-region failover, backup restoration, key rotation, incident response and disaster-recovery drills before claiming high availability.

## Required validation gates

1. Establish a baseline with realistic customer, provider and dispatch query mixes.
2. Run staged 50, 100, 250, 500 and 1,000 virtual-user tests against a dedicated staging environment; do not run write-heavy load against production without approval.
3. Add soak tests, burst tests, database failover tests and backup restore tests.
4. Test booking idempotency, duplicate payment callbacks, provider assignment contention, notification retries and RLS isolation under load.
5. Record infrastructure tier, region, limits, test scripts, data volume, p95/p99 latency, error rate and cost per 1,000 completed bookings.
6. Increase capacity only after a measured bottleneck and cost model are documented.

A k6 starter script is provided in `scripts/load/kwick-read-smoke.js`. It is a staging smoke/load harness, not proof of production capacity. The current development environment has not been used to claim million-user performance.
