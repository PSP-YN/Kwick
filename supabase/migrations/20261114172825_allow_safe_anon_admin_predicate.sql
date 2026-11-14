-- Public catalogue policies are also evaluated for the anon role.
-- is_admin must be executable there; its private implementation returns false
-- for the anonymous JWT because auth.uid() is null and AAL2 is absent.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.is_admin();
$$;

GRANT USAGE ON SCHEMA private TO anon;
GRANT EXECUTE ON FUNCTION private.is_admin() TO anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon;
GRANT SELECT ON TABLE public.service_categories, public.service_areas TO anon;
