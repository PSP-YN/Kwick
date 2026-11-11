-- Strengthen dispatch invariants: a provider can hold only one active offer/job,
-- and dispatch must respect both availability and the request's service area.

CREATE UNIQUE INDEX IF NOT EXISTS idx_assignments_single_active_per_provider
  ON public.assignments(provider_id)
  WHERE status IN ('offered', 'accepted');

CREATE OR REPLACE FUNCTION public.assign_provider_to_request(
    p_request_id UUID,
    p_provider_id UUID,
    p_quoted_price_minor BIGINT DEFAULT NULL
)
RETURNS UUID AS $function$
DECLARE
    v_actor_id UUID;
    v_req RECORD;
    v_prov RECORD;
    v_assignment_id UUID;
BEGIN
    v_actor_id := auth.uid();
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Administrative privileges required.' USING ERRCODE = '42501';
    END IF;

    SELECT * INTO v_req FROM public.service_requests WHERE id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Service request not found.' USING ERRCODE = 'P0002';
    END IF;

    IF v_req.status NOT IN ('requested', 'reviewing') THEN
        RAISE EXCEPTION 'Cannot assign provider to request in status %.', v_req.status USING ERRCODE = 'P0003';
    END IF;

    SELECT * INTO v_prov FROM public.providers WHERE id = p_provider_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Provider record not found.' USING ERRCODE = 'P0004';
    END IF;

    IF v_prov.verification_status <> 'approved' THEN
        RAISE EXCEPTION 'Provider is not approved for assignments.' USING ERRCODE = 'P0005';
    END IF;

    IF v_prov.availability_status <> 'available' THEN
        RAISE EXCEPTION 'Provider is not currently available.' USING ERRCODE = 'P0006';
    END IF;

    IF v_prov.service_area_id IS DISTINCT FROM v_req.service_area_id THEN
        RAISE EXCEPTION 'Provider is not registered for this service area.' USING ERRCODE = 'P0008';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.provider_services
        WHERE provider_id = p_provider_id
          AND category_id = v_req.category_id
          AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Provider is not qualified for category.' USING ERRCODE = 'P0007';
    END IF;

    INSERT INTO public.assignments (
        request_id, provider_id, status, assigned_by, assigned_at
    ) VALUES (
        p_request_id, p_provider_id, 'offered', v_actor_id, now()
    ) RETURNING id INTO v_assignment_id;

    UPDATE public.service_requests
    SET status = 'assigned',
        quoted_price_minor = COALESCE(p_quoted_price_minor, quoted_price_minor),
        updated_at = now()
    WHERE id = p_request_id;

    INSERT INTO public.order_events (
        request_id, actor_user_id, event_type, old_status, new_status, metadata
    ) VALUES (
        p_request_id, v_actor_id, 'provider_assigned', v_req.status, 'assigned',
        jsonb_build_object(
          'provider_id', p_provider_id,
          'assignment_id', v_assignment_id,
          'quoted_price_minor', p_quoted_price_minor
        )
    );

    INSERT INTO public.admin_audit_logs (
        actor_id, action, target_entity, target_id, before_values, after_values, reason
    ) VALUES (
        v_actor_id, 'assign_provider', 'service_requests', p_request_id,
        jsonb_build_object('status', v_req.status),
        jsonb_build_object('status', 'assigned', 'provider_id', p_provider_id),
        'Operational dispatch'
    );

    RETURN v_assignment_id;
END;
$function$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
