import React from 'react';
import { 
  RefreshCw, 
  Coins, 
  PlusCircle, 
  ArrowRightLeft, 
  Clock 
} from 'lucide-react';

export default function StudentPanel({
  nomeAluno,
  idConta,
  dadosConta,
  loadingConta,
  carregarDadosConta,
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
  extrato
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
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
      
      {/* COLUNA ESQUERDA: INFORMAÇÕES DA CONTA & FORMULÁRIOS */}
      <div className="lg:col-span-2 space-y-6">
        
        {/* CARD DE SALDO */}
        <div className="bg-gray-950 rounded-lg shadow-2xl border border-gray-800 p-6 relative overflow-hidden">
          <div className="absolute top-0 right-0 w-32 h-32 bg-neutral-900/40 rounded-full -mr-8 -mt-8 -z-10 opacity-50"></div>
          
          <div className="flex justify-between items-start mb-6">
            <div>
              <span className="text-[10px] uppercase font-bold text-gray-300">Conta Ativa</span>
              <h2 className="text-2xl font-bold text-white mt-0.5">{nomeAluno}</h2>
              <p className="text-xs text-neutral-400">ID da Conta: #{idConta} • Responsável: Agência {idConta % 3}</p>
            </div>
            <button 
              onClick={carregarDadosConta}
              disabled={loadingConta}
              className="p-2 hover:bg-gray-800 rounded text-slate-400 hover:text-white transition"
              title="Atualizar Dados"
            >
              <RefreshCw size={16} className={loadingConta ? 'animate-spin' : ''} />
            </button>
          </div>

          <div className="bg-gray-900/50 rounded-lg p-5 border border-gray-800 flex items-center justify-between">
            <div>
              <span className="text-xs text-neutral-300 font-semibold">Saldo Disponível</span>
              <p className="text-3xl font-extrabold text-white mt-1">
                R$ {dadosConta ? dadosConta.saldo.toFixed(2) : '0,00'}
              </p>
            </div>
            <Coins size={36} className="text-amber-400 opacity-90" />
          </div>
        </div>

        {/* CARD DE MOVIMENTAÇÕES (SAQUE / DEPÓSITO) */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          
          {/* DEPÓSITO */}
          <div className="bg-green-950/50 rounded-lg shadow-2xl border border-green-800/50 p-5">
            <h3 className="text-sm font-bold text-neutral-100 mb-3 flex items-center gap-1.5">
              <PlusCircle size={16} className="text-emerald-400" />
              Efetuar Depósito
            </h3>
            <form onSubmit={handleDeposito} className="space-y-3">
              <div>
                <input 
                  type="number" 
                  step="0.01"
                  min="0"
                  onKeyDown={blockNegative}
                  value={valorDeposito}
                  onChange={(e) => {
                    const val = e.target.value;
                    if (val === '' || (Number(val) >= 0 && !val.includes('-'))) {
                      setValorDeposito(val);
                    }
                  }}
                  placeholder="Valor (R$)"
                  className="w-full text-xs border border-green-800/50 bg-gray-900/30 text-white rounded p-2 focus:outline-none focus:ring-2 focus:ring-emerald-700 placeholder:text-neutral-100"
                  required
                />
              </div>
              <button 
                type="submit"
                className="w-full bg-emerald-700/80 hover:bg-emerald-600 text-white font-bold py-2 rounded shadow transition text-xs"
              >
                Depositar
              </button>
            </form>
          </div>

          {/* SAQUE */}
          <div className="bg-orange-950/50 rounded-lg shadow-2xl border border-orange-800/50 p-5">
            <h3 className="text-sm font-bold text-neutral-100 mb-3 flex items-center gap-1.5">
              <Coins size={16} className="text-orange-400" />
              Efetuar Saque
            </h3>
            <form onSubmit={handleSaque} className="space-y-3">
              <div>
                <input 
                  type="number" 
                  step="0.01"
                  min="0"
                  onKeyDown={blockNegative}
                  value={valorSaque}
                  onChange={(e) => {
                    const val = e.target.value;
                    if (val === '' || (Number(val) >= 0 && !val.includes('-'))) {
                      setValorSaque(val);
                    }
                  }}
                  placeholder="Valor (R$)"
                  className="w-full text-xs border border-orange-800/50 bg-neutral-900/30 text-white rounded p-2 focus:outline-none focus:ring-2 focus:ring-orange-800 placeholder:text-neutral-100"
                  required
                />
              </div>
              <button 
                type="submit"
                className="w-full bg-orange-800/80 hover:bg-orange-700 text-white font-bold py-2 rounded shadow transition text-xs"
              >
                Sacar
              </button>
            </form>
          </div>

        </div>

        {/* CARD DE TRANSFERÊNCIA */}
        <div className="bg-gray-950 rounded-lg shadow-2xl border border-gray-800 p-6">
          <h3 className="text-sm font-bold text-white mb-2 flex items-center gap-2">
            <ArrowRightLeft size={16} className="text-blue-400" />
            Realizar Transferência
          </h3>
          <p className="text-[11px] text-slate-400 mb-4">
            Transferências para contas com IDs que geram o mesmo resto (id % 3) ocorrem localmente na mesma agência. Para restos diferentes, ocorrem entre agências via rede.
          </p>
          
          <form onSubmit={handleTransferencia} className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-[10px] font-bold text-slate-300 mb-1">ID da Conta de Destino</label>
              <input 
                type="number" 
                min="0"
                onKeyDown={blockNegativeAndDecimals}
                value={transferDestId}
                onChange={(e) => {
                  const val = e.target.value;
                  if (val === '' || (Number(val) >= 0 && !val.includes('-'))) {
                    setTransferDestId(val);
                  }
                }}
                placeholder="Ex: 1"
                className="w-full text-xs border border-gray-800 bg-neutral-900/60 text-white rounded p-2 focus:outline-none focus:ring-2 focus:ring-blue-800/80 placeholder:text-gray-600"
                required
              />
            </div>
            <div>
              <label className="block text-[10px] font-bold text-slate-300 mb-1">Valor (R$)</label>
              <input 
                type="number" 
                step="0.01"
                min="0"
                onKeyDown={blockNegative}
                value={transferValor}
                onChange={(e) => {
                  const val = e.target.value;
                  if (val === '' || (Number(val) >= 0 && !val.includes('-'))) {
                    setTransferValor(val);
                  }
                }}
                placeholder="0,00"
                className="w-full text-xs border border-gray-800 bg-neutral-900/60 text-white rounded p-2 focus:outline-none focus:ring-2 focus:ring-blue-800/80 placeholder:text-gray-600"
                required
              />
            </div>
            <div className="sm:col-span-2 flex justify-end pt-1">
              <button 
                type="submit"
                className="bg-puc-accent/80 hover:bg-puc-accent text-white font-bold py-2 px-6 rounded shadow transition text-xs"
              >
                Enviar Dinheiro
              </button>
            </div>
          </form>
        </div>

      </div>

      {/* COLUNA DIREITA: EXTRATO / HISTÓRICO DE EVENTOS */}
      <div className="bg-gray-950/90 rounded-lg shadow-2xl border border-gray-800 p-6 flex flex-col justify-between max-h-[500px]">
        <div>
          <h3 className="text-sm font-bold text-white mb-4 flex items-center gap-2">
            <Clock size={16} className="text-amber-400" />
            Histórico (Relógio de Lamport)
          </h3>
          
          {extrato.length === 0 ? (
            <div className="text-center py-12 text-gray-500 text-xs">
              Nenhuma transação registrada.
            </div>
          ) : (
            <div className="overflow-y-auto max-h-[380px] space-y-3 pr-2 scrollbar-thin">
              {[...extrato].reverse().map((evento, idx) => {
                const isFalha = evento.tipo === "TRANSFERENCIA_FALHOU";
                
                return (
                  <div key={idx} className="border border-gray-800 rounded p-3 text-xs shadow-sm bg-gray-900/80 hover:border-gray-700 hover:bg-gray-900/80 transition">
                    <div className="flex justify-between items-center mb-1">
                      <span className="font-semibold text-slate-200 uppercase tracking-wider text-[9px]">
                        {evento.tipo.replace('_', ' ')}
                      </span>
                      <span className="bg-gray-800 text-amber-300 border border-gray-700 font-bold px-1.5 py-0.5 rounded text-[9px] flex items-center gap-0.5">
                        Lamport: {evento.timestampLamport}
                      </span>
                    </div>

                    <div className="flex justify-between items-center text-[10px] text-slate-300">
                      <span>
                        {evento.tipo === "CRIAR_CONTA" && `Criado: R$ ${evento.detalhes.saldoInicial.toFixed(2)}`}
                        {evento.tipo === "DEPOSITO" && `Valor: +R$ ${evento.detalhes.valor.toFixed(2)}`}
                        {evento.tipo === "SAQUE" && `Valor: -R$ ${evento.detalhes.valor.toFixed(2)}`}
                        {evento.tipo === "TRANSFERENCIA_DEBITO" && `Para Conta #${evento.detalhes.idDestino}: -R$ ${evento.detalhes.valor.toFixed(2)}`}
                        {evento.tipo === "TRANSFERENCIA_CREDITO" && `De Conta #${evento.detalhes.idOrigem}: +R$ ${evento.detalhes.valor.toFixed(2)}`}
                        {evento.tipo === "TRANSFERENCIA_CREDITO_REMOTO" && `De Agência ${evento.detalhes.origemAgencia}: +R$ ${evento.detalhes.valor.toFixed(2)}`}
                        {evento.tipo === "TRANSFERENCIA_FALHOU" && `Destino #${evento.detalhes.idDestino}: R$ ${evento.detalhes.valor.toFixed(2)}`}
                      </span>
                      <span className="text-[8px] text-slate-400">
                        {new Date(evento.dataHora).toLocaleString('pt-BR')}
                      </span>
                    </div>
                    {isFalha && (
                      <p className="text-[9px] text-red-300 bg-red-950/60 border border-red-900/80 p-1.5 rounded mt-1.5 break-words">
                        Erro: {evento.detalhes.erro.substring(0, 100)}...
                      </p>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>

    </div>
  );
}
