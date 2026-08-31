import React from 'react';
import { Building2 } from 'lucide-react';

export default function AgencySelector({ portaAgencia, setPortaAgencia, agencias }) {
  return (
    <div className="flex items-center gap-2 bg-puc-blue/80 px-3 py-1.5 rounded-lg border border-slate-700 text-sm">
      <Building2 size={16} className="text-amber-400" />
      <span className="font-semibold text-slate-200">Porta de Entrada:</span>
      <select 
        value={portaAgencia}
        onChange={(e) => setPortaAgencia(parseInt(e.target.value, 10))}
        className="bg-puc-dark text-white text-xs py-0.5 px-1.5 rounded focus:outline-none border border-slate-600 cursor-pointer"
      >
        {agencias.map(ag => (
          <option key={ag.id} value={ag.porta}>{ag.nome}</option>
        ))}
      </select>
    </div>
  );
}
