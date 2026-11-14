-- Enforce RLS even for the table owner; the audit trigger writes through its trusted SECURITY DEFINER function.
ALTER TABLE public.provider_service_price_events FORCE ROW LEVEL SECURITY;
