-- Enforce the customer/partner boundary in PostgreSQL, not only in Flutter.
-- Existing customers and requests are preserved. No role is auto-promoted.

CREATE OR REPLACE FUNCTION public.enforce_exclusive_app_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.role IN ('customer', 'provider') AND EXISTS (
    SELECT 1
      FROM public.user_roles r
     WHERE r.user_id = NEW.user_id
       AND r.role IN ('customer', 'provider')
       AND r.role <> NEW.role
  ) THEN
    RAISE EXCEPTION 'A Kwick account cannot be both a customer and a service partner.'
      USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.enforce_exclusive_app_role() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS enforce_exclusive_app_role ON public.user_roles;
CREATE TRIGGER enforce_exclusive_app_role
  BEFORE INSERT OR UPDATE OF user_id, role ON public.user_roles
  FOR EACH ROW EXECUTE FUNCTION public.enforce_exclusive_app_role();

-- A customer account cannot create a provider identity by calling the Data API.
CREATE OR REPLACE FUNCTION public.enforce_provider_identity_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.profile_id <> auth.uid()
     OR NOT public.has_role(auth.uid(), 'provider')
     OR NEW.verification_status <> 'pending' THEN
    RAISE EXCEPTION 'Only a provider account may create its own pending partner profile.'
      USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.enforce_provider_identity_role() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS enforce_provider_identity_role ON public.providers;
CREATE TRIGGER enforce_provider_identity_role
  BEFORE INSERT ON public.providers
  FOR EACH ROW EXECUTE FUNCTION public.enforce_provider_identity_role();

-- The transactional booking RPC is also protected. This prevents a partner
-- account from creating customer bookings by bypassing the customer app.
CREATE OR REPLACE FUNCTION public.enforce_customer_booking_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.customer_id <> auth.uid()
     OR NOT public.has_role(auth.uid(), 'customer') THEN
    RAISE EXCEPTION 'Only the owning customer account may create a service request.'
      USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.enforce_customer_booking_role() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS enforce_customer_booking_role ON public.service_requests;
CREATE TRIGGER enforce_customer_booking_role
  BEFORE INSERT ON public.service_requests
  FOR EACH ROW EXECUTE FUNCTION public.enforce_customer_booking_role();

-- A partner can accept/progress only while the provider identity remains approved.
-- This closes the suspended-provider / stale-assignment path.
CREATE OR REPLACE FUNCTION public.enforce_assignment_provider_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_provider_user UUID;
  v_verification_status TEXT;
BEGIN
  IF auth.uid() IS NULL OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  SELECT p.profile_id, p.verification_status
    INTO v_provider_user, v_verification_status
    FROM public.providers p
   WHERE p.id = NEW.provider_id;

  IF v_provider_user IS DISTINCT FROM auth.uid()
     OR NOT public.has_role(auth.uid(), 'provider')
     OR v_verification_status <> 'approved' THEN
    RAISE EXCEPTION 'Only the approved owner of this provider account may change its assignment.'
      USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.enforce_assignment_provider_role() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS enforce_assignment_provider_role ON public.assignments;
CREATE TRIGGER enforce_assignment_provider_role
  BEFORE INSERT OR UPDATE ON public.assignments
  FOR EACH ROW EXECUTE FUNCTION public.enforce_assignment_provider_role();

-- Rebuild RLS policies with explicit app-role predicates.
DROP POLICY IF EXISTS providers_select_authorized ON public.providers;
CREATE POLICY providers_select_authorized ON public.providers
  FOR SELECT TO authenticated
  USING (
    (profile_id = (SELECT auth.uid()) AND public.has_role((SELECT auth.uid()), 'provider'))
    OR public.is_admin()
    OR (
      public.has_role((SELECT auth.uid()), 'customer')
      AND id IN (SELECT public.get_assigned_provider_ids_for_customer((SELECT auth.uid())))
    )
  );

DROP POLICY IF EXISTS providers_insert_own ON public.providers;
CREATE POLICY providers_insert_own ON public.providers
  FOR INSERT TO authenticated
  WITH CHECK (
    profile_id = (SELECT auth.uid())
    AND public.has_role((SELECT auth.uid()), 'provider')
    AND verification_status = 'pending'
  );

DROP POLICY IF EXISTS providers_update_own_availability ON public.providers;
CREATE POLICY providers_update_own_availability ON public.providers
  FOR UPDATE TO authenticated
  USING (
    profile_id = (SELECT auth.uid())
    AND public.has_role((SELECT auth.uid()), 'provider')
  )
  WITH CHECK (
    profile_id = (SELECT auth.uid())
    AND public.has_role((SELECT auth.uid()), 'provider')
    AND verification_status = (
      SELECT p.verification_status FROM public.providers p WHERE p.id = providers.id
    )
  );

DROP POLICY IF EXISTS provider_services_select ON public.provider_services;
CREATE POLICY provider_services_select ON public.provider_services
  FOR SELECT TO authenticated
  USING (
    (
      provider_id = public.get_provider_id_for_user((SELECT auth.uid()))
      AND public.has_role((SELECT auth.uid()), 'provider')
    )
    OR public.is_admin()
  );
-- The separate approved-catalogue policy from migration 17 remains in force.

DROP POLICY IF EXISTS provider_services_manage_own ON public.provider_services;
CREATE POLICY provider_services_manage_own ON public.provider_services
  FOR ALL TO authenticated
  USING (
    (
      provider_id = public.get_provider_id_for_user((SELECT auth.uid()))
      AND public.has_role((SELECT auth.uid()), 'provider')
    )
    OR public.is_admin()
  )
  WITH CHECK (
    (
      provider_id = public.get_provider_id_for_user((SELECT auth.uid()))
      AND public.has_role((SELECT auth.uid()), 'provider')
    )
    OR public.is_admin()
  );

DROP POLICY IF EXISTS provider_documents_select ON public.provider_documents;
CREATE POLICY provider_documents_select ON public.provider_documents
  FOR SELECT TO authenticated
  USING (
    (
      provider_id = public.get_provider_id_for_user((SELECT auth.uid()))
      AND public.has_role((SELECT auth.uid()), 'provider')
    )
    OR public.is_admin()
  );

DROP POLICY IF EXISTS provider_documents_insert_own ON public.provider_documents;
CREATE POLICY provider_documents_insert_own ON public.provider_documents
  FOR INSERT TO authenticated
  WITH CHECK (
    provider_id = public.get_provider_id_for_user((SELECT auth.uid()))
    AND public.has_role((SELECT auth.uid()), 'provider')
  );

DROP POLICY IF EXISTS service_requests_select_authorized ON public.service_requests;
CREATE POLICY service_requests_select_authorized ON public.service_requests
  FOR SELECT TO authenticated
  USING (
    (
      customer_id = (SELECT auth.uid())
      AND public.has_role((SELECT auth.uid()), 'customer')
    )
    OR public.is_admin()
    OR (
      public.has_role((SELECT auth.uid()), 'provider')
      AND id IN (SELECT public.get_assigned_request_ids_for_provider((SELECT auth.uid())))
    )
  );

DROP POLICY IF EXISTS service_requests_insert_own ON public.service_requests;
CREATE POLICY service_requests_insert_own ON public.service_requests
  FOR INSERT TO authenticated
  WITH CHECK (
    customer_id = (SELECT auth.uid())
    AND public.has_role((SELECT auth.uid()), 'customer')
    AND status = 'requested'
  );

DROP POLICY IF EXISTS assignments_select_authorized ON public.assignments;
CREATE POLICY assignments_select_authorized ON public.assignments
  FOR SELECT TO authenticated
  USING (
    (
      provider_id = public.get_provider_id_for_user((SELECT auth.uid()))
      AND public.has_role((SELECT auth.uid()), 'provider')
    )
    OR public.is_admin()
    OR (
      public.has_role((SELECT auth.uid()), 'customer')
      AND request_id IN (SELECT public.get_customer_request_ids((SELECT auth.uid())))
    )
  );

DROP POLICY IF EXISTS reviews_insert_customer ON public.reviews;
CREATE POLICY reviews_insert_customer ON public.reviews
  FOR INSERT TO authenticated
  WITH CHECK (
    customer_id = (SELECT auth.uid())
    AND public.has_role((SELECT auth.uid()), 'customer')
    AND request_id IN (
      SELECT id FROM public.service_requests
       WHERE customer_id = (SELECT auth.uid()) AND status = 'completed'
    )
  );

-- Provider KYC objects remain private and require the partner role in addition
-- to the per-user storage path. Customers cannot enumerate or upload KYC files.
DROP POLICY IF EXISTS provider_documents_bucket_insert ON storage.objects;
CREATE POLICY provider_documents_bucket_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'provider-documents'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
    AND public.has_role((SELECT auth.uid()), 'provider')
  );

DROP POLICY IF EXISTS provider_documents_bucket_select ON storage.objects;
CREATE POLICY provider_documents_bucket_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'provider-documents'
    AND (
      (
        (storage.foldername(name))[1] = (SELECT auth.uid())::text
        AND public.has_role((SELECT auth.uid()), 'provider')
      )
      OR public.is_admin()
    )
  );

COMMENT ON FUNCTION public.enforce_exclusive_app_role() IS
  'Prevents a single Supabase identity from simultaneously holding customer and provider app roles.';
COMMENT ON FUNCTION public.enforce_customer_booking_role() IS
  'Database-level guard: only customer-role identities can create service requests.';
COMMENT ON FUNCTION public.enforce_provider_identity_role() IS
  'Database-level guard: only provider-role identities can create pending provider profiles.';
