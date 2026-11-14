-- Move privileged transaction implementations out of PostgREST's exposed
-- public schema. Public RPC names remain as SECURITY INVOKER wrappers.
ALTER FUNCTION public.admin_override_request_status(UUID, TEXT, TEXT) SET SCHEMA private;
ALTER FUNCTION public.admin_record_provider_commission_terms(UUID, UUID, INTEGER, BOOLEAN, TEXT) SET SCHEMA private;
ALTER FUNCTION public.admin_verify_provider(UUID, TEXT, TEXT) SET SCHEMA private;
ALTER FUNCTION public.assign_provider_to_request(UUID, UUID, BIGINT) SET SCHEMA private;
ALTER FUNCTION public.cancel_service_request(UUID, TEXT) SET SCHEMA private;
ALTER FUNCTION public.create_service_request(UUID, UUID, TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, TIMESTAMPTZ, TEXT, TEXT) SET SCHEMA private;
ALTER FUNCTION public.progress_service_request(UUID, TEXT, BIGINT) SET SCHEMA private;
ALTER FUNCTION public.respond_to_assignment(UUID, BOOLEAN, TEXT) SET SCHEMA private;

REVOKE ALL ON FUNCTION private.admin_override_request_status(UUID, TEXT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.admin_record_provider_commission_terms(UUID, UUID, INTEGER, BOOLEAN, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.admin_verify_provider(UUID, TEXT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.assign_provider_to_request(UUID, UUID, BIGINT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.cancel_service_request(UUID, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.create_service_request(UUID, UUID, TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, TIMESTAMPTZ, TEXT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.progress_service_request(UUID, TEXT, BIGINT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.respond_to_assignment(UUID, BOOLEAN, TEXT) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION private.admin_override_request_status(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION private.admin_record_provider_commission_terms(UUID, UUID, INTEGER, BOOLEAN, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION private.admin_verify_provider(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION private.assign_provider_to_request(UUID, UUID, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION private.cancel_service_request(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION private.create_service_request(UUID, UUID, TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, TIMESTAMPTZ, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION private.progress_service_request(UUID, TEXT, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION private.respond_to_assignment(UUID, BOOLEAN, TEXT) TO authenticated;

CREATE FUNCTION public.admin_override_request_status(
  p_request_id UUID, p_new_status TEXT, p_reason TEXT
) RETURNS BOOLEAN
LANGUAGE sql VOLATILE SECURITY INVOKER SET search_path = ''
AS $$ SELECT private.admin_override_request_status(p_request_id, p_new_status, p_reason); $$;

CREATE FUNCTION public.admin_record_provider_commission_terms(
  p_provider_id UUID, p_category_id UUID, p_commission_rate_bps INTEGER,
  p_provider_agreed BOOLEAN, p_terms_note TEXT
) RETURNS UUID
LANGUAGE sql VOLATILE SECURITY INVOKER SET search_path = ''
AS $$ SELECT private.admin_record_provider_commission_terms(
  p_provider_id, p_category_id, p_commission_rate_bps, p_provider_agreed, p_terms_note
); $$;

CREATE FUNCTION public.admin_verify_provider(
  p_provider_id UUID, p_status TEXT, p_notes TEXT DEFAULT NULL
) RETURNS BOOLEAN
LANGUAGE sql VOLATILE SECURITY INVOKER SET search_path = ''
AS $$ SELECT private.admin_verify_provider(p_provider_id, p_status, p_notes); $$;

CREATE FUNCTION public.assign_provider_to_request(
  p_request_id UUID, p_provider_id UUID, p_quoted_price_minor BIGINT DEFAULT NULL
) RETURNS UUID
LANGUAGE sql VOLATILE SECURITY INVOKER SET search_path = ''
AS $$ SELECT private.assign_provider_to_request(p_request_id, p_provider_id, p_quoted_price_minor); $$;

CREATE FUNCTION public.cancel_service_request(
  p_request_id UUID, p_reason TEXT
) RETURNS BOOLEAN
LANGUAGE sql VOLATILE SECURITY INVOKER SET search_path = ''
AS $$ SELECT private.cancel_service_request(p_request_id, p_reason); $$;

CREATE FUNCTION public.create_service_request(
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
) RETURNS UUID
LANGUAGE sql VOLATILE SECURITY INVOKER SET search_path = ''
AS $$ SELECT private.create_service_request(
  p_category_id, p_service_area_id, p_description, p_address_line, p_pincode,
  p_latitude, p_longitude, p_scheduled_at, p_customer_notes, p_photo_storage_path
); $$;

CREATE FUNCTION public.progress_service_request(
  p_request_id UUID, p_new_status TEXT, p_final_price_minor BIGINT DEFAULT NULL
) RETURNS BOOLEAN
LANGUAGE sql VOLATILE SECURITY INVOKER SET search_path = ''
AS $$ SELECT private.progress_service_request(p_request_id, p_new_status, p_final_price_minor); $$;

CREATE FUNCTION public.respond_to_assignment(
  p_assignment_id UUID, p_accept BOOLEAN, p_decline_reason TEXT DEFAULT NULL
) RETURNS BOOLEAN
LANGUAGE sql VOLATILE SECURITY INVOKER SET search_path = ''
AS $$ SELECT private.respond_to_assignment(p_assignment_id, p_accept, p_decline_reason); $$;

REVOKE ALL ON FUNCTION public.admin_override_request_status(UUID, TEXT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_record_provider_commission_terms(UUID, UUID, INTEGER, BOOLEAN, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_verify_provider(UUID, TEXT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.assign_provider_to_request(UUID, UUID, BIGINT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.cancel_service_request(UUID, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.create_service_request(UUID, UUID, TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, TIMESTAMPTZ, TEXT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.progress_service_request(UUID, TEXT, BIGINT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.respond_to_assignment(UUID, BOOLEAN, TEXT) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.admin_override_request_status(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_record_provider_commission_terms(UUID, UUID, INTEGER, BOOLEAN, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_verify_provider(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assign_provider_to_request(UUID, UUID, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_service_request(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_service_request(UUID, UUID, TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, TIMESTAMPTZ, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.progress_service_request(UUID, TEXT, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.respond_to_assignment(UUID, BOOLEAN, TEXT) TO authenticated;

COMMENT ON FUNCTION public.create_service_request(UUID, UUID, TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, TIMESTAMPTZ, TEXT, TEXT) IS
  'SECURITY INVOKER API wrapper. Transactional implementation is isolated in the private schema.';
COMMENT ON FUNCTION public.assign_provider_to_request(UUID, UUID, BIGINT) IS
  'SECURITY INVOKER API wrapper. Transactional implementation is isolated in the private schema.';
