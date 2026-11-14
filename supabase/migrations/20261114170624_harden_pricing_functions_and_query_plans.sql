-- Close public execution of trigger-only SECURITY DEFINER functions.
-- These functions are invoked by PostgreSQL triggers, never through the Data API.
REVOKE ALL ON FUNCTION public.audit_provider_service_price_change() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.enforce_provider_service_price_review() FROM PUBLIC, anon, authenticated;

ALTER FUNCTION public.audit_provider_service_price_change() SET search_path = '';
ALTER FUNCTION public.enforce_provider_service_price_review() SET search_path = '';
ALTER FUNCTION public.admin_record_provider_commission_terms(UUID, UUID, INTEGER, BOOLEAN, TEXT) SET search_path = '';

-- Avoid per-row auth context evaluation in the new commercial table policies.
DROP POLICY IF EXISTS provider_service_price_events_read_own_or_admin
  ON public.provider_service_price_events;
CREATE POLICY provider_service_price_events_read_own_or_admin
  ON public.provider_service_price_events
  FOR SELECT TO authenticated
  USING (
    provider_id = public.get_provider_id_for_user((SELECT auth.uid()))
    OR (SELECT public.is_admin())
  );

DROP POLICY IF EXISTS provider_commission_terms_read_own_or_admin
  ON public.provider_commission_terms;
CREATE POLICY provider_commission_terms_read_own_or_admin
  ON public.provider_commission_terms
  FOR SELECT TO authenticated
  USING (
    provider_id = public.get_provider_id_for_user((SELECT auth.uid()))
    OR (SELECT public.is_admin())
  );

-- Replace broad FOR ALL policies with operation-specific policies. SELECT remains
-- governed by the explicit ownership/catalogue policies above.
DROP POLICY IF EXISTS provider_commission_terms_admin_manage
  ON public.provider_commission_terms;
CREATE POLICY provider_commission_terms_admin_insert
  ON public.provider_commission_terms FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY provider_commission_terms_admin_update
  ON public.provider_commission_terms FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin()))
  WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY provider_commission_terms_admin_delete
  ON public.provider_commission_terms FOR DELETE TO authenticated
  USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS provider_documents_admin_manage
  ON public.provider_documents;
CREATE POLICY provider_documents_admin_update
  ON public.provider_documents FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin()))
  WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY provider_documents_admin_delete
  ON public.provider_documents FOR DELETE TO authenticated
  USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS provider_services_manage_own
  ON public.provider_services;
CREATE POLICY provider_services_insert_own_or_admin
  ON public.provider_services FOR INSERT TO authenticated
  WITH CHECK (
    (provider_id = public.get_provider_id_for_user((SELECT auth.uid()))
      AND public.has_role((SELECT auth.uid()), 'provider'))
    OR (SELECT public.is_admin())
  );
CREATE POLICY provider_services_update_own_or_admin
  ON public.provider_services FOR UPDATE TO authenticated
  USING (
    (provider_id = public.get_provider_id_for_user((SELECT auth.uid()))
      AND public.has_role((SELECT auth.uid()), 'provider'))
    OR (SELECT public.is_admin())
  )
  WITH CHECK (
    (provider_id = public.get_provider_id_for_user((SELECT auth.uid()))
      AND public.has_role((SELECT auth.uid()), 'provider'))
    OR (SELECT public.is_admin())
  );
CREATE POLICY provider_services_delete_own_or_admin
  ON public.provider_services FOR DELETE TO authenticated
  USING (
    (provider_id = public.get_provider_id_for_user((SELECT auth.uid()))
      AND public.has_role((SELECT auth.uid()), 'provider'))
    OR (SELECT public.is_admin())
  );

DROP POLICY IF EXISTS providers_admin_manage ON public.providers;
CREATE POLICY providers_admin_insert
  ON public.providers FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY providers_admin_update
  ON public.providers FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin()))
  WITH CHECK ((SELECT public.is_admin()));

DROP POLICY IF EXISTS service_areas_admin_manage ON public.service_areas;
CREATE POLICY service_areas_admin_insert
  ON public.service_areas FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY service_areas_admin_update
  ON public.service_areas FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin()))
  WITH CHECK ((SELECT public.is_admin()));

DROP POLICY IF EXISTS service_categories_admin_manage ON public.service_categories;
CREATE POLICY service_categories_admin_insert
  ON public.service_categories FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY service_categories_admin_update
  ON public.service_categories FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin()))
  WITH CHECK ((SELECT public.is_admin()));

DROP POLICY IF EXISTS user_roles_admin_all ON public.user_roles;
CREATE POLICY user_roles_admin_insert
  ON public.user_roles FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY user_roles_admin_update
  ON public.user_roles FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin()))
  WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY user_roles_admin_delete
  ON public.user_roles FOR DELETE TO authenticated
  USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS assignments_admin_update ON public.assignments;
DROP POLICY IF EXISTS assignments_provider_respond ON public.assignments;
CREATE POLICY assignments_update_provider_or_admin
  ON public.assignments FOR UPDATE TO authenticated
  USING (
    (SELECT public.is_admin())
    OR (
      provider_id = public.get_provider_id_for_user((SELECT auth.uid()))
      AND public.has_role((SELECT auth.uid()), 'provider')
      AND status = 'offered'
    )
  )
  WITH CHECK (
    (SELECT public.is_admin())
    OR (
      provider_id = public.get_provider_id_for_user((SELECT auth.uid()))
      AND public.has_role((SELECT auth.uid()), 'provider')
      AND status IN ('accepted', 'declined')
    )
  );

DROP POLICY IF EXISTS service_requests_admin_update ON public.service_requests;
DROP POLICY IF EXISTS service_requests_update_own ON public.service_requests;
CREATE POLICY service_requests_update_customer_or_admin
  ON public.service_requests FOR UPDATE TO authenticated
  USING (
    (SELECT public.is_admin())
    OR (
      customer_id = (SELECT auth.uid())
      AND public.has_role((SELECT auth.uid()), 'customer')
      AND status IN ('requested', 'reviewing', 'assigned')
    )
  )
  WITH CHECK (
    (SELECT public.is_admin())
    OR (
      customer_id = (SELECT auth.uid())
      AND public.has_role((SELECT auth.uid()), 'customer')
    )
  );

-- Cover the foreign keys added by the commercial terms and price audit tables.
CREATE INDEX IF NOT EXISTS idx_provider_commission_terms_approved_by
  ON public.provider_commission_terms (approved_by);
CREATE INDEX IF NOT EXISTS idx_provider_commission_terms_category
  ON public.provider_commission_terms (category_id);
CREATE INDEX IF NOT EXISTS idx_provider_commission_terms_created_by
  ON public.provider_commission_terms (created_by);
CREATE INDEX IF NOT EXISTS idx_provider_service_price_events_actor
  ON public.provider_service_price_events (actor_user_id);
CREATE INDEX IF NOT EXISTS idx_provider_service_price_events_category
  ON public.provider_service_price_events (category_id);
CREATE INDEX IF NOT EXISTS idx_provider_service_price_events_service
  ON public.provider_service_price_events (provider_service_id);
CREATE INDEX IF NOT EXISTS idx_provider_services_price_reviewed_by
  ON public.provider_services (price_reviewed_by);

COMMENT ON POLICY assignments_update_provider_or_admin ON public.assignments IS
  'Providers may respond only to their own offered assignment; AAL2 admins may perform operational overrides.';
