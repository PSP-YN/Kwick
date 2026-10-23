'use client';

import React, { useEffect, useState } from 'react';
import Header from '../components/Header';
import MetricCards from '../components/MetricCards';
import DispatchQueue from '../components/DispatchQueue';
import ProviderVerification from '../components/ProviderVerification';
import DisputeResolution from '../components/DisputeResolution';
import {
  AdminMetrics,
  ServiceRequest,
  ProviderProfile,
  SupportTicket,
} from '../types';
import {
  fetchAdminMetrics,
  fetchServiceRequests,
  fetchProviders,
  fetchSupportTickets,
} from '../lib/supabase';
import { MapPin, ShieldCheck, TrendingUp, Clock } from 'lucide-react';

export default function AdminPage() {
  const [activeTab, setActiveTab] = useState<'overview' | 'dispatch' | 'providers' | 'disputes'>('overview');
  const [metrics, setMetrics] = useState<AdminMetrics>({
    pending_requests: 0,
    matched_requests: 0,
    active_jobs: 0,
    completed_today: 0,
    verified_providers: 0,
    pending_verifications: 0,
  });
  const [requests, setRequests] = useState<ServiceRequest[]>([]);
  const [providers, setProviders] = useState<ProviderProfile[]>([]);
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);

  const loadData = async () => {
    setIsRefreshing(true);
    try {
      const [m, r, p, t] = await Promise.all([
        fetchAdminMetrics(),
        fetchServiceRequests(),
        fetchProviders(),
        fetchSupportTickets(),
      ]);
      setMetrics(m);
      setRequests(r);
      setProviders(p);
      setTickets(t);
    } catch (err) {
      console.error('Failed to load operational admin data:', err);
    } finally {
      setLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    let isMounted = true;
    const init = async () => {
      try {
        const [m, r, p, t] = await Promise.all([
          fetchAdminMetrics(),
          fetchServiceRequests(),
          fetchProviders(),
          fetchSupportTickets(),
        ]);
        if (isMounted) {
          setMetrics(m);
          setRequests(r);
          setProviders(p);
          setTickets(t);
          setLoading(false);
        }
      } catch (err) {
        console.error('Initial admin data load error:', err);
        if (isMounted) setLoading(false);
      }
    };
    init();
    return () => {
      isMounted = false;
    };
  }, []);

  return (
    <div className="min-h-screen bg-zinc-50 flex flex-col font-sans">
      <Header
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        onRefresh={loadData}
        isRefreshing={isRefreshing}
      />

      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {loading ? (
          <div className="flex flex-col items-center justify-center py-20 space-y-3">
            <div className="w-8 h-8 border-3 border-emerald-600 border-t-transparent rounded-full animate-spin" />
            <p className="text-xs text-zinc-500 font-medium">Loading Operations Console...</p>
          </div>
        ) : (
          <>
            {/* Top KPI Cards */}
            <MetricCards metrics={metrics} />

            {/* Tab Views */}
            {activeTab === 'overview' && (
              <div className="space-y-8">
                {/* Pilot Region Status Banner */}
                <div className="bg-gradient-to-r from-emerald-800 to-teal-900 rounded-2xl p-6 text-white shadow-md flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                  <div className="space-y-1">
                    <div className="flex items-center space-x-2">
                      <MapPin className="w-5 h-5 text-emerald-300" />
                      <h2 className="text-lg font-bold">Bengaluru South Pilot Region (560102)</h2>
                    </div>
                    <p className="text-xs text-emerald-100 max-w-xl">
                      Authoritative single-zone pilot for HSR Layout and Koramangala. Strict partial unique indexes prevent double-booking. Financial amounts recorded in integer paise.
                    </p>
                  </div>
                  <div className="flex items-center space-x-3 bg-white/10 px-4 py-2 rounded-xl backdrop-blur-xs">
                    <ShieldCheck className="w-6 h-6 text-emerald-300" />
                    <div>
                      <p className="text-[11px] text-emerald-200 uppercase font-semibold">Security State</p>
                      <p className="text-xs font-bold text-white">Row Level Security Active</p>
                    </div>
                  </div>
                </div>

                {/* Split grid: Recent Activity & Field Readiness */}
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  {/* Recent Service Orders */}
                  <div className="bg-white rounded-xl border border-zinc-200 shadow-xs p-5">
                    <div className="flex items-center justify-between pb-3 border-b border-zinc-100">
                      <div className="flex items-center space-x-2">
                        <Clock className="w-4 h-4 text-zinc-600" />
                        <h3 className="text-sm font-bold text-zinc-900">Recent Service Activity</h3>
                      </div>
                      <button
                        onClick={() => setActiveTab('dispatch')}
                        className="text-xs text-emerald-700 font-semibold hover:underline"
                      >
                        View Queue →
                      </button>
                    </div>

                    <div className="divide-y divide-zinc-100 mt-2">
                      {requests.slice(0, 4).map((req) => (
                        <div key={req.id} className="py-3 flex justify-between items-center text-xs">
                          <div>
                            <div className="flex items-center space-x-2">
                              <span className="font-semibold text-zinc-800">{req.category_name}</span>
                              <span className="text-[10px] text-zinc-400 font-mono">({req.id})</span>
                            </div>
                            <p className="text-zinc-500 text-[11px] truncate max-w-[240px]">
                              {req.address_line1}
                            </p>
                          </div>
                          <div className="text-right">
                            <span
                              className={`text-[10px] font-semibold px-2 py-0.5 rounded-full capitalize ${
                                req.status === 'completed'
                                  ? 'bg-emerald-100 text-emerald-800'
                                  : req.status === 'in_progress'
                                  ? 'bg-blue-100 text-blue-800'
                                  : req.status === 'assigned'
                                  ? 'bg-purple-100 text-purple-800'
                                  : 'bg-amber-100 text-amber-800'
                              }`}
                            >
                              {req.status.replace('_', ' ')}
                            </span>
                            <p className="text-[11px] font-medium text-zinc-800 mt-0.5">
                              ₹{(req.estimated_price_paise / 100).toLocaleString('en-IN')}
                            </p>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Active Partner Roster */}
                  <div className="bg-white rounded-xl border border-zinc-200 shadow-xs p-5">
                    <div className="flex items-center justify-between pb-3 border-b border-zinc-100">
                      <div className="flex items-center space-x-2">
                        <TrendingUp className="w-4 h-4 text-zinc-600" />
                        <h3 className="text-sm font-bold text-zinc-900">Field Partner Readiness</h3>
                      </div>
                      <button
                        onClick={() => setActiveTab('providers')}
                        className="text-xs text-emerald-700 font-semibold hover:underline"
                      >
                        Manage Verifications →
                      </button>
                    </div>

                    <div className="divide-y divide-zinc-100 mt-2">
                      {providers.slice(0, 4).map((pro) => (
                        <div key={pro.id} className="py-3 flex justify-between items-center text-xs">
                          <div>
                            <div className="flex items-center space-x-2">
                              <span className="font-semibold text-zinc-900">{pro.full_name}</span>
                              <span className="text-[10px] bg-zinc-100 text-zinc-600 px-1 py-0.5 rounded">
                                {pro.categories.join(', ')}
                              </span>
                            </div>
                            <p className="text-zinc-500 text-[11px]">
                              {pro.experience_years} yrs exp • {pro.total_jobs_completed} jobs completed
                            </p>
                          </div>
                          <div className="text-right">
                            <span
                              className={`text-[10px] font-semibold px-2 py-0.5 rounded-full capitalize ${
                                pro.availability_status === 'available'
                                  ? 'bg-emerald-100 text-emerald-800'
                                  : 'bg-amber-100 text-amber-800'
                              }`}
                            >
                              {pro.availability_status}
                            </span>
                            <p className="text-[11px] text-zinc-500 mt-0.5">
                              ★ {pro.rating_average.toFixed(1)} rating
                            </p>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'dispatch' && (
              <DispatchQueue
                requests={requests}
                providers={providers}
                onActionComplete={loadData}
              />
            )}

            {activeTab === 'providers' && (
              <ProviderVerification
                providers={providers}
                onActionComplete={loadData}
              />
            )}

            {activeTab === 'disputes' && (
              <DisputeResolution
                tickets={tickets}
                requests={requests}
                onActionComplete={loadData}
              />
            )}
          </>
        )}
      </main>

      {/* Footer */}
      <footer className="border-t border-zinc-200 bg-white py-4 mt-auto">
        <div className="max-w-7xl mx-auto px-4 text-center text-xs text-zinc-500">
          NexHelp Operations Platform • Bengaluru South Pilot • PostgreSQL 16 + RLS • Built for Production
        </div>
      </footer>
    </div>
  );
}
