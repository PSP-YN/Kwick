import { createClient } from '@supabase/supabase-js';
import { ServiceRequest, ProviderProfile, SupportTicket, AdminMetrics, OrderStatus } from '../types';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
export const isSupabaseConfigured = Boolean(supabaseUrl && supabaseAnonKey);
export const supabase = createClient(supabaseUrl || 'http://127.0.0.1:54321', supabaseAnonKey || 'missing-local-development-key');

function assertSupabaseConfigured(): void {
  if (!isSupabaseConfigured) throw new Error('Kwick Operations is not connected. Configure NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY.');
}
function throwIfError(error: { message: string } | null): void {
  if (error) throw new Error(error.message);
}
function toPaise(value: number | string | null | undefined): number | null {
  if (value === null || value === undefined) return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

export async function fetchAdminMetrics(): Promise<AdminMetrics> {
  assertSupabaseConfigured();
  const startOfDay = new Date(); startOfDay.setHours(0, 0, 0, 0);
  const results = await Promise.all([
    supabase.from('service_requests').select('id', { count: 'exact', head: true }).in('status', ['requested', 'reviewing']),
    supabase.from('service_requests').select('id', { count: 'exact', head: true }).in('status', ['assigned', 'accepted', 'travelling', 'in_progress']),
    supabase.from('service_requests').select('id', { count: 'exact', head: true }).eq('status', 'completed').gte('updated_at', startOfDay.toISOString()),
    supabase.from('providers').select('id', { count: 'exact', head: true }).eq('verification_status', 'approved'),
    supabase.from('providers').select('id', { count: 'exact', head: true }).eq('verification_status', 'pending'),
  ]);
  results.forEach((result) => throwIfError(result.error));
  return {
    pending_requests: results[0].count || 0,
    active_jobs: results[1].count || 0, completed_today: results[2].count || 0,
    verified_providers: results[3].count || 0, pending_verifications: results[4].count || 0,
  };
}

export async function fetchServiceRequests(): Promise<ServiceRequest[]> {
  assertSupabaseConfigured();
  const { data, error } = await supabase.from('service_requests').select(`
    id, customer_id, category_id, pincode, address_line, description, customer_notes, status,
    quoted_price_minor, final_price_minor, created_at, scheduled_at, service_categories(name)
  `).order('created_at', { ascending: false });
  throwIfError(error);
  if (!data?.length) return [];
  const customerIds = [...new Set(data.map((row) => row.customer_id))];
  const requestIds = data.map((row) => row.id);
  const [profilesResult, assignmentsResult] = await Promise.all([
    supabase.from('profiles').select('id, full_name, phone').in('id', customerIds),
    supabase.from('assignments').select('request_id, provider_id, status, providers(id, profile_id, profiles(full_name))')
      .in('request_id', requestIds).in('status', ['offered', 'accepted', 'completed']),
  ]);
  throwIfError(profilesResult.error); throwIfError(assignmentsResult.error);
  const profiles = new Map((profilesResult.data || []).map((profile) => [profile.id, profile]));
  const assignments = new Map<string, { providerId: string; name?: string }>();
  for (const row of assignmentsResult.data || []) {
    const provider = Array.isArray(row.providers) ? row.providers[0] : row.providers;
    const nestedProfile = provider && (Array.isArray(provider.profiles) ? provider.profiles[0] : provider.profiles);
    assignments.set(row.request_id, { providerId: row.provider_id, name: nestedProfile?.full_name || undefined });
  }
  return data.map((row) => {
    const profile = profiles.get(row.customer_id);
    const category = Array.isArray(row.service_categories) ? row.service_categories[0] : row.service_categories;
    const assignment = assignments.get(row.id);
    return {
      id: row.id, customer_id: row.customer_id, customer_name: profile?.full_name || 'Customer',
      customer_phone: profile?.phone || undefined, category_id: row.category_id,
      category_name: category?.name || 'General', pincode: row.pincode, address_line1: row.address_line,
      description: row.description, customer_notes: row.customer_notes, status: row.status as OrderStatus,
      estimated_price_paise: toPaise(row.quoted_price_minor), final_price_paise: toPaise(row.final_price_minor),
      created_at: row.created_at, scheduled_for: row.scheduled_at || undefined,
      current_provider_id: assignment?.providerId, current_provider_name: assignment?.name,
    };
  });
}

export async function fetchProviders(): Promise<ProviderProfile[]> {
  assertSupabaseConfigured();
  const { data, error } = await supabase.from('providers').select(`
    id, profile_id, experience_years, verification_status, availability_status, verification_notes, created_at,
    profiles(full_name, phone), provider_services(is_active, service_categories(name)),
    provider_documents(document_type, storage_path, verification_status)
  `).order('created_at', { ascending: false });
  throwIfError(error); if (!data?.length) return [];
  const ids = data.map((provider) => provider.id);
  const [reviewsResult, completedResult] = await Promise.all([
    supabase.from('reviews').select('provider_id, rating').in('provider_id', ids).eq('moderation_status', 'published'),
    supabase.from('assignments').select('provider_id').in('provider_id', ids).eq('status', 'completed'),
  ]);
  throwIfError(reviewsResult.error); throwIfError(completedResult.error);
  const ratings = new Map<string, number[]>(); const completed = new Map<string, number>();
  for (const review of reviewsResult.data || []) ratings.set(review.provider_id, [...(ratings.get(review.provider_id) || []), Number(review.rating)]);
  for (const assignment of completedResult.data || []) completed.set(assignment.provider_id, (completed.get(assignment.provider_id) || 0) + 1);
  return Promise.all(data.map(async (provider) => {
    const profile = Array.isArray(provider.profiles) ? provider.profiles[0] : provider.profiles;
    const categories = (provider.provider_services || []).filter((service) => service.is_active).map((service) => {
      const category = Array.isArray(service.service_categories) ? service.service_categories[0] : service.service_categories;
      return category?.name;
    }).filter((name): name is string => Boolean(name));
    const docs = provider.provider_documents || [];
    const signedUrl = async (path?: string) => {
      if (!path) return undefined;
      const result = await supabase.storage.from('provider-documents').createSignedUrl(path, 300);
      throwIfError(result.error);
      if (!result.data?.signedUrl) throw new Error('Could not create a temporary provider-document link.');
      return result.data.signedUrl;
    };
    const idDoc = docs.find((doc) => doc.document_type === 'id_proof');
    const tradeDoc = docs.find((doc) => doc.document_type === 'trade_certification');
    const providerRatings = ratings.get(provider.id) || [];
    return {
      id: provider.id, user_id: provider.profile_id, full_name: profile?.full_name || 'Service Partner',
      phone: profile?.phone || '', experience_years: provider.experience_years,
      verification_status: provider.verification_status as ProviderProfile['verification_status'],
      availability_status: provider.availability_status as ProviderProfile['availability_status'],
      categories: categories.length ? categories : ['Unspecified'],
      rating_average: providerRatings.length ? providerRatings.reduce((sum, rating) => sum + rating, 0) / providerRatings.length : 0,
      total_jobs_completed: completed.get(provider.id) || 0,
      id_document_url: await signedUrl(idDoc?.storage_path), trade_license_url: await signedUrl(tradeDoc?.storage_path),
      verification_notes: provider.verification_notes || undefined, created_at: provider.created_at,
    };
  }));
}

export async function fetchSupportTickets(): Promise<SupportTicket[]> {
  assertSupabaseConfigured();
  const { data, error } = await supabase.from('support_tickets')
    .select('id, request_id, user_id, issue_category, description, status, resolution_notes, created_at')
    .order('created_at', { ascending: false });
  throwIfError(error); if (!data?.length) return [];
  const ids = [...new Set(data.map((ticket) => ticket.user_id))];
  const rolesResult = await supabase.from('user_roles').select('user_id, role').in('user_id', ids);
  throwIfError(rolesResult.error);
  const roles = new Map((rolesResult.data || []).map((role) => [role.user_id, role.role]));
  return data.map((ticket) => ({
    id: ticket.id, service_request_id: ticket.request_id, reporter_id: ticket.user_id,
    reporter_role: roles.get(ticket.user_id) === 'provider' ? 'provider' : 'customer',
    subject: ticket.issue_category.replaceAll('_', ' '), description: ticket.description,
    status: ticket.status, resolution_notes: ticket.resolution_notes || undefined, created_at: ticket.created_at,
  }));
}

export async function assignProviderRpc(requestId: string, providerId: string): Promise<{ success: boolean; message: string }> {
  assertSupabaseConfigured();
  const { data, error } = await supabase.rpc('assign_provider_to_request', { p_request_id: requestId, p_provider_id: providerId });
  if (error) return { success: false, message: error.message };
  return { success: true, message: `Provider assigned successfully (Assignment ID: ${data}).` };
}
export async function verifyProviderRpc(providerId: string, newStatus: 'approved' | 'rejected', notes: string): Promise<{ success: boolean; message: string }> {
  assertSupabaseConfigured();
  const { error } = await supabase.rpc('admin_verify_provider', { p_provider_id: providerId, p_new_status: newStatus, p_notes: notes });
  if (error) return { success: false, message: error.message };
  return { success: true, message: `Provider status updated to ${newStatus}.` };
}
export async function overrideRequestStatusRpc(requestId: string, newStatus: OrderStatus, reason: string): Promise<{ success: boolean; message: string }> {
  assertSupabaseConfigured();
  if (reason.trim().length < 5) return { success: false, message: 'A documented audit reason of at least 5 characters is required.' };
  const { error } = await supabase.rpc('admin_override_request_status', { p_request_id: requestId, p_new_status: newStatus, p_reason: reason.trim() });
  if (error) return { success: false, message: error.message };
  return { success: true, message: `Request status updated to ${newStatus}.` };
}
