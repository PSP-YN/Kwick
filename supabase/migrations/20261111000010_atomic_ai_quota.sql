-- Atomically reserve one AI diagnosis slot per user and rolling hour.
-- The server-side Edge Function is the only client allowed to execute this RPC.

CREATE OR REPLACE FUNCTION public.reserve_ai_diagnosis_slot(
  p_user_id UUID,
  p_model TEXT,
  p_limit INTEGER DEFAULT 5
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_count BIGINT;
BEGIN
  IF p_user_id IS NULL
     OR p_model IS NULL
     OR pg_catalog.length(pg_catalog.btrim(p_model)) = 0
     OR p_limit IS NULL
     OR p_limit < 1
     OR p_limit > 100 THEN
    RAISE EXCEPTION 'Invalid AI quota reservation parameters.'
      USING ERRCODE = '22023';
  END IF;

  -- Serialize reservations for the same user within this transaction.
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_user_id::TEXT, 0)
  );

  SELECT pg_catalog.count(*)
    INTO v_count
  FROM public.ai_diagnosis_usage
  WHERE user_id = p_user_id
    AND created_at >= pg_catalog.now() - INTERVAL '1 hour';

  IF v_count >= p_limit THEN
    RETURN FALSE;
  END IF;

  INSERT INTO public.ai_diagnosis_usage (user_id, model)
  VALUES (p_user_id, pg_catalog.left(pg_catalog.btrim(p_model), 100));

  RETURN TRUE;
END;
$function$;

REVOKE ALL ON FUNCTION public.reserve_ai_diagnosis_slot(UUID, TEXT, INTEGER)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reserve_ai_diagnosis_slot(UUID, TEXT, INTEGER)
  TO service_role;

COMMENT ON FUNCTION public.reserve_ai_diagnosis_slot(UUID, TEXT, INTEGER) IS
  'Atomically reserves a per-user AI diagnosis slot. Service-role Edge Function only.';
