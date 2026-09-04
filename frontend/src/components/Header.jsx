import React from 'react';
import { LogOut } from 'lucide-react';
import AgencySelector from './AgencySelector';

export default function Header({
  portaAgencia,
  setPortaAgencia,
  agencias,
  token,
  handleLogout
}) {
  return (
    <header className="bg-gray-950 text-white border-b border-gray-900 shadow-xl">
      <div className="max-w-6xl mx-auto px-4 py-4 flex flex-col sm:flex-row justify-between items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="bg-blue-950/80 border border-blue-800/30 text-white px-2.5 py-1.5 rounded-sm font-bold text-lg tracking-wider shadow">
            ICEI
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-wide text-white">ICEIBank</h1>
            <p className="text-xs text-slate-400">Sistema Distribuído de Agências • PUC Minas</p>
          </div>
        </div>

        <div className="flex items-center gap-4">
          {/* Seletor de agência de entrada */}
          <AgencySelector 
            portaAgencia={portaAgencia}
            setPortaAgencia={setPortaAgencia}
            agencias={agencias}
          />

          {token && (
            <button 
              onClick={() => handleLogout(true)}
              className="flex items-center gap-2 bg-red-950/80 hover:bg-red-900 border border-red-900 text-red-50 font-semibold text-xs py-2 px-3 rounded-lg shadow transition"
            >
              <LogOut size={14} />
              Sair
            </button>
          )}
        </div>
      </div>
    </header>
  );
}
