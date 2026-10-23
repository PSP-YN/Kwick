# Decisions
Durable, verified decisions only. Format: `YYYY-MM-DD: decision. Why. Tradeoff. Revisit when.`
- 2026-10-23: Monorepo for Flutter, Next.js Admin, and Supabase. Keep migrations and models synchronized during pilot. Slightly larger repo. Revisit if teams diverge.
- 2026-10-23: PostgreSQL as authoritative state & permission engine via RLS and SECURITY DEFINER RPCs. Prevent client-side bypasses and race conditions. Requires SQL integration testing. Revisit never (security baseline).
- 2026-10-23: Riverpod + GoRouter for mobile application. State immutability and role-guarded routing. Requires discipline in provider scoping.
- 2026-10-23: Financial pricing in integer paise (BIGINT). Avoid floating point inaccuracies in Indian Rupees. Must format in UI. Revisit if multi-currency added.
- 2026-10-23: Single active assignment invariant enforced via PostgreSQL partial unique index on assignments table. Prevents dual-dispatch race conditions. Revisit if batch multi-provider dispatch is introduced.
