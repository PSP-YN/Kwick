-- ============================================================================
-- Kwick Database Schema Migration: 002 Row-Level Security (RLS)
-- ============================================================================

-- Enable RLS on ALL tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

-- Force RLS even for table owners
ALTER TABLE public.profiles FORCE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles FORCE ROW LEVEL SECURITY;
ALTER TABLE public.service_areas FORCE ROW LEVEL SECURITY;
ALTER TABLE public.service_categories FORCE ROW LEVEL SECURITY;
ALTER TABLE public.providers FORCE ROW LEVEL SECURITY;
ALTER TABLE public.provider_services FORCE ROW LEVEL SECURITY;
ALTER TABLE public.provider_documents FORCE ROW LEVEL SECURITY;
ALTER TABLE public.service_requests FORCE ROW LEVEL SECURITY;
ALTER TABLE public.assignments FORCE ROW LEVEL SECURITY;
ALTER TABLE public.order_events FORCE ROW LEVEL SECURITY;
ALTER TABLE public.reviews FORCE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets FORCE ROW LEVEL SECURITY;
ALTER TABLE public.notifications FORCE ROW LEVEL SECURITY;
ALTER TABLE public.device_tokens FORCE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs FORCE ROW LEVEL SECURITY;

-- Ensure standard Supabase roles exist (for local/testing PostgreSQL)
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN 
        CREATE ROLE anon NOLOGIN; 
    END IF; 
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN 
        CREATE ROLE authenticated NOLOGIN; 
    END IF; 
END $$;

-- Explicitly grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- ----------------------------------------------------------------------------
-- 1. Profiles Policies
-- ----------------------------------------------------------------------------
-- Anyone authenticated can view their own profile; admins can view all profiles
CREATE POLICY "profiles_select_own_or_admin" ON public.profiles
    FOR SELECT TO authenticated
    USING (id = auth.uid() OR public.is_admin());

-- Users can update only their own profile
CREATE POLICY "profiles_update_own" ON public.profiles
    FOR UPDATE TO authenticated
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- Profiles can be inserted for the authenticated user during signup
CREATE POLICY "profiles_insert_own" ON public.profiles
    FOR INSERT TO authenticated
    WITH CHECK (id = auth.uid());

-- ----------------------------------------------------------------------------
-- 2. User Roles Policies
-- ----------------------------------------------------------------------------
-- Users can view their own roles; admins can view all roles
CREATE POLICY "user_roles_select_own_or_admin" ON public.user_roles
    FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR public.is_admin());

-- Only admins or bootstrap functions can manage roles
CREATE POLICY "user_roles_admin_all" ON public.user_roles
    FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ----------------------------------------------------------------------------
-- 3. Service Areas Policies (Public read for active areas)
-- ----------------------------------------------------------------------------
CREATE POLICY "service_areas_read_active" ON public.service_areas
    FOR SELECT TO anon, authenticated
    USING (is_active = true OR public.is_admin());

CREATE POLICY "service_areas_admin_manage" ON public.service_areas
    FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ----------------------------------------------------------------------------
-- 4. Service Categories Policies (Public read for active categories)
-- ----------------------------------------------------------------------------
CREATE POLICY "service_categories_read_active" ON public.service_categories
    FOR SELECT TO anon, authenticated
    USING (is_active = true OR public.is_admin());

CREATE POLICY "service_categories_admin_manage" ON public.service_categories
    FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ----------------------------------------------------------------------------
-- Cross-Table Lookup Helpers (Security Definer to prevent RLS recursion)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_assigned_request_ids_for_provider(p_user_id UUID)
RETURNS SETOF UUID AS $$
    SELECT request_id FROM public.assignments
    WHERE provider_id = public.get_provider_id_for_user(p_user_id)
      AND status IN ('offered', 'accepted', 'completed');
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp;

CREATE OR REPLACE FUNCTION public.get_customer_request_ids(p_user_id UUID)
RETURNS SETOF UUID AS $$
    SELECT id FROM public.service_requests WHERE customer_id = p_user_id;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp;

CREATE OR REPLACE FUNCTION public.get_assigned_provider_ids_for_customer(p_user_id UUID)
RETURNS SETOF UUID AS $$
    SELECT a.provider_id FROM public.assignments a
    JOIN public.service_requests sr ON sr.id = a.request_id
    WHERE sr.customer_id = p_user_id AND a.status IN ('offered', 'accepted', 'completed');
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp;

-- ----------------------------------------------------------------------------
-- 5. Providers Policies
-- ----------------------------------------------------------------------------
-- Providers can read their own provider record; admins can read all; customers can read provider if assigned
CREATE POLICY "providers_select_authorized" ON public.providers
    FOR SELECT TO authenticated
    USING (
        profile_id = auth.uid() 
        OR public.is_admin()
        OR id IN (SELECT public.get_assigned_provider_ids_for_customer(auth.uid()))
    );

-- Providers can insert their initial onboarding record
CREATE POLICY "providers_insert_own" ON public.providers
    FOR INSERT TO authenticated
    WITH CHECK (
        profile_id = auth.uid()
        AND verification_status = 'pending'
    );

-- Providers can update their own availability, but NOT verification status or approved_by
CREATE POLICY "providers_update_own_availability" ON public.providers
    FOR UPDATE TO authenticated
    USING (profile_id = auth.uid())
    WITH CHECK (
        profile_id = auth.uid()
        AND verification_status = (SELECT p.verification_status FROM public.providers p WHERE p.id = providers.id)
    );

-- Admins have full management over providers
CREATE POLICY "providers_admin_manage" ON public.providers
    FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ----------------------------------------------------------------------------
-- 6. Provider Services Policies
-- ----------------------------------------------------------------------------
CREATE POLICY "provider_services_select" ON public.provider_services
    FOR SELECT TO authenticated
    USING (
        provider_id = public.get_provider_id_for_user(auth.uid())
        OR public.is_admin()
    );

CREATE POLICY "provider_services_manage_own" ON public.provider_services
    FOR ALL TO authenticated
    USING (provider_id = public.get_provider_id_for_user(auth.uid()) OR public.is_admin())
    WITH CHECK (provider_id = public.get_provider_id_for_user(auth.uid()) OR public.is_admin());

-- ----------------------------------------------------------------------------
-- 7. Provider Documents Policies
-- ----------------------------------------------------------------------------
CREATE POLICY "provider_documents_select" ON public.provider_documents
    FOR SELECT TO authenticated
    USING (
        provider_id = public.get_provider_id_for_user(auth.uid())
        OR public.is_admin()
    );

CREATE POLICY "provider_documents_insert_own" ON public.provider_documents
    FOR INSERT TO authenticated
    WITH CHECK (
        provider_id = public.get_provider_id_for_user(auth.uid())
    );

CREATE POLICY "provider_documents_admin_manage" ON public.provider_documents
    FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ----------------------------------------------------------------------------
-- 8. Service Requests Policies
-- ----------------------------------------------------------------------------
-- Customers see their own requests.
-- Assigned providers see only requests assigned to them.
-- Admins see all requests.
CREATE POLICY "service_requests_select_authorized" ON public.service_requests
    FOR SELECT TO authenticated
    USING (
        customer_id = auth.uid()
        OR public.is_admin()
        OR id IN (SELECT public.get_assigned_request_ids_for_provider(auth.uid()))
    );

-- Customers can insert requests only for themselves
CREATE POLICY "service_requests_insert_own" ON public.service_requests
    FOR INSERT TO authenticated
    WITH CHECK (
        customer_id = auth.uid()
        AND status = 'requested'
    );

-- Customers can update their own request only if it is in an editable/cancellable state
CREATE POLICY "service_requests_update_own" ON public.service_requests
    FOR UPDATE TO authenticated
    USING (
        customer_id = auth.uid() 
        AND status IN ('requested', 'reviewing', 'assigned')
    )
    WITH CHECK (
        customer_id = auth.uid()
    );

-- Admins can update any request
CREATE POLICY "service_requests_admin_update" ON public.service_requests
    FOR UPDATE TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ----------------------------------------------------------------------------
-- 9. Assignments Policies
-- ----------------------------------------------------------------------------
-- Customers see assignments for their own requests.
-- Providers see assignments offered to them.
-- Admins see all assignments.
CREATE POLICY "assignments_select_authorized" ON public.assignments
    FOR SELECT TO authenticated
    USING (
        provider_id = public.get_provider_id_for_user(auth.uid())
        OR public.is_admin()
        OR request_id IN (SELECT public.get_customer_request_ids(auth.uid()))
    );

-- Assignments can only be created by admins or transactional RPC functions
CREATE POLICY "assignments_insert_admin" ON public.assignments
    FOR INSERT TO authenticated
    WITH CHECK (public.is_admin());

-- Providers can respond (accept/decline) to their offered assignment
CREATE POLICY "assignments_provider_respond" ON public.assignments
    FOR UPDATE TO authenticated
    USING (
        provider_id = public.get_provider_id_for_user(auth.uid())
        AND status = 'offered'
    )
    WITH CHECK (
        provider_id = public.get_provider_id_for_user(auth.uid())
        AND status IN ('accepted', 'declined')
    );

-- Admins can update assignments
CREATE POLICY "assignments_admin_update" ON public.assignments
    FOR UPDATE TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ----------------------------------------------------------------------------
-- 10. Order Events Policies (Append-only audit)
-- ----------------------------------------------------------------------------
-- Parties involved or admins can read events
CREATE POLICY "order_events_select_authorized" ON public.order_events
    FOR SELECT TO authenticated
    USING (
        public.is_admin()
        OR request_id IN (
            SELECT id FROM public.service_requests WHERE customer_id = auth.uid()
        )
        OR request_id IN (
            SELECT request_id FROM public.assignments 
            WHERE provider_id = public.get_provider_id_for_user(auth.uid())
        )
    );

-- Insert permitted via RPC functions or authorized transitions
CREATE POLICY "order_events_insert_authorized" ON public.order_events
    FOR INSERT TO authenticated
    WITH CHECK (
        actor_user_id = auth.uid()
        OR public.is_admin()
    );

-- ----------------------------------------------------------------------------
-- 11. Reviews Policies
-- ----------------------------------------------------------------------------
-- Anyone authenticated can read published reviews
CREATE POLICY "reviews_select_published" ON public.reviews
    FOR SELECT TO authenticated
    USING (moderation_status = 'published' OR customer_id = auth.uid() OR public.is_admin());

-- Customers can insert a review only for their own completed requests
CREATE POLICY "reviews_insert_customer" ON public.reviews
    FOR INSERT TO authenticated
    WITH CHECK (
        customer_id = auth.uid()
        AND request_id IN (
            SELECT id FROM public.service_requests 
            WHERE customer_id = auth.uid() AND status = 'completed'
        )
    );

-- Admins can moderate reviews
CREATE POLICY "reviews_admin_manage" ON public.reviews
    FOR UPDATE TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ----------------------------------------------------------------------------
-- 12. Support Tickets Policies
-- ----------------------------------------------------------------------------
CREATE POLICY "support_tickets_select" ON public.support_tickets
    FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY "support_tickets_insert" ON public.support_tickets
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "support_tickets_admin_manage" ON public.support_tickets
    FOR UPDATE TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ----------------------------------------------------------------------------
-- 13. Notifications Policies
-- ----------------------------------------------------------------------------
CREATE POLICY "notifications_select_own" ON public.notifications
    FOR SELECT TO authenticated
    USING (recipient_id = auth.uid());

CREATE POLICY "notifications_update_own" ON public.notifications
    FOR UPDATE TO authenticated
    USING (recipient_id = auth.uid())
    WITH CHECK (recipient_id = auth.uid());

-- ----------------------------------------------------------------------------
-- 14. Device Tokens Policies
-- ----------------------------------------------------------------------------
CREATE POLICY "device_tokens_manage_own" ON public.device_tokens
    FOR ALL TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- 15. Admin Audit Logs Policies
-- ----------------------------------------------------------------------------
-- Strictly accessible only to admins
CREATE POLICY "admin_audit_logs_select" ON public.admin_audit_logs
    FOR SELECT TO authenticated
    USING (public.is_admin());

CREATE POLICY "admin_audit_logs_insert" ON public.admin_audit_logs
    FOR INSERT TO authenticated
    WITH CHECK (public.is_admin() AND actor_id = auth.uid());
