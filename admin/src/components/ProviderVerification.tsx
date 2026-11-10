'use client';

import React, { useState } from 'react';
import { ShieldAlert, ShieldCheck, CheckCircle2, XCircle, FileText, ExternalLink, AlertCircle } from 'lucide-react';
import { ProviderProfile } from '../types';
import { verifyProviderRpc } from '../lib/supabase';

interface ProviderVerificationProps {
  providers: ProviderProfile[];
  onActionComplete: () => void;
}

export default function ProviderVerification({
  providers,
  onActionComplete,
}: ProviderVerificationProps) {
  const [selectedProvider, setSelectedProvider] = useState<ProviderProfile | null>(null);
  const [decision, setDecision] = useState<'approved' | 'rejected'>('approved');
  const [notes, setNotes] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(
    null
  );
  const [activeFilter, setActiveFilter] = useState<'pending' | 'approved' | 'all'>('pending');

  const filteredProviders = providers.filter((p) => {
    if (activeFilter === 'pending') {
      return p.verification_status === 'pending';
    }
    if (activeFilter === 'approved') {
      return p.verification_status === 'approved';
    }
    return true;
  });

  const handleDecisionSubmit = async () => {
    if (!selectedProvider) return;
    if (!notes.trim()) {
      setFeedback({ type: 'error', message: 'Verification audit notes are required for compliance.' });
      return;
    }

    setIsSubmitting(true);
    setFeedback(null);

    const res = await verifyProviderRpc(selectedProvider.id, decision, notes.trim());
    setIsSubmitting(false);

    if (res.success) {
      setFeedback({ type: 'success', message: res.message });
      setSelectedProvider(null);
      setNotes('');
      onActionComplete();
    } else {
      setFeedback({ type: 'error', message: res.message });
    }
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

      {/* Filter Tabs */}
      <div className="flex space-x-2 border-b border-zinc-200 pb-2">
        {[
          { id: 'pending', label: 'Pending Audit' },
          { id: 'approved', label: 'Approved Partners' },
          { id: 'all', label: 'All Records' },
        ].map((f) => (
          <button
            key={f.id}
            onClick={() => setActiveFilter(f.id as 'pending' | 'approved' | 'all')}
            className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition ${
              activeFilter === f.id
                ? 'bg-zinc-900 text-white shadow-xs'
                : 'text-zinc-600 hover:bg-zinc-100'
            }`}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-zinc-200 shadow-xs overflow-hidden">
        <div className="px-6 py-4 border-b border-zinc-200">
          <h2 className="text-base font-bold text-zinc-900">
            Provider Identity & Credential Audits
          </h2>
          <p className="text-xs text-zinc-500">
            Review Government Photo IDs (Aadhaar/PAN) and trade certifications before enabling on-field matching.
          </p>
        </div>

        {filteredProviders.length === 0 ? (
          <div className="p-12 text-center">
            <ShieldCheck className="w-12 h-12 text-emerald-500 mx-auto mb-3" />
            <h3 className="text-sm font-semibold text-zinc-800">No Providers in this View</h3>
            <p className="text-xs text-zinc-500 mt-1">
              All provider applications have been audited.
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-zinc-50 text-[11px] font-semibold text-zinc-500 uppercase tracking-wider border-b border-zinc-200">
                  <th className="py-3 px-4">Partner Profile</th>
                  <th className="py-3 px-4">Category & Experience</th>
                  <th className="py-3 px-4">Verification Status</th>
                  <th className="py-3 px-4">Uploaded Credentials</th>
                  <th className="py-3 px-4">Audit Notes</th>
                  <th className="py-3 px-4 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-200 text-xs sm:text-sm">
                {filteredProviders.map((pro) => (
                  <tr key={pro.id} className="hover:bg-zinc-50/80 transition">
                    <td className="py-3.5 px-4">
                      <div className="font-semibold text-zinc-900">{pro.full_name}</div>
                      <div className="text-xs text-zinc-500">{pro.phone}</div>
                    </td>
                    <td className="py-3.5 px-4">
                      <span className="font-medium text-zinc-800">
                        {pro.categories.join(', ')}
                      </span>
                      <div className="text-xs text-zinc-500">{pro.experience_years} years in field</div>
                    </td>
                    <td className="py-3.5 px-4">
                      <span
                        className={`inline-flex items-center space-x-1 px-2.5 py-1 rounded-full text-xs font-semibold ${
                          pro.verification_status === 'approved'
                            ? 'bg-emerald-100 text-emerald-800'
                            : pro.verification_status === 'rejected'
                            ? 'bg-rose-100 text-rose-800'
                            : 'bg-amber-100 text-amber-800'
                        }`}
                      >
                        {pro.verification_status === 'approved' && (
                          <ShieldCheck className="w-3.5 h-3.5 mr-1" />
                        )}
                        {pro.verification_status === 'rejected' && (
                          <ShieldAlert className="w-3.5 h-3.5 mr-1" />
                        )}
                        <span className="capitalize">{pro.verification_status.replace('_', ' ')}</span>
                      </span>
                    </td>
                    <td className="py-3.5 px-4">
                      <div className="flex flex-col space-y-1">
                        {pro.id_document_url ? (
                          <a
                            href={pro.id_document_url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center space-x-1 text-xs text-emerald-700 hover:underline"
                          >
                            <FileText className="w-3.5 h-3.5" />
                            <span>Govt ID Document</span>
                            <ExternalLink className="w-3 h-3 text-zinc-400" />
                          </a>
                        ) : (
                          <span className="text-xs text-zinc-400">ID Not Uploaded</span>
                        )}

                        {pro.trade_license_url ? (
                          <a
                            href={pro.trade_license_url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center space-x-1 text-xs text-emerald-700 hover:underline"
                          >
                            <FileText className="w-3.5 h-3.5" />
                            <span>Trade Certificate</span>
                            <ExternalLink className="w-3 h-3 text-zinc-400" />
                          </a>
                        ) : (
                          <span className="text-xs text-zinc-400">Cert Not Uploaded</span>
                        )}
                      </div>
                    </td>
                    <td className="py-3.5 px-4 max-w-xs">
                      <p className="text-zinc-600 text-xs italic truncate" title={pro.verification_notes}>
                        {pro.verification_notes || 'No review notes logged yet.'}
                      </p>
                    </td>
                    <td className="py-3.5 px-4 text-right">
                      <button
                        onClick={() => {
                          setSelectedProvider(pro);
                          setDecision(pro.verification_status === 'approved' ? 'rejected' : 'approved');
                          setNotes(pro.verification_notes || '');
                        }}
                        className="px-3 py-1.5 text-xs font-semibold rounded-lg border border-zinc-300 hover:bg-zinc-100 text-zinc-800 transition"
                      >
                        Audit / Edit
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Verification Audit Modal */}
      {selectedProvider && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-zinc-200">
            <h3 className="text-lg font-bold text-zinc-900 mb-1">
              Audit Partner: {selectedProvider.full_name}
            </h3>
            <p className="text-xs text-zinc-500 mb-4">
              Phone: {selectedProvider.phone} • Field: {selectedProvider.categories.join(', ')}
            </p>

            <div className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-zinc-700 mb-1">
                  Verification Decision:
                </label>
                <div className="grid grid-cols-2 gap-3">
                  <button
                    type="button"
                    onClick={() => setDecision('approved')}
                    className={`flex items-center justify-center space-x-2 py-2 px-3 rounded-lg border text-xs font-semibold transition ${
                      decision === 'approved'
                        ? 'border-emerald-500 bg-emerald-50 text-emerald-800 ring-1 ring-emerald-500'
                        : 'border-zinc-200 hover:bg-zinc-50 text-zinc-700'
                    }`}
                  >
                    <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                    <span>Approve Partner</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setDecision('rejected')}
                    className={`flex items-center justify-center space-x-2 py-2 px-3 rounded-lg border text-xs font-semibold transition ${
                      decision === 'rejected'
                        ? 'border-rose-500 bg-rose-50 text-rose-800 ring-1 ring-rose-500'
                        : 'border-zinc-200 hover:bg-zinc-50 text-zinc-700'
                    }`}
                  >
                    <XCircle className="w-4 h-4 text-rose-600" />
                    <span>Reject Application</span>
                  </button>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-zinc-700 mb-1">
                  Compliance Audit Notes (Mandatory for log):
                </label>
                <textarea
                  rows={3}
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="e.g. Government Aadhaar card verified against DigiLocker. Electrical license #KA-2024-BLR confirmed active."
                  className="w-full text-xs border border-zinc-300 rounded-lg p-2.5 focus:ring-2 focus:ring-emerald-500"
                />
              </div>
            </div>

            <div className="flex justify-end space-x-3 pt-4 mt-4 border-t border-zinc-200">
              <button
                type="button"
                onClick={() => setSelectedProvider(null)}
                className="px-4 py-2 text-xs font-semibold text-zinc-700 hover:bg-zinc-100 rounded-lg transition"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={isSubmitting}
                onClick={handleDecisionSubmit}
                className="px-4 py-2 text-xs font-semibold bg-zinc-900 hover:bg-black text-white rounded-lg shadow-sm transition disabled:opacity-50"
              >
                {isSubmitting ? 'Saving...' : 'Submit Audit Log'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
