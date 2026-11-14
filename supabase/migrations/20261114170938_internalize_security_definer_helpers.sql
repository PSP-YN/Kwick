-- Keep SECURITY DEFINER lookup helpers outside PostgREST-exposed schemas.
-- Public compatibility wrappers remain SECURITY INVOKER and delegate to scoped
-- private helpers. Existing RPC signatures and client calls remain unchanged.

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated;
GRANT USAGE ON SCHEMA private TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA private
  REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

CREATE OR REPLACE FUNCTION private.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT COALESCE(auth.jwt() ->> 'aal' = 'aal2', false)
     AND EXISTS (
       SELECT 1 FROM public.user_roles
        WHERE user_id = auth.uid()
          AND role IN ('admin', 'super_admin')
     );
$$;

CREATE OR REPLACE FUNCTION private.has_role(check_user_id UUID, check_role TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL OR check_user_id IS NULL THEN
    RETURN false;
  END IF;
  IF check_user_id <> auth.uid() AND NOT private.is_admin() THEN
    RETURN false;
  END IF;
  RETURN EXISTS (
    SELECT 1 FROM public.user_roles
     WHERE user_id = check_user_id AND role = check_role
  );
END;
$$;

CREATE OR REPLACE FUNCTION private.get_provider_id_for_user(check_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NULL;
  END IF;
  IF check_user_id <> auth.uid() AND NOT private.is_admin() THEN
    RETURN NULL;
  END IF;
  RETURN (
    SELECT id FROM public.providers
     WHERE profile_id = check_user_id
     LIMIT 1
  );
END;
$$;

CREATE OR REPLACE FUNCTION private.get_customer_request_ids(p_user_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT sr.id
    FROM public.service_requests sr
   WHERE (p_user_id = auth.uid() OR private.is_admin())
     AND sr.customer_id = p_user_id;
$$;

CREATE OR REPLACE FUNCTION private.get_assigned_provider_ids_for_customer(p_user_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT a.provider_id
    FROM public.assignments a
    JOIN public.service_requests sr ON sr.id = a.request_id
   WHERE (p_user_id = auth.uid() OR private.is_admin())
     AND sr.customer_id = p_user_id
     AND a.status IN ('offered', 'accepted', 'completed');
$$;

CREATE OR REPLACE FUNCTION private.get_assigned_request_ids_for_provider(p_user_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT a.request_id
    FROM public.assignments a
   WHERE (p_user_id = auth.uid() OR private.is_admin())
     AND a.provider_id = private.get_provider_id_for_user(p_user_id)
     AND a.status IN ('offered', 'accepted', 'completed');
$$;

REVOKE ALL ON ALL FUNCTIONS IN SCHEMA private FROM PUBLIC, anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA private TO authenticated;

-- Preserve existing client and policy function signatures, but remove their
-- SECURITY DEFINER privilege. The private implementation enforces auth.uid().
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$ SELECT private.is_admin(); $$;

CREATE OR REPLACE FUNCTION public.has_role(check_user_id UUID, check_role TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$ SELECT private.has_role(check_user_id, check_role); $$;

CREATE OR REPLACE FUNCTION public.get_provider_id_for_user(check_user_id UUID)
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$ SELECT private.get_provider_id_for_user(check_user_id); $$;

CREATE OR REPLACE FUNCTION public.get_customer_request_ids(p_user_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$ SELECT * FROM private.get_customer_request_ids(p_user_id); $$;

CREATE OR REPLACE FUNCTION public.get_assigned_provider_ids_for_customer(p_user_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$ SELECT * FROM private.get_assigned_provider_ids_for_customer(p_user_id); $$;

CREATE OR REPLACE FUNCTION public.get_assigned_request_ids_for_provider(p_user_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$ SELECT * FROM private.get_assigned_request_ids_for_provider(p_user_id); $$;

COMMENT ON SCHEMA private IS
  'Non-PostgREST schema for narrowly scoped SECURITY DEFINER authorization helpers. Do not add this schema to the Data API exposed schemas.';
