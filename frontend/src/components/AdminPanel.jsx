import React from 'react';
import { Shield, PlusCircle } from 'lucide-react';

export default function AdminPanel({
  portaAgencia,
  newAccountId,
  setNewAccountId,
  newAccountName,
  setNewAccountName,
  newAccountBalance,
  setNewAccountBalance,
  handleCriarConta,
  isDark = true
}) {
  const blockNegativeAndDecimals = (e) => {
    if (e.key === '-' || e.key === 'e' || e.key === '+' || e.key === '.') {
      e.preventDefault();
    }
  };

  const blockNegative = (e) => {
    if (e.key === '-' || e.key === 'e' || e.key === '+') {
      e.preventDefault();
    }
  };

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <div className={`rounded-lg shadow border p-6 transition ${
        isDark ? 'bg-gray-950 border-gray-800 shadow-2xl' : 'bg-white border-slate-200'
      }`}>
        <h2 className={`text-xl font-bold mb-2 flex items-center gap-2 ${isDark ? 'text-white' : 'text-puc-blue'}`}>
          <Shield className="text-amber-400" />
          Painel Administrativo do Sistema
        </h2>
        <p className={`text-sm mb-6 ${isDark ? 'text-slate-400' : 'text-slate-500'}`}>
          Agência selecionada na porta {portaAgencia}. Crie contas de alunos associando-as à partição correta de cada agência.
        </p>

        <div className={`border-t pt-6 ${isDark ? 'border-gray-800' : 'border-slate-100'}`}>
          <h3 className={`text-sm font-bold mb-4 flex items-center gap-2 ${isDark ? 'text-slate-200' : 'text-slate-800'}`}>
            <PlusCircle size={16} className={isDark ? 'text-blue-400' : 'text-puc-accent'} />
            Cadastrar Nova Conta de Aluno
          </h3>

          <form onSubmit={handleCriarConta} className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className={`block text-xs font-bold mb-1 ${isDark ? 'text-slate-300' : 'text-slate-700'}`}>
                ID da Conta (Número)
              </label>
              <input 
                type="number" 
                min="0"
                onWheel={(e) => e.currentTarget.blur()}
                onKeyDown={blockNegativeAndDecimals}
                value={newAccountId}
                onChange={(e) => {
                  const val = e.target.value;
                  if (val === '' || (Number(val) >= 0 && !val.includes('-'))) {
                    setNewAccountId(val);
                  }
                }}
                placeholder="Ex: 0"
                className={`w-full text-sm border rounded p-2 focus:outline-none focus:ring-2 ${
                  isDark 
                    ? 'border-gray-800 bg-neutral-900/60 text-white focus:ring-puc-accent placeholder:text-gray-600' 
                    : 'border-slate-300 bg-white text-slate-900 focus:ring-puc-blue placeholder:text-slate-400'
                }`}
                required
              />
            </div>
            <div>
              <label className={`block text-xs font-bold mb-1 ${isDark ? 'text-slate-300' : 'text-slate-700'}`}>
                Nome Completo do Aluno
              </label>
              <input 
                type="text" 
                value={newAccountName}
                onChange={(e) => setNewAccountName(e.target.value)}
                placeholder="Ex: Ana"
                className={`w-full text-sm border rounded p-2 focus:outline-none focus:ring-2 ${
                  isDark 
                    ? 'border-gray-800 bg-neutral-900/60 text-white focus:ring-puc-accent placeholder:text-gray-600' 
                    : 'border-slate-300 bg-white text-slate-900 focus:ring-puc-blue placeholder:text-slate-400'
                }`}
                required
              />
            </div>
            <div>
              <label className={`block text-xs font-bold mb-1 ${isDark ? 'text-slate-300' : 'text-slate-700'}`}>
                Saldo Inicial (R$)
              </label>
              <input 
                type="number" 
                step="0.01"
                min="0"
                onWheel={(e) => e.currentTarget.blur()}
                onKeyDown={blockNegative}
                value={newAccountBalance}
                onChange={(e) => {
                  const val = e.target.value;
                  if (val === '' || (Number(val) >= 0 && !val.includes('-'))) {
                    setNewAccountBalance(val);
                  }
                }}
                placeholder="Ex: 100.00"
                className={`w-full text-sm border rounded p-2 focus:outline-none focus:ring-2 ${
                  isDark 
                    ? 'border-gray-800 bg-neutral-900/60 text-white focus:ring-puc-accent placeholder:text-gray-600' 
                    : 'border-slate-300 bg-white text-slate-900 focus:ring-puc-blue placeholder:text-slate-400'
                }`}
              />
            </div>
            <div className="md:col-span-3 flex justify-end pt-2">
              <button 
                type="submit"
                className={`text-white font-bold py-2 px-6 rounded shadow transition text-xs ${
                  isDark ? 'bg-puc-accent/80 hover:bg-puc-accent' : 'bg-puc-blue hover:bg-puc-accent'
                }`}
              >
                Criar Conta
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
