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
  handleCriarConta
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
      <div className="bg-gray-950 rounded-lg shadow-2xl border border-gray-800 p-6">
        <h2 className="text-xl font-bold text-white mb-2 flex items-center gap-2">
          <Shield className="text-amber-400" />
          Painel Administrativo do Sistema
        </h2>
        <p className="text-sm text-slate-400 mb-6">
          Agência selecionada na porta {portaAgencia}. Crie contas de alunos associando-as à partição correta de cada agência.
        </p>

        <div className="border-t border-gray-800 pt-6">
          <h3 className="text-sm font-bold text-slate-200 mb-4 flex items-center gap-2">
            <PlusCircle size={16} className="text-blue-400" />
            Cadastrar Nova Conta de Aluno
          </h3>

          <form onSubmit={handleCriarConta} className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-300 mb-1">ID da Conta (Número)</label>
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
                className="w-full text-sm border border-gray-800 bg-neutral-900/60 text-white rounded p-2 focus:outline-none focus:ring-2 focus:ring-puc-accent placeholder:text-gray-600"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-300 mb-1">Nome Completo do Aluno</label>
              <input 
                type="text" 
                value={newAccountName}
                onChange={(e) => setNewAccountName(e.target.value)}
                placeholder="Ex: Ana"
                className="w-full text-sm border border-gray-800 bg-neutral-900/60 text-white rounded p-2 focus:outline-none focus:ring-2 focus:ring-puc-accent placeholder:text-gray-600"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-300 mb-1">Saldo Inicial (R$)</label>
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
                className="w-full text-sm border border-gray-800 bg-neutral-900/60 text-white rounded p-2 focus:outline-none focus:ring-2 focus:ring-puc-accent placeholder:text-gray-600"
              />
            </div>
            <div className="md:col-span-3 flex justify-end pt-2">
              <button 
                type="submit"
                className="bg-puc-accent/80 hover:bg-puc-accent text-white font-bold py-2 px-6 rounded shadow-lg transition text-xs"
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
