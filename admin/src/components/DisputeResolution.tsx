'use client';

import React, { useState } from 'react';
import { AlertTriangle, CheckCircle2, MessageSquare, AlertCircle } from 'lucide-react';
import { SupportTicket, ServiceRequest } from '../types';
import { overrideRequestStatusRpc } from '../lib/supabase';

interface DisputeResolutionProps {
  tickets: SupportTicket[];
  requests: ServiceRequest[];
  onActionComplete: () => void;
}

export default function DisputeResolution({
  tickets,
  requests,
  onActionComplete,
}: DisputeResolutionProps) {
  const [selectedRequest, setSelectedRequest] = useState<ServiceRequest | null>(null);
  const [targetStatus, setTargetStatus] = useState<string>('cancelled');
  const [overrideReason, setOverrideReason] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(
    null
  );

  const handleOverrideSubmit = async () => {
    if (!selectedRequest) return;
    if (!overrideReason.trim()) {
      setFeedback({ type: 'error', message: 'An authoritative audit reason is mandatory for overrides.' });
      return;
    }

    setIsSubmitting(true);
    setFeedback(null);

    const res = await overrideRequestStatusRpc(selectedRequest.id, targetStatus, overrideReason.trim());
    setIsSubmitting(false);

    if (res.success) {
      setFeedback({ type: 'success', message: res.message });
      setSelectedRequest(null);
      setOverrideReason('');
      onActionComplete();
    } else {
      setFeedback({ type: 'error', message: res.message });
    }
  };

  return (
    <div className="space-y-8">
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
              <CheckCircle2 className="w-5 h-5 text-emerald-600" />
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

      {/* Support Tickets Queue */}
      <div className="bg-white rounded-xl border border-zinc-200 shadow-xs overflow-hidden">
        <div className="px-6 py-4 border-b border-zinc-200">
          <div className="flex items-center space-x-2">
            <MessageSquare className="w-5 h-5 text-indigo-600" />
            <h2 className="text-base font-bold text-zinc-900">Customer & Partner Inquiries</h2>
          </div>
          <p className="text-xs text-zinc-500 mt-0.5">
            Real-time escalations regarding delays, billing questions, and on-field disputes
          </p>
        </div>

        {tickets.length === 0 ? (
          <div className="p-8 text-center text-xs text-zinc-500">
            No support tickets open at this time.
          </div>
        ) : (
          <div className="divide-y divide-zinc-200">
            {tickets.map((tkt) => (
              <div key={tkt.id} className="p-4 sm:p-5 hover:bg-zinc-50 transition flex flex-col sm:flex-row justify-between items-start gap-4">
                <div className="space-y-1">
                  <div className="flex items-center space-x-2">
                    <span className="font-semibold text-zinc-900 text-sm">{tkt.subject}</span>
                    <span
                      className={`text-[10px] font-semibold uppercase px-2 py-0.5 rounded-full ${
                        tkt.status === 'open'
                          ? 'bg-rose-100 text-rose-800'
                          : tkt.status === 'resolved'
                          ? 'bg-emerald-100 text-emerald-800'
                          : 'bg-amber-100 text-amber-800'
                      }`}
                    >
                      {tkt.status}
                    </span>
                    <span className="text-[11px] text-zinc-400 capitalize">
                      via {tkt.reporter_role}
                    </span>
                  </div>
                  <p className="text-xs text-zinc-600">{tkt.description}</p>
                  {tkt.resolution_notes && (
                    <p className="text-xs text-emerald-700 bg-emerald-50 p-2 rounded border border-emerald-100">
                      Resolution: {tkt.resolution_notes}
                    </p>
                  )}
                  <p className="text-[10px] text-zinc-400">
                    Linked Request: <span className="font-mono text-zinc-600">{tkt.service_request_id}</span>
                  </p>
                </div>

                <div className="flex items-center space-x-2 shrink-0">
                  <button
                    onClick={() => {
                      const req = requests.find((r) => r.id === tkt.service_request_id);
                      if (req) {
                        setSelectedRequest(req);
                        setTargetStatus('disputed');
                        setOverrideReason(`Investigating ticket ${tkt.id}: ${tkt.subject}`);
                      } else {
                        setFeedback({
                          type: 'error',
                          message: `Request ${tkt.service_request_id} not found in active list.`,
                        });
                      }
                    }}
                    className="px-3 py-1.5 text-xs font-semibold rounded-lg bg-indigo-50 hover:bg-indigo-100 text-indigo-700 transition"
                  >
                    Action Order
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Emergency Status Override Section */}
      <div className="bg-white rounded-xl border border-zinc-200 shadow-xs overflow-hidden">
        <div className="px-6 py-4 border-b border-zinc-200 flex items-center justify-between">
          <div>
            <div className="flex items-center space-x-2">
              <AlertTriangle className="w-5 h-5 text-amber-600" />
              <h2 className="text-base font-bold text-zinc-900">Authoritative State Override</h2>
            </div>
            <p className="text-xs text-zinc-500 mt-0.5">
              Execute <code className="font-mono text-zinc-700">admin_override_request_status</code> RPC with logged justification
            </p>
          </div>
        </div>

        <div className="p-6">
          <p className="text-xs text-zinc-600 mb-4">
            Select any active or past request from the pilot region to forcibly correct its state in edge-case situations (e.g., customer cancel by phone, emergency weather halt).
          </p>

          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="bg-zinc-50 font-semibold text-zinc-500 uppercase tracking-wider border-b border-zinc-200">
                  <th className="py-2.5 px-3">Request ID</th>
                  <th className="py-2.5 px-3">Category</th>
                  <th className="py-2.5 px-3">Current Status</th>
                  <th className="py-2.5 px-3">Assigned Partner</th>
                  <th className="py-2.5 px-3 text-right">Emergency Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-200">
                {requests.slice(0, 5).map((req) => (
                  <tr key={req.id} className="hover:bg-zinc-50">
                    <td className="py-3 px-3 font-mono font-medium text-zinc-700">{req.id}</td>
                    <td className="py-3 px-3">{req.category_name}</td>
                    <td className="py-3 px-3">
                      <span className="font-semibold px-2 py-0.5 rounded-full bg-zinc-100 text-zinc-800 text-[11px] capitalize">
                        {req.status}
                      </span>
                    </td>
                    <td className="py-3 px-3 text-zinc-600">
                      {req.current_provider_name || 'None'}
                    </td>
                    <td className="py-3 px-3 text-right">
                      <button
                        onClick={() => {
                          setSelectedRequest(req);
                          setTargetStatus(req.status === 'in_progress' ? 'completed' : 'cancelled');
                        }}
                        className="px-2.5 py-1 text-xs font-semibold text-rose-700 bg-rose-50 hover:bg-rose-100 rounded border border-rose-200 transition"
                      >
                        Override Status
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Override Modal */}
      {selectedRequest && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-zinc-200">
            <div className="flex items-center space-x-2 text-rose-600 mb-2">
              <AlertTriangle className="w-5 h-5" />
              <h3 className="text-base font-bold text-zinc-900">
                Authoritative State Override
              </h3>
            </div>
            <p className="text-xs text-zinc-500 mb-4">
              Overriding request <span className="font-mono text-zinc-800">{selectedRequest.id}</span>. This action bypasses standard client state transitions and writes to the audit trail.
            </p>

            <div className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-zinc-700 mb-1">
                  Target Status:
                </label>
                <select
                  value={targetStatus}
                  onChange={(e) => setTargetStatus(e.target.value)}
                  className="w-full text-xs border border-zinc-300 rounded-lg p-2.5 bg-white focus:ring-2 focus:ring-emerald-500"
                >
                  <option value="draft">draft</option>
                  <option value="submitted">submitted</option>
                  <option value="matched">matched</option>
                  <option value="assigned">assigned</option>
                  <option value="in_progress">in_progress</option>
                  <option value="completed">completed</option>
                  <option value="cancelled">cancelled</option>
                  <option value="disputed">disputed</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-zinc-700 mb-1">
                  Mandatory Audit Reason:
                </label>
                <textarea
                  rows={3}
                  value={overrideReason}
                  onChange={(e) => setOverrideReason(e.target.value)}
                  placeholder="e.g. Customer phoned operations to cancel due to water board supply disruption. Partner compensated travel allowance."
                  className="w-full text-xs border border-zinc-300 rounded-lg p-2.5 focus:ring-2 focus:ring-emerald-500"
                />
              </div>
            </div>

            <div className="flex justify-end space-x-3 pt-4 mt-4 border-t border-zinc-200">
              <button
                type="button"
                onClick={() => setSelectedRequest(null)}
                className="px-4 py-2 text-xs font-semibold text-zinc-700 hover:bg-zinc-100 rounded-lg transition"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={isSubmitting}
                onClick={handleOverrideSubmit}
                className="px-4 py-2 text-xs font-semibold bg-rose-600 hover:bg-rose-700 text-white rounded-lg shadow-sm transition disabled:opacity-50"
              >
                {isSubmitting ? 'Overriding...' : 'Execute Override'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
