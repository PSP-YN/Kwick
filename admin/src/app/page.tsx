'use client';

import React, { useCallback, useEffect, useState } from 'react';
import Header from '../components/Header';
import MetricCards from '../components/MetricCards';
import DispatchQueue from '../components/DispatchQueue';
import ProviderVerification from '../components/ProviderVerification';
import DisputeResolution from '../components/DisputeResolution';
import CommercialTerms from '../components/CommercialTerms';
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
import { isSupabaseConfigured, supabase } from '../lib/supabase';

function AdminDashboard({ userEmail, onSignOut }: { userEmail: string; onSignOut: () => void }) {
  const [activeTab, setActiveTab] = useState<'overview' | 'dispatch' | 'providers' | 'commercial' | 'disputes'>('overview');
  const [metrics, setMetrics] = useState<AdminMetrics>({
    pending_requests: 0,
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
  const [loadError, setLoadError] = useState<string | null>(null);

  const loadData = async () => {
    setIsRefreshing(true);
    setLoadError(null);
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
      const message = err instanceof Error ? err.message : 'Unable to load operational data.';
      setLoadError(message);
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
        if (isMounted) {
          setLoadError(err instanceof Error ? err.message : 'Unable to load operational data.');
          setLoading(false);
        }
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
        userEmail={userEmail}
        onSignOut={onSignOut}
      />

      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {loading ? (
          <div className="flex flex-col items-center justify-center py-20 space-y-3">
            <div className="w-8 h-8 border-3 border-emerald-600 border-t-transparent rounded-full animate-spin" />
            <p className="text-xs text-zinc-500 font-medium">Loading Operations Console...</p>
          </div>
        ) : (
          <>
            {loadError && (
              <div role="alert" className="mb-6 rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800">
                Live database data could not be loaded: {loadError}
              </div>
            )}

            {/* Top KPI Cards */}
            <MetricCards metrics={metrics} />

            {/* Tab Views */}
            {activeTab === 'overview' && (
              <div className="space-y-8">
                {/* Pilot Region Status Banner */}
                <div className="bg-gradient-to-r from-emerald-800 to-teal-900 rounded-2xl p-6 text-white shadow-md flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                  <div className="space-y-1">
                    <div className="flex items-center space-x-2">
                      <MapPin className="w-5 h-5 text-[#F4A900]" />
                      <h2 className="text-lg font-bold">HSR Layout Pilot · 560102</h2>
                    </div>
                    <p className="text-xs text-zinc-200 max-w-xl">
                      Initial service zone: HSR Layout, 560102. Additional Bengaluru neighbourhoods open only after partner coverage is verified. Financial amounts are stored in integer paise; fixed prices require review.
                    </p>
                  </div>
                  <div className="flex items-center space-x-3 bg-white/10 px-4 py-2 rounded-xl backdrop-blur-xs">
                    <ShieldCheck className="w-6 h-6 text-[#F4A900]" />
                    <div>
                      <p className="text-[11px] text-amber-200 uppercase font-semibold">Security State</p>
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
                        className="text-xs text-[#B97900] font-semibold hover:underline"
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
                                  ? 'bg-[#FFF3D6] text-[#8A5200]'
                                  : 'bg-amber-100 text-amber-800'
                              }`}
                            >
                              {req.status.replace('_', ' ')}
                            </span>
                            <p className="text-[11px] font-medium text-zinc-800 mt-0.5">
                              {req.estimated_price_paise === null ? 'Not quoted' : `₹${(req.estimated_price_paise / 100).toLocaleString('en-IN')}`}
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
                        className="text-xs text-[#B97900] font-semibold hover:underline"
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

            {activeTab === 'commercial' && (
              <CommercialTerms onActionComplete={loadData} />
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
          Kwick Operations Platform • 560102 Pilot Zone • PostgreSQL 17 + RLS • Pre-launch
        </div>
      </footer>
    </div>
  );
}


type AuthStatus = 'checking' | 'signed_out' | 'authorized' | 'denied' | 'configuration_error' | 'mfa_required' | 'mfa_enroll';

export default function AdminPage() {
  const [authStatus, setAuthStatus] = useState<AuthStatus>(isSupabaseConfigured ? 'checking' : 'configuration_error');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [userEmail, setUserEmail] = useState('');
  const [authError, setAuthError] = useState<string | null>(isSupabaseConfigured ? null : 'Configure NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY to connect the operations console.');
  const [isSigningIn, setIsSigningIn] = useState(false);
  const [mfaFactorId, setMfaFactorId] = useState('');
  const [mfaQrCode, setMfaQrCode] = useState<string | null>(null);
  const [mfaSecret, setMfaSecret] = useState<string | null>(null);
  const [mfaCode, setMfaCode] = useState('');
  const [isMfaBusy, setIsMfaBusy] = useState(false);

  const requireAdminMfa = useCallback(async (): Promise<boolean> => {
    const { data: assurance, error: assuranceError } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel();
    if (assuranceError) throw assuranceError;
    if (assurance.currentLevel === 'aal2') return true;

    const { data: factors, error: factorsError } = await supabase.auth.mfa.listFactors();
    if (factorsError) throw factorsError;
    const verifiedTotp = factors.totp.find((factor) => factor.status === 'verified');
    if (verifiedTotp) {
      setMfaFactorId(verifiedTotp.id);
      setMfaQrCode(null);
      setMfaSecret(null);
      setAuthStatus('mfa_required');
    } else {
      const allFactors = factors.all as Array<{ id: string; factor_type: string; status: string }>;
      const pendingTotp = allFactors.find(
        (factor) => factor.factor_type === 'totp' && factor.status === 'unverified',
      );
      setMfaFactorId(pendingTotp?.id ?? '');
      setMfaQrCode(null);
      setMfaSecret(null);
      setAuthStatus('mfa_enroll');
      if (pendingTotp) setAuthError('An incomplete authenticator setup already exists. Contact the project owner to reset the pending factor before retrying enrollment.');
    }
    return false;
  }, []);

  useEffect(() => {
    let active = true;
    const verifySession = async (session: import('@supabase/supabase-js').Session | null) => {
      if (!active) return;
      if (!session) {
        setAuthStatus('signed_out');
        setUserEmail('');
        return;
      }
      const { data, error } = await supabase
        .from('user_roles')
        .select('role')
        .eq('user_id', session.user.id);
      if (!active) return;
      if (error) {
        setAuthError(error.message);
        setAuthStatus('denied');
        return;
      }
      const allowed = data?.some((entry) => entry.role === 'admin' || entry.role === 'super_admin');
      if (!allowed) {
        setAuthError('This account does not have Kwick administrator privileges.');
        setAuthStatus('denied');
        return;
      }
      setUserEmail(session.user.email || session.user.phone || 'Authorized administrator');
      try {
        const mfaSatisfied = await requireAdminMfa();
        if (!active) return;
        setAuthError(mfaSatisfied ? null : 'Administrator access requires a verified authenticator app code.');
        if (mfaSatisfied) setAuthStatus('authorized');
      } catch (mfaError) {
        if (!active) return;
        setAuthError(mfaError instanceof Error ? mfaError.message : 'Unable to verify administrator MFA.');
        setAuthStatus('denied');
      }
    };

    if (!isSupabaseConfigured) {
      return () => { active = false; };
    }

    supabase.auth.getSession().then(({ data, error }) => {
      if (error) {
        if (active) {
          setAuthError(error.message);
          setAuthStatus('signed_out');
        }
        return;
      }
      void verifySession(data.session);
    });

    const { data: authListener } = supabase.auth.onAuthStateChange((_event, session) => {
      void verifySession(session);
    });
    return () => {
      active = false;
      authListener.subscription.unsubscribe();
    };
  }, [requireAdminMfa]);

  const handleSignIn = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setIsSigningIn(true);
    setAuthError(null);
    const { data, error } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
    setIsSigningIn(false);
    if (error) {
      setAuthError(error.message);
      return;
    }
    if (!data.session) {
      setAuthError('Authentication succeeded without an active session. Please retry.');
      return;
    }
    const { data: roles, error: roleError } = await supabase
      .from('user_roles')
      .select('role')
      .eq('user_id', data.session.user.id);
    if (roleError) {
      setAuthError(roleError.message);
      return;
    }
    if (!roles?.some((entry) => entry.role === 'admin' || entry.role === 'super_admin')) {
      await supabase.auth.signOut();
      setAuthError('This account does not have Kwick administrator privileges.');
      setAuthStatus('signed_out');
      return;
    }
    setUserEmail(data.session.user.email || data.session.user.phone || 'Authorized administrator');
    try {
      const mfaSatisfied = await requireAdminMfa();
      setAuthError(mfaSatisfied ? null : 'Administrator access requires a verified authenticator app code.');
      if (mfaSatisfied) setAuthStatus('authorized');
    } catch (mfaError) {
      setAuthError(mfaError instanceof Error ? mfaError.message : 'Unable to verify administrator MFA.');
      setAuthStatus('denied');
    }
  };

  const handleMfaEnroll = async () => {
    setIsMfaBusy(true);
    setAuthError(null);
    try {
      const { data, error } = await supabase.auth.mfa.enroll({
        factorType: 'totp',
        friendlyName: 'Kwick Operations',
      });
      if (error) throw error;
      setMfaFactorId(data.id);
      setMfaQrCode(data.totp.qr_code);
      setMfaSecret(data.totp.secret);
      setMfaCode('');
      setAuthStatus('mfa_enroll');
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Unable to start authenticator setup.');
    } finally {
      setIsMfaBusy(false);
    }
  };

  const handleMfaVerify = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!mfaFactorId || !/^\d{6}$/.test(mfaCode.trim())) {
      setAuthError('Enter the current six-digit code from your authenticator app.');
      return;
    }
    setIsMfaBusy(true);
    setAuthError(null);
    try {
      const { data: challenge, error: challengeError } = await supabase.auth.mfa.challenge({ factorId: mfaFactorId });
      if (challengeError) throw challengeError;
      const { error: verifyError } = await supabase.auth.mfa.verify({
        factorId: mfaFactorId,
        challengeId: challenge.id,
        code: mfaCode.trim(),
      });
      if (verifyError) throw verifyError;
      const { data: assurance, error: assuranceError } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel();
      if (assuranceError) throw assuranceError;
      if (assurance.currentLevel !== 'aal2') throw new Error('The session has not reached MFA assurance level AAL2.');
      setMfaQrCode(null);
      setMfaSecret(null);
      setMfaCode('');
      setAuthError(null);
      setAuthStatus('authorized');
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Authenticator verification failed.');
    } finally {
      setIsMfaBusy(false);
    }
  };

  const handleSignOut = async () => {
    await supabase.auth.signOut();
    setAuthStatus('signed_out');
    setUserEmail('');
    setMfaFactorId('');
    setMfaQrCode(null);
    setMfaSecret(null);
    setMfaCode('');
  };

  if (authStatus === 'authorized') {
    return <AdminDashboard userEmail={userEmail} onSignOut={() => void handleSignOut()} />;
  }

  const heading = authStatus === 'configuration_error'
    ? 'Operations connection required'
    : authStatus === 'denied'
      ? 'Administrator access denied'
      : authStatus === 'checking'
        ? 'Checking administrator access'
        : authStatus === 'mfa_required'
          ? 'Verify administrator MFA'
          : authStatus === 'mfa_enroll'
            ? 'Set up administrator MFA'
            : 'Kwick Operations';

  return (
    <main className="min-h-screen bg-zinc-950 flex items-center justify-center px-4 py-12">
      <section className="w-full max-w-md rounded-2xl border border-zinc-800 bg-zinc-900 p-8 shadow-2xl">
        <div className="mb-8">
          <div className="mb-5 flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-600 text-white">
            <ShieldCheck className="h-6 w-6" />
          </div>
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-emerald-400">Kwick · Operations</p>
          <h1 className="mt-2 text-2xl font-bold text-white">{heading}</h1>
          <p className="mt-2 text-sm text-zinc-400">Sign in with an account that has an admin or super-admin role.</p>
        </div>
        {authError && <div role="alert" className="mb-5 rounded-lg border border-rose-800 bg-rose-950/60 p-3 text-sm text-rose-200">{authError}</div>}
        {authStatus === 'checking' ? (
          <p className="text-sm text-zinc-400">Verifying your session…</p>
        ) : authStatus === 'configuration_error' ? (
          <p className="text-sm text-zinc-300">The dashboard is not configured to connect to a Supabase project. Set the required public environment variables in your deployment.</p>
        ) : authStatus === 'denied' ? (
          <button onClick={() => void handleSignOut()} className="w-full rounded-lg bg-zinc-700 px-4 py-3 text-sm font-semibold text-white hover:bg-zinc-600">Sign out</button>
        ) : authStatus === 'mfa_required' || authStatus === 'mfa_enroll' ? (
          <div className="space-y-4">
            <p className="text-sm text-zinc-300">Administrator access is protected by TOTP multi-factor authentication. Set up an authenticator app once, then enter its six-digit code at each sign-in.</p>
            {authStatus === 'mfa_enroll' && !mfaFactorId && (
              <button type="button" disabled={isMfaBusy} onClick={() => void handleMfaEnroll()} className="w-full rounded-lg bg-emerald-600 px-4 py-3 text-sm font-semibold text-white disabled:opacity-60">
                {isMfaBusy ? 'Preparing authenticator…' : 'Set up authenticator app'}
              </button>
            )}
            {mfaQrCode && (
              <div className="rounded-lg bg-white p-4 text-center">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={mfaQrCode} alt="Kwick Operations authenticator QR code" className="mx-auto h-52 w-52" />
                <p className="mt-3 text-xs text-zinc-700">Scan with an authenticator app. If scanning is unavailable, enter this secret manually:</p>
                <code className="mt-2 block break-all text-xs text-zinc-900">{mfaSecret}</code>
              </div>
            )}
            {mfaFactorId && (authStatus === 'mfa_required' || mfaQrCode) && (
              <form onSubmit={handleMfaVerify} className="space-y-3">
                <label className="block text-sm font-medium text-zinc-300">
                  Authenticator code
                  <input required inputMode="numeric" autoComplete="one-time-code" maxLength={6} value={mfaCode} onChange={(event) => setMfaCode(event.target.value.replace(/\D/g, '').slice(0, 6))} className="mt-1.5 w-full rounded-lg border border-zinc-700 bg-zinc-950 px-3 py-3 text-center text-lg tracking-[0.4em] text-white outline-none focus:border-emerald-500" />
                </label>
                <button disabled={isMfaBusy} type="submit" className="w-full rounded-lg bg-emerald-600 px-4 py-3 text-sm font-semibold text-white disabled:opacity-60">
                  {isMfaBusy ? 'Verifying…' : 'Verify and continue'}
                </button>
              </form>
            )}
            {authStatus === 'mfa_enroll' && mfaFactorId && !mfaQrCode && (
              <p className="text-sm text-amber-300">An incomplete authenticator setup already exists. Contact the project owner to reset the pending factor before trying again.</p>
            )}
            <button onClick={() => void handleSignOut()} className="w-full rounded-lg bg-zinc-700 px-4 py-3 text-sm font-semibold text-white hover:bg-zinc-600">Sign out</button>
          </div>
        ) : (
          <form onSubmit={handleSignIn} className="space-y-4">
            <label className="block text-sm font-medium text-zinc-300">
              Email
              <input required type="email" autoComplete="username" value={email} onChange={(event) => setEmail(event.target.value)} className="mt-1.5 w-full rounded-lg border border-zinc-700 bg-zinc-950 px-3 py-3 text-white outline-none focus:border-emerald-500" />
            </label>
            <label className="block text-sm font-medium text-zinc-300">
              Password
              <input required type="password" autoComplete="current-password" value={password} onChange={(event) => setPassword(event.target.value)} className="mt-1.5 w-full rounded-lg border border-zinc-700 bg-zinc-950 px-3 py-3 text-white outline-none focus:border-emerald-500" />
            </label>
            <button disabled={isSigningIn} type="submit" className="w-full rounded-lg bg-emerald-600 px-4 py-3 text-sm font-semibold text-white transition hover:bg-emerald-500 disabled:cursor-not-allowed disabled:opacity-60">
              {isSigningIn ? 'Signing in…' : 'Sign in to Operations'}
            </button>
          </form>
        )}
      </section>
    </main>
  );
}
