import * as config from '../config.js';
import compararVetores from '../services/compararVetores.js';

function criarConta(req, res) {
  const { id, nomeAluno, saldoInicial } = req.body;
  const { contas, relogio, registro, idAgencia } = req.app.locals;

  if (config.agenciaResponsavel(id) !== idAgencia) {
    return res.status(400).json({ erro: `Conta ${id} não pertence a esta agência.` });
  }
  if (contas.has(id)) {
    return res.status(409).json({ erro: 'Conta já existe.' });
  }

  const ts = relogio.eventoLocal();
  contas.set(id, { id, nomeAluno, saldo: saldoInicial || 0 });
  registro.registrar('CRIAR_CONTA', ts, { id, nomeAluno, saldoInicial });

  res.status(201).json(contas.get(id));
}

function consultarSaldo(req, res) {
  const { contas, relogio } = req.app.locals;
  const id = parseInt(req.params.id, 10);
  const conta = contas.get(id);
  if (!conta) return res.status(404).json({ erro: 'Conta não encontrada nesta agência.' });
  // O app guarda o vetorAtual para devolvê-lo ao sincronizar operações feitas offline
  res.json({ ...conta, vetorAtual: relogio.obterVetorAtual() });
}

function depositar(req, res) {
  const { contas, relogio, registro } = req.app.locals;
  const id = parseInt(req.params.id, 10);
  const { valor } = req.body;
  const conta = contas.get(id);
  if (!conta) return res.status(404).json({ erro: 'Conta não encontrada nesta agência.' });

  const ts = relogio.eventoLocal();
  conta.saldo += valor;
  registro.registrar('DEPOSITO', ts, { id, valor, novoSaldo: conta.saldo });

  res.json(conta);
}

function sacar(req, res) {
  const { contas, relogio, registro } = req.app.locals;
  const id = parseInt(req.params.id, 10);
  const { valor } = req.body;
  const conta = contas.get(id);
  if (!conta) return res.status(404).json({ erro: 'Conta não encontrada nesta agência.' });
  if (conta.saldo < valor) return res.status(400).json({ erro: 'Saldo insuficiente.' });

  const ts = relogio.eventoLocal();
  conta.saldo -= valor;
  registro.registrar('SAQUE', ts, { id, valor, novoSaldo: conta.saldo });

  res.json(conta);
}

// Aplica uma operação feita offline pelo app, mas só se a agência não mudou desde
// a última leitura do app: o vetor que o app conhecia precisa ser IGUAL ao vetor
// atual da agência. Caso contrário devolve 409 com o estado atual, para o app
// decidir o que fazer (não resolve o conflito sozinha).
// Comparar e aplicar são atômicos aqui: o Node é single-thread e não há `await`
// entre a comparação e a aplicação.
function sincronizarOperacaoPendente(req, res) {
  const { contas, relogio, registro } = req.app.locals;
  const id = parseInt(req.params.id, 10);
  const { tipo, valor, vetorConhecido } = req.body;

  const conta = contas.get(id);
  if (!conta) return res.status(404).json({ erro: 'Conta não encontrada nesta agência.' });

  if (tipo !== 'DEPOSITO' && tipo !== 'SAQUE') {
    return res.status(400).json({ erro: 'Tipo de operação pendente não suportado.' });
  }
  if (typeof valor !== 'number' || !(valor > 0)) {
    return res.status(400).json({ erro: 'O valor da operação deve ser maior que zero.' });
  }
  if (
    !Array.isArray(vetorConhecido) ||
    vetorConhecido.length !== config.NUMERO_AGENCIAS ||
    !vetorConhecido.every(Number.isInteger)
  ) {
    return res
      .status(400)
      .json({ erro: `O vetor conhecido deve ter ${config.NUMERO_AGENCIAS} posições.` });
  }

  const vetorAtual = relogio.obterVetorAtual();
  const relacao = compararVetores(vetorConhecido, vetorAtual);

  if (relacao !== 'IGUAIS') {
    // Qualquer diferença conta como conflito: a agência avançou enquanto o app
    // estava offline (ANTES), foi reiniciada e perdeu o estado (DEPOIS) ou os dois
    // divergiram (CONCORRENTES). Não aplica às cegas, devolve o estado atual.
    return res.status(409).json({
      erro: 'Conflito detectado: o estado da conta mudou desde a última sincronização do app.',
      relacao,
      vetorConhecido,
      vetorAtual,
      contaAtual: conta,
    });
  }

  if (tipo === 'SAQUE' && conta.saldo < valor) {
    return res.status(400).json({ erro: 'Saldo insuficiente.' });
  }

  const vetor = relogio.eventoLocal();
  if (tipo === 'DEPOSITO') conta.saldo += valor;
  else conta.saldo -= valor;

  registro.registrar('SINCRONIZACAO_OFFLINE', vetor, { id, tipo, valor, novoSaldo: conta.saldo });
  // Devolve o vetor novo: o app precisa dele para a próxima sincronização
  res.json({ ...conta, vetorAtual: vetor });
}

export { criarConta, consultarSaldo, depositar, sacar, sincronizarOperacaoPendente };
