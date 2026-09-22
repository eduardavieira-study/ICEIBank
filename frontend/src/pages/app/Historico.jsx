import React from 'react';
import { Clock, Search } from 'lucide-react';
import { useApp } from '../../context/AppContext';

function resumoEvento(evento) {
  switch (evento.tipo) {
    case 'CRIAR_CONTA':
      return `Criado: R$ ${evento.detalhes.saldoInicial.toFixed(2)}`;
    case 'DEPOSITO':
      return `Valor: +R$ ${evento.detalhes.valor.toFixed(2)}`;
    case 'SAQUE':
      return `Valor: -R$ ${evento.detalhes.valor.toFixed(2)}`;
    case 'TRANSFERENCIA_DEBITO':
      return `Para Conta #${evento.detalhes.idDestino}: -R$ ${evento.detalhes.valor.toFixed(2)}`;
    case 'TRANSFERENCIA_CREDITO':
      return `De Conta #${evento.detalhes.idOrigem}: +R$ ${evento.detalhes.valor.toFixed(2)}`;
    case 'TRANSFERENCIA_CREDITO_REMOTO':
      return `De Agência ${evento.detalhes.origemAgencia}: +R$ ${evento.detalhes.valor.toFixed(2)}`;
    case 'TRANSFERENCIA_FALHOU':
      return `Destino #${evento.detalhes.idDestino}: R$ ${evento.detalhes.valor.toFixed(2)}`;
    default:
      return '';
  }
}

export default function Historico() {
  const { extrato } = useApp();
  const [busca, setBusca] = React.useState('');

  const eventos = [...extrato].sort((a, b) => new Date(b.dataHora) - new Date(a.dataHora));
  const termo = busca.trim().toLowerCase();
  const eventosFiltrados = termo
    ? eventos.filter((evento) => {
        const alvo = `${evento.tipo} ${resumoEvento(evento)}`.toLowerCase().replace(/_/g, ' ');
        return alvo.includes(termo);
      })
    : eventos;

  return (
    <div className="card p-6">
      <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-6">
        <div>
          <h3 className="text-sm font-bold flex items-center gap-2 mb-2">
            <span className="icon-tile bg-secondary-500/10">
              <Clock size={16} className="text-secondary-500" />
            </span>
            Histórico (Relógio de Lamport)
          </h3>
          <p className="text-xs text-muted max-w-md leading-relaxed">
            Todas as suas transações, da mais recente à mais antiga, com o relógio lógico de Lamport de cada evento.
          </p>
        </div>

        <div className="relative sm:w-72 lg:w-96 shrink-0">
          <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted" />
          <input
            type="text"
            value={busca}
            onChange={(e) => setBusca(e.target.value)}
            placeholder="Pesquisar por tipo, conta ou valor..."
            className="input-base pl-10 lg:py-3 lg:text-[15px]"
          />
        </div>
      </div>

      {eventos.length === 0 ? (
        <div className="text-center py-12 text-muted text-xs">Nenhuma transação registrada.</div>
      ) : eventosFiltrados.length === 0 ? (
        <div className="text-center py-12 text-muted text-xs">Nenhum resultado para “{busca}”.</div>
      ) : (
        <div className="space-y-2.5">
          {eventosFiltrados.map((evento, idx) => {
            const isFalha = evento.tipo === 'TRANSFERENCIA_FALHOU';

            return (
              <div key={idx} className="rounded-md border surface-alt p-3.5 text-xs">
                <div className="flex justify-between items-center mb-1.5">
                  <span className="font-semibold uppercase tracking-wider text-[9px] text-muted">
                    {evento.tipo.replace(/_/g, ' ')}
                  </span>
                  <span className="badge bg-primary-500/10 text-primary-700 dark:text-primary-300">
                    Lamport: {evento.timestampLamport}
                  </span>
                </div>

                <div className="flex justify-between items-center text-[11px]">
                  <span>{resumoEvento(evento)}</span>
                  <span className="text-[10px] text-muted shrink-0 ml-2">
                    {new Date(evento.dataHora).toLocaleString('pt-BR')}
                  </span>
                </div>
                {isFalha && (
                  <p className="text-[10px] p-1.5 rounded mt-1.5 break-words bg-red-500/10 text-red-500">
                    Erro: {evento.detalhes.erro.substring(0, 100)}...
                  </p>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
