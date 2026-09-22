import React from 'react';
import { Wifi } from 'lucide-react';
import Logo from './Logo';

export default function BankCard({ className = '' }) {
  return (
    <div className={`relative overflow-hidden aspect-[1.6/1] w-full max-w-sm rounded-lg bg-brand-gradient text-white p-6 flex flex-col justify-between shadow-lg ${className}`}>
      <div className="noise-overlay" />

      <div className="relative flex items-start justify-between">
        <Logo inverted className="text-base" />
        <Wifi size={20} className="rotate-90 text-white/80" />
      </div>

      <div className="relative w-10 h-7 rounded-[3px] bg-white/25 border border-white/30" />

      <div className="relative">
        <p className="font-mono text-lg tracking-[0.2em] mb-4">•••• •••• •••• 3491</p>
        <div className="flex items-end justify-between">
          <div>
            <p className="text-[9px] uppercase tracking-wider text-white/60">Conta digital</p>
            <p className="text-xs font-semibold">Titular da conta</p>
          </div>
          <div className="w-8 h-8 rounded-full bg-white/15 flex items-center justify-center text-[10px] font-bold">
            IB
          </div>
        </div>
      </div>
    </div>
  );
}
