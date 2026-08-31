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
  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <div className="bg-white rounded-lg shadow border border-slate-200 p-6">
        <h2 className="text-xl font-bold text-puc-blue mb-2 flex items-center gap-2">
          <Shield className="text-amber-500" />
          Painel Administrativo do Sistema
        </h2>
        <p className="text-sm text-slate-500 mb-6">Agência selecionada na porta {portaAgencia}. Crie contas de alunos associando-as à partição correta de cada agência.</p>

        <div className="border-t border-slate-100 pt-6">
          <h3 className="text-sm font-bold text-slate-800 mb-4 flex items-center gap-2">
            <PlusCircle size={16} className="text-puc-accent" />
            Cadastrar Nova Conta de Aluno
          </h3>

          <form onSubmit={handleCriarConta} className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">ID da Conta (Número)</label>
              <input 
                type="number" 
                value={newAccountId}
                onChange={(e) => setNewAccountId(e.target.value)}
                placeholder="Ex: 0"
                className="w-full text-sm border border-slate-300 rounded p-2 focus:outline-none focus:ring-2 focus:ring-puc-blue"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Nome Completo do Aluno</label>
              <input 
                type="text" 
                value={newAccountName}
                onChange={(e) => setNewAccountName(e.target.value)}
                placeholder="Ex: Ana"
                className="w-full text-sm border border-slate-300 rounded p-2 focus:outline-none focus:ring-2 focus:ring-puc-blue"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Saldo Inicial (R$)</label>
              <input 
                type="number" 
                step="0.01"
                value={newAccountBalance}
                onChange={(e) => setNewAccountBalance(e.target.value)}
                placeholder="Ex: 100.00"
                className="w-full text-sm border border-slate-300 rounded p-2 focus:outline-none focus:ring-2 focus:ring-puc-blue"
              />
            </div>
            <div className="md:col-span-3 flex justify-end pt-2">
              <button 
                type="submit"
                className="bg-puc-blue hover:bg-puc-accent text-white font-bold py-2 px-6 rounded shadow transition text-xs"
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
