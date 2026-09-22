import React from 'react';
import { Building2, ChevronDown } from 'lucide-react';
import { useApp } from '../context/AppContext';

export default function AgencySelector({ compact = false }) {
  const { portaAgencia, setPortaAgencia, AGENCIAS } = useApp();

  return (
    <div className="relative inline-flex items-center gap-2 rounded-md border surface-alt px-3 py-2 text-xs">
      <Building2 size={15} className="text-secondary-500 shrink-0" />
      {!compact && <span className="font-medium text-muted hidden lg:inline">Agência:</span>}
      <select
        value={portaAgencia}
        onChange={(e) => setPortaAgencia(parseInt(e.target.value, 10))}
        className="appearance-none bg-transparent pr-5 font-semibold outline-none cursor-pointer max-w-[9.5rem] sm:max-w-none truncate"
      >
        {AGENCIAS.map((ag) => (
          <option key={ag.id} value={ag.porta} className="text-slate-900">
            {compact ? ag.nome.split(' ')[1] : ag.nome}
          </option>
        ))}
      </select>
      <ChevronDown size={13} className="absolute right-2.5 pointer-events-none text-muted" />
    </div>
  );
}
