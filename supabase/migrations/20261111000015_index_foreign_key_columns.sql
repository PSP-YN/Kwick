-- Add indexes for foreign-key columns that participate in ownership,
-- audit, and dispatch lookups. Keep each index idempotent for safe repair.
create index if not exists idx_assignments_assigned_by
  on public.assignments (assigned_by);

create index if not exists idx_order_events_actor_user_id
  on public.order_events (actor_user_id);

create index if not exists idx_provider_documents_reviewed_by
  on public.provider_documents (reviewed_by);

create index if not exists idx_providers_approved_by
  on public.providers (approved_by);

create index if not exists idx_reviews_customer_id
  on public.reviews (customer_id);

create index if not exists idx_service_requests_cancelled_by
  on public.service_requests (cancelled_by);

create index if not exists idx_support_tickets_assigned_operator_id
  on public.support_tickets (assigned_operator_id);

create index if not exists idx_support_tickets_request_id
  on public.support_tickets (request_id);

create index if not exists idx_user_roles_granted_by
  on public.user_roles (granted_by);
