-- Validate booking inputs at the database boundary.
-- The client is untrusted: service-area membership, scheduling, coordinates and
-- uploaded-photo ownership must be checked by the authoritative RPC.

DO $constraint$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_constraint
    WHERE conname = 'service_requests_coordinate_pair_check'
      AND conrelid = 'public.service_requests'::pg_catalog.regclass
  ) THEN
    ALTER TABLE public.service_requests
      ADD CONSTRAINT service_requests_coordinate_pair_check
      CHECK ((latitude IS NULL) = (longitude IS NULL)) NOT VALID;
  END IF;
END;
$constraint$;

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
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
    v_customer_id UUID := auth.uid();
    v_request_id UUID;
    v_is_cat_active BOOLEAN;
    v_is_area_active BOOLEAN;
    v_area_pincode TEXT;
    v_description TEXT := pg_catalog.btrim(p_description);
    v_address_line TEXT := pg_catalog.btrim(p_address_line);
    v_pincode TEXT := pg_catalog.btrim(p_pincode);
    v_photo_path TEXT := NULLIF(pg_catalog.btrim(p_photo_storage_path), '');
BEGIN
    IF v_customer_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required.' USING ERRCODE = '42501';
    END IF;

    IF v_description IS NULL OR pg_catalog.length(v_description) NOT BETWEEN 10 AND 2000 THEN
        RAISE EXCEPTION 'Description must contain 10 to 2000 characters.' USING ERRCODE = 'P0003';
    END IF;
    IF v_address_line IS NULL OR pg_catalog.length(v_address_line) NOT BETWEEN 5 AND 500 THEN
        RAISE EXCEPTION 'Address must contain 5 to 500 characters.' USING ERRCODE = 'P0004';
    END IF;
    IF v_pincode IS NULL OR v_pincode !~ '^[0-9]{6}$' THEN
        RAISE EXCEPTION 'Enter a valid six-digit service pincode.' USING ERRCODE = 'P0009';
    END IF;
    IF (p_latitude IS NULL) IS DISTINCT FROM (p_longitude IS NULL) THEN
        RAISE EXCEPTION 'Latitude and longitude must be provided together.' USING ERRCODE = 'P0010';
    END IF;
    IF p_latitude IS NOT NULL AND (p_latitude < -90 OR p_latitude > 90 OR p_longitude < -180 OR p_longitude > 180) THEN
        RAISE EXCEPTION 'Coordinates are outside valid geographic bounds.' USING ERRCODE = 'P0010';
    END IF;
    IF p_scheduled_at IS NOT NULL AND p_scheduled_at < pg_catalog.now() THEN
        RAISE EXCEPTION 'A service cannot be scheduled in the past.' USING ERRCODE = 'P0011';
    END IF;
    IF p_customer_notes IS NOT NULL AND pg_catalog.length(p_customer_notes) > 1000 THEN
        RAISE EXCEPTION 'Customer notes cannot exceed 1000 characters.' USING ERRCODE = 'P0012';
    END IF;

    SELECT is_active
      INTO v_is_cat_active
      FROM public.service_categories
     WHERE id = p_category_id;
    IF v_is_cat_active IS NOT TRUE THEN
        RAISE EXCEPTION 'Selected service category is not available.' USING ERRCODE = 'P0001';
    END IF;

    SELECT is_active, pincode
      INTO v_is_area_active, v_area_pincode
      FROM public.service_areas
     WHERE id = p_service_area_id;
    IF v_is_area_active IS NOT TRUE THEN
        RAISE EXCEPTION 'Service is not available in the specified area.' USING ERRCODE = 'P0002';
    END IF;
    IF v_area_pincode IS NOT NULL AND v_pincode IS DISTINCT FROM v_area_pincode THEN
        RAISE EXCEPTION 'The entered pincode is outside the selected service area.' USING ERRCODE = 'P0009';
    END IF;

    IF p_photo_storage_path IS NOT NULL THEN
        IF v_photo_path IS NULL
           OR pg_catalog.length(v_photo_path) > 1024
           OR pg_catalog.left(v_photo_path, pg_catalog.length(v_customer_id::TEXT) + 1) <> v_customer_id::TEXT || '/'
           OR NOT EXISTS (
                SELECT 1
                  FROM storage.objects
                 WHERE bucket_id = 'service-request-photos'
                   AND name = v_photo_path
           ) THEN
            RAISE EXCEPTION 'The selected photo is not an uploaded photo owned by this account.' USING ERRCODE = 'P0013';
        END IF;
    END IF;

    INSERT INTO public.service_requests (
        customer_id, category_id, service_area_id, description, address_line,
        pincode, latitude, longitude, scheduled_at, customer_notes,
        photo_storage_path, status
    ) VALUES (
        v_customer_id, p_category_id, p_service_area_id, v_description, v_address_line,
        v_pincode, p_latitude, p_longitude, p_scheduled_at, p_customer_notes,
        v_photo_path, 'requested'
    ) RETURNING id INTO v_request_id;

    INSERT INTO public.order_events (
        request_id, actor_user_id, event_type, old_status, new_status, metadata
    ) VALUES (
        v_request_id, v_customer_id, 'request_created', NULL, 'requested',
        pg_catalog.jsonb_build_object('pincode', v_pincode, 'scheduled_at', p_scheduled_at)
    );

    RETURN v_request_id;
END;
$function$;

REVOKE ALL ON FUNCTION public.create_service_request(
    UUID, UUID, TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, TIMESTAMPTZ, TEXT, TEXT
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_service_request(
    UUID, UUID, TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, TIMESTAMPTZ, TEXT, TEXT
) TO authenticated;

COMMENT ON FUNCTION public.create_service_request(
    UUID, UUID, TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, TIMESTAMPTZ, TEXT, TEXT
) IS 'Creates a service request only after validating service-area pincode, schedule, coordinates, and customer-owned uploaded photo.';
