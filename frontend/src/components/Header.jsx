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
    <header className="bg-puc-dark text-white border-b-4 border-amber-500 shadow-md">
      <div className="max-w-6xl mx-auto px-4 py-4 flex flex-col sm:flex-row justify-between items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="bg-amber-500 text-puc-dark p-2 rounded font-bold text-xl tracking-wider shadow">
            ICEI
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-wide">ICEIBank</h1>
            <p className="text-xs text-slate-300">Sistema Distribuído de Agências • PUC Minas</p>
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
              className="flex items-center gap-2 bg-red-800 hover:bg-red-700 text-white font-semibold text-xs py-2 px-3 rounded shadow transition"
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
