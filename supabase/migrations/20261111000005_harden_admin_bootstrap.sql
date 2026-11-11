-- Restrict first-admin bootstrap to trusted database operators.
-- Execute this one-time function from the Supabase SQL editor as the database owner.
REVOKE ALL ON FUNCTION public.bootstrap_admin(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.bootstrap_admin(UUID) FROM anon;
REVOKE ALL ON FUNCTION public.bootstrap_admin(UUID) FROM authenticated;
COMMENT ON FUNCTION public.bootstrap_admin(UUID) IS
  'Privileged one-time bootstrap. Execute only from the trusted SQL editor as the database owner.';
