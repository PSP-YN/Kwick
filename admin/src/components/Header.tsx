'use client';

import React from 'react';
import { ShieldCheck, MapPin, Wrench, RefreshCw } from 'lucide-react';

interface HeaderProps {
  activeTab: 'overview' | 'dispatch' | 'providers' | 'disputes';
  setActiveTab: (tab: 'overview' | 'dispatch' | 'providers' | 'disputes') => void;
  onRefresh: () => void;
  isRefreshing: boolean;
}

export default function Header({
  activeTab,
  setActiveTab,
  onRefresh,
  isRefreshing,
}: HeaderProps) {
  return (
    <header className="border-b border-zinc-200 bg-white sticky top-0 z-30 shadow-xs">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Logo & Pilot Area Badge */}
          <div className="flex items-center space-x-4">
            <div className="flex items-center space-x-2">
              <div className="w-9 h-9 bg-emerald-600 rounded-lg flex items-center justify-center text-white font-bold text-lg shadow-sm">
                <Wrench className="w-5 h-5 text-white" />
              </div>
              <div>
                <span className="text-xl font-bold tracking-tight text-zinc-900">
                  NexHelp
                </span>
                <span className="ml-1 text-xs font-semibold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200">
                  Ops Console
                </span>
              </div>
            </div>

            <div className="hidden md:flex items-center space-x-1.5 px-3 py-1 rounded-md bg-zinc-100 text-xs font-medium text-zinc-700">
              <MapPin className="w-3.5 h-3.5 text-emerald-600" />
              <span>Pilot Zone: Bengaluru South (HSR / Koramangala 560102)</span>
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
                <p className="text-xs font-semibold text-zinc-900">Lead Dispatcher</p>
                <div className="flex items-center space-x-1">
                  <ShieldCheck className="w-3 h-3 text-emerald-600" />
                  <span className="text-[10px] text-zinc-500 font-mono">admin_role</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Tab Navigation */}
        <nav className="flex space-x-1 sm:space-x-4 border-t border-zinc-100 pt-2 pb-1 overflow-x-auto">
          {[
            { id: 'overview', label: 'Operations Overview' },
            { id: 'dispatch', label: 'Manual Dispatch Queue' },
            { id: 'providers', label: 'Provider Verifications' },
            { id: 'disputes', label: 'Disputes & Overrides' },
          ].map((tab) => {
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as 'overview' | 'dispatch' | 'providers' | 'disputes')}
                className={`px-3 py-2 text-xs sm:text-sm font-medium rounded-t-md transition whitespace-nowrap border-b-2 ${
                  isActive
                    ? 'border-emerald-600 text-emerald-700 bg-emerald-50/50'
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
