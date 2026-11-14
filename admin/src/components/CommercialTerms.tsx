'use client';

import { useCallback, useEffect, useState } from 'react';
import { CheckCircle2, CircleDollarSign, Percent, RefreshCw, ShieldCheck, XCircle } from 'lucide-react';
import { supabase } from '../lib/supabase';

type CommercialRow = {
  id: string;
  provider_id: string;
  category_id: string;
  base_price_minor: number | null;
  pricing_model: 'provider_quote' | 'agreed_fixed';
  price_approval_status: 'not_required' | 'pending' | 'approved' | 'rejected';
  price_review_note: string | null;
  providers: { profiles: { full_name: string; phone: string | null } | { full_name: string; phone: string | null }[] | null } | { profiles: { full_name: string; phone: string | null } | { full_name: string; phone: string | null }[] | null }[] | null;
  service_categories: { name: string } | { name: string }[] | null;
};

type TermRow = {
  id: string;
  provider_id: string;
  category_id: string;
  commission_rate_bps: number;
  status: 'draft' | 'active' | 'rejected' | 'superseded';
  terms_note: string | null;
  provider_agreed_at: string | null;
};

function first<T>(value: T | T[] | null | undefined): T | null {
  if (!value) return null;
  return Array.isArray(value) ? value[0] ?? null : value as T;
}

export default function CommercialTerms({ onActionComplete }: { onActionComplete: () => void }) {
  const [rows, setRows] = useState<CommercialRow[]>([]);
  const [terms, setTerms] = useState<TermRow[]>([]);
  const [rates, setRates] = useState<Record<string, string>>({});
  const [notes, setNotes] = useState<Record<string, string>>({});
  const [providerAgreed, setProviderAgreed] = useState<Record<string, boolean>>({});
  const [reviewNotes, setReviewNotes] = useState<Record<string, string>>({});
  const [busyId, setBusyId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    const [servicesResult, termsResult] = await Promise.all([
      supabase.from('provider_services').select(`
        id, provider_id, category_id, base_price_minor, pricing_model, price_approval_status, price_review_note,
        providers(profiles(full_name, phone)), service_categories(name)
      `).order('category_id', { ascending: true }),
      supabase.from('provider_commission_terms').select('id, provider_id, category_id, commission_rate_bps, status, terms_note, provider_agreed_at').in('status', ['draft', 'active']).order('created_at', { ascending: false }),
    ]);
    if (servicesResult.error || termsResult.error) {
      setError(servicesResult.error?.message || termsResult.error?.message || 'Unable to load commercial terms.');
      setRows([]);
      setTerms([]);
    } else {
      setRows((servicesResult.data || []) as unknown as CommercialRow[]);
      setTerms((termsResult.data || []) as TermRow[]);
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    const handle = window.setTimeout(() => { void load(); }, 0);
    return () => window.clearTimeout(handle);
  }, [load]);

  const saveCommission = async (row: CommercialRow) => {
    const key = row.id;
    const percent = Number(rates[key]);
    if (!Number.isFinite(percent) || percent < 0 || percent > 100) {
      setError('Enter a commission percentage from 0 to 100.');
      return;
    }
    if (providerAgreed[key] && (notes[key] || '').trim().length < 5) {
      setError('Record how and when the provider agreed before activating a rate.');
      return;
    }
    setBusyId(key); setError(null); setMessage(null);
    const { error: saveError } = await supabase.rpc('admin_record_provider_commission_terms', {
      p_provider_id: row.provider_id,
      p_category_id: row.category_id,
      p_commission_rate_bps: Math.round(percent * 100),
      p_provider_agreed: Boolean(providerAgreed[key]),
      p_terms_note: (notes[key] || '').trim() || null,
    });
    if (saveError) setError(saveError.message);
    else {
      setMessage(providerAgreed[key]
        ? 'Commission agreement activated. The previous active term, if any, was superseded.'
        : 'Draft commission proposal saved. It is not active and must not be charged.');
      await load();
      onActionComplete();
    }
    setBusyId(null);
  };

  const reviewFixedPrice = async (row: CommercialRow, decision: 'approved' | 'rejected') => {
    const note = (reviewNotes[row.id] || '').trim();
    if (note.length < 5) {
      setError('Add a short review note (at least 5 characters) before deciding a fixed price.');
      return;
    }
    setBusyId(row.id); setError(null); setMessage(null);
    const { data: userResult, error: userError } = await supabase.auth.getUser();
    if (userError || !userResult.user) {
      setError(userError?.message || 'Admin session is unavailable.');
      setBusyId(null);
      return;
    }
    const { error: updateError } = await supabase.from('provider_services').update({
      price_approval_status: decision,
      price_reviewed_by: userResult.user.id,
      price_reviewed_at: new Date().toISOString(),
      price_review_note: note,
    }).eq('id', row.id).eq('price_approval_status', 'pending');
    if (updateError) setError(updateError.message);
    else {
      setMessage(decision === 'approved' ? 'Fixed price approved and customer-visible.' : 'Fixed price proposal rejected.');
      await load();
      onActionComplete();
    }
    setBusyId(null);
  };

  const currentTerm = (row: CommercialRow) => terms.find((term) => term.provider_id === row.provider_id && term.category_id === row.category_id && term.status === 'active');
  const providerName = (row: CommercialRow) => {
    const provider = first(row.providers);
    const profile = first(provider?.profiles);
    return profile?.full_name || 'Service partner';
  };
  const categoryName = (row: CommercialRow) => first(row.service_categories)?.name || 'Service';

  return (
    <section className="space-y-5">
      <div className="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-amber-700">Kwick · Commercial controls</p>
          <h2 className="mt-1 text-xl font-bold text-zinc-950">Provider pricing & commission</h2>
          <p className="mt-1 max-w-3xl text-sm text-zinc-600">Provider prices and Kwick commission are separate agreements. A provider&apos;s fixed price is hidden from customers until approved. A commission rate stays draft until provider agreement is explicitly recorded.</p>
        </div>
        <button onClick={() => void load()} disabled={loading} className="inline-flex items-center gap-2 rounded-lg border border-zinc-300 bg-white px-3 py-2 text-xs font-semibold text-zinc-700 hover:bg-zinc-50 disabled:opacity-50">
          <RefreshCw className={`h-3.5 w-3.5 ${loading ? 'animate-spin' : ''}`} /> Refresh
        </button>
      </div>

      <div className="grid gap-3 sm:grid-cols-3">
        <div className="rounded-xl border border-zinc-200 bg-white p-4"><div className="flex items-center gap-2 text-zinc-500"><CircleDollarSign className="h-4 w-4"/><span className="text-xs font-medium">Provider price</span></div><p className="mt-2 text-sm font-semibold text-zinc-900">Provider quote or approved fixed price</p></div>
        <div className="rounded-xl border border-zinc-200 bg-white p-4"><div className="flex items-center gap-2 text-zinc-500"><Percent className="h-4 w-4"/><span className="text-xs font-medium">Platform commission</span></div><p className="mt-2 text-sm font-semibold text-zinc-900">Negotiated per provider and trade</p></div>
        <div className="rounded-xl border border-zinc-200 bg-white p-4"><div className="flex items-center gap-2 text-zinc-500"><ShieldCheck className="h-4 w-4"/><span className="text-xs font-medium">Partner subscription</span></div><p className="mt-2 text-sm font-semibold text-zinc-900">No monthly fee during the pilot</p></div>
      </div>

      {error && <div role="alert" className="rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800">{error}</div>}
      {message && <div role="status" className="rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">{message}</div>}
      {loading ? <div className="rounded-xl border border-zinc-200 bg-white p-8 text-center text-sm text-zinc-500">Loading live provider pricing…</div> : rows.length === 0 ? <div className="rounded-xl border border-zinc-200 bg-white p-8 text-center text-sm text-zinc-500">No provider services are configured yet. No prices or commission rates are assumed.</div> : (
        <div className="space-y-4">
          {rows.map((row) => {
            const term = currentTerm(row);
            const pendingPrice = row.pricing_model === 'agreed_fixed' && row.price_approval_status === 'pending';
            return <article key={row.id} className="rounded-xl border border-zinc-200 bg-white p-4 shadow-xs sm:p-5">
              <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                <div>
                  <h3 className="text-sm font-bold text-zinc-950">{providerName(row)} · {categoryName(row)}</h3>
                  <p className="mt-1 text-xs text-zinc-500">{row.pricing_model === 'agreed_fixed' ? `Fixed price: ₹${((row.base_price_minor || 0) / 100).toFixed(2)}` : 'Provider quotes after assessing the job'}</p>
                  <p className="mt-1 text-xs text-zinc-500">Price approval: <span className="font-semibold capitalize">{row.price_approval_status.replaceAll('_', ' ')}</span></p>
                  {term ? <p className="mt-1 text-xs text-emerald-700">Active commission: {(term.commission_rate_bps / 100).toFixed(2)}% · provider agreement recorded</p> : <p className="mt-1 text-xs text-amber-700">No active commission agreement</p>}
                </div>
                {pendingPrice && <span className="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2.5 py-1 text-[11px] font-semibold text-amber-800"><ShieldCheck className="h-3.5 w-3.5"/> Fixed price review required</span>}
              </div>

              {pendingPrice && <div className="mt-4 rounded-lg border border-amber-200 bg-amber-50/60 p-3">
                <label className="block text-xs font-semibold text-zinc-800">Price review note</label>
                <textarea value={reviewNotes[row.id] || ''} onChange={(event) => setReviewNotes((old) => ({ ...old, [row.id]: event.target.value }))} rows={2} className="mt-2 w-full rounded-md border border-zinc-300 bg-white p-2 text-sm text-zinc-900 outline-none focus:border-amber-500" placeholder="Record the provider agreement / price check evidence…" />
                <div className="mt-2 flex flex-wrap gap-2">
                  <button onClick={() => void reviewFixedPrice(row, 'approved')} disabled={busyId === row.id} className="inline-flex items-center gap-1.5 rounded-md bg-[#17212B] px-3 py-2 text-xs font-semibold text-white disabled:opacity-50"><CheckCircle2 className="h-3.5 w-3.5"/> Approve fixed price</button>
                  <button onClick={() => void reviewFixedPrice(row, 'rejected')} disabled={busyId === row.id} className="inline-flex items-center gap-1.5 rounded-md border border-rose-300 bg-white px-3 py-2 text-xs font-semibold text-rose-700 disabled:opacity-50"><XCircle className="h-3.5 w-3.5"/> Reject</button>
                </div>
              </div>}

              <div className="mt-4 grid gap-3 border-t border-zinc-100 pt-4 md:grid-cols-[140px_1fr_auto] md:items-end">
                <div>
                  <label className="block text-xs font-semibold text-zinc-700">Commission (%)</label>
                  <input inputMode="decimal" value={rates[row.id] ?? (term ? (term.commission_rate_bps / 100).toFixed(2) : '')} onChange={(event) => setRates((old) => ({ ...old, [row.id]: event.target.value }))} className="mt-1 w-full rounded-md border border-zinc-300 px-3 py-2 text-sm text-zinc-900 outline-none focus:border-amber-500" placeholder="Not set" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-zinc-700">Agreement evidence / note</label>
                  <input value={notes[row.id] ?? term?.terms_note ?? ''} onChange={(event) => setNotes((old) => ({ ...old, [row.id]: event.target.value }))} className="mt-1 w-full rounded-md border border-zinc-300 px-3 py-2 text-sm text-zinc-900 outline-none focus:border-amber-500" placeholder="Provider meeting date, signed agreement reference…" />
                  <label className="mt-2 inline-flex items-center gap-2 text-xs text-zinc-600"><input type="checkbox" checked={Boolean(providerAgreed[row.id])} onChange={(event) => setProviderAgreed((old) => ({ ...old, [row.id]: event.target.checked }))} /> Provider has explicitly agreed to this rate</label>
                </div>
                <button onClick={() => void saveCommission(row)} disabled={busyId === row.id} className="rounded-md bg-[#17212B] px-4 py-2.5 text-xs font-semibold text-white hover:bg-[#354452] disabled:opacity-50">{providerAgreed[row.id] ? 'Record active agreement' : 'Save as draft'}</button>
              </div>
              <p className="mt-2 text-[11px] leading-5 text-zinc-500">Do not check the agreement box until the provider has accepted the rate. Saving a draft does not activate a commission. This screen records terms; it does not collect money or calculate payouts.</p>
            </article>;
          })}
        </div>
      )}
    </section>
  );
}
