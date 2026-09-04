import React from 'react';
import { LogOut, Sun, Moon } from 'lucide-react';
import AgencySelector from './AgencySelector';

export default function Header({
  portaAgencia,
  setPortaAgencia,
  agencias,
  token,
  handleLogout,
  isDark = true,
  toggleTheme
}) {
  return (
    <header className={`${isDark ? 'bg-gray-950 text-white border-b border-gray-900' : 'bg-puc-dark text-white border-b-4 border-amber-500'} shadow-md transition-colors duration-200`}>
      <div className="max-w-6xl mx-auto px-4 py-4 flex flex-col sm:flex-row justify-between items-center gap-4">
        <div className="flex items-center gap-3">
          <div className={`${isDark ? 'bg-blue-950 text-white p-2' : 'bg-amber-500 text-puc-dark p-2'} rounded font-bold text-xl tracking-wider shadow`}>
            ICEI
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-wide text-white">ICEIBank</h1>
            <p className="text-xs text-slate-300">Sistema Distribuído de Agências • PUC Minas</p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          {/* Seletor de agência de entrada */}
          <AgencySelector 
            portaAgencia={portaAgencia}
            setPortaAgencia={setPortaAgencia}
            agencias={agencias}
            isDark={isDark}
          />

          {/* Botão de alternância de Tema (Claro / Escuro) */}
          <button
            type="button"
            onClick={toggleTheme}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-md text-xs font-semibold border transition ${
              isDark 
                ? 'bg-gray-900 text-amber-300 border-gray-800 hover:bg-gray-800 hover:text-amber-200' 
                : 'bg-puc-blue/80 text-amber-300 border-slate-700 hover:bg-puc-blue'
            }`}
            title={isDark ? "Ativar Modo Claro" : "Ativar Modo Escuro"}
          >
            {isDark ? <Sun size={15} className="text-amber-400 shrink-0" /> : <Moon size={15} className="text-amber-300 shrink-0" />}
            <span className="hidden sm:inline">{isDark ? "Claro" : "Escuro"}</span>
          </button>

          {token && (
            <button 
              onClick={() => handleLogout(true)}
              className="flex items-center gap-2 bg-red-900/90 border border-red-800 hover:bg-red-700 text-white font-semibold text-xs py-2 px-3 rounded shadow transition"
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
