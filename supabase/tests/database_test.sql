-- ============================================================================
-- Kwick Automated Database & Security Test Suite
-- ============================================================================

\set ON_ERROR_STOP on

BEGIN;

-- Setup mock auth & storage schemas for testing outside full Supabase host
CREATE SCHEMA IF NOT EXISTS auth;
CREATE TABLE IF NOT EXISTS auth.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT,
    phone TEXT,
    raw_user_meta_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Mock Supabase Auth helpers for session simulation outside the hosted platform.
CREATE OR REPLACE FUNCTION auth.uid() RETURNS UUID AS $$
    SELECT NULLIF(current_setting('request.jwt.claim.sub', true), '')::UUID;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION auth.jwt() RETURNS JSONB AS $$
    SELECT COALESCE(
        NULLIF(current_setting('request.jwt.claims', true), ''),
        '{}'
    )::JSONB;
$$ LANGUAGE sql STABLE;

CREATE SCHEMA IF NOT EXISTS storage;
CREATE TABLE IF NOT EXISTS storage.buckets (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    public BOOLEAN DEFAULT false,
    file_size_limit BIGINT,
    allowed_mime_types TEXT[]
);
CREATE TABLE IF NOT EXISTS storage.objects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bucket_id TEXT REFERENCES storage.buckets(id),
    name TEXT NOT NULL,
    owner UUID,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE OR REPLACE FUNCTION storage.foldername(name TEXT) RETURNS TEXT[] AS $folder$
    SELECT string_to_array(name, '/');
$folder$ LANGUAGE sql IMMUTABLE;

DO $roles$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role NOLOGIN BYPASSRLS;
    END IF;
END;
$roles$;

COMMIT;

-- Apply Migrations
\i supabase/migrations/20261023000001_initial_schema.sql
\i supabase/migrations/20261023000002_rls_policies.sql
\i supabase/migrations/20261023000003_rpc_functions.sql
\i supabase/migrations/20261023000004_seed_pilot_data.sql
\i supabase/migrations/20261111000005_harden_admin_bootstrap.sql
\i supabase/migrations/20261111000006_auth_provisioning_and_write_privileges.sql
\i supabase/migrations/20261111000007_dispatch_provider_invariants.sql
\i supabase/migrations/20261111000008_ai_diagnosis_usage.sql
\i supabase/migrations/20261111000009_harden_definer_helpers.sql
\i supabase/migrations/20261111000010_atomic_ai_quota.sql
\i supabase/migrations/20261111000011_validate_booking_inputs.sql
\i supabase/migrations/20261111000012_ai_consent_audit.sql
\i supabase/migrations/20261111000013_require_admin_mfa.sql
\i supabase/migrations/20261111000014_revoke_anon_admin_helper.sql
\i supabase/migrations/20261111000015_index_foreign_key_columns.sql
\i supabase/migrations/20261111000016_hoist_auth_rls_helpers.sql
\i supabase/migrations/20261114000017_kwick_commercial_terms.sql

-- ============================================================================
-- Test Suite Execution (Part 1: Superuser / Admin & Operations)
-- ============================================================================
BEGIN;

DO $$
DECLARE
    v_admin_id UUID := '11111111-1111-1111-1111-111111111111';
    v_customer_a_id UUID := '22222222-2222-2222-2222-222222222222';
    v_customer_b_id UUID := '33333333-3333-3333-3333-333333333333';
    v_provider_user_id UUID := '44444444-4444-4444-4444-444444444444';
    v_unrelated_provider_id UUID := '55555555-5555-5555-5555-555555555555';

    v_cat_plumbing UUID;
    v_pilot_area UUID;
    v_provider_id UUID;
    v_unrelated_prov_pk UUID;
    v_request_id UUID;
    v_assignment_id UUID;
    v_second_request_id UUID;
    v_failed BOOLEAN;
BEGIN
    RAISE NOTICE '>>> Starting Kwick Automated Test Suite <<<';

    -- ------------------------------------------------------------------------
    -- Test 1: Verify Seed Data (Pilot Area & Categories)
    -- ------------------------------------------------------------------------
    SELECT id INTO v_pilot_area FROM public.service_areas WHERE city = 'Bengaluru' AND pincode = '560102' AND is_active = true;
    ASSERT v_pilot_area IS NOT NULL, 'Test 1 Failed: Pilot service area missing';

    SELECT id INTO v_cat_plumbing FROM public.service_categories WHERE slug = 'plumbing' AND is_active = true;
    ASSERT v_cat_plumbing IS NOT NULL, 'Test 1 Failed: Plumbing service category missing';
    RAISE NOTICE '[PASS] Test 1: Seed data verified (Area & Categories)';

    -- ------------------------------------------------------------------------
    -- Setup Test Users
    -- ------------------------------------------------------------------------
    INSERT INTO auth.users (id, email, raw_user_meta_data) VALUES
        (v_admin_id, 'admin@nexhelp.com', jsonb_build_object('full_name', 'Platform Admin', 'initial_role', 'customer')),
        (v_customer_a_id, 'customer.a@test.com', jsonb_build_object('full_name', 'Customer Alice', 'initial_role', 'customer')),
        (v_customer_b_id, 'customer.b@test.com', jsonb_build_object('full_name', 'Customer Bob', 'initial_role', 'customer')),
        (v_provider_user_id, 'plumber.rajesh@test.com', jsonb_build_object('full_name', 'Rajesh Kumar', 'initial_role', 'provider')),
        (v_unrelated_provider_id, 'electrician.suresh@test.com', jsonb_build_object('full_name', 'Suresh Gowda', 'initial_role', 'provider'));

    -- Admin Bootstrap and MFA assurance gate.
    PERFORM set_config('request.jwt.claim.sub', v_admin_id::text, true);
    PERFORM set_config('request.jwt.claims', pg_catalog.jsonb_build_object('sub', v_admin_id::text, 'role', 'authenticated', 'aal', 'aal1')::text, true);
    ASSERT public.is_admin() = false, 'Test 2 Failed: Admin access was granted to an AAL1 session';
    PERFORM set_config('request.jwt.claims', pg_catalog.jsonb_build_object('sub', v_admin_id::text, 'role', 'authenticated', 'aal', 'aal2')::text, true);
    PERFORM public.bootstrap_admin(v_admin_id);
    ASSERT public.is_admin() = true, 'Test 2 Failed: Admin access was denied to an AAL2 session';
    ASSERT public.has_role(v_admin_id, 'admin') = true, 'Test 2 Failed: Admin role missing';
    ASSERT public.has_role(v_admin_id, 'super_admin') = true, 'Test 2 Failed: Super Admin role missing';

    -- Auth trigger must provision profile and allowlisted initial role.
    ASSERT EXISTS (SELECT 1 FROM public.profiles WHERE id = v_customer_a_id AND full_name = 'Customer Alice'),
        'Test 2 Failed: Auth trigger did not provision customer profile';
    ASSERT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = v_provider_user_id AND role = 'provider'),
        'Test 2 Failed: Auth trigger did not provision provider role';
    RAISE NOTICE '[PASS] Test 2: User profiles, authentication and RBAC roles created';

    -- ------------------------------------------------------------------------
    -- Test 3: Customer A creates a service request via RPC
    -- ------------------------------------------------------------------------
    PERFORM set_config('request.jwt.claim.sub', v_customer_a_id::text, true);
    
    v_request_id := public.create_service_request(
        p_category_id := v_cat_plumbing,
        p_service_area_id := v_pilot_area,
        p_description := 'Kitchen sink tap is leaking continuously since morning',
        p_address_line := '#142, 5th Cross, 19th Main, HSR Layout Sector 1',
        p_pincode := '560102',
        p_scheduled_at := now() + interval '2 hours'
    );
    ASSERT v_request_id IS NOT NULL, 'Test 3 Failed: Request ID not returned';
    ASSERT (SELECT status FROM public.service_requests WHERE id = v_request_id) = 'requested', 'Test 3 Failed: Status must be requested';
    ASSERT (SELECT count(*) FROM public.order_events WHERE request_id = v_request_id AND event_type = 'request_created') = 1, 'Test 3 Failed: Order event not created';
    RAISE NOTICE '[PASS] Test 3: Customer service request created with audit trail';

    -- Test 3b: Reject a pincode outside the selected service area.
    v_failed := false;
    BEGIN
        PERFORM public.create_service_request(
            p_category_id := v_cat_plumbing,
            p_service_area_id := v_pilot_area,
            p_description := 'Kitchen sink tap is leaking continuously',
            p_address_line := 'Test address, Bengaluru',
            p_pincode := '560034'
        );
    EXCEPTION WHEN SQLSTATE 'P0009' THEN
        v_failed := true;
    END;
    ASSERT v_failed, 'Test 3b Failed: Request accepted outside the selected service-area pincode';

    -- Test 3c: Coordinates must be supplied as a complete latitude/longitude pair.
    v_failed := false;
    BEGIN
        PERFORM public.create_service_request(
            p_category_id := v_cat_plumbing,
            p_service_area_id := v_pilot_area,
            p_description := 'Kitchen sink tap is leaking continuously',
            p_address_line := 'Test address, Bengaluru',
            p_pincode := '560102',
            p_latitude := 12.91
        );
    EXCEPTION WHEN SQLSTATE 'P0010' THEN
        v_failed := true;
    END;
    ASSERT v_failed, 'Test 3c Failed: Request accepted with only one coordinate';

    -- Test 3d: Past appointments must be rejected by the database, not only the UI.
    v_failed := false;
    BEGIN
        PERFORM public.create_service_request(
            p_category_id := v_cat_plumbing,
            p_service_area_id := v_pilot_area,
            p_description := 'Kitchen sink tap is leaking continuously',
            p_address_line := 'Test address, Bengaluru',
            p_pincode := '560102',
            p_scheduled_at := now() - interval '1 minute'
        );
    EXCEPTION WHEN SQLSTATE 'P0011' THEN
        v_failed := true;
    END;
    ASSERT v_failed, 'Test 3d Failed: Request accepted with a past appointment time';

    -- Test 3e: A customer cannot attach another account's storage object to a request.
    v_failed := false;
    BEGIN
        PERFORM public.create_service_request(
            p_category_id := v_cat_plumbing,
            p_service_area_id := v_pilot_area,
            p_description := 'Kitchen sink tap is leaking continuously',
            p_address_line := 'Test address, Bengaluru',
            p_pincode := '560102',
            p_photo_storage_path := v_customer_b_id::text || '/private-photo.jpg'
        );
    EXCEPTION WHEN SQLSTATE 'P0013' THEN
        v_failed := true;
    END;
    ASSERT v_failed, 'Test 3e Failed: Request accepted a photo outside the current customer folder';
    RAISE NOTICE '[PASS] Test 3b-3e: Service-area, coordinate, schedule, and photo ownership validation';

    -- ------------------------------------------------------------------------
    -- Test 4: Provider Onboarding & Unapproved Assignment Prevention
    -- ------------------------------------------------------------------------
    PERFORM set_config('request.jwt.claim.sub', v_provider_user_id::text, true);
    INSERT INTO public.providers (profile_id, service_area_id, experience_years, verification_status, availability_status)
    VALUES (v_provider_user_id, v_pilot_area, 6, 'pending', 'available')
    RETURNING id INTO v_provider_id;

    -- Add category skill
    INSERT INTO public.provider_services (provider_id, category_id, base_price_minor)
    VALUES (v_provider_id, v_cat_plumbing, 25000); -- Rs 250.00

    -- As Admin, attempt to assign pending provider (MUST FAIL with exception P0005)
    PERFORM set_config('request.jwt.claim.sub', v_admin_id::text, true);
    v_failed := false;
    BEGIN
        PERFORM public.assign_provider_to_request(v_request_id, v_provider_id, 30000);
    EXCEPTION WHEN SQLSTATE 'P0005' THEN
        v_failed := true;
    END;
    ASSERT v_failed = true, 'Test 4 Failed: Assigning unapproved provider did not abort with P0005';
    RAISE NOTICE '[PASS] Test 4: Unapproved provider correctly blocked from assignments';

    -- ------------------------------------------------------------------------
    -- Test 5: Admin Approves Provider and Assigns to Request
    -- ------------------------------------------------------------------------
    PERFORM public.admin_verify_provider(v_provider_id, 'approved', 'Documents verified by operations team');
    ASSERT (SELECT verification_status FROM public.providers WHERE id = v_provider_id) = 'approved', 'Test 5 Failed: Verification status not updated';

    v_assignment_id := public.assign_provider_to_request(v_request_id, v_provider_id, 35000);
    ASSERT v_assignment_id IS NOT NULL, 'Test 5 Failed: Assignment ID not returned';
    ASSERT (SELECT status FROM public.service_requests WHERE id = v_request_id) = 'assigned', 'Test 5 Failed: Request status not assigned';
    ASSERT (SELECT status FROM public.assignments WHERE id = v_assignment_id) = 'offered', 'Test 5 Failed: Assignment status not offered';
    RAISE NOTICE '[PASS] Test 5: Provider approved and assigned successfully';

    -- Test 5b: A provider cannot receive a second active offer for another request.
    PERFORM set_config('request.jwt.claim.sub', v_customer_a_id::text, true);
    v_second_request_id := public.create_service_request(
        p_category_id := v_cat_plumbing,
        p_service_area_id := v_pilot_area,
        p_description := 'Bathroom tap is dripping and needs inspection',
        p_address_line := '#142, 5th Cross, 19th Main, HSR Layout Sector 1',
        p_pincode := '560102'
    );
    PERFORM set_config('request.jwt.claim.sub', v_admin_id::text, true);
    v_failed := false;
    BEGIN
        PERFORM public.assign_provider_to_request(v_second_request_id, v_provider_id, 32000);
    EXCEPTION WHEN unique_violation THEN
        v_failed := true;
    END;
    ASSERT v_failed = true, 'Test 5b Failed: Provider received multiple active offers';
    RAISE NOTICE '[PASS] Test 5b: One active assignment per provider enforced';

    -- ------------------------------------------------------------------------
    -- Test 6: Invariant Test — Duplicate Active Assignment Prevented
    -- ------------------------------------------------------------------------
    -- Setup second provider
    INSERT INTO public.providers (profile_id, service_area_id, experience_years, verification_status, availability_status)
    VALUES (v_unrelated_provider_id, v_pilot_area, 4, 'approved', 'available')
    RETURNING id INTO v_unrelated_prov_pk;
    INSERT INTO public.provider_services (provider_id, category_id, base_price_minor)
    VALUES (v_unrelated_prov_pk, v_cat_plumbing, 25000);

    v_failed := false;
    BEGIN
        -- Attempt to directly insert a second offered assignment for same request
        INSERT INTO public.assignments (request_id, provider_id, status)
        VALUES (v_request_id, v_unrelated_prov_pk, 'offered');
    EXCEPTION WHEN unique_violation THEN
        v_failed := true;
    END;
    ASSERT v_failed = true, 'Test 6 Failed: Invariant failed! Dual active assignments allowed';
    RAISE NOTICE '[PASS] Test 6: Partial unique index strictly prevents concurrent active assignments';

    -- ------------------------------------------------------------------------
    -- Test 7: Provider Responds & Accepts Assignment
    -- ------------------------------------------------------------------------
    PERFORM set_config('request.jwt.claim.sub', v_provider_user_id::text, true);
    PERFORM public.respond_to_assignment(v_assignment_id, true);

    ASSERT (SELECT status FROM public.assignments WHERE id = v_assignment_id) = 'accepted', 'Test 7 Failed: Assignment not accepted';
    ASSERT (SELECT status FROM public.service_requests WHERE id = v_request_id) = 'accepted', 'Test 7 Failed: Request not accepted';
    ASSERT (SELECT availability_status FROM public.providers WHERE id = v_provider_id) = 'busy', 'Test 7 Failed: Provider not busy';

    PERFORM set_config('request.jwt.claim.sub', v_admin_id::text, true);
    v_failed := false;
    BEGIN
        PERFORM public.assign_provider_to_request(v_second_request_id, v_provider_id, 32000);
    EXCEPTION WHEN SQLSTATE 'P0006' THEN
        v_failed := true;
    END;
    ASSERT v_failed = true, 'Test 7 Failed: Busy provider was assigned another request';
    RAISE NOTICE '[PASS] Test 7: Provider accept transition and busy dispatch guard verified';

    PERFORM set_config('request.jwt.claim.sub', v_provider_user_id::text, true);

    -- ------------------------------------------------------------------------
    -- Test 8: Job Progression Lifecycle to Completion
    -- ------------------------------------------------------------------------
    PERFORM public.progress_service_request(v_request_id, 'travelling');
    ASSERT (SELECT status FROM public.service_requests WHERE id = v_request_id) = 'travelling', 'Test 8 Failed: Travelling state';

    PERFORM public.progress_service_request(v_request_id, 'in_progress');
    ASSERT (SELECT status FROM public.service_requests WHERE id = v_request_id) = 'in_progress', 'Test 8 Failed: In-progress state';

    PERFORM public.progress_service_request(v_request_id, 'completed', 35000);
    ASSERT (SELECT status FROM public.service_requests WHERE id = v_request_id) = 'completed', 'Test 8 Failed: Completed state';
    ASSERT (SELECT availability_status FROM public.providers WHERE id = v_provider_id) = 'available', 'Test 8 Failed: Provider not returned to available';
    ASSERT (SELECT status FROM public.assignments WHERE id = v_assignment_id) = 'completed', 'Test 8 Failed: Assignment not completed';
    RAISE NOTICE '[PASS] Test 8: Sequential job progression to completion verified';

    -- ------------------------------------------------------------------------
    -- Test 9: Customer Feedback & One Review Invariant
    -- ------------------------------------------------------------------------
    PERFORM set_config('request.jwt.claim.sub', v_customer_a_id::text, true);
    INSERT INTO public.reviews (customer_id, request_id, provider_id, rating, comment)
    VALUES (v_customer_a_id, v_request_id, v_provider_id, 5, 'Prompt arrival, fixed the leak within 20 minutes!');

    v_failed := false;
    BEGIN
        INSERT INTO public.reviews (customer_id, request_id, provider_id, rating, comment)
        VALUES (v_customer_a_id, v_request_id, v_provider_id, 4, 'Second duplicate review');
    EXCEPTION WHEN unique_violation THEN
        v_failed := true;
    END;
    ASSERT v_failed = true, 'Test 9 Failed: Multiple reviews permitted for single request';
    RAISE NOTICE '[PASS] Test 9: Customer feedback submitted and duplicate review blocked';
END;
$$;

-- ----------------------------------------------------------------------------
-- Test 10: RLS Isolation — Authenticated Non-Superuser Role Verification
-- ----------------------------------------------------------------------------
-- Switch session to authenticated role
SET ROLE authenticated;

-- Customer A can see their own request
SET request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
DO $$
BEGIN
    ASSERT (SELECT count(*) FROM public.service_requests WHERE customer_id = '22222222-2222-2222-2222-222222222222') >= 1,
        'Test 10 Failed: Customer A cannot see their own request';
END;
$$;

-- Customer B tries to view Customer A's request (Must return 0 rows)
SET request.jwt.claim.sub = '33333333-3333-3333-3333-333333333333';
DO $customer_b$
BEGIN
    ASSERT (SELECT count(*) FROM public.service_requests) = 0,
        'Test 10 Failed: Customer B can see Customer A request under RLS';
    ASSERT (SELECT count(*) FROM public.get_customer_request_ids('22222222-2222-2222-2222-222222222222')) = 0,
        'Test 10 Failed: Customer B can retrieve Customer A request IDs through helper RPC';
    ASSERT (SELECT count(*) FROM public.get_assigned_provider_ids_for_customer('22222222-2222-2222-2222-222222222222')) = 0,
        'Test 10 Failed: Customer B can retrieve Customer A provider IDs through helper RPC';
    ASSERT (SELECT count(*) FROM public.get_assigned_request_ids_for_provider('33333333-3333-3333-3333-333333333333')) = 0,
        'Test 10 Failed: Customer B can retrieve another provider assignment IDs';
END;
$customer_b$;

-- Unassigned Provider tries to view Customer A's request (Must return 0 rows)
SET request.jwt.claim.sub = '55555555-5555-5555-5555-555555555555';
DO $$
BEGIN
    ASSERT (SELECT count(*) FROM public.service_requests) = 0,
        'Test 10 Failed: Unassigned Provider can see Customer A request under RLS';
END;
$$;

RESET ROLE;

DO $$
BEGIN
    RAISE NOTICE '[PASS] Test 10: Row-Level Security isolation strictly enforced for authenticated users';
    RAISE NOTICE '[PASS] Test 10: RLS isolation verified; remaining security assertions execute below.';
END;
$$;

-- Test 11: First-admin bootstrap is not executable by untrusted API roles.
DO $audit$
DECLARE
    v_i INTEGER;
    v_reserved BOOLEAN;
BEGIN
    ASSERT NOT has_function_privilege('anon', 'public.bootstrap_admin(uuid)', 'EXECUTE'),
        'Test 11 Failed: anon can execute bootstrap_admin';
    ASSERT NOT has_function_privilege('authenticated', 'public.bootstrap_admin(uuid)', 'EXECUTE'),
        'Test 11 Failed: authenticated can execute bootstrap_admin';
    RAISE NOTICE '[PASS] Test 11: bootstrap_admin execution restricted to trusted database operators';
    ASSERT has_column_privilege('authenticated', 'public.providers', 'availability_status', 'UPDATE'),
        'Test 12 Failed: provider availability update privilege missing';
    ASSERT NOT has_column_privilege('authenticated', 'public.providers', 'verification_status', 'UPDATE'),
        'Test 12 Failed: providers can directly update verification status';
    ASSERT NOT has_table_privilege('authenticated', 'public.service_requests', 'UPDATE'),
        'Test 12 Failed: authenticated users can directly update service requests';
    ASSERT NOT has_table_privilege('authenticated', 'public.assignments', 'UPDATE'),
        'Test 12 Failed: authenticated users can directly update assignments';
    ASSERT NOT has_table_privilege('authenticated', 'public.order_events', 'INSERT'),
        'Test 12 Failed: authenticated users can forge order events';
    RAISE NOTICE '[PASS] Test 12: direct write privileges restricted to intended operations';
    ASSERT NOT has_table_privilege('authenticated', 'public.ai_diagnosis_usage', 'SELECT'),
        'Test 13 Failed: authenticated users can read AI usage audit records';
    ASSERT NOT has_table_privilege('authenticated', 'public.ai_diagnosis_usage', 'INSERT'),
        'Test 13 Failed: authenticated users can forge AI usage records';
    RAISE NOTICE '[PASS] Test 13: AI usage audit records are private to trusted server operations';
    ASSERT NOT has_function_privilege('anon', 'public.has_role(uuid,text)', 'EXECUTE'),
        'Test 14 Failed: anon can inspect role helper';
    ASSERT has_function_privilege('authenticated', 'public.get_provider_id_for_user(uuid)', 'EXECUTE'),
        'Test 14 Failed: provider RLS lookup helper is not executable';
    ASSERT has_function_privilege('authenticated', 'public.has_role(uuid,text)', 'EXECUTE'),
        'Test 14 Failed: scoped role helper is not executable';
    ASSERT NOT has_function_privilege('anon', 'public.get_provider_id_for_user(uuid)', 'EXECUTE'),
        'Test 14 Failed: anon can invoke provider lookup helper';
    ASSERT has_function_privilege('authenticated', 'public.get_customer_request_ids(uuid)', 'EXECUTE'),
        'Test 14 Failed: RLS customer request helper unavailable';
    ASSERT has_function_privilege('authenticated', 'public.create_service_request(uuid,uuid,text,text,text,double precision,double precision,timestamp with time zone,text,text)', 'EXECUTE'),
        'Test 14 Failed: authenticated customer cannot create requests';
    ASSERT NOT has_function_privilege('anon', 'public.create_service_request(uuid,uuid,text,text,text,double precision,double precision,timestamp with time zone,text,text)', 'EXECUTE'),
        'Test 14 Failed: anon can create service requests';
    RAISE NOTICE '[PASS] Test 14: SECURITY DEFINER helpers and RPC grants are restricted';
    ASSERT has_function_privilege('service_role', 'public.reserve_ai_diagnosis_slot(uuid,text,integer)', 'EXECUTE'),
        'Test 15 Failed: service_role cannot reserve AI quota';
    ASSERT NOT has_function_privilege('authenticated', 'public.reserve_ai_diagnosis_slot(uuid,text,integer)', 'EXECUTE'),
        'Test 15 Failed: authenticated clients can reserve AI quota directly';
    ASSERT NOT has_function_privilege('anon', 'public.reserve_ai_diagnosis_slot(uuid,text,integer)', 'EXECUTE'),
        'Test 15 Failed: anon can reserve AI quota';
    FOR v_i IN 1..5 LOOP
        SELECT public.reserve_ai_diagnosis_slot(
            '22222222-2222-2222-2222-222222222222',
            'gemini-3.8-flash',
            5
        ) INTO v_reserved;
        ASSERT v_reserved, 'Test 15 Failed: valid AI quota slot was rejected';
    END LOOP;
    SELECT public.reserve_ai_diagnosis_slot(
        '22222222-2222-2222-2222-222222222222',
        'gemini-3.8-flash',
        5
    ) INTO v_reserved;
    ASSERT NOT v_reserved, 'Test 15 Failed: AI quota allowed a sixth reservation';
    ASSERT (SELECT count(*) FROM public.ai_diagnosis_usage
            WHERE user_id = '22222222-2222-2222-2222-222222222222') = 5,
        'Test 15 Failed: AI usage log count does not match successful reservations';
    ASSERT (SELECT count(*) FROM public.ai_diagnosis_usage
            WHERE user_id = '22222222-2222-2222-2222-222222222222'
              AND consent_version = '2026-11-11-v1') = 5,
        'Test 15 Failed: AI usage records do not retain the accepted consent version';
    RAISE NOTICE '[PASS] Test 15: AI quota reservation is atomic and server-role-only';
END;
$audit$;

-- Test 16: Provider price changes are proposals, never self-approved.
SET ROLE authenticated;
SET request.jwt.claim.sub = '44444444-4444-4444-4444-444444444444';
UPDATE public.provider_services
   SET pricing_model = 'agreed_fixed', base_price_minor = 32500
 WHERE provider_id = (SELECT id FROM public.providers WHERE profile_id = '44444444-4444-4444-4444-444444444444');
DO $$
DECLARE v_provider_id UUID;
BEGIN
    SELECT id INTO v_provider_id FROM public.providers WHERE profile_id = '44444444-4444-4444-4444-444444444444';
    ASSERT (SELECT price_approval_status FROM public.provider_services WHERE provider_id = v_provider_id) = 'pending',
      'Test 16 Failed: Provider fixed-price proposal was not forced to pending';
    UPDATE public.provider_services SET price_approval_status = 'approved' WHERE provider_id = v_provider_id;
    ASSERT (SELECT price_approval_status FROM public.provider_services WHERE provider_id = v_provider_id) = 'pending',
      'Test 16 Failed: Provider was able to self-approve a fixed price';
    ASSERT (SELECT count(*) FROM public.provider_service_price_events WHERE provider_id = v_provider_id) >= 1,
      'Test 16 Failed: Provider price change was not audited';
END;
$$;
DO $$ BEGIN RAISE NOTICE '[PASS] Test 16: Provider pricing proposals require operator approval and are audited'; END; $$;

-- Test 17: Customers cannot see unapproved fixed prices.
SET request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
DO $$
BEGIN
    ASSERT (SELECT count(*) FROM public.provider_services WHERE pricing_model = 'agreed_fixed') = 0,
      'Test 17 Failed: Customer can see an unapproved fixed price';
END;
$$;

-- Test 18: Only an AAL2 admin can activate commission after recording provider agreement.
RESET ROLE;
SET request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
SET request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated","aal":"aal2"}';
UPDATE public.provider_services
   SET price_approval_status = 'approved'
 WHERE provider_id = (SELECT id FROM public.providers WHERE profile_id = '44444444-4444-4444-4444-444444444444');
DO $$
DECLARE v_provider_id UUID; v_category_id UUID;
BEGIN
    SELECT p.id, ps.category_id INTO v_provider_id, v_category_id
      FROM public.providers p
      JOIN public.provider_services ps ON ps.provider_id = p.id
     WHERE p.profile_id = '44444444-4444-4444-4444-444444444444';
    ASSERT has_function_privilege('authenticated', 'public.admin_record_provider_commission_terms(uuid,uuid,integer,boolean,text)', 'EXECUTE'),
      'Test 18 Failed: Admin commission terms RPC is not granted to authenticated role';
    ASSERT NOT has_function_privilege('anon', 'public.admin_record_provider_commission_terms(uuid,uuid,integer,boolean,text)', 'EXECUTE'),
      'Test 18 Failed: Anonymous role can record commission terms';
    PERFORM public.admin_record_provider_commission_terms(
      v_provider_id, v_category_id, 650, true,
      'Provider agreed in person; signed partner terms dated 14 Nov 2026.'
    );
END;
$$;
DO $$
DECLARE v_provider_id UUID;
BEGIN
    SELECT id INTO v_provider_id FROM public.providers WHERE profile_id = '44444444-4444-4444-4444-444444444444';
    ASSERT (SELECT price_approval_status FROM public.provider_services WHERE provider_id = v_provider_id) = 'approved',
      'Test 18 Failed: Admin could not approve a fixed price';
    ASSERT (SELECT count(*) FROM public.provider_commission_terms WHERE provider_id = v_provider_id AND status = 'active') = 1,
      'Test 18 Failed: Active commission agreement was not saved';
END;
$$;
DO $$ BEGIN RAISE NOTICE '[PASS] Test 18: Admin approval and explicit provider agreement are required for active commission'; END; $$;

-- Test 19: Customer can see the approved catalogue price, never the provider's commission.
SET ROLE authenticated;
SET request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
DO $$
BEGIN
    ASSERT (SELECT count(*) FROM public.provider_services WHERE pricing_model = 'agreed_fixed' AND price_approval_status = 'approved') = 1,
      'Test 19 Failed: Customer cannot see an approved fixed price';
    ASSERT (SELECT count(*) FROM public.provider_commission_terms) = 0,
      'Test 19 Failed: Customer can read private provider commission terms';
END;
$$;

-- Test 20: Provider can read only its own active commission terms; no rate exists for another provider.
SET request.jwt.claim.sub = '44444444-4444-4444-4444-444444444444';
DO $$
DECLARE v_provider_id UUID; v_other_provider_id UUID;
BEGIN
    SELECT id INTO v_provider_id FROM public.providers WHERE profile_id = '44444444-4444-4444-4444-444444444444';
    SELECT id INTO v_other_provider_id FROM public.providers WHERE profile_id = '55555555-5555-5555-5555-555555555555';
    ASSERT (SELECT count(*) FROM public.provider_commission_terms WHERE provider_id = v_provider_id) = 1,
      'Test 20 Failed: Provider cannot read its own negotiated commission';
    ASSERT (SELECT count(*) FROM public.provider_commission_terms WHERE provider_id = v_other_provider_id) = 0,
      'Test 20 Failed: Provider can read another provider commission';
END;
$$;
DO $$ BEGIN RAISE NOTICE '[PASS] Test 20: Commission terms are private to the provider and admin'; END; $$;

RESET ROLE;
ROLLBACK;
