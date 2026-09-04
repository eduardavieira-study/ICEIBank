import React from 'react';
import { Building2 } from 'lucide-react';

export default function AgencySelector({ portaAgencia, setPortaAgencia, agencias }) {
  return (
    <div className="flex items-center gap-2 bg-puc-blue/30 px-3 py-1.5 rounded-md border border-gray-800 text-sm">
      <Building2 size={16} className="text-amber-400" />
      <span className="font-medium text-slate-50">Porta de Entrada:</span>
      <select 
        value={portaAgencia}
        onChange={(e) => setPortaAgencia(parseInt(e.target.value, 10))}
        className="bg-puc-blue/60 text-white text-xs py-0.5 px-1.5 rounded focus:outline-none border border-gray-700 cursor-pointer"
      >
        {agencias.map(ag => (
          <option key={ag.id} value={ag.porta}>{ag.nome}</option>
        ))}
      </select>
    </div>
  );
}
