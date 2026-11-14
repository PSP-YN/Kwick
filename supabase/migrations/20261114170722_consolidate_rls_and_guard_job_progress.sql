-- Consolidate overlapping SELECT/INSERT/UPDATE policies without broadening access.
DROP POLICY IF EXISTS provider_services_customer_approved_catalog_read
  ON public.provider_services;
DROP POLICY IF EXISTS provider_services_select
  ON public.provider_services;
CREATE POLICY provider_services_select
  ON public.provider_services FOR SELECT TO authenticated
  USING (
    (
      provider_id = public.get_provider_id_for_user((SELECT auth.uid()))
      AND public.has_role((SELECT auth.uid()), 'provider')
    )
    OR (SELECT public.is_admin())
    OR (
      public.has_role((SELECT auth.uid()), 'customer')
      AND is_active = true
      AND pricing_model = 'agreed_fixed'
      AND price_approval_status = 'approved'
    )
  );

DROP POLICY IF EXISTS providers_admin_insert ON public.providers;
DROP POLICY IF EXISTS providers_insert_own ON public.providers;
CREATE POLICY providers_insert_own_or_admin
  ON public.providers FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT public.is_admin())
    OR (
      profile_id = (SELECT auth.uid())
      AND public.has_role((SELECT auth.uid()), 'provider')
      AND verification_status = 'pending'
    )
  );

DROP POLICY IF EXISTS providers_admin_update ON public.providers;
DROP POLICY IF EXISTS providers_update_own_availability ON public.providers;
CREATE POLICY providers_update_own_or_admin
  ON public.providers FOR UPDATE TO authenticated
  USING (
    (SELECT public.is_admin())
    OR (
      profile_id = (SELECT auth.uid())
      AND public.has_role((SELECT auth.uid()), 'provider')
    )
  )
  WITH CHECK (
    (SELECT public.is_admin())
    OR (
      profile_id = (SELECT auth.uid())
      AND public.has_role((SELECT auth.uid()), 'provider')
      AND verification_status = (
        SELECT p.verification_status FROM public.providers p WHERE p.id = providers.id
      )
    )
  );

-- A partner may progress only a job currently assigned to their approved identity.
-- Customers may update only their own booking. Admins continue through AAL2 checks.
CREATE OR REPLACE FUNCTION public.enforce_service_request_update_actor()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_provider_id UUID;
  v_provider_status TEXT;
BEGIN
  IF auth.uid() IS NULL OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.customer_id = auth.uid()
     AND public.has_role(auth.uid(), 'customer') THEN
    RETURN NEW;
  END IF;

  IF public.has_role(auth.uid(), 'provider') THEN
    SELECT p.id, p.verification_status
      INTO v_provider_id, v_provider_status
      FROM public.providers p
     WHERE p.profile_id = auth.uid();

    IF v_provider_id IS NOT NULL
       AND v_provider_status = 'approved'
       AND EXISTS (
         SELECT 1 FROM public.assignments a
          WHERE a.request_id = OLD.id
            AND a.provider_id = v_provider_id
            AND a.status IN ('accepted', 'completed')
       ) THEN
      RETURN NEW;
    END IF;
  END IF;

  RAISE EXCEPTION 'Only the customer, the approved assigned provider, or an AAL2 administrator may update this service request.'
    USING ERRCODE = '42501';
END;
$$;

REVOKE ALL ON FUNCTION public.enforce_service_request_update_actor() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS enforce_service_request_update_actor ON public.service_requests;
CREATE TRIGGER enforce_service_request_update_actor
  BEFORE UPDATE ON public.service_requests
  FOR EACH ROW EXECUTE FUNCTION public.enforce_service_request_update_actor();

COMMENT ON FUNCTION public.enforce_service_request_update_actor() IS
  'Blocks customer/provider cross-role updates and requires an approved, accepted provider assignment for provider-side job progression.';
