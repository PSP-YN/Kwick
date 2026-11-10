-- Minimal audit trail for AI diagnosis usage. Raw issue descriptions are never stored here.
CREATE TABLE IF NOT EXISTS public.ai_diagnosis_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  model TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_diagnosis_usage_user_created
  ON public.ai_diagnosis_usage(user_id, created_at DESC);

ALTER TABLE public.ai_diagnosis_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_diagnosis_usage FORCE ROW LEVEL SECURITY;

REVOKE ALL ON public.ai_diagnosis_usage FROM PUBLIC;
REVOKE ALL ON public.ai_diagnosis_usage FROM anon;
REVOKE ALL ON public.ai_diagnosis_usage FROM authenticated;

DO $grant$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
    GRANT SELECT, INSERT ON public.ai_diagnosis_usage TO service_role;
  END IF;
END;
$grant$;
