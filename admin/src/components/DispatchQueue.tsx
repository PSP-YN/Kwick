'use client';

import React, { useState } from 'react';
import { Send, MapPin, AlertCircle, CheckCircle, Search, Filter } from 'lucide-react';
import { ServiceRequest, ProviderProfile } from '../types';
import { assignProviderRpc } from '../lib/supabase';

interface DispatchQueueProps {
  requests: ServiceRequest[];
  providers: ProviderProfile[];
  onActionComplete: () => void;
}

export default function DispatchQueue({
  requests,
  providers,
  onActionComplete,
}: DispatchQueueProps) {
  const [selectedRequest, setSelectedRequest] = useState<ServiceRequest | null>(null);
  const [selectedProviderId, setSelectedProviderId] = useState<string>('');
  const [filterCategory, setFilterCategory] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(
    null
  );

  // Filter requests that are waiting for dispatch
  const dispatchableRequests = requests.filter((r) => {
    const matchesStatus = r.status === 'requested' || r.status === 'reviewing';
    const matchesCategory =
      filterCategory === 'all' || r.category_name.toLowerCase() === filterCategory.toLowerCase();
    const matchesSearch =
      r.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.address_line1.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (r.customer_name && r.customer_name.toLowerCase().includes(searchQuery.toLowerCase()));
    return matchesStatus && matchesCategory && matchesSearch;
  });

  // Eligible providers: approved and available
  const eligibleProviders = providers.filter(
    (p) => p.verification_status === 'approved' && p.availability_status === 'available'
  );

  const handleAssign = async () => {
    if (!selectedRequest || !selectedProviderId) return;
    setIsSubmitting(true);
    setFeedback(null);

    const res = await assignProviderRpc(selectedRequest.id, selectedProviderId);
    setIsSubmitting(false);

    if (res.success) {
      setFeedback({ type: 'success', message: res.message });
      setSelectedRequest(null);
      setSelectedProviderId('');
      onActionComplete();
    } else {
      setFeedback({ type: 'error', message: res.message });
    }
  };

  const formatINR = (paise: number | null) => {
    return paise === null ? 'Not quoted' : `₹${(paise / 100).toLocaleString('en-IN')}`;
  };

  return (
    <div className="space-y-6">
      {/* Feedback Banner */}
      {feedback && (
        <div
          className={`p-4 rounded-lg flex items-center justify-between text-sm ${
            feedback.type === 'success'
              ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
              : 'bg-rose-50 text-rose-800 border border-rose-200'
          }`}
        >
          <div className="flex items-center space-x-2">
            {feedback.type === 'success' ? (
              <CheckCircle className="w-5 h-5 text-emerald-600" />
            ) : (
              <AlertCircle className="w-5 h-5 text-rose-600" />
            )}
            <span>{feedback.message}</span>
          </div>
          <button
            onClick={() => setFeedback(null)}
            className="text-xs font-semibold hover:underline"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* Control Bar: Search & Filter */}
      <div className="flex flex-col sm:flex-row justify-between gap-4 bg-white p-4 rounded-xl border border-zinc-200 shadow-xs">
        <div className="relative flex-1">
          <Search className="w-4 h-4 text-zinc-400 absolute left-3 top-3" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search address, issue description, or customer..."
            className="w-full pl-9 pr-4 py-2 text-xs sm:text-sm border border-zinc-300 rounded-lg focus:outline-hidden focus:ring-2 focus:ring-emerald-500"
          />
        </div>

        <div className="flex items-center space-x-2">
          <Filter className="w-4 h-4 text-zinc-500" />
          <span className="text-xs font-medium text-zinc-600">Category:</span>
          <select
            value={filterCategory}
            onChange={(e) => setFilterCategory(e.target.value)}
            className="text-xs sm:text-sm border border-zinc-300 rounded-lg px-3 py-2 bg-white focus:ring-2 focus:ring-emerald-500"
          >
            <option value="all">All Services</option>
            <option value="plumbing">Plumbing</option>
            <option value="electrical">Electrical</option>
          </select>
        </div>
      </div>

      {/* Dispatch Table */}
      <div className="bg-white rounded-xl border border-zinc-200 shadow-xs overflow-hidden">
        <div className="px-6 py-4 border-b border-zinc-200 flex justify-between items-center">
          <div>
            <h2 className="text-base font-bold text-zinc-900">
              Awaiting Dispatch ({dispatchableRequests.length})
            </h2>
            <p className="text-xs text-zinc-500">
              Pending customer orders requiring field partner allocation in Bengaluru South
            </p>
          </div>
        </div>

        {dispatchableRequests.length === 0 ? (
          <div className="p-12 text-center">
            <CheckCircle className="w-12 h-12 text-emerald-500 mx-auto mb-3" />
            <h3 className="text-sm font-semibold text-zinc-800">Dispatch Queue is Clear</h3>
            <p className="text-xs text-zinc-500 mt-1">
              All active requests in pincode 560102 have been matched or assigned.
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-zinc-50 text-[11px] font-semibold text-zinc-500 uppercase tracking-wider border-b border-zinc-200">
                  <th className="py-3 px-4">Request ID</th>
                  <th className="py-3 px-4">Category</th>
                  <th className="py-3 px-4">Customer & Location</th>
                  <th className="py-3 px-4">Issue Description</th>
                  <th className="py-3 px-4">Estimate</th>
                  <th className="py-3 px-4 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-200 text-xs sm:text-sm">
                {dispatchableRequests.map((req) => (
                  <tr key={req.id} className="hover:bg-zinc-50/80 transition">
                    <td className="py-3.5 px-4 font-mono text-xs font-medium text-zinc-600">
                      {req.id}
                      <span className="block text-[10px] text-zinc-400 font-sans">
                        {new Date(req.created_at).toLocaleTimeString([], {
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </span>
                    </td>
                    <td className="py-3.5 px-4">
                      <span
                        className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold ${
                          req.category_name.toLowerCase().includes('plumbing')
                            ? 'bg-blue-50 text-blue-700 border border-blue-200'
                            : 'bg-amber-50 text-amber-700 border border-amber-200'
                        }`}
                      >
                        {req.category_name}
                      </span>
                    </td>
                    <td className="py-3.5 px-4">
                      <div className="font-medium text-zinc-900">{req.customer_name || 'Customer'}</div>
                      <div className="flex items-center text-zinc-500 text-xs mt-0.5">
                        <MapPin className="w-3 h-3 mr-1 text-zinc-400 shrink-0" />
                        <span className="truncate max-w-[200px]" title={req.address_line1}>
                          {req.address_line1} ({req.pincode})
                        </span>
                      </div>
                    </td>
                    <td className="py-3.5 px-4 max-w-xs">
                      <p className="text-zinc-700 truncate" title={req.description}>
                        {req.description}
                      </p>
                    </td>
                    <td className="py-3.5 px-4 font-semibold text-zinc-900">
                      {formatINR(req.estimated_price_paise)}
                    </td>
                    <td className="py-3.5 px-4 text-right">
                      <button
                        onClick={() => {
                          setSelectedRequest(req);
                          setSelectedProviderId('');
                        }}
                        className="inline-flex items-center space-x-1.5 px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-semibold rounded-lg shadow-xs transition"
                      >
                        <Send className="w-3.5 h-3.5" />
                        <span>Dispatch</span>
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Manual Dispatch Modal */}
      {selectedRequest && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-zinc-200">
            <h3 className="text-lg font-bold text-zinc-900 mb-1">
              Manual Dispatch Assignment
            </h3>
            <p className="text-xs text-zinc-500 mb-4">
              Allocating request <span className="font-mono text-zinc-800">{selectedRequest.id}</span>{' '}
              ({selectedRequest.category_name}) to an approved partner.
            </p>

            <div className="bg-zinc-50 p-3 rounded-lg border border-zinc-200 text-xs mb-4 space-y-1">
              <p>
                <span className="font-semibold text-zinc-700">Location:</span>{' '}
                {selectedRequest.address_line1} (Pincode: {selectedRequest.pincode})
              </p>
              <p>
                <span className="font-semibold text-zinc-700">Issue:</span> {selectedRequest.description}
              </p>
              <p>
                <span className="font-semibold text-zinc-700">Estimate:</span>{' '}
                {formatINR(selectedRequest.estimated_price_paise)}
              </p>
              {selectedRequest.customer_notes && (
                <p className="border-t border-zinc-200 pt-2 mt-2 whitespace-pre-wrap">
                  <span className="font-semibold text-zinc-700">Customer notes / AI triage:</span>{' '}
                  {selectedRequest.customer_notes}
                </p>
              )}
            </div>

            <div className="mb-4">
              <label className="block text-xs font-semibold text-zinc-700 mb-2">
                Select Available & Verified Partner:
              </label>
              {eligibleProviders.length === 0 ? (
                <p className="text-xs text-rose-600 bg-rose-50 p-3 rounded border border-rose-200">
                  No verified providers currently available. Please approve pending providers first.
                </p>
              ) : (
                <div className="space-y-2 max-h-56 overflow-y-auto pr-1">
                  {eligibleProviders.map((pro) => (
                    <label
                      key={pro.id}
                      className={`flex items-center justify-between p-3 rounded-lg border cursor-pointer transition ${
                        selectedProviderId === pro.id
                          ? 'border-emerald-500 bg-emerald-50/40 ring-1 ring-emerald-500'
                          : 'border-zinc-200 hover:bg-zinc-50'
                      }`}
                    >
                      <div className="flex items-center space-x-3">
                        <input
                          type="radio"
                          name="provider"
                          value={pro.id}
                          checked={selectedProviderId === pro.id}
                          onChange={() => setSelectedProviderId(pro.id)}
                          className="text-emerald-600 focus:ring-emerald-500"
                        />
                        <div>
                          <div className="flex items-center space-x-2">
                            <span className="font-semibold text-zinc-900 text-xs sm:text-sm">
                              {pro.full_name}
                            </span>
                            <span className="text-[10px] bg-zinc-100 text-zinc-600 px-1.5 py-0.5 rounded font-medium">
                              ★ {pro.rating_average.toFixed(1)}
                            </span>
                          </div>
                          <p className="text-[11px] text-zinc-500">
                            {pro.categories.join(', ')} • {pro.experience_years} yrs exp • {pro.total_jobs_completed} jobs
                          </p>
                        </div>
                      </div>

                      <span
                        className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${
                          pro.availability_status === 'available'
                            ? 'bg-emerald-100 text-emerald-800'
                            : 'bg-amber-100 text-amber-800'
                        }`}
                      >
                        {pro.availability_status}
                      </span>
                    </label>
                  ))}
                </div>
              )}
            </div>

            <div className="flex justify-end space-x-3 pt-3 border-t border-zinc-200">
              <button
                type="button"
                onClick={() => setSelectedRequest(null)}
                className="px-4 py-2 text-xs font-semibold text-zinc-700 hover:bg-zinc-100 rounded-lg transition"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={!selectedProviderId || isSubmitting}
                onClick={handleAssign}
                className="px-4 py-2 text-xs font-semibold bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg shadow-sm transition disabled:opacity-50"
              >
                {isSubmitting ? 'Assigning...' : 'Confirm Assignment'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
