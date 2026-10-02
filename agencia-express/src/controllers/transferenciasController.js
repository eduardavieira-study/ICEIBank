import * as config from '../config.js';
import { publicar } from '../services/mensageria.js';

async function transferir(req, res) {
  const { contas, relogio, registro, idAgencia } = req.app.locals;
  const { idOrigem, idDestino, valor } = req.body;

  const contaOrigem = contas.get(idOrigem);
  if (!contaOrigem) return res.status(404).json({ erro: 'Conta de origem não encontrada nesta agência.' });
  if (contaOrigem.saldo < valor) return res.status(400).json({ erro: 'Saldo insuficiente.' });

  const agenciaDestino = config.agenciaResponsavel(idDestino);

  // O débito é sempre local, pois esta agência é a dona da conta de origem
  const tsDebito = relogio.eventoLocal();
  contaOrigem.saldo -= valor;
  registro.registrar('TRANSFERENCIA_DEBITO', tsDebito, { idOrigem, idDestino, valor });

  if (agenciaDestino === idAgencia) {
    // Caso simples: mesma agência, credita direto
    const contaDestino = contas.get(idDestino);
    if (!contaDestino) {
      contaOrigem.saldo += valor;
      return res.status(404).json({ erro: 'Conta de destino não encontrada.' });
    }
    const tsCredito = relogio.eventoLocal();
    contaDestino.saldo += valor;
    registro.registrar('TRANSFERENCIA_CREDITO', tsCredito, { idOrigem, idDestino, valor });
    return res.json({ mensagem: 'Transferência concluída (mesma agência).' });
  }

  // Caso entre agências: em vez de chamar a outra agência diretamente via
  // REST (Sprint 1), publicamos um evento na exchange do RabbitMQ. A agência
  // de destino consome quando puder - mesmo que esteja fora do ar agora, a
  // mensagem fica retida na fila (durable) e é entregue quando ela voltar.
  const vetorEnvio = relogio.aoEnviar();
  try {
    await publicar(`agencia.${agenciaDestino}.creditar`, {
      idConta: idDestino,
      valor,
      vetorEnvio,
      origemAgencia: idAgencia,
    });
  } catch (erro) {
    // Reverte o débito se nem foi possível publicar a mensagem (ex.: RabbitMQ fora do ar)
    contaOrigem.saldo += valor;
    return res.status(502).json({ erro: `Falha ao publicar mensagem no RabbitMQ: ${erro.message}` });
  }

  res.json({ mensagem: 'Transferência publicada para a agência de destino (entrega assíncrona).' });
}

// Chamado pelo consumidor de mensagens (RabbitMQ) ao receber um crédito vindo
// de outra agência. Não passa por nenhuma rota HTTP/Express.
function processarCreditoRemoto(appLocals, mensagem) {
  const { contas, relogio, registro } = appLocals;
  const { idConta, valor, vetorEnvio, origemAgencia } = mensagem;

  // Ao RECEBER uma mensagem de outra agência, o relógio vetorial funde o
  // vetor recebido com o próprio - é a regra 3 do algoritmo (Parte B).
  const vetor = relogio.aoReceber(vetorEnvio);

  const conta = contas.get(idConta);
  if (!conta) {
    registro.registrar('CREDITO_REMOTO_FALHOU', vetor, {
      idConta,
      valor,
      origemAgencia,
      motivo: 'conta nao encontrada',
    });
    return;
  }

  conta.saldo += valor;
  registro.registrar('TRANSFERENCIA_CREDITO_REMOTO', vetor, { idConta, valor, origemAgencia });
}

export { transferir, processarCreditoRemoto };
