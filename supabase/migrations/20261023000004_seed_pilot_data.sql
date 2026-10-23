-- ============================================================================
-- NexHelp Database Schema Migration: 004 Seed Pilot Data & Storage
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Pilot Service Area Seed
-- ----------------------------------------------------------------------------
INSERT INTO public.service_areas (id, name, city, state, pincode, is_active)
VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'Bengaluru South — HSR & Koramangala Pilot Sector',
    'Bengaluru',
    'Karnataka',
    '560102',
    true
)
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 2. Pilot Service Categories Seed (Plumbing and Electrical)
-- ----------------------------------------------------------------------------
INSERT INTO public.service_categories (id, name, slug, description, icon_key, is_active, sort_order)
VALUES 
(
    'c0000000-0000-0000-0000-000000000001',
    'Plumbing',
    'plumbing',
    'Tap and faucet repairs, water leakage assistance, drainage and blockage removal, and bathroom plumbing repairs.',
    'plumbing',
    true,
    1
),
(
    'c0000000-0000-0000-0000-000000000002',
    'Electrical Work',
    'electrical',
    'Switches, sockets, wiring repairs, light and fan installation/repair, and basic electrical fault diagnosis.',
    'electrical_services',
    true,
    2
)
ON CONFLICT (slug) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    icon_key = EXCLUDED.icon_key,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order;

-- ----------------------------------------------------------------------------
-- 3. Supabase Private Storage Buckets Setup
-- ----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
(
    'provider-documents',
    'provider-documents',
    false,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'application/pdf']
),
(
    'service-request-photos',
    'service-request-photos',
    false,
    5242880,  -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS Policies
-- Provider Documents: Providers can upload and read their own folder; Admins read all
CREATE POLICY "provider_documents_bucket_select" ON storage.objects
    FOR SELECT TO authenticated
    USING (
        bucket_id = 'provider-documents'
        AND (
            (storage.foldername(name))[1] = auth.uid()::text
            OR public.is_admin()
        )
    );

CREATE POLICY "provider_documents_bucket_insert" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'provider-documents'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Service Request Photos: Customers can upload into their folder; assigned providers & admins read
CREATE POLICY "service_request_photos_bucket_select" ON storage.objects
    FOR SELECT TO authenticated
    USING (
        bucket_id = 'service-request-photos'
        AND (
            (storage.foldername(name))[1] = auth.uid()::text
            OR public.is_admin()
            OR EXISTS (
                SELECT 1 FROM public.assignments a
                JOIN public.service_requests sr ON sr.id = a.request_id
                WHERE a.provider_id = public.get_provider_id_for_user(auth.uid())
                AND sr.photo_storage_path LIKE '%' || name || '%'
            )
        )
    );

CREATE POLICY "service_request_photos_bucket_insert" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'service-request-photos'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );
