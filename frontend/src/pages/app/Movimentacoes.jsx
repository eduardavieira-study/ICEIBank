import React from 'react';
import { Link } from 'react-router-dom';
import { PlusCircle, Coins, ArrowRightLeft, Clock, ArrowRight } from 'lucide-react';
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

export default function Movimentacoes() {
  const {
    valorDeposito,
    setValorDeposito,
    handleDeposito,
    valorSaque,
    setValorSaque,
    handleSaque,
    transferDestId,
    setTransferDestId,
    transferValor,
    setTransferValor,
    handleTransferencia,
    extrato,
  } = useApp();

  const recentes = [...extrato]
    .sort((a, b) => new Date(b.dataHora) - new Date(a.dataHora))
    .slice(0, 6);

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
      <div className="lg:col-span-2 space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="card p-6">
            <h3 className="text-sm font-bold mb-4 flex items-center gap-2">
              <span className="icon-tile bg-accent-500/10">
                <PlusCircle size={16} className="text-accent-600 dark:text-accent-400" />
              </span>
              Efetuar Depósito
            </h3>
            <form onSubmit={handleDeposito} className="space-y-3">
              <input
                type="number"
                step="0.01"
                min="0"
                onWheel={(e) => e.currentTarget.blur()}
                onKeyDown={blockNegative}
                value={valorDeposito}
                onChange={(e) => {
                  const val = e.target.value;
                  if (val === '' || (Number(val) >= 0 && !val.includes('-'))) {
                    setValorDeposito(val);
                  }
                }}
                placeholder="Valor (R$)"
                className="input-base"
                required
              />
              <button type="submit" className="btn w-full text-white bg-accent-600 hover:bg-accent-700">
                Depositar
              </button>
            </form>
          </div>

          <div className="card p-6">
            <h3 className="text-sm font-bold mb-4 flex items-center gap-2">
              <span className="icon-tile bg-secondary-500/10">
                <Coins size={16} className="text-secondary-500" />
              </span>
              Efetuar Saque
            </h3>
            <form onSubmit={handleSaque} className="space-y-3">
              <input
                type="number"
                step="0.01"
                min="0"
                onWheel={(e) => e.currentTarget.blur()}
                onKeyDown={blockNegative}
                value={valorSaque}
                onChange={(e) => {
                  const val = e.target.value;
                  if (val === '' || (Number(val) >= 0 && !val.includes('-'))) {
                    setValorSaque(val);
                  }
                }}
                placeholder="Valor (R$)"
                className="input-base"
                required
              />
              <button type="submit" className="btn w-full text-white bg-secondary-500 hover:bg-secondary-600">
                Sacar
              </button>
            </form>
          </div>
        </div>

        <div className="card p-6">
          <h3 className="text-sm font-bold mb-2 flex items-center gap-2">
            <span className="icon-tile bg-primary-500/10">
              <ArrowRightLeft size={16} className="text-primary-600 dark:text-primary-300" />
            </span>
            Realizar Transferência
          </h3>
          <p className="text-xs text-muted mb-6 leading-relaxed">
            Transferências para contas com o mesmo resto (id % 3) ocorrem localmente na mesma agência. Para restos diferentes, ocorrem entre agências via rede.
          </p>

          <form onSubmit={handleTransferencia} className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-[11px] font-bold mb-1.5 text-muted">ID da Conta de Destino</label>
              <input
                type="number"
                min="0"
                onWheel={(e) => e.currentTarget.blur()}
                onKeyDown={blockNegativeAndDecimals}
                value={transferDestId}
                onChange={(e) => {
                  const val = e.target.value;
                  if (val === '' || (Number(val) >= 0 && !val.includes('-'))) {
                    setTransferDestId(val);
                  }
                }}
                placeholder="Ex: 1"
                className="input-base"
                required
              />
            </div>
            <div>
              <label className="block text-[11px] font-bold mb-1.5 text-muted">Valor (R$)</label>
              <input
                type="number"
                step="0.01"
                min="0"
                onWheel={(e) => e.currentTarget.blur()}
                onKeyDown={blockNegative}
                value={transferValor}
                onChange={(e) => {
                  const val = e.target.value;
                  if (val === '' || (Number(val) >= 0 && !val.includes('-'))) {
                    setTransferValor(val);
                  }
                }}
                placeholder="0,00"
                className="input-base"
                required
              />
            </div>
            <div className="sm:col-span-2 flex justify-end pt-1">
              <button type="submit" className="btn-primary px-6">
                Enviar Dinheiro
              </button>
            </div>
          </form>
        </div>
      </div>

      <div className="card p-6 lg:sticky lg:top-24">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-sm font-bold flex items-center gap-2">
            <span className="icon-tile bg-secondary-500/10">
              <Clock size={16} className="text-secondary-500" />
            </span>
            Últimas movimentações
          </h3>
        </div>

        {recentes.length === 0 ? (
          <div className="text-center py-10 text-muted text-xs">Nenhuma transação registrada.</div>
        ) : (
          <div className="space-y-1">
            {recentes.map((evento, idx) => (
              <div key={idx} className="flex justify-between items-center text-xs py-2.5 border-b last:border-0" style={{ borderColor: 'rgb(var(--border))' }}>
                <span className="font-medium text-muted">{evento.tipo.replace(/_/g, ' ')}</span>
                <span className="text-[11px] text-muted shrink-0 ml-2">{new Date(evento.dataHora).toLocaleString('pt-BR')}</span>
              </div>
            ))}
          </div>
        )}

        <Link to="/app/historico" className="mt-4 text-xs font-semibold text-primary-600 dark:text-primary-300 flex items-center gap-1">
          Ver histórico completo <ArrowRight size={12} />
        </Link>
      </div>
    </div>
  );
}
