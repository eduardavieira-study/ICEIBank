import React from 'react';
import { Link } from 'react-router-dom';
import { RefreshCw, Banknote, Clock, Shield, ShieldPlus, ArrowRight, Wallet } from 'lucide-react';
import { useApp } from '../../context/AppContext';

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

function StudentOverview() {
  const { nomeAluno, idConta, dadosConta, loadingConta, carregarDadosConta, extrato } = useApp();
  const recentes = [...extrato]
    .sort((a, b) => new Date(b.dataHora) - new Date(a.dataHora))
    .slice(0, 3);

  return (
    <div className="space-y-6">
      <div className="card p-6 relative overflow-hidden">
        <div className="absolute -bottom-12 -right-12 w-56 h-56 rounded-full bg-brand-gradient opacity-[0.16] blur-2xl pointer-events-none" />

        <div className="flex justify-between items-start mb-6 relative">
          <div>
            <span className="text-[11px] uppercase font-bold text-muted tracking-wider">Conta Ativa</span>
            <h2 className="text-xl font-display font-bold mt-0.5">{nomeAluno}</h2>
            <p className="text-xs text-muted mt-0.5">ID da Conta: #{idConta} • Agência {idConta % 3}</p>
          </div>
          <button
            onClick={carregarDadosConta}
            disabled={loadingConta}
            className="p-2 rounded-md surface-alt border hover:border-primary-400/50 transition"
            title="Atualizar Dados"
          >
            <RefreshCw size={15} className={loadingConta ? 'animate-spin text-primary-500' : 'text-muted'} />
          </button>
        </div>

        <div className="flex items-center justify-between gap-4 relative">
          <div>
            <span className="text-xs font-semibold text-muted">Saldo Disponível</span>
            <p className="text-4xl font-display font-extrabold mt-1 tracking-tight">
              R$ {dadosConta ? dadosConta.saldo.toFixed(2) : '0,00'}
            </p>
          </div>
          <span className="icon-tile w-12 h-12 bg-secondary-300/15 dark:bg-primary-500/10 shrink-0">
            <Wallet size={20} className="text-secondary-500 dark:text-primary-300" />
          </span>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <Link to="/app/movimentacoes" className="card p-4 flex items-center gap-3 hover:border-primary-400/50 transition">
          <span className="icon-tile bg-accent-500/10">
            <Banknote size={16} className="text-accent-600 dark:text-accent-400" />
          </span>
          <span className="text-sm font-semibold">Movimentações e Transferências</span>
        </Link>
        <Link to="/app/historico" className="card p-4 flex items-center gap-3 hover:border-primary-400/50 transition">
          <span className="icon-tile bg-secondary-500/10">
            <Clock size={16} className="text-secondary-500" />
          </span>
          <span className="text-sm font-semibold">Histórico</span>
        </Link>
      </div>

      <div className="card p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-sm font-bold">Últimas movimentações</h3>
          <Link to="/app/historico" className="text-xs font-semibold text-primary-600 dark:text-primary-300 flex items-center gap-1">
            Ver tudo <ArrowRight size={12} />
          </Link>
        </div>

        {recentes.length === 0 ? (
          <div className="text-center py-10 text-muted text-xs">Nenhuma transação registrada.</div>
        ) : (
          <div className="space-y-2">
            {recentes.map((evento, idx) => (
              <div key={idx} className="flex justify-between items-center text-xs py-2 border-b last:border-0" style={{ borderColor: 'rgb(var(--border))' }}>
                <span className="font-medium text-muted">{evento.tipo.replace(/_/g, ' ')}</span>
                <span className="text-[11px] text-muted">{new Date(evento.dataHora).toLocaleString('pt-BR')}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function AdminOverview() {
  const {
    portaAgencia,
    newAccountId,
    setNewAccountId,
    newAccountName,
    setNewAccountName,
    newAccountBalance,
    setNewAccountBalance,
    handleCriarConta,
  } = useApp();

  return (
    <div className="space-y-6">
      <div className="card p-6">
        <h2 className="text-lg font-display font-bold mb-2 flex items-center gap-2.5">
          <span className="icon-tile bg-primary-500/10">
            <Shield size={16} className="text-primary-600 dark:text-primary-300" />
          </span>
          Painel Administrativo do Sistema
        </h2>
        <p className="text-sm text-muted">
          Agência selecionada na porta <span className="font-semibold">{portaAgencia}</span>. Crie contas de alunos associando-as à partição correta de cada agência.
        </p>
      </div>

      <div className="card p-6 lg:p-8 max-w-5xl">
        <h3 className="text-sm font-bold mb-2 flex items-center gap-2">
          <span className="icon-tile bg-primary-500/10">
            <ShieldPlus size={16} className="text-primary-600 dark:text-primary-300" />
          </span>
          Cadastrar Nova Conta de Aluno
        </h3>
        <p className="text-xs text-muted mb-6 leading-relaxed">
          O ID da conta deve seguir a regra de partição da agência ativa: id % 3 deve ser igual ao ID desta agência.
        </p>

        <form onSubmit={handleCriarConta} className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="block text-[11px] font-bold mb-1.5 text-muted">ID da Conta (Número)</label>
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
              className="input-base"
              required
            />
          </div>
          <div>
            <label className="block text-[11px] font-bold mb-1.5 text-muted">Nome Completo do Aluno</label>
            <input
              type="text"
              value={newAccountName}
              onChange={(e) => setNewAccountName(e.target.value)}
              placeholder="Ex: Ana"
              className="input-base"
              required
            />
          </div>
          <div>
            <label className="block text-[11px] font-bold mb-1.5 text-muted">Saldo Inicial (R$)</label>
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
              className="input-base"
            />
          </div>
          <div className="md:col-span-3 flex justify-end pt-2">
            <button type="submit" className="btn-primary px-6">
              Criar Conta
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default function Overview() {
  const { role } = useApp();
  return role === 'admin' ? <AdminOverview /> : <StudentOverview />;
}
