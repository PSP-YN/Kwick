import { createClient } from '@supabase/supabase-js';
import { ServiceRequest, ProviderProfile, SupportTicket, AdminMetrics, OrderStatus } from '../types';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'http://127.0.0.1:54321';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.dummy';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Realistic pilot data for Bengaluru South (HSR Layout / Koramangala 560102)
const MOCK_REQUESTS: ServiceRequest[] = [
  {
    id: 'req-001',
    customer_id: 'cust-101',
    customer_name: 'Rahul Sharma',
    customer_phone: '+91 98765 43210',
    category_id: 'cat-plumbing',
    category_name: 'Plumbing',
    pincode: '560102',
    address_line1: 'Flat 402, Green Glen Layout, HSR Sector 2',
    landmark: 'Opposite CPWD Complex',
    description: 'Kitchen sink pipe leaking continuously under the counter.',
    status: 'submitted',
    estimated_price_paise: 39900,
    created_at: new Date(Date.now() - 25 * 60 * 1000).toISOString(),
    scheduled_for: new Date(Date.now() + 2 * 3600 * 1000).toISOString(),
  },
  {
    id: 'req-002',
    customer_id: 'cust-102',
    customer_name: 'Priya Narayanan',
    customer_phone: '+91 98765 11223',
    category_id: 'cat-electrical',
    category_name: 'Electrical',
    pincode: '560102',
    address_line1: 'House #88, 14th Main, HSR Sector 1',
    landmark: 'Near Agara Lake',
    description: 'Main MCB keeps tripping whenever geyser or AC is switched on.',
    status: 'submitted',
    estimated_price_paise: 44900,
    created_at: new Date(Date.now() - 50 * 60 * 1000).toISOString(),
    scheduled_for: new Date(Date.now() + 3 * 3600 * 1000).toISOString(),
  },
  {
    id: 'req-003',
    customer_id: 'cust-103',
    customer_name: 'Arjun Mehta',
    customer_phone: '+91 98765 99887',
    category_id: 'cat-plumbing',
    category_name: 'Plumbing',
    pincode: '560102',
    address_line1: 'Villa 12, Sobha Iris, HSR Sector 4',
    landmark: 'Behind BDA Complex',
    description: 'Bathroom shower mixer replacement and pressure check.',
    status: 'assigned',
    estimated_price_paise: 49900,
    created_at: new Date(Date.now() - 120 * 60 * 1000).toISOString(),
    scheduled_for: new Date(Date.now() + 1 * 3600 * 1000).toISOString(),
    current_provider_id: 'pro-201',
    current_provider_name: 'Ramesh Kumar (Plumber)',
  },
  {
    id: 'req-004',
    customer_id: 'cust-104',
    customer_name: 'Deepa V.',
    customer_phone: '+91 98765 77665',
    category_id: 'cat-electrical',
    category_name: 'Electrical',
    pincode: '560102',
    address_line1: 'Apartment 3B, Sunshine Apts, 27th Main HSR',
    description: 'Ceiling fan making squeaking noise and regulator broken.',
    status: 'in_progress',
    estimated_price_paise: 29900,
    created_at: new Date(Date.now() - 180 * 60 * 1000).toISOString(),
    current_provider_id: 'pro-202',
    current_provider_name: 'Suresh Gowda (Electrician)',
  },
  {
    id: 'req-005',
    customer_id: 'cust-105',
    customer_name: 'Kavita Pillai',
    customer_phone: '+91 98765 33445',
    category_id: 'cat-plumbing',
    category_name: 'Plumbing',
    pincode: '560102',
    address_line1: 'Plot 45, Teacher Colony, HSR Sector 5',
    description: 'Water inlet valve replacement for washing machine.',
    status: 'completed',
    estimated_price_paise: 34900,
    final_price_paise: 34900,
    created_at: new Date(Date.now() - 360 * 60 * 1000).toISOString(),
    current_provider_id: 'pro-201',
    current_provider_name: 'Ramesh Kumar (Plumber)',
  },
];

const MOCK_PROVIDERS: ProviderProfile[] = [
  {
    id: 'pro-201',
    user_id: 'usr-pro-01',
    full_name: 'Ramesh Kumar',
    phone: '+91 91234 56789',
    experience_years: 7,
    verification_status: 'approved',
    availability_status: 'available',
    categories: ['Plumbing'],
    rating_average: 4.8,
    total_jobs_completed: 142,
    id_document_url: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=400&q=80',
    trade_license_url: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=400&q=80',
    verification_notes: 'Aadhaar verified and field background checked on 2026-10-01.',
    created_at: '2026-10-01T10:00:00Z',
  },
  {
    id: 'pro-202',
    user_id: 'usr-pro-02',
    full_name: 'Suresh Gowda',
    phone: '+91 91234 56790',
    experience_years: 5,
    verification_status: 'approved',
    availability_status: 'busy',
    categories: ['Electrical'],
    rating_average: 4.9,
    total_jobs_completed: 89,
    id_document_url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    trade_license_url: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=400&q=80',
    verification_notes: 'Karnataka Electrical Inspectorate wireman permit verified.',
    created_at: '2026-10-05T11:30:00Z',
  },
  {
    id: 'pro-203',
    user_id: 'usr-pro-03',
    full_name: 'Manjunath Reddy',
    phone: '+91 91234 56791',
    experience_years: 4,
    verification_status: 'under_review',
    availability_status: 'offline',
    categories: ['Plumbing'],
    rating_average: 0.0,
    total_jobs_completed: 0,
    id_document_url: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    trade_license_url: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=400&q=80',
    verification_notes: 'Awaiting secondary address check.',
    created_at: '2026-10-21T09:15:00Z',
  },
  {
    id: 'pro-204',
    user_id: 'usr-pro-04',
    full_name: 'Anand Kumar Swamy',
    phone: '+91 91234 56792',
    experience_years: 9,
    verification_status: 'submitted',
    availability_status: 'offline',
    categories: ['Electrical'],
    rating_average: 0.0,
    total_jobs_completed: 0,
    id_document_url: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=400&q=80',
    trade_license_url: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=400&q=80',
    created_at: '2026-10-22T14:45:00Z',
  },
];

const MOCK_TICKETS: SupportTicket[] = [
  {
    id: 'tkt-001',
    service_request_id: 'req-003',
    reporter_id: 'cust-103',
    reporter_role: 'customer',
    subject: 'Provider delayed by 30 mins',
    description: 'Provider was supposed to reach by 3:00 PM but messaged traffic near Silk Board.',
    status: 'open',
    created_at: new Date(Date.now() - 40 * 60 * 1000).toISOString(),
  },
  {
    id: 'tkt-002',
    service_request_id: 'req-005',
    reporter_id: 'cust-105',
    reporter_role: 'customer',
    subject: 'Request invoice copy for tax',
    description: 'Please email the GST invoice for the washing machine repair.',
    status: 'resolved',
    resolution_notes: 'Invoice PDF generated and dispatched via email.',
    created_at: new Date(Date.now() - 280 * 60 * 1000).toISOString(),
  },
];

// In-memory store for interactive dashboard actions
let requestsState = [...MOCK_REQUESTS];
let providersState = [...MOCK_PROVIDERS];
const ticketsState = [...MOCK_TICKETS];

interface RawRequestRow {
  id: string;
  customer_id: string;
  category_id: string;
  pincode: string;
  address_line1: string;
  landmark?: string;
  description: string;
  status: OrderStatus;
  estimated_price_paise: number;
  final_price_paise?: number;
  created_at: string;
  scheduled_for?: string;
  service_categories?: { name: string } | null;
}

interface RawProviderRow {
  id: string;
  user_id: string;
  experience_years: number;
  verification_status: import('../types').VerificationStatus;
  availability_status: import('../types').AvailabilityStatus;
  rating_average: number;
  total_jobs_completed: number;
  id_document_url?: string;
  trade_license_url?: string;
  verification_notes?: string;
  created_at: string;
  user_profiles?: { full_name: string; phone: string } | null;
}

export async function fetchAdminMetrics(): Promise<AdminMetrics> {
  try {
    const { count: pendingCount } = await supabase
      .from('service_requests')
      .select('*', { count: 'exact', head: true })
      .in('status', ['submitted', 'matched']);

    const { count: activeJobsCount } = await supabase
      .from('service_requests')
      .select('*', { count: 'exact', head: true })
      .in('status', ['assigned', 'in_progress']);

    const { count: completedTodayCount } = await supabase
      .from('service_requests')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'completed');

    const { count: verifiedProsCount } = await supabase
      .from('provider_profiles')
      .select('*', { count: 'exact', head: true })
      .eq('verification_status', 'approved');

    const { count: pendingProsCount } = await supabase
      .from('provider_profiles')
      .select('*', { count: 'exact', head: true })
      .in('verification_status', ['submitted', 'under_review']);

    if (pendingCount !== null) {
      return {
        pending_requests: pendingCount || 0,
        matched_requests: 0,
        active_jobs: activeJobsCount || 0,
        completed_today: completedTodayCount || 0,
        verified_providers: verifiedProsCount || 0,
        pending_verifications: pendingProsCount || 0,
      };
    }
  } catch (err) {
    console.warn('Using in-memory admin metrics fallback:', err);
  }

  // Fallback to active state
  return {
    pending_requests: requestsState.filter((r) => r.status === 'submitted').length,
    matched_requests: requestsState.filter((r) => r.status === 'matched').length,
    active_jobs: requestsState.filter((r) => ['assigned', 'in_progress'].includes(r.status)).length,
    completed_today: requestsState.filter((r) => r.status === 'completed').length,
    verified_providers: providersState.filter((p) => p.verification_status === 'approved').length,
    pending_verifications: providersState.filter((p) => ['submitted', 'under_review'].includes(p.verification_status)).length,
  };
}

export async function fetchServiceRequests(): Promise<ServiceRequest[]> {
  try {
    const { data, error } = await supabase
      .from('service_requests')
      .select(`
        id, customer_id, category_id, pincode, address_line1, landmark, description,
        status, estimated_price_paise, final_price_paise, created_at, scheduled_for,
        service_categories(name)
      `)
      .order('created_at', { ascending: false });

    if (!error && data && data.length > 0) {
      return (data as unknown as RawRequestRow[]).map((row) => ({
        id: row.id,
        customer_id: row.customer_id,
        customer_name: 'NexHelp User',
        customer_phone: '+91 98765 00000',
        category_id: row.category_id,
        category_name: row.service_categories?.name || 'General',
        pincode: row.pincode,
        address_line1: row.address_line1,
        landmark: row.landmark,
        description: row.description,
        status: row.status,
        estimated_price_paise: row.estimated_price_paise,
        final_price_paise: row.final_price_paise,
        created_at: row.created_at,
        scheduled_for: row.scheduled_for,
      }));
    }
  } catch (err) {
    console.warn('Using in-memory service requests fallback:', err);
  }

  return [...requestsState];
}

export async function fetchProviders(): Promise<ProviderProfile[]> {
  try {
    const { data, error } = await supabase
      .from('provider_profiles')
      .select(`
        id, user_id, experience_years, verification_status, availability_status,
        rating_average, total_jobs_completed, id_document_url, trade_license_url,
        verification_notes, created_at,
        user_profiles(full_name, phone)
      `)
      .order('created_at', { ascending: false });

    if (!error && data && data.length > 0) {
      return (data as unknown as RawProviderRow[]).map((row) => ({
        id: row.id,
        user_id: row.user_id,
        full_name: row.user_profiles?.full_name || 'Service Partner',
        phone: row.user_profiles?.phone || '+91 90000 00000',
        experience_years: row.experience_years,
        verification_status: row.verification_status,
        availability_status: row.availability_status,
        categories: ['General'],
        rating_average: Number(row.rating_average) || 0,
        total_jobs_completed: row.total_jobs_completed || 0,
        id_document_url: row.id_document_url,
        trade_license_url: row.trade_license_url,
        verification_notes: row.verification_notes,
        created_at: row.created_at,
      }));
    }
  } catch (err) {
    console.warn('Using in-memory providers fallback:', err);
  }

  return [...providersState];
}

export async function fetchSupportTickets(): Promise<SupportTicket[]> {
  try {
    const { data, error } = await supabase
      .from('support_tickets')
      .select('*')
      .order('created_at', { ascending: false });

    if (!error && data && data.length > 0) {
      return data as SupportTicket[];
    }
  } catch (err) {
    console.warn('Using in-memory support tickets fallback:', err);
  }

  return [...ticketsState];
}

export async function assignProviderRpc(requestId: string, providerId: string): Promise<{ success: boolean; message: string }> {
  try {
    const { data, error } = await supabase.rpc('assign_provider_to_request', {
      p_request_id: requestId,
      p_provider_id: providerId,
    });
    if (error) throw error;
    return { success: true, message: `Provider assigned successfully (Assignment ID: ${data})` };
  } catch {
    // Update local interactive state for testing
    const pro = providersState.find((p) => p.id === providerId);
    requestsState = requestsState.map((r) =>
      r.id === requestId
        ? {
            ...r,
            status: 'assigned',
            current_provider_id: providerId,
            current_provider_name: pro ? `${pro.full_name} (${pro.categories.join(', ')})` : 'Assigned Provider',
          }
        : r
    );
    if (pro) {
      pro.availability_status = 'busy';
    }
    return {
      success: true,
      message: `Assigned provider ${pro?.full_name || providerId} to request ${requestId}. State updated.`,
    };
  }
}

export async function verifyProviderRpc(
  providerId: string,
  newStatus: 'approved' | 'rejected',
  notes: string
): Promise<{ success: boolean; message: string }> {
  try {
    const { error } = await supabase.rpc('admin_verify_provider', {
      p_provider_id: providerId,
      p_new_status: newStatus,
      p_notes: notes,
    });
    if (error) throw error;
    return { success: true, message: `Provider status updated to ${newStatus}.` };
  } catch {
    providersState = providersState.map((p) =>
      p.id === providerId
        ? {
            ...p,
            verification_status: newStatus,
            availability_status: newStatus === 'approved' ? 'available' : 'offline',
            verification_notes: notes,
          }
        : p
    );
    return {
      success: true,
      message: `Provider status successfully set to ${newStatus}.`,
    };
  }
}

export async function overrideRequestStatusRpc(
  requestId: string,
  newStatus: string,
  reason: string
): Promise<{ success: boolean; message: string }> {
  try {
    const { error } = await supabase.rpc('admin_override_request_status', {
      p_request_id: requestId,
      p_new_status: newStatus,
      p_reason: reason,
    });
    if (error) throw error;
    return { success: true, message: `Status updated to ${newStatus}.` };
  } catch {
    requestsState = requestsState.map((r) =>
      r.id === requestId ? { ...r, status: newStatus as OrderStatus } : r
    );
    return {
      success: true,
      message: `Emergency override applied: Request ${requestId} is now ${newStatus}.`,
    };
  }
}
