-- ============================================================================
-- Kwick Database Schema Migration: 003 Transactional RPC Functions
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Create Service Request (Customer)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_service_request(
    p_category_id UUID,
    p_service_area_id UUID,
    p_description TEXT,
    p_address_line TEXT,
    p_pincode TEXT,
    p_latitude DOUBLE PRECISION DEFAULT NULL,
    p_longitude DOUBLE PRECISION DEFAULT NULL,
    p_scheduled_at TIMESTAMPTZ DEFAULT NULL,
    p_customer_notes TEXT DEFAULT NULL,
    p_photo_storage_path TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_customer_id UUID;
    v_request_id UUID;
    v_is_cat_active BOOLEAN;
    v_is_area_active BOOLEAN;
BEGIN
    v_customer_id := auth.uid();
    IF v_customer_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required.' USING ERRCODE = '42501';
    END IF;

    -- Verify category is active
    SELECT is_active INTO v_is_cat_active FROM public.service_categories WHERE id = p_category_id;
    IF v_is_cat_active IS NOT TRUE THEN
        RAISE EXCEPTION 'Selected service category is not available.' USING ERRCODE = 'P0001';
    END IF;

    -- Verify service area is active
    SELECT is_active INTO v_is_area_active FROM public.service_areas WHERE id = p_service_area_id;
    IF v_is_area_active IS NOT TRUE THEN
        RAISE EXCEPTION 'Service is not available in the specified area.' USING ERRCODE = 'P0002';
    END IF;

    -- Validate description & address
    IF length(trim(p_description)) < 10 THEN
        RAISE EXCEPTION 'Description must be at least 10 characters long.' USING ERRCODE = 'P0003';
    END IF;
    IF length(trim(p_address_line)) < 5 THEN
        RAISE EXCEPTION 'Address must be at least 5 characters long.' USING ERRCODE = 'P0004';
    END IF;

    -- Insert Request
    INSERT INTO public.service_requests (
        customer_id,
        category_id,
        service_area_id,
        description,
        address_line,
        pincode,
        latitude,
        longitude,
        scheduled_at,
        customer_notes,
        photo_storage_path,
        status
    ) VALUES (
        v_customer_id,
        p_category_id,
        p_service_area_id,
        trim(p_description),
        trim(p_address_line),
        trim(p_pincode),
        p_latitude,
        p_longitude,
        p_scheduled_at,
        p_customer_notes,
        p_photo_storage_path,
        'requested'
    ) RETURNING id INTO v_request_id;

    -- Append Order Event
    INSERT INTO public.order_events (
        request_id,
        actor_user_id,
        event_type,
        old_status,
        new_status,
        metadata
    ) VALUES (
        v_request_id,
        v_customer_id,
        'request_created',
        NULL,
        'requested',
        jsonb_build_object(
            'pincode', p_pincode,
            'scheduled_at', p_scheduled_at
        )
    );

    RETURN v_request_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ----------------------------------------------------------------------------
-- 2. Cancel Service Request (Customer or Admin)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cancel_service_request(
    p_request_id UUID,
    p_reason TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_actor_id UUID;
    v_req RECORD;
BEGIN
    v_actor_id := auth.uid();
    IF v_actor_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required.' USING ERRCODE = '42501';
    END IF;

    SELECT * INTO v_req FROM public.service_requests WHERE id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Service request not found.' USING ERRCODE = 'P0002';
    END IF;

    -- Authorization check: owner or admin
    IF v_req.customer_id <> v_actor_id AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Not authorized to cancel this request.' USING ERRCODE = '42501';
    END IF;

    -- Permitted states check
    IF v_req.status NOT IN ('requested', 'reviewing', 'assigned') THEN
        RAISE EXCEPTION 'Service request cannot be cancelled in state %.', v_req.status USING ERRCODE = 'P0003';
    END IF;

    -- If there is an offered assignment, withdraw it
    UPDATE public.assignments
    SET status = 'withdrawn', updated_at = now()
    WHERE request_id = p_request_id AND status = 'offered';

    -- Update request
    UPDATE public.service_requests
    SET status = 'cancelled',
        cancellation_reason = p_reason,
        cancelled_by = v_actor_id,
        updated_at = now()
    WHERE id = p_request_id;

    -- Log event
    INSERT INTO public.order_events (
        request_id,
        actor_user_id,
        event_type,
        old_status,
        new_status,
        metadata
    ) VALUES (
        p_request_id,
        v_actor_id,
        'request_cancelled',
        v_req.status,
        'cancelled',
        jsonb_build_object('reason', p_reason)
    );

    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ----------------------------------------------------------------------------
-- 3. Assign Provider to Request (Admin Dispatcher)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.assign_provider_to_request(
    p_request_id UUID,
    p_provider_id UUID,
    p_quoted_price_minor BIGINT DEFAULT NULL
)
RETURNS UUID AS $$
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

    -- Lock and check request
    SELECT * INTO v_req FROM public.service_requests WHERE id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Service request not found.' USING ERRCODE = 'P0002';
    END IF;

    IF v_req.status NOT IN ('requested', 'reviewing') THEN
        RAISE EXCEPTION 'Cannot assign provider to request in status %.', v_req.status USING ERRCODE = 'P0003';
    END IF;

    -- Lock and check provider eligibility
    SELECT * INTO v_prov FROM public.providers WHERE id = p_provider_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Provider record not found.' USING ERRCODE = 'P0004';
    END IF;

    IF v_prov.verification_status <> 'approved' THEN
        RAISE EXCEPTION 'Provider is not approved for assignments.' USING ERRCODE = 'P0005';
    END IF;

    IF v_prov.availability_status = 'unavailable' THEN
        RAISE EXCEPTION 'Provider is currently marked unavailable.' USING ERRCODE = 'P0006';
    END IF;

    -- Verify category capability
    IF NOT EXISTS (
        SELECT 1 FROM public.provider_services
        WHERE provider_id = p_provider_id AND category_id = v_req.category_id AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Provider is not qualified for category.' USING ERRCODE = 'P0007';
    END IF;

    -- Insert assignment (DB constraint guarantees no duplicate active assignment)
    INSERT INTO public.assignments (
        request_id,
        provider_id,
        status,
        assigned_by,
        assigned_at
    ) VALUES (
        p_request_id,
        p_provider_id,
        'offered',
        v_actor_id,
        now()
    ) RETURNING id INTO v_assignment_id;

    -- Update request status and quoted price
    UPDATE public.service_requests
    SET status = 'assigned',
        quoted_price_minor = COALESCE(p_quoted_price_minor, quoted_price_minor),
        updated_at = now()
    WHERE id = p_request_id;

    -- Append order event
    INSERT INTO public.order_events (
        request_id,
        actor_user_id,
        event_type,
        old_status,
        new_status,
        metadata
    ) VALUES (
        p_request_id,
        v_actor_id,
        'provider_assigned',
        v_req.status,
        'assigned',
        jsonb_build_object(
            'provider_id', p_provider_id,
            'assignment_id', v_assignment_id,
            'quoted_price_minor', p_quoted_price_minor
        )
    );

    -- Log admin action
    INSERT INTO public.admin_audit_logs (
        actor_id,
        action,
        target_entity,
        target_id,
        before_values,
        after_values,
        reason
    ) VALUES (
        v_actor_id,
        'assign_provider',
        'service_requests',
        p_request_id,
        jsonb_build_object('status', v_req.status),
        jsonb_build_object('status', 'assigned', 'provider_id', p_provider_id),
        'Operational dispatch'
    );

    RETURN v_assignment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ----------------------------------------------------------------------------
-- 4. Respond to Assignment (Provider Accept / Decline)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.respond_to_assignment(
    p_assignment_id UUID,
    p_accept BOOLEAN,
    p_decline_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_actor_id UUID;
    v_provider_id UUID;
    v_assign RECORD;
    v_req RECORD;
BEGIN
    v_actor_id := auth.uid();
    v_provider_id := public.get_provider_id_for_user(v_actor_id);

    IF v_provider_id IS NULL THEN
        RAISE EXCEPTION 'Caller is not a registered provider.' USING ERRCODE = '42501';
    END IF;

    -- Lock and check assignment
    SELECT * INTO v_assign FROM public.assignments WHERE id = p_assignment_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment not found.' USING ERRCODE = 'P0002';
    END IF;

    IF v_assign.provider_id <> v_provider_id THEN
        RAISE EXCEPTION 'Not authorized to respond to another provider assignment.' USING ERRCODE = '42501';
    END IF;

    IF v_assign.status <> 'offered' THEN
        RAISE EXCEPTION 'Assignment is no longer offered (current status: %).', v_assign.status USING ERRCODE = 'P0003';
    END IF;

    -- Lock request
    SELECT * INTO v_req FROM public.service_requests WHERE id = v_assign.request_id FOR UPDATE;

    IF p_accept IS TRUE THEN
        -- Accept assignment
        UPDATE public.assignments
        SET status = 'accepted', responded_at = now(), updated_at = now()
        WHERE id = p_assignment_id;

        -- Update request
        UPDATE public.service_requests
        SET status = 'accepted', updated_at = now()
        WHERE id = v_assign.request_id;

        -- Mark provider as busy
        UPDATE public.providers
        SET availability_status = 'busy', updated_at = now()
        WHERE id = v_provider_id;

        -- Log event
        INSERT INTO public.order_events (
            request_id,
            actor_user_id,
            event_type,
            old_status,
            new_status,
            metadata
        ) VALUES (
            v_assign.request_id,
            v_actor_id,
            'assignment_accepted',
            v_req.status,
            'accepted',
            jsonb_build_object('assignment_id', p_assignment_id)
        );
    ELSE
        -- Decline assignment
        UPDATE public.assignments
        SET status = 'declined',
            decline_reason = p_decline_reason,
            responded_at = now(),
            updated_at = now()
        WHERE id = p_assignment_id;

        -- Return request to 'requested' so operator can reassign
        UPDATE public.service_requests
        SET status = 'requested', updated_at = now()
        WHERE id = v_assign.request_id;

        -- Log event
        INSERT INTO public.order_events (
            request_id,
            actor_user_id,
            event_type,
            old_status,
            new_status,
            metadata
        ) VALUES (
            v_assign.request_id,
            v_actor_id,
            'assignment_declined',
            v_req.status,
            'requested',
            jsonb_build_object(
                'assignment_id', p_assignment_id,
                'reason', p_decline_reason
            )
        );
    END IF;

    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ----------------------------------------------------------------------------
-- 5. Progress Service Request (Provider Lifecycle Updates)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.progress_service_request(
    p_request_id UUID,
    p_new_status TEXT,
    p_final_price_minor BIGINT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_actor_id UUID;
    v_provider_id UUID;
    v_assign RECORD;
    v_req RECORD;
BEGIN
    v_actor_id := auth.uid();
    v_provider_id := public.get_provider_id_for_user(v_actor_id);

    IF v_provider_id IS NULL AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Caller is not authorized.' USING ERRCODE = '42501';
    END IF;

    SELECT * INTO v_req FROM public.service_requests WHERE id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Service request not found.' USING ERRCODE = 'P0002';
    END IF;

    -- Provider must be assigned to this request
    IF NOT public.is_admin() THEN
        SELECT * INTO v_assign FROM public.assignments
        WHERE request_id = p_request_id AND provider_id = v_provider_id AND status = 'accepted'
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Caller is not the accepted provider for this request.' USING ERRCODE = '42501';
        END IF;
    END IF;

    -- Validate sequential transitions:
    -- accepted -> travelling OR in_progress
    -- travelling -> in_progress
    -- in_progress -> completed
    IF v_req.status = 'accepted' AND p_new_status NOT IN ('travelling', 'in_progress') THEN
        RAISE EXCEPTION 'Invalid transition from accepted to %.', p_new_status USING ERRCODE = 'P0003';
    ELSIF v_req.status = 'travelling' AND p_new_status <> 'in_progress' THEN
        RAISE EXCEPTION 'Invalid transition from travelling to %.', p_new_status USING ERRCODE = 'P0003';
    ELSIF v_req.status = 'in_progress' AND p_new_status <> 'completed' THEN
        RAISE EXCEPTION 'Invalid transition from in_progress to %.', p_new_status USING ERRCODE = 'P0003';
    ELSIF v_req.status NOT IN ('accepted', 'travelling', 'in_progress') THEN
        RAISE EXCEPTION 'Cannot progress order in state %.', v_req.status USING ERRCODE = 'P0003';
    END IF;

    -- If completed: complete assignment and free provider availability
    IF p_new_status = 'completed' THEN
        UPDATE public.assignments
        SET status = 'completed', updated_at = now()
        WHERE request_id = p_request_id AND status = 'accepted';

        IF v_provider_id IS NOT NULL THEN
            UPDATE public.providers
            SET availability_status = 'available', updated_at = now()
            WHERE id = v_provider_id;
        END IF;
    END IF;

    -- Update request
    UPDATE public.service_requests
    SET status = p_new_status,
        final_price_minor = COALESCE(p_final_price_minor, final_price_minor, quoted_price_minor),
        updated_at = now()
    WHERE id = p_request_id;

    -- Record event
    INSERT INTO public.order_events (
        request_id,
        actor_user_id,
        event_type,
        old_status,
        new_status,
        metadata
    ) VALUES (
        p_request_id,
        v_actor_id,
        'order_' || p_new_status,
        v_req.status,
        p_new_status,
        jsonb_build_object('final_price_minor', p_final_price_minor)
    );

    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ----------------------------------------------------------------------------
-- 6. Admin Provider Verification
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_verify_provider(
    p_provider_id UUID,
    p_status TEXT,
    p_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_actor_id UUID;
    v_prov RECORD;
BEGIN
    v_actor_id := auth.uid();
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Administrative privileges required.' USING ERRCODE = '42501';
    END IF;

    IF p_status NOT IN ('pending', 'approved', 'rejected', 'suspended') THEN
        RAISE EXCEPTION 'Invalid verification status: %.', p_status USING ERRCODE = 'P0003';
    END IF;

    SELECT * INTO v_prov FROM public.providers WHERE id = p_provider_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Provider not found.' USING ERRCODE = 'P0002';
    END IF;

    UPDATE public.providers
    SET verification_status = p_status,
        verification_notes = p_notes,
        approved_by = CASE WHEN p_status = 'approved' THEN v_actor_id ELSE approved_by END,
        approved_at = CASE WHEN p_status = 'approved' THEN now() ELSE approved_at END,
        updated_at = now()
    WHERE id = p_provider_id;

    -- Audit log
    INSERT INTO public.admin_audit_logs (
        actor_id,
        action,
        target_entity,
        target_id,
        before_values,
        after_values,
        reason
    ) VALUES (
        v_actor_id,
        'verify_provider',
        'providers',
        p_provider_id,
        jsonb_build_object('verification_status', v_prov.verification_status),
        jsonb_build_object('verification_status', p_status, 'notes', p_notes),
        p_notes
    );

    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ----------------------------------------------------------------------------
-- 7. Admin Override Request Status
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_override_request_status(
    p_request_id UUID,
    p_new_status TEXT,
    p_reason TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_actor_id UUID;
    v_req RECORD;
BEGIN
    v_actor_id := auth.uid();
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Administrative privileges required.' USING ERRCODE = '42501';
    END IF;

    IF length(trim(COALESCE(p_reason, ''))) < 5 THEN
        RAISE EXCEPTION 'A documented reason of at least 5 characters is required for status overrides.' USING ERRCODE = 'P0003';
    END IF;

    SELECT * INTO v_req FROM public.service_requests WHERE id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Request not found.' USING ERRCODE = 'P0002';
    END IF;

    UPDATE public.service_requests
    SET status = p_new_status, updated_at = now()
    WHERE id = p_request_id;

    -- Audit log
    INSERT INTO public.admin_audit_logs (
        actor_id,
        action,
        target_entity,
        target_id,
        before_values,
        after_values,
        reason
    ) VALUES (
        v_actor_id,
        'override_status',
        'service_requests',
        p_request_id,
        jsonb_build_object('status', v_req.status),
        jsonb_build_object('status', p_new_status),
        p_reason
    );

    -- Order event
    INSERT INTO public.order_events (
        request_id,
        actor_user_id,
        event_type,
        old_status,
        new_status,
        metadata
    ) VALUES (
        p_request_id,
        v_actor_id,
        'admin_override',
        v_req.status,
        p_new_status,
        jsonb_build_object('reason', p_reason)
    );

    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ----------------------------------------------------------------------------
-- 8. Bootstrap Admin Procedure
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.bootstrap_admin(
    p_target_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_caller_id UUID;
    v_has_super_admin BOOLEAN;
BEGIN
    v_caller_id := auth.uid();
    
    -- Check if any super_admin exists
    SELECT EXISTS (
        SELECT 1 FROM public.user_roles WHERE role = 'super_admin'
    ) INTO v_has_super_admin;

    -- If super_admins already exist, only a super_admin can grant admin roles
    IF v_has_super_admin AND NOT public.has_role(v_caller_id, 'super_admin') THEN
        RAISE EXCEPTION 'Only existing super-admins can grant administrative privileges.' USING ERRCODE = '42501';
    END IF;

    -- Grant super_admin & admin roles
    INSERT INTO public.user_roles (user_id, role, granted_by)
    VALUES 
        (p_target_user_id, 'admin', v_caller_id),
        (p_target_user_id, 'super_admin', v_caller_id)
    ON CONFLICT (user_id, role) DO NOTHING;

    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
