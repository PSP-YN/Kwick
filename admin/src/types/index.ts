export type OrderStatus = 'requested' | 'reviewing' | 'assigned' | 'accepted' | 'travelling' | 'in_progress' | 'completed' | 'cancelled' | 'disputed';
export type VerificationStatus = 'pending' | 'approved' | 'rejected' | 'suspended';
export type AvailabilityStatus = 'available' | 'busy' | 'unavailable';

export interface ServiceRequest {
  id: string; customer_id: string; customer_name?: string; customer_phone?: string;
  category_id: string; category_name: string; pincode: string; address_line1: string;
  landmark?: string; description: string; customer_notes?: string | null; status: OrderStatus;
  estimated_price_paise: number | null; final_price_paise?: number | null;
  created_at: string; scheduled_for?: string; current_provider_id?: string; current_provider_name?: string;
}
export interface ProviderProfile {
  id: string; user_id: string; full_name: string; phone: string; experience_years: number;
  verification_status: VerificationStatus; availability_status: AvailabilityStatus;
  categories: string[]; rating_average: number; total_jobs_completed: number;
  id_document_url?: string; trade_license_url?: string; verification_notes?: string; created_at: string;
}
export interface SupportTicket {
  id: string; service_request_id: string | null; reporter_id: string;
  reporter_role: 'customer' | 'provider'; subject: string; description: string;
  status: 'open' | 'in_progress' | 'resolved' | 'closed'; resolution_notes?: string; created_at: string;
}
export interface AdminMetrics {
  pending_requests: number; active_jobs: number;
  completed_today: number; verified_providers: number; pending_verifications: number;
}
