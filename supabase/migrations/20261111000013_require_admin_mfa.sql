-- Require phishing-resistant second-factor verification for all admin data and RPC access.
-- Supabase Auth places the current authenticator assurance level in the signed JWT.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT COALESCE(auth.jwt() ->> 'aal' = 'aal2', false)
     AND EXISTS (
       SELECT 1
       FROM public.user_roles
       WHERE user_id = auth.uid()
         AND role IN ('admin', 'super_admin')
     );
$function$;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;

COMMENT ON FUNCTION public.is_admin() IS
  'Returns true only for an admin/super_admin with a verified AAL2 Supabase Auth session.';
