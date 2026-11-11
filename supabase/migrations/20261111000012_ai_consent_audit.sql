-- Record the exact, affirmative AI-processing disclosure version accepted by the user.
-- The Edge Function refuses AI requests without this version and a positive consent flag.
ALTER TABLE public.ai_diagnosis_usage
  ADD COLUMN IF NOT EXISTS consent_version TEXT NOT NULL DEFAULT '2026-11-11-v1';

COMMENT ON COLUMN public.ai_diagnosis_usage.consent_version IS
  'Version of the optional AI triage consent notice accepted for this assessment.';
