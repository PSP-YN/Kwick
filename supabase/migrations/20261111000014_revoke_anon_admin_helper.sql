-- Restrict the MFA-aware administrator predicate to authenticated sessions.
-- RLS policies invoke this helper for authenticated users only.
revoke execute on function public.is_admin() from anon;
