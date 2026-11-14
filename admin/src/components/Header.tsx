'use client';

import React from 'react';
import { ShieldCheck, MapPin, RefreshCw, LogOut } from 'lucide-react';

interface HeaderProps {
  activeTab: 'overview' | 'dispatch' | 'providers' | 'commercial' | 'disputes';
  setActiveTab: (tab: 'overview' | 'dispatch' | 'providers' | 'commercial' | 'disputes') => void;
  onRefresh: () => void;
  isRefreshing: boolean;
  userEmail: string;
  onSignOut: () => void;
}

export default function Header({
  activeTab,
  setActiveTab,
  onRefresh,
  isRefreshing,
  userEmail,
  onSignOut,
}: HeaderProps) {
  return (
    <header className="border-b border-zinc-200 bg-white sticky top-0 z-30 shadow-xs">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Logo & Pilot Area Badge */}
          <div className="flex items-center space-x-4">
            <div className="flex items-center space-x-2">
              <img src="/kwick-mark.png" alt="" className="h-9 w-9 object-contain" />
              <div>
                <span className="text-xl font-bold tracking-tight text-zinc-900">
                  Kwick
                </span>
                <span className="ml-1 text-xs font-semibold px-2 py-0.5 rounded-full bg-amber-50 text-amber-800 border border-amber-200">
                  Ops Console
                </span>
              </div>
            </div>

            <div className="hidden md:flex items-center space-x-1.5 px-3 py-1 rounded-md bg-zinc-100 text-xs font-medium text-zinc-700">
              <MapPin className="w-3.5 h-3.5 text-[#B97900]" />
              <span>Pilot Zone: HSR Layout · Bengaluru 560102</span>
            </div>
          </div>

          {/* Refresh & User State */}
          <div className="flex items-center space-x-3">
            <button
              onClick={onRefresh}
              disabled={isRefreshing}
              className="flex items-center space-x-1.5 text-xs font-medium px-3 py-1.5 rounded-md border border-zinc-300 text-zinc-700 hover:bg-zinc-50 transition"
              title="Refresh database state"
            >
              <RefreshCw
                className={`w-3.5 h-3.5 text-zinc-600 ${
                  isRefreshing ? 'animate-spin' : ''
                }`}
              />
              <span className="hidden sm:inline">Refresh Data</span>
            </button>

            <div className="flex items-center space-x-2 pl-3 border-l border-zinc-200">
              <div className="w-8 h-8 rounded-full bg-emerald-100 border border-emerald-300 flex items-center justify-center text-emerald-800 font-bold text-xs">
                AD
              </div>
              <div className="hidden sm:block text-left">
                <p className="max-w-[180px] truncate text-xs font-semibold text-zinc-900">{userEmail}</p>
                <div className="flex items-center space-x-1">
                  <ShieldCheck className="w-3 h-3 text-[#B97900]" />
                  <span className="text-[10px] text-zinc-500 font-mono">Verified admin session</span>
                </div>
              </div>
            </div>
            <button onClick={onSignOut} className="inline-flex items-center gap-1.5 rounded-md border border-zinc-300 px-2.5 py-1.5 text-xs font-medium text-zinc-700 hover:bg-zinc-50" title="Sign out">
              <LogOut className="h-3.5 w-3.5" /><span className="hidden sm:inline">Sign out</span>
            </button>
          </div>
        </div>

        {/* Tab Navigation */}
        <nav className="flex space-x-1 sm:space-x-4 border-t border-zinc-100 pt-2 pb-1 overflow-x-auto">
          {[
            { id: 'overview', label: 'Operations Overview' },
            { id: 'dispatch', label: 'Manual Dispatch Queue' },
            { id: 'providers', label: 'Provider Verifications' },
            { id: 'commercial', label: 'Pricing & Commission' },
            { id: 'disputes', label: 'Disputes & Overrides' },
          ].map((tab) => {
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as 'overview' | 'dispatch' | 'providers' | 'commercial' | 'disputes')}
                className={`px-3 py-2 text-xs sm:text-sm font-medium rounded-t-md transition whitespace-nowrap border-b-2 ${
                  isActive
                    ? 'border-[#F4A900] text-[#17212B] bg-amber-50/60'
                    : 'border-transparent text-zinc-600 hover:text-zinc-900 hover:border-zinc-300'
                }`}
              >
                {tab.label}
              </button>
            );
          })}
        </nav>
      </div>
    </header>
  );
}
