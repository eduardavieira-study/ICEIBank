import * as config from '../config.js';

const TIMEOUT_MS = 1000;

async function postar(url, corpo) {
  const resposta = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(corpo),
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  if (!resposta.ok) throw new Error(`HTTP ${resposta.status}`);
}

function criarServicoBully(idAgencia, relogio, registro) {
  let liderAtual = null;
  let eleicaoEmAndamento = false;

  function agenciasComIdMaior() {
    return config.AGENCIAS.filter((a) => a.id > idAgencia);
  }

  async function iniciarEleicao() {
    if (eleicaoEmAndamento) return;
    eleicaoEmAndamento = true;
    const vetor = relogio.eventoLocal();
    registro.registrar('ELEICAO_INICIADA', vetor, { idAgencia });

    let alguemRespondeu = false;

    for (const agencia of agenciasComIdMaior()) {
      try {
        const vetorEnvio = relogio.aoEnviar();
        await postar(`${agencia.url}/bully/eleicao`, { origemId: idAgencia, vetorEnvio });
        alguemRespondeu = true;
      } catch (erro) {
        // agência fora do ar ou não respondeu a tempo - ignora e segue
      }
    }

    eleicaoEmAndamento = false;

    if (!alguemRespondeu) {
      await tornarMeLider();
    }
    // se alguém maior respondeu, é essa agência quem vai conduzir a própria
    // eleição e eventualmente anunciar o resultado via /bully/coordenador
  }

  async function tornarMeLider() {
    liderAtual = idAgencia;
    const vetor = relogio.eventoLocal();
    registro.registrar('TORNOU_LIDER', vetor, { idAgencia });
    for (const agencia of config.AGENCIAS) {
      if (agencia.id === idAgencia) continue;
      try {
        const vetorEnvio = relogio.aoEnviar();
        await postar(`${agencia.url}/bully/coordenador`, { liderId: idAgencia, vetorEnvio });
      } catch (erro) {
        // agência fora do ar - vai descobrir a líder quando voltar
      }
    }
  }

  function receberEleicao(origemId, vetorRecebido) {
    const vetor = relogio.aoReceber(vetorRecebido);
    registro.registrar('ELEICAO_RECEBIDA', vetor, { de: origemId, minhaId: idAgencia });
    // o 200 da rota já serve como "OK" implícito - e inicio minha própria
    // eleição, pois posso ser a nova líder (tenho ID maior que quem chamou)
    iniciarEleicao();
  }

  function receberCoordenador(liderId, vetorRecebido) {
    liderAtual = liderId;
    const vetor = relogio.aoReceber(vetorRecebido);
    registro.registrar('LIDER_ANUNCIADO', vetor, { liderId, agencia: idAgencia });
  }

  function obterLiderAtual() {
    return liderAtual;
  }

  async function verificarLider() {
    if (liderAtual === null) {
      await iniciarEleicao();
      return;
    }
    if (liderAtual === idAgencia) return; // eu sou a lider, nada a verificar

    const liderInfo = config.AGENCIAS.find((a) => a.id === liderAtual);
    try {
      const resposta = await fetch(`${liderInfo.url}/bully/lider`, { signal: AbortSignal.timeout(TIMEOUT_MS) });
      if (!resposta.ok) throw new Error(`HTTP ${resposta.status}`);
    } catch (erro) {
      const vetor = relogio.eventoLocal();
      registro.registrar('LIDER_NAO_RESPONDEU', vetor, { liderAtual, agencia: idAgencia });
      liderAtual = null;
      await iniciarEleicao();
    }
  }

  function iniciarHeartbeat(intervaloMs = 3000) {
    setInterval(verificarLider, intervaloMs);
  }

  return { iniciarEleicao, receberEleicao, receberCoordenador, obterLiderAtual, verificarLider, iniciarHeartbeat };
}

export default criarServicoBully;
