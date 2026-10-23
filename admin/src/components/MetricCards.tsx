'use client';

import React from 'react';
import { Clock, CheckCircle2, UserCheck, Activity } from 'lucide-react';
import { AdminMetrics } from '../types';

interface MetricCardsProps {
  metrics: AdminMetrics;
}

export default function MetricCards({ metrics }: MetricCardsProps) {
  const cards = [
    {
      title: 'Requests Awaiting Dispatch',
      value: metrics.pending_requests + metrics.matched_requests,
      subtext: 'Pilot Pincode 560102',
      icon: Clock,
      color: 'text-amber-600',
      bgColor: 'bg-amber-50',
      borderColor: 'border-amber-200',
    },
    {
      title: 'Active Jobs In Progress',
      value: metrics.active_jobs,
      subtext: 'Assigned or currently underway',
      icon: Activity,
      color: 'text-blue-600',
      bgColor: 'bg-blue-50',
      borderColor: 'border-blue-200',
    },
    {
      title: 'Verified Partners On-Field',
      value: metrics.verified_providers,
      subtext: `${metrics.pending_verifications} awaiting document audit`,
      icon: UserCheck,
      color: 'text-emerald-600',
      bgColor: 'bg-emerald-50',
      borderColor: 'border-emerald-200',
    },
    {
      title: 'Jobs Completed Today',
      value: metrics.completed_today,
      subtext: '100% verified pilot delivery',
      icon: CheckCircle2,
      color: 'text-indigo-600',
      bgColor: 'bg-indigo-50',
      borderColor: 'border-indigo-200',
    },
  ];

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
      {cards.map((card, idx) => {
        const Icon = card.icon;
        return (
          <div
            key={idx}
            className={`p-5 rounded-xl border ${card.borderColor} bg-white shadow-xs flex items-center justify-between`}
          >
            <div>
              <p className="text-xs font-medium text-zinc-500 uppercase tracking-wider">
                {card.title}
              </p>
              <p className="text-2xl sm:text-3xl font-extrabold text-zinc-900 mt-1">
                {card.value}
              </p>
              <p className="text-xs text-zinc-500 mt-1">{card.subtext}</p>
            </div>
            <div className={`p-3 rounded-lg ${card.bgColor} ${card.color}`}>
              <Icon className="w-6 h-6" />
            </div>
          </div>
        );
      })}
    </div>
  );
}
