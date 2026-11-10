-- Harden direct table writes and provision app identity from Supabase Auth.
-- User role assignment is performed by this trusted trigger, never by client upserts.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
DECLARE
  v_full_name TEXT;
  v_initial_role TEXT;
BEGIN
  v_full_name := NULLIF(trim(COALESCE(NEW.raw_user_meta_data ->> 'full_name', '')), '');
  IF v_full_name IS NULL OR length(v_full_name) < 2 THEN
    v_full_name := NULLIF(split_part(COALESCE(NEW.email, ''), '@', 1), '');
  END IF;
  IF v_full_name IS NULL OR length(v_full_name) < 2 THEN
    v_full_name := 'NexHelp User';
  END IF;

  v_initial_role := NEW.raw_user_meta_data ->> 'initial_role';
  IF v_initial_role NOT IN ('customer', 'provider') THEN
    v_initial_role := 'customer';
  END IF;

  INSERT INTO public.profiles (id, full_name, phone, email)
  VALUES (
    NEW.id,
    v_full_name,
    NULLIF(NEW.raw_user_meta_data ->> 'phone', ''),
    NEW.email
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_roles (user_id, role)
  VALUES (NEW.id, v_initial_role)
  ON CONFLICT (user_id, role) DO NOTHING;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM anon;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM authenticated;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Backfill users that predate this trigger without overwriting existing roles.
INSERT INTO public.profiles (id, full_name, phone, email)
SELECT
  u.id,
  COALESCE(
    NULLIF(trim(u.raw_user_meta_data ->> 'full_name'), ''),
    CASE
      WHEN length(split_part(COALESCE(u.email, ''), '@', 1)) >= 2
        THEN split_part(u.email, '@', 1)
      ELSE 'NexHelp User'
    END
  ),
  NULLIF(u.raw_user_meta_data ->> 'phone', ''),
  u.email
FROM auth.users u
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_roles (user_id, role)
SELECT
  u.id,
  CASE
    WHEN u.raw_user_meta_data ->> 'initial_role' IN ('customer', 'provider')
      THEN u.raw_user_meta_data ->> 'initial_role'
    ELSE 'customer'
  END
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM public.user_roles r WHERE r.user_id = u.id
)
ON CONFLICT (user_id, role) DO NOTHING;

-- Restrict user writes to the columns and operations required by the mobile app.
REVOKE INSERT ON public.profiles FROM authenticated;
REVOKE UPDATE ON public.profiles FROM authenticated;
GRANT UPDATE (full_name, phone) ON public.profiles TO authenticated;

REVOKE INSERT, UPDATE, DELETE ON public.user_roles FROM authenticated;
GRANT SELECT ON public.user_roles TO authenticated;

REVOKE UPDATE ON public.providers FROM authenticated;
GRANT UPDATE (availability_status) ON public.providers TO authenticated;

-- All service-request and assignment state changes must pass through transactional RPCs.
REVOKE INSERT, UPDATE ON public.service_requests FROM authenticated;
REVOKE INSERT, UPDATE ON public.assignments FROM authenticated;

-- Event and audit records are written only by trusted SECURITY DEFINER RPCs.
REVOKE INSERT, UPDATE, DELETE ON public.order_events FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.admin_audit_logs FROM authenticated;

-- No mobile client currently needs to mutate notification delivery metadata.
REVOKE UPDATE ON public.notifications FROM authenticated;
