-- Kwick commercial terms: provider-owned pricing and negotiated platform commission.
-- No default commission is inserted. A commission is active only after an operator
-- records the provider's explicit offline agreement and approves the terms.

ALTER TABLE public.provider_services
  ADD COLUMN IF NOT EXISTS pricing_model TEXT NOT NULL DEFAULT 'provider_quote'
    CHECK (pricing_model IN ('provider_quote', 'agreed_fixed')),
  ADD COLUMN IF NOT EXISTS price_approval_status TEXT NOT NULL DEFAULT 'not_required'
    CHECK (price_approval_status IN ('not_required', 'pending', 'approved', 'rejected')),
  ADD COLUMN IF NOT EXISTS price_updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE public.provider_services
  ADD CONSTRAINT provider_services_fixed_price_required
  CHECK (pricing_model <> 'agreed_fixed' OR base_price_minor IS NOT NULL);

CREATE INDEX IF NOT EXISTS idx_provider_services_catalog_visible
  ON public.provider_services (category_id, is_active, price_approval_status)
  WHERE pricing_model = 'agreed_fixed';

-- A provider can propose a fixed price, but only an admin can approve it.
CREATE OR REPLACE FUNCTION public.enforce_provider_service_price_review()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.uid() IS NOT NULL AND NOT public.is_admin() THEN
    IF TG_OP = 'INSERT' THEN
      NEW.price_approval_status := CASE
        WHEN NEW.pricing_model = 'agreed_fixed' THEN 'pending'
        ELSE 'not_required'
      END;
      NEW.price_updated_at := now();
    ELSIF NEW.base_price_minor IS DISTINCT FROM OLD.base_price_minor
       OR NEW.pricing_model IS DISTINCT FROM OLD.pricing_model THEN
      NEW.price_approval_status := CASE
        WHEN NEW.pricing_model = 'agreed_fixed' THEN 'pending'
        ELSE 'not_required'
      END;
      NEW.price_updated_at := now();
    ELSE
      NEW.price_approval_status := OLD.price_approval_status;
    END IF;
  ELSIF TG_OP = 'UPDATE'
    AND (NEW.base_price_minor IS DISTINCT FROM OLD.base_price_minor
      OR NEW.pricing_model IS DISTINCT FROM OLD.pricing_model) THEN
    NEW.price_updated_at := now();
  END IF;

  IF NEW.pricing_model = 'agreed_fixed' AND NEW.base_price_minor IS NULL THEN
    RAISE EXCEPTION 'An agreed fixed price is required before price approval';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enforce_provider_service_price_review ON public.provider_services;
CREATE TRIGGER enforce_provider_service_price_review
  BEFORE INSERT OR UPDATE ON public.provider_services
  FOR EACH ROW EXECUTE FUNCTION public.enforce_provider_service_price_review();

-- Append-only audit of provider price proposals and admin approvals.
CREATE TABLE IF NOT EXISTS public.provider_service_price_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_service_id UUID NOT NULL REFERENCES public.provider_services(id) ON DELETE CASCADE,
  provider_id UUID NOT NULL REFERENCES public.providers(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES public.service_categories(id) ON DELETE RESTRICT,
  actor_user_id UUID REFERENCES auth.users(id),
  old_price_minor BIGINT,
  new_price_minor BIGINT,
  old_pricing_model TEXT,
  new_pricing_model TEXT NOT NULL,
  approval_status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_provider_service_price_events_provider_created
  ON public.provider_service_price_events (provider_id, created_at DESC);

ALTER TABLE public.provider_service_price_events ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON public.provider_service_price_events TO authenticated;
CREATE POLICY provider_service_price_events_read_own_or_admin
  ON public.provider_service_price_events
  FOR SELECT TO authenticated
  USING (
    provider_id = public.get_provider_id_for_user(auth.uid())
    OR public.is_admin()
  );

CREATE OR REPLACE FUNCTION public.audit_provider_service_price_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF TG_OP = 'INSERT'
    OR NEW.base_price_minor IS DISTINCT FROM OLD.base_price_minor
    OR NEW.pricing_model IS DISTINCT FROM OLD.pricing_model
    OR NEW.price_approval_status IS DISTINCT FROM OLD.price_approval_status THEN
    INSERT INTO public.provider_service_price_events (
      provider_service_id, provider_id, category_id, actor_user_id,
      old_price_minor, new_price_minor, old_pricing_model,
      new_pricing_model, approval_status
    ) VALUES (
      NEW.id, NEW.provider_id, NEW.category_id, auth.uid(),
      CASE WHEN TG_OP = 'UPDATE' THEN OLD.base_price_minor ELSE NULL END,
      NEW.base_price_minor,
      CASE WHEN TG_OP = 'UPDATE' THEN OLD.pricing_model ELSE NULL END,
      NEW.pricing_model, NEW.price_approval_status
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS audit_provider_service_price_change ON public.provider_services;
CREATE TRIGGER audit_provider_service_price_change
  AFTER INSERT OR UPDATE ON public.provider_services
  FOR EACH ROW EXECUTE FUNCTION public.audit_provider_service_price_change();

-- Commission agreements are negotiated provider-by-provider and category-by-category.
-- Basis points avoid floating point; 100 bps = 1%. There is intentionally no global default.
CREATE TABLE IF NOT EXISTS public.provider_commission_terms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES public.providers(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES public.service_categories(id) ON DELETE RESTRICT,
  commission_rate_bps INTEGER NOT NULL CHECK (commission_rate_bps BETWEEN 0 AND 10000),
  status TEXT NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'active', 'rejected', 'superseded')),
  provider_agreed_at TIMESTAMPTZ,
  effective_from TIMESTAMPTZ,
  created_by UUID REFERENCES auth.users(id),
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMPTZ,
  terms_note TEXT CHECK (terms_note IS NULL OR length(terms_note) <= 2000),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT active_commission_requires_agreement CHECK (
    status <> 'active'
    OR (provider_agreed_at IS NOT NULL AND approved_by IS NOT NULL AND approved_at IS NOT NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_provider_commission_one_active_term
  ON public.provider_commission_terms (provider_id, category_id)
  WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_provider_commission_terms_provider_status
  ON public.provider_commission_terms (provider_id, status, category_id);

CREATE TRIGGER set_provider_commission_terms_updated_at
  BEFORE UPDATE ON public.provider_commission_terms
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

ALTER TABLE public.provider_commission_terms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_commission_terms FORCE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.provider_commission_terms TO authenticated;

CREATE POLICY provider_commission_terms_read_own_or_admin
  ON public.provider_commission_terms
  FOR SELECT TO authenticated
  USING (
    provider_id = public.get_provider_id_for_user(auth.uid())
    OR public.is_admin()
  );
CREATE POLICY provider_commission_terms_admin_manage
  ON public.provider_commission_terms
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Customers may only see a provider's fixed catalogue price after an admin approval.
CREATE POLICY provider_services_customer_approved_catalog_read
  ON public.provider_services
  FOR SELECT TO authenticated
  USING (
    is_active = true
    AND pricing_model = 'agreed_fixed'
    AND price_approval_status = 'approved'
  );

COMMENT ON COLUMN public.provider_services.pricing_model IS
  'provider_quote: provider confirms price after assessing the job; agreed_fixed: mutually agreed catalogue price requiring admin approval.';
COMMENT ON COLUMN public.provider_services.price_approval_status IS
  'Provider changes to agreed_fixed prices are forced to pending; only an admin can approve them.';
COMMENT ON TABLE public.provider_commission_terms IS
  'Provider/category-specific negotiated platform commission. No active rate exists until the provider agreement and admin approval are recorded.';
COMMENT ON TABLE public.provider_service_price_events IS
  'Append-only audit trail for provider price proposals and admin approvals.';

ALTER TABLE public.provider_services
  ADD COLUMN IF NOT EXISTS price_reviewed_by UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS price_reviewed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS price_review_note TEXT CHECK (price_review_note IS NULL OR length(price_review_note) <= 1000);

CREATE OR REPLACE FUNCTION public.admin_record_provider_commission_terms(
  p_provider_id UUID,
  p_category_id UUID,
  p_commission_rate_bps INTEGER,
  p_provider_agreed BOOLEAN,
  p_terms_note TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_term_id UUID;
  v_status TEXT;
BEGIN
  IF NOT public.is_admin() OR (auth.jwt() ->> 'aal') <> 'aal2' THEN
    RAISE EXCEPTION 'A verified Kwick administrator session is required';
  END IF;
  IF p_commission_rate_bps IS NULL OR p_commission_rate_bps < 0 OR p_commission_rate_bps > 10000 THEN
    RAISE EXCEPTION 'Commission rate must be between 0 and 100 percent';
  END IF;
  IF p_provider_agreed AND length(trim(COALESCE(p_terms_note, ''))) < 5 THEN
    RAISE EXCEPTION 'Record the provider agreement evidence before activating commission';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.providers WHERE id = p_provider_id) THEN
    RAISE EXCEPTION 'Provider does not exist';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.provider_services WHERE provider_id = p_provider_id AND category_id = p_category_id) THEN
    RAISE EXCEPTION 'Provider is not onboarded for this service category';
  END IF;

  v_status := CASE WHEN p_provider_agreed THEN 'active' ELSE 'draft' END;
  IF p_provider_agreed THEN
    UPDATE public.provider_commission_terms
       SET status = 'superseded'
     WHERE provider_id = p_provider_id
       AND category_id = p_category_id
       AND status = 'active';
  END IF;

  INSERT INTO public.provider_commission_terms (
    provider_id, category_id, commission_rate_bps, status,
    provider_agreed_at, effective_from, created_by,
    approved_by, approved_at, terms_note
  ) VALUES (
    p_provider_id, p_category_id, p_commission_rate_bps, v_status,
    CASE WHEN p_provider_agreed THEN now() ELSE NULL END,
    CASE WHEN p_provider_agreed THEN now() ELSE NULL END,
    auth.uid(),
    CASE WHEN p_provider_agreed THEN auth.uid() ELSE NULL END,
    CASE WHEN p_provider_agreed THEN now() ELSE NULL END,
    NULLIF(trim(p_terms_note), '')
  ) RETURNING id INTO v_term_id;

  RETURN v_term_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_record_provider_commission_terms(UUID, UUID, INTEGER, BOOLEAN, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_record_provider_commission_terms(UUID, UUID, INTEGER, BOOLEAN, TEXT) TO authenticated;
COMMENT ON FUNCTION public.admin_record_provider_commission_terms(UUID, UUID, INTEGER, BOOLEAN, TEXT) IS
  'Creates a draft commission proposal or activates a provider/category rate only after AAL2 admin records explicit provider agreement.';
