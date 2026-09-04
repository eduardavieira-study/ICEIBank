import React from 'react';
import { Building2 } from 'lucide-react';

export default function AgencySelector({ portaAgencia, setPortaAgencia, agencias, isDark = true }) {
  return (
    <div className={`flex items-center gap-2 px-3 py-1.5 rounded-md border text-sm transition ${
      isDark 
        ? 'bg-puc-blue/30 border-gray-800' 
        : 'bg-puc-blue/80 border-slate-700'
    }`}>
      <Building2 size={16} className="text-amber-400 shrink-0" />
      <span className={`text-xs ${isDark ? 'font-medium text-slate-50' : 'font-semibold text-slate-200'}`}>
        Porta de Entrada:
      </span>
      <select 
        value={portaAgencia}
        onChange={(e) => setPortaAgencia(parseInt(e.target.value, 10))}
        className={`text-white text-xs py-0.5 px-1.5 rounded focus:outline-none cursor-pointer ${
          isDark 
            ? 'bg-puc-blue/60 border border-gray-700' 
            : 'bg-puc-dark border border-slate-600'
        }`}
      >
        {agencias.map(ag => (
          <option key={ag.id} value={ag.porta}>{ag.nome}</option>
        ))}
      </select>
    </div>
  );
}
