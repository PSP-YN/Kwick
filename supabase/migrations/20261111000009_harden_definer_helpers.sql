-- Harden SECURITY DEFINER helpers against cross-user lookup and search_path attacks.

CREATE OR REPLACE FUNCTION public.has_role(check_user_id UUID, check_role TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF auth.uid() IS NULL OR check_user_id IS NULL THEN
    RETURN false;
  END IF;

  IF check_user_id <> auth.uid() AND NOT public.is_admin() THEN
    RETURN false;
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = check_user_id
      AND role = check_role
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = auth.uid()
      AND role IN ('admin', 'super_admin')
  );
$function$;

CREATE OR REPLACE FUNCTION public.get_provider_id_for_user(check_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NULL;
  END IF;
  IF check_user_id <> auth.uid() AND NOT public.is_admin() THEN
    RETURN NULL;
  END IF;

  RETURN (
    SELECT id
    FROM public.providers
    WHERE profile_id = check_user_id
    LIMIT 1
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_assigned_request_ids_for_provider(p_user_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT a.request_id
  FROM public.assignments a
  WHERE (p_user_id = auth.uid() OR public.is_admin())
    AND a.provider_id = public.get_provider_id_for_user(p_user_id)
    AND a.status IN ('offered', 'accepted', 'completed');
$function$;

CREATE OR REPLACE FUNCTION public.get_customer_request_ids(p_user_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT sr.id
  FROM public.service_requests sr
  WHERE (p_user_id = auth.uid() OR public.is_admin())
    AND sr.customer_id = p_user_id;
$function$;

CREATE OR REPLACE FUNCTION public.get_assigned_provider_ids_for_customer(p_user_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT a.provider_id
  FROM public.assignments a
  JOIN public.service_requests sr ON sr.id = a.request_id
  WHERE (p_user_id = auth.uid() OR public.is_admin())
    AND sr.customer_id = p_user_id
    AND a.status IN ('offered', 'accepted', 'completed');
$function$;

-- Helper functions are not public APIs. RLS policies receive only the helpers they need.
REVOKE ALL ON FUNCTION public.has_role(UUID, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.get_provider_id_for_user(UUID) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.get_assigned_request_ids_for_provider(UUID) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.get_customer_request_ids(UUID) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.get_assigned_provider_ids_for_customer(UUID) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.get_assigned_request_ids_for_provider(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_customer_request_ids(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_assigned_provider_ids_for_customer(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;

-- Keep the application RPC surface authenticated-only. Each function performs
-- its own ownership or administrator authorization checks.
REVOKE ALL ON FUNCTION public.create_service_request(UUID, UUID, TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, TIMESTAMPTZ, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_service_request(UUID, UUID, TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, TIMESTAMPTZ, TEXT, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.cancel_service_request(UUID, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_service_request(UUID, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.assign_provider_to_request(UUID, UUID, BIGINT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.assign_provider_to_request(UUID, UUID, BIGINT) TO authenticated;

REVOKE ALL ON FUNCTION public.respond_to_assignment(UUID, BOOLEAN, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.respond_to_assignment(UUID, BOOLEAN, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.progress_service_request(UUID, TEXT, BIGINT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.progress_service_request(UUID, TEXT, BIGINT) TO authenticated;

REVOKE ALL ON FUNCTION public.admin_verify_provider(UUID, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_verify_provider(UUID, TEXT, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.admin_override_request_status(UUID, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_override_request_status(UUID, TEXT, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.bootstrap_admin(UUID) FROM PUBLIC, anon, authenticated;

-- SECURITY DEFINER functions use an empty search path; all app objects are schema-qualified.
ALTER FUNCTION public.handle_new_user() SET search_path = '';
ALTER FUNCTION public.has_role(UUID, TEXT) SET search_path = '';
ALTER FUNCTION public.is_admin() SET search_path = '';
ALTER FUNCTION public.get_provider_id_for_user(UUID) SET search_path = '';
ALTER FUNCTION public.get_assigned_request_ids_for_provider(UUID) SET search_path = '';
ALTER FUNCTION public.get_customer_request_ids(UUID) SET search_path = '';
ALTER FUNCTION public.get_assigned_provider_ids_for_customer(UUID) SET search_path = '';
ALTER FUNCTION public.create_service_request(UUID, UUID, TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, TIMESTAMPTZ, TEXT, TEXT) SET search_path = '';
ALTER FUNCTION public.cancel_service_request(UUID, TEXT) SET search_path = '';
ALTER FUNCTION public.assign_provider_to_request(UUID, UUID, BIGINT) SET search_path = '';
ALTER FUNCTION public.respond_to_assignment(UUID, BOOLEAN, TEXT) SET search_path = '';
ALTER FUNCTION public.progress_service_request(UUID, TEXT, BIGINT) SET search_path = '';
ALTER FUNCTION public.admin_verify_provider(UUID, TEXT, TEXT) SET search_path = '';
ALTER FUNCTION public.admin_override_request_status(UUID, TEXT, TEXT) SET search_path = '';
ALTER FUNCTION public.bootstrap_admin(UUID) SET search_path = '';
ALTER FUNCTION public.handle_updated_at() SET search_path = '';
