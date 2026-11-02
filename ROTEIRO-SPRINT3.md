# Roteiro de Projeto - Sprint 3: ICEIBank

| | |
|---|---|
| **Disciplina** | Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas |
| **Unidade** | U4 - Desenvolvimento Móvel |
| **Professores** | T1 - Cleiton Tavares Silva · T2 - Cristiano de Macedo Neto |
| **Modalidade** | Projeto individual, ao longo do sprint (não é uma atividade de aula única) |
| **Valor** | 20 pontos (Sprint 3 de 4) |
| **Pré-requisito** | Ter concluído os Sprints 1 e 2 (particionamento, relógio de Lamport e vetorial, API REST/MVC, autenticação JWT, frontend web e mensageria via RabbitMQ do ICEIBank) |

> **Nota de transparência (uso de IA):** este roteiro foi diagramado e organizado com apoio do Claude (Anthropic), utilizado de forma responsável apenas para redação, estruturação e revisão do material - incluindo a validação do código de exemplo, que foi executado e testado (com as 3 agências reais, derrubando a líder e observando a reeleição automática) antes da publicação. O aluno pode utilizar ferramentas de IA para apoiar rascunhos e revisões de código, desde que declare o uso na entrega e seja capaz de explicar e defender qualquer trecho entregue. Copiar e colar sem entender o funcionamento do código caracteriza uso não responsável e será tratado como falta de integridade acadêmica.

---

## 1. Visão geral do projeto: ICEIBank

Relembrando o mapeamento completo dos 4 sprints:

| Sprint | Unidade da ementa | Tecnologia | Conceito de Sistemas Distribuídos aplicado |
|---|---|---|---|
| 1 | U2 - Desenvolvimento Web | API REST / MVC | Relógio lógico de Lamport |
| 2 | U3 - Comunicação indireta | Mensageria / Pub-Sub | Relógio vetorial |
| **3 (este)** | **U4 - Desenvolvimento Móvel** | **App Flutter** | **Consenso (eleição de líder)** |
| 4 | U5 - Computação em Nuvem | Containers | Transações distribuídas (2PC/Saga) |

---

## 2. Escopo da entrega (Sprint 3)

Até agora, as 3 agências do ICEIBank operam como pares - nenhuma tem autoridade especial sobre as outras. Neste sprint, as agências passam a eleger uma líder entre si, usando o **algoritmo de Bully**: quando uma agência percebe que não há líder (ou que a líder atual parou de responder), ela inicia uma eleição; a agência de maior identificador entre as que estão ativas sempre vence.

Ao mesmo tempo, nasce o **app Flutter** - o primeiro cliente mobile do projeto, reaproveitando a mesma API REST que o frontend web do Sprint 1 já consome. Além do fluxo bancário completo, o app exibe qual agência é a líder atual e atualiza isso automaticamente quando uma reeleição acontece - o consenso deixa de ser só um log no terminal e passa a aparecer na tela.

Por ser o primeiro cliente mobile do projeto, o app também passa a seguir o paradigma **offline-first**: continua funcionando (com dados em cache) e permite registrar operações mesmo sem conexão com a agência responsável, sincronizando tudo automaticamente assim que a conectividade volta. Isso reaproveita diretamente o relógio vetorial do Sprint 2 - não para ordenar eventos entre agências como antes, mas para a agência conseguir detectar se uma operação feita offline pelo app ainda é segura de aplicar, ou se o estado da conta mudou enquanto o app estava desconectado.

**O que este sprint entrega:**

- Algoritmo de Bully implementado nas 3 agências: mensagens de eleição e de anúncio de coordenador
- Heartbeat periódico: cada agência verifica se a líder atual continua ativa, e dispara uma nova eleição automaticamente se não estiver
- Um script que reconstrói o histórico de lideranças a partir dos logs das 3 agências
- Um app Flutter com o fluxo bancário completo (login, saldo, depósito, saque, transferência) e um painel mostrando a líder atual em tempo real
- Um endpoint de sincronização no backend, que usa o relógio vetorial para detectar conflitos entre operações feitas offline e mudanças que aconteceram enquanto o app estava desconectado
- Um app Flutter offline-first: armazenamento local, fila de operações pendentes e sincronização automática ao reconectar

**O que este sprint deliberadamente NÃO resolve ainda:** a líder eleita é, por enquanto, só informativa - nenhuma operação do banco passa a ser coordenada por ela. Isso é intencional: é exatamente o papel que a líder vai assumir no Sprint 4, coordenando transações distribuídas (2PC) entre agências. Da mesma forma, a detecção de conflito offline-first deste sprint é propositalmente simples: ela sinaliza que algo mudou na agência enquanto o app estava offline, mas não tenta resolver o conflito sozinha - cabe ao app (ou à pessoa usuária) decidir o que fazer com uma sincronização rejeitada.

### 2.1 Funcionalidade adicional (obrigatória)

Mesma regra dos sprints anteriores (detalhes no roteiro do Sprint 1, seção 2.1). Documente em `RESPOSTAS.md`, evidencie com print em `evidencias/sprint3/`, e faça um commit próprio.

Exemplos possíveis para este sprint:

- **Histórico de líderes na tela:** além de mostrar a líder atual, o app exibe as últimas trocas de liderança.
- **Indicador de agências ativas:** o app mostra quais das 3 agências estão respondendo no momento, não só quem é a líder.
- **Eleição sob demanda:** um botão (no app ou um endpoint) para forçar uma nova eleição manualmente, útil para demonstração em sala.
- **Timeout configurável:** tornar o intervalo do heartbeat e o timeout de resposta configuráveis por variável de ambiente, em vez de fixos no código.

### 2.2 Linguagens

O backend continua na mesma linguagem escolhida no Sprint 1 (Java ou Python) - sem mudança. O código de exemplo deste roteiro está em Node.js/Express, apenas como referência ilustrativa dos materiais da disciplina (seção 11 traz orientações para adaptar às duas linguagens de entrega).

O app mobile é **obrigatoriamente em Flutter** - essa é a tecnologia da Unidade 4 e não é opcional. Diferente do backend, não há código de exemplo do app Flutter neste roteiro (seções 8 e 10 trazem os requisitos, não a implementação) - a mesma política já usada para o frontend web e a autenticação JWT no Sprint 1.

---

## 4. Preparação do ambiente

Mesma convenção dos sprints anteriores: Windows com PowerShell.

- Flutter SDK instalado (`flutter doctor` sem erros críticos) - veja o link de instalação na seção de Referências
- Um emulador Android configurado, ou um dispositivo físico com depuração USB habilitada - o app pode ser testado em qualquer um dos dois
- O backend (agências + RabbitMQ/CloudAMQP) dos Sprints 1 e 2 continua sendo necessário - o app Flutter é um cliente a mais, não substitui nada

### 4.1 Estrutura do repositório

Mesmo repositório dos sprints anteriores. A estrutura ganha a pasta do app Flutter:

```
iceibank/
├── agencia/
│   ├── src/
│   │   ├── app.js
│   │   ├── config.js
│   │   ├── routes.js
│   │   ├── controllers/
│   │   │   └── contasController.js    (atualizado - ganha /sincronizar)
│   │   └── services/
│   │       ├── vectorClock.js         (atualizado - ganha obterVetorAtual)
│   │       ├── eventLog.js
│   │       ├── mensageria.js
│   │       ├── compararVetores.js     (novo)
│   │       └── bullyService.js        (novo)
│   ├── data/
│   ├── mesclar-logs.js
│   └── historico-lideranca.js         (novo)
├── frontend/
├── app_mobile/                        (novo - projeto Flutter)
├── evidencias/
│   ├── sprint1/
│   ├── sprint2/
│   └── sprint3/
├── RESPOSTAS.md
├── .gitignore
└── README.md
```

```powershell
New-Item -ItemType Directory -Force -Path evidencias/sprint3
```

### 4.2 Evidências de teste

Mesma convenção: prints reais, com `Get-Date` visível em algum terminal.

- `evidencias/sprint3/eleicao-inicial.png` - as 3 agências subindo e convergindo para a mesma líder (consulte `/bully/lider` nas 3)
- `evidencias/sprint3/failover.png` - a líder sendo derrubada e uma nova eleição acontecendo automaticamente (seção 6.3)
- `evidencias/sprint3/historico-lideranca.png` - a saída do script `historico-lideranca.js`
- `evidencias/sprint3/app-lider-atual.png` - o app Flutter mostrando a líder atual
- `evidencias/sprint3/app-failover.png` - o app Flutter atualizando o painel da líder após uma queda, sem o usuário precisar atualizar manualmente
- `evidencias/sprint3/conflito-sincronizacao.png` - o backend recusando uma sincronização desatualizada (resposta 409), conforme a seção 9.3
- `evidencias/sprint3/app-offline.png` - o app em modo avião, com uma operação feita offline aparecendo como pendente na tela
- `evidencias/sprint3/app-sincronizacao.png` - o app reconectando e sincronizando sozinho a operação pendente, sem ação manual

### 4.3 Portas exclusivas

Mesmo `OFFSET` pessoal dos sprints anteriores, já embutido no `config.js` - sem mudanças nesta parte.

### 4.4 Disciplina de commits

Mesma orientação: trabalho individual, commits pequenos e incrementais ao longo das 3 semanas.

---

## 5. Parte A: Mensagens de eleição e coordenador

**Conceito:** o algoritmo de Bully (Garcia-Molina, 1982) elege sempre o processo de maior identificador entre os ativos. Cada agência conhece o ID de todas as outras (0, 1, 2). Quando uma agência decide iniciar uma eleição:

1. Ela envia uma mensagem de **eleição** para todas as agências com ID maior que o seu.
2. Se nenhuma responder, ela mesma vence - vira líder e anuncia isso a todas as outras (mensagem de **coordenador**).
3. Se alguma agência de ID maior responder, essa agência assume a responsabilidade de conduzir a eleição (e eventualmente anunciar o resultado) - a agência que perguntou simplesmente espera.
4. Ao receber uma eleição de alguém com ID menor, a agência responde (confirmando que está viva) e inicia sua própria eleição - afinal, ela também é candidata.

O resultado é sempre o mesmo: a agência de maior ID entre as ativas se torna líder.

### 5.1 `agencia/src/services/bullyService.js` (parte 1: eleição e coordenador)

```javascript
import axios from 'axios';
import * as config from '../config.js';

const TIMEOUT_MS = 1000;

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

    const maiores = agenciasComIdMaior();
    let alguemRespondeu = false;

    for (const agencia of maiores) {
      try {
        const vetorEnvio = relogio.aoEnviar();
        await axios.post(`${agencia.url}/bully/eleicao`, { origemId: idAgencia, vetorEnvio }, { timeout: TIMEOUT_MS });
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
        await axios.post(`${agencia.url}/bully/coordenador`, { liderId: idAgencia, vetorEnvio }, { timeout: TIMEOUT_MS });
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

  return { iniciarEleicao, receberEleicao, receberCoordenador, obterLiderAtual };
}

export default criarServicoBully;
```

Vamos completar este arquivo com o heartbeat na Parte B - por enquanto, teste só a eleição inicial.

### 5.2 `agencia/src/routes.js` (rotas do Bully)

Adicione estas rotas às já existentes (contas, transferências etc.):

```javascript
router.post('/bully/eleicao', (req, res) => {
  const { origemId, vetorEnvio } = req.body;
  req.app.locals.bully.receberEleicao(origemId, vetorEnvio);
  res.sendStatus(200);
});

router.post('/bully/coordenador', (req, res) => {
  const { liderId, vetorEnvio } = req.body;
  req.app.locals.bully.receberCoordenador(liderId, vetorEnvio);
  res.sendStatus(200);
});

router.get('/bully/lider', (req, res) => {
  const liderAtual = req.app.locals.bully.obterLiderAtual();
  res.json({ idAgencia: req.app.locals.idAgencia, liderAtual });
});
```

### 5.3 `agencia/src/app.js` (integração)

Adicione ao `app.js` já existente (mantendo tudo que já está lá - relógio, registro, rotas de contas etc.):

```javascript
import criarServicoBully from './services/bullyService.js';

// ... depois de criar relogio e registro:
const bully = criarServicoBully(idAgencia, relogio, registro);
app.locals.bully = bully;

// ... dentro do callback de app.listen(porta, () => { ... }):
bully.iniciarEleicao();
```

Ao subir, cada agência já dispara sua própria eleição para descobrir (ou estabelecer) quem é a líder.

### 5.4 Tarefa

1. Suba as 3 agências ao mesmo tempo (em 3 terminais, como nos sprints anteriores).
2. Espere alguns segundos e consulte `/bully/lider` nas 3:

   ```powershell
   Invoke-RestMethod -Uri "http://localhost:4000/bully/lider" -Method Get
   Invoke-RestMethod -Uri "http://localhost:4001/bully/lider" -Method Get
   Invoke-RestMethod -Uri "http://localhost:4002/bully/lider" -Method Get
   ```

3. Confirme que as 3 concordam sobre quem é a líder - deve ser a agência de maior ID que você subiu (normalmente a 2).
4. Observe nos logs do terminal a "tempestade" de eleições acontecendo na subida - é normal várias agências iniciarem eleições quase ao mesmo tempo; o algoritmo converge de qualquer forma para o ID mais alto.
5. Capture um print para `evidencias/sprint3/eleicao-inicial.png`.
6. Faça o commit:

   ```powershell
   git add agencia/src/services/bullyService.js agencia/src/routes.js agencia/src/app.js evidencias/sprint3
   git commit -m "feat(bully): implementa mensagens de eleicao e coordenador"
   ```

### 5.5 Perguntas - Parte A

1. Por que o algoritmo de Bully sempre elege o processo de maior ID, e não o de menor? O resultado seria diferente (mas ainda assim correto) se a regra fosse invertida?
2. No passo 4 da tarefa, você deve ter visto mais de uma agência declarar `TORNOU_LIDER` durante a subida, antes de convergir. Isso é um bug, ou um comportamento esperado do algoritmo? Justifique com base no que você observou nos logs.
3. O endpoint `/bully/eleicao` não tem nenhuma autenticação. Qualquer processo que descubra a URL de uma agência pode disparar uma eleição nela. Isso é um problema de segurança real para este projeto? Por quê, ou por que não?

---

## 6. Parte B: Heartbeat e failover automático

**Conceito:** eleger uma líder uma vez não é suficiente - o sistema precisa perceber quando ela cai e reagir sozinho. Cada agência passa a verificar periodicamente (heartbeat) se a líder que ela conhece ainda está respondendo. Se não estiver, ela esquece a líder antiga e inicia uma nova eleição.

### 6.1 Completando `agencia/src/services/bullyService.js`

Adicione estas funções dentro de `criarServicoBully` (antes do `return` final), e inclua `verificarLider` e `iniciarHeartbeat` no objeto retornado:

```javascript
  async function verificarLider() {
    if (liderAtual === null) {
      await iniciarEleicao();
      return;
    }
    if (liderAtual === idAgencia) return; // eu sou a lider, nada a verificar

    const liderInfo = config.AGENCIAS.find((a) => a.id === liderAtual);
    try {
      await axios.get(`${liderInfo.url}/bully/lider`, { timeout: TIMEOUT_MS });
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
```

E atualize o `return` do final da função:

```javascript
  return { iniciarEleicao, receberEleicao, receberCoordenador, obterLiderAtual, iniciarHeartbeat };
```

### 6.2 Completando `agencia/src/app.js`

Adicione, logo após `bully.iniciarEleicao();`:

```javascript
bully.iniciarHeartbeat();
```

### 6.3 Tarefa

1. Suba as 3 agências e confirme a eleição inicial (como na Parte A).
2. Derrube a agência líder (feche o terminal dela).
3. Espere alguns segundos (o heartbeat roda a cada 3 segundos, por padrão) e consulte `/bully/lider` nas 2 agências restantes.
4. Confirme que ambas concordam sobre uma nova líder - a de maior ID entre as que sobraram.
5. Capture um print da sequência (derrubar a líder + consultar o novo resultado) para `evidencias/sprint3/failover.png`.
6. Suba a agência derrubada de novo. Observe o que acontece: ela vai iniciar sua própria eleição ao subir - se o ID dela for maior que o da líder atual, uma nova troca de liderança deve acontecer.
7. Faça o commit:

   ```powershell
   git add agencia/src/services/bullyService.js agencia/src/app.js evidencias/sprint3
   git commit -m "feat(bully): adiciona heartbeat e failover automatico"
   ```

### 6.4 Perguntas - Parte B

1. O que aconteceria se o intervalo do heartbeat (`intervaloMs`) fosse muito curto (ex.: 100ms)? E se fosse muito longo (ex.: 60 segundos)? Pense no trade-off entre detectar falhas rápido e sobrecarregar a rede com verificações.
2. No passo 6 da tarefa, a agência que você derrubou e subiu de novo pode, dependendo do ID dela, "tomar" a liderança de volta mesmo que a eleição atual estivesse funcionando bem. Isso é desejável? Que problema prático isso pode causar em um sistema real (pense em uma troca de liderança acontecendo bem no meio de uma operação importante)?
3. O `TIMEOUT_MS` de 1 segundo é usado tanto para detectar uma agência fora do ar quanto para decidir se alguém respondeu a uma eleição. O que aconteceria se a rede estivesse genuinamente lenta (não a agência fora do ar, só uma resposta demorada) e isso ultrapassasse 1 segundo?

---

## 7. Parte C: Observando a eleição

### 7.1 `agencia/historico-lideranca.js`

Este script filtra os eventos de eleição dos logs das 3 agências e reconstrói a linha do tempo de lideranças:

```javascript
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const pastaDados = path.join(__dirname, 'data');
const arquivos = fs.readdirSync(pastaDados).filter((f) => f.endsWith('.jsonl'));

let eventos = [];
for (const arquivo of arquivos) {
  const linhas = fs
    .readFileSync(path.join(pastaDados, arquivo), 'utf-8')
    .trim()
    .split('\n')
    .filter(Boolean);
  eventos.push(...linhas.map((l) => JSON.parse(l)));
}

const tiposBully = ['ELEICAO_INICIADA', 'ELEICAO_RECEBIDA', 'TORNOU_LIDER', 'LIDER_ANUNCIADO', 'LIDER_NAO_RESPONDEU'];
const eventosBully = eventos.filter((e) => tiposBully.includes(e.tipo));
eventosBully.sort((a, b) => new Date(a.horaParede) - new Date(b.horaParede));

console.log('=== Histórico de eventos de eleição ===');
for (const evento of eventosBully) {
  console.log(`(${evento.horaParede}) [${evento.agencia}] ${evento.tipo}`, JSON.stringify(evento.detalhes));
}

const tornouLider = eventosBully.filter((e) => e.tipo === 'TORNOU_LIDER');
console.log('\n=== Linha do tempo de líderes ===');
for (const evento of tornouLider) {
  console.log(`A partir de ${evento.horaParede}: Agência ${evento.detalhes.idAgencia} é a líder`);
}
```

Como executar (depois de já ter gerado eventos nas seções anteriores):

```powershell
node historico-lideranca.js
```

### 7.2 Tarefa

1. Rode o script depois de reproduzir a eleição inicial e o failover da Parte B.
2. Confirme que a linha do tempo de líderes reflete corretamente a sequência: líder inicial -> queda -> nova líder.
3. Capture um print para `evidencias/sprint3/historico-lideranca.png`.
4. Faça o commit:

   ```powershell
   git add agencia/historico-lideranca.js evidencias/sprint3
   git commit -m "feat(observabilidade): adiciona historico de liderancas"
   ```

### 7.3 Perguntas - Parte C

1. Observando a saída do script, quantas vezes a liderança mudou de mãos durante a "tempestade" de eleições da subida inicial (Parte A), antes de estabilizar? Isso tem algum custo real para o sistema (rede, tempo), mesmo não afetando o resultado final?

---

## 8. Parte D: App Flutter

**Conceito:** o app mobile consome a mesma API que o frontend web do Sprint 1 já usa, com um adicional: um painel mostrando qual agência é a líder atual, atualizado automaticamente conforme o consenso muda.

**Esta parte não vem com código de exemplo.** Assim como o frontend web e a autenticação JWT no Sprint 1, a implementação é 100% sua - inclusive as decisões de design (estrutura de telas, gerenciamento de estado, como fazer o polling da liderança).

### 8.1 Requisitos obrigatórios

**Fluxo bancário** (reaproveitando a lógica do frontend web do Sprint 1):

- Tela de login, autenticando via JWT e guardando o token para as próximas requisições
- Consulta de saldo
- Depósito e saque, via formulário
- Transferência, local e entre agências
- Tratamento visível de erros retornados pela API (saldo insuficiente, conta não encontrada, 401 por token expirado etc.)

**Painel de liderança** (a parte nova deste sprint):

- Um painel (pode ser parte da tela principal, ou uma tela própria) mostrando qual agência é a líder atual, consultando `GET /bully/lider` em alguma agência conhecida
- O app deve consultar periodicamente (ex.: a cada poucos segundos) para detectar trocas de liderança, sem exigir que a pessoa usuária atualize a tela manualmente
- Se a agência consultada não responder (está fora do ar), o app deve tentar outra das 3 agências conhecidas antes de desistir

### 8.2 Tarefa

1. Implemente o fluxo bancário completo no app.
2. Implemente o painel de liderança, com atualização periódica.
3. Com o app rodando e as 3 agências no ar, confirme que o painel mostra a líder correta. Capture um print para `evidencias/sprint3/app-lider-atual.png`.
4. Com o app ainda rodando, derrube a agência líder (como na Parte B) e observe o painel do app. Sem reiniciar o app nem tocar em nada na tela, confirme que o painel atualiza sozinho para a nova líder dentro de alguns segundos. Capture um print dessa transição (ou duas capturas, antes e depois) para `evidencias/sprint3/app-failover.png`.
5. Faça o commit:

   ```powershell
   git add app_mobile evidencias/sprint3
   git commit -m "feat(mobile): implementa app Flutter com painel de lideranca"
   ```

### 8.3 Perguntas - Parte D

1. Como o app decide com que frequência consultar `/bully/lider`? Que trade-off você considerou ao escolher esse intervalo (resposta rápida a mudanças vs. consumo de bateria/rede do celular)?
2. Se, num momento de transição, você consultasse duas agências diferentes e elas respondessem líderes diferentes (uma ainda não sabe da nova eleição), como seu app se comporta? Isso é um problema real, ou se resolve sozinho na próxima consulta?
3. Compare a arquitetura do app Flutter com a do frontend web do Sprint 1: o que foi reaproveitável (conceitos, não necessariamente código) e o que precisou ser pensado de forma diferente por ser uma plataforma mobile?

---

## 9. Parte E: Sincronização offline-first no backend

**Conceito:** para o app poder operar offline com segurança, a agência precisa de uma forma de saber se uma operação feita "no passado" (enquanto o app estava desconectado) ainda é segura de aplicar, ou se o estado da conta já mudou desde então. O relógio vetorial do Sprint 2 resolve exatamente esse problema: o app guarda o vetor que a agência tinha na última vez em que leu a conta, e devolve esse vetor junto quando sincroniza. A agência compara esse "vetor conhecido" com o seu vetor atual:

- Se forem **iguais**, nada mudou desde a última leitura do app - a operação é aplicada normalmente.
- Se o vetor atual da agência **avançou**, algo aconteceu enquanto o app estava offline - a agência recusa aplicar cegamente e devolve o estado atual, para o app decidir o que fazer.

### 9.1 Lendo o vetor atual: `agencia/src/services/vectorClock.js` (atualizado)

Adicione este método à classe `RelogioVetorial` já existente (não altera as regras de `eventoLocal`/`aoEnviar`/`aoReceber` do Sprint 2 - só adiciona uma forma de ler o vetor sem incrementá-lo):

```javascript
  obterVetorAtual() {
    return [...this.vetor];
  }
```

### 9.2 `agencia/src/services/compararVetores.js`

A mesma lógica de comparação usada no `mesclar-logs.js` do Sprint 2, agora reaproveitada em tempo real pelo backend:

```javascript
function compararVetores(v1, v2) {
  let v1MenorOuIgual = true;
  let v2MenorOuIgual = true;
  for (let i = 0; i < v1.length; i++) {
    if (v1[i] > v2[i]) v1MenorOuIgual = false;
    if (v2[i] > v1[i]) v2MenorOuIgual = false;
  }
  if (v1MenorOuIgual && v2MenorOuIgual) return 'IGUAIS';
  if (v1MenorOuIgual) return 'ANTES';
  if (v2MenorOuIgual) return 'DEPOIS';
  return 'CONCORRENTES';
}

export default compararVetores;
```

### 9.3 `agencia/src/controllers/contasController.js` (atualizado)

A consulta de saldo passa a devolver o vetor atual (para o app guardar), e um novo endpoint de sincronização usa esse vetor para detectar conflito:

```javascript
import * as config from '../config.js';
import compararVetores from '../services/compararVetores.js';

// ... criarConta, depositar e sacar continuam iguais ao Sprint 1 ...

function consultarSaldo(req, res) {
  const { contas, relogio } = req.app.locals;
  const id = parseInt(req.params.id, 10);
  const conta = contas.get(id);
  if (!conta) return res.status(404).json({ erro: 'Conta não encontrada nesta agência.' });
  res.json({ ...conta, vetorAtual: relogio.obterVetorAtual() });
}

function sincronizarOperacaoPendente(req, res) {
  const { contas, relogio, registro } = req.app.locals;
  const id = parseInt(req.params.id, 10);
  const { tipo, valor, vetorConhecido } = req.body;

  const conta = contas.get(id);
  if (!conta) return res.status(404).json({ erro: 'Conta não encontrada nesta agência.' });

  const vetorAtual = relogio.obterVetorAtual();
  const relacao = compararVetores(vetorConhecido, vetorAtual);

  if (relacao !== 'IGUAIS') {
    // outras operações aconteceram na agência desde a última sincronização do
    // app - não aplica cegamente, devolve o estado atual para o app decidir
    return res.status(409).json({
      erro: 'Conflito detectado: o estado da conta mudou desde a última sincronização do app.',
      vetorConhecido,
      vetorAtual,
      contaAtual: conta,
    });
  }

  let vetor;
  if (tipo === 'DEPOSITO') {
    vetor = relogio.eventoLocal();
    conta.saldo += valor;
  } else if (tipo === 'SAQUE') {
    if (conta.saldo < valor) return res.status(400).json({ erro: 'Saldo insuficiente.' });
    vetor = relogio.eventoLocal();
    conta.saldo -= valor;
  } else {
    return res.status(400).json({ erro: 'Tipo de operação pendente não suportado.' });
  }

  registro.registrar('SINCRONIZACAO_OFFLINE', vetor, { id, tipo, valor });
  res.json(conta);
}

export { criarConta, consultarSaldo, depositar, sacar, sincronizarOperacaoPendente };
```

O exemplo acima cobre depósito e saque. Estender a mesma lógica para transferências fica por sua conta - a comparação de vetores é idêntica, só muda o que acontece quando a operação é aplicada.

### 9.4 `agencia/src/routes.js` (nova rota)

```javascript
router.post('/contas/:id/sincronizar', contasController.sincronizarOperacaoPendente);
```

### 9.5 Tarefa

1. Crie uma conta e consulte seu saldo - confirme que a resposta agora inclui `vetorAtual`.
2. Guarde esse vetor à mão (ou com um script simples) e faça um depósito diretamente (simulando uma mudança que aconteceu "enquanto o app estava offline").
3. Tente sincronizar uma operação usando o vetor antigo (de antes do depósito) e confirme que recebe 409 - o conflito foi detectado.
4. Capture um print dessa resposta para `evidencias/sprint3/conflito-sincronizacao.png`.
5. Agora sincronize de novo, usando o `vetorAtual` devolvido na resposta de conflito, e confirme que a operação é aplicada com sucesso.
6. Faça o commit:

   ```powershell
   git add agencia/src evidencias/sprint3
   git commit -m "feat(offline-first): adiciona endpoint de sincronizacao com deteccao de conflito via vetor"
   ```

### 9.6 Perguntas - Parte E

1. Por que a agência compara o vetor inteiro, e não só verifica se o saldo da conta mudou? O que a comparação de vetores detecta que uma simples comparação de saldo não detectaria?
2. Neste exemplo, qualquer mudança no vetor da agência (mesmo em uma operação de outra conta, que nada tem a ver com a sua) é tratada como conflito. Isso é uma simplificação - explique por que ela existe (lembre-se de que o vetor é por agência, não por conta) e o que seria necessário para tornar a detecção mais precisa, por conta.
3. Quando a sincronização é recusada (409), a agência devolve o estado atual da conta. O que o app deveria fazer com essa informação - descartar a operação pendente, tentar de novo automaticamente, ou perguntar à pessoa usuária? Justifique sua escolha de design na Parte F.

---

## 10. Parte F: App Flutter - modo offline-first

**Conceito:** o app deixa de depender de uma conexão constante com a agência. Dados consultados ficam disponíveis mesmo sem internet, e operações feitas offline são guardadas localmente e sincronizadas automaticamente assim que a conexão volta.

**Esta parte também não vem com código de exemplo**, pela mesma razão das demais partes do app: a implementação - inclusive a escolha da biblioteca de armazenamento local e a estratégia de resolução de conflito - é sua.

### 10.1 Requisitos obrigatórios

- **Armazenamento local:** o app guarda localmente (ex.: `sqflite`, `Hive` ou `Drift`) uma cópia do saldo e do `vetorAtual` mais recente de cada conta consultada, para que a tela de saldo funcione mesmo sem conexão, mostrando o último dado conhecido.
- **Fila de operações pendentes:** se uma operação de escrita (depósito, saque) for feita sem conexão com a agência responsável, ela não falha - é guardada localmente numa fila de pendentes, junto com o `vetorAtual` que o app tinha no momento.
- **UI otimista:** ao registrar uma operação offline, a tela já reflete o efeito esperado imediatamente (ex.: saldo provisório atualizado), com uma indicação visual clara de que está pendente de sincronização.
- **Sincronização automática ao reconectar:** o app detecta quando a conectividade volta (ex.: pacote `connectivity_plus`) e tenta sincronizar a fila pendente automaticamente - sem exigir que a pessoa usuária aperte nada.
- **Tratamento do conflito (HTTP 409):** quando o backend recusa uma sincronização por conflito (seção 9.3), o app deve tratar isso de forma visível - no mínimo, avisando a pessoa usuária de que a operação pendente não pôde ser aplicada automaticamente e mostrando o estado atual e real da conta. Uma estratégia de nova tentativa automática é bem-vinda, mas não obrigatória.

### 10.2 Tarefa

1. Implemente o armazenamento local e a fila de operações pendentes.
2. Coloque o dispositivo/emulador em modo avião (ou desligue o Wi-Fi) e faça um depósito pelo app. Confirme que a operação aparece na tela como pendente, sem erro.
3. Capture um print para `evidencias/sprint3/app-offline.png`.
4. Reative a conexão e observe o app sincronizar a operação pendente sozinho, sem você tocar em nada além de reconectar. Capture um print (ou dois, antes/depois) para `evidencias/sprint3/app-sincronizacao.png`.
5. Reproduza também um caso de conflito: faça uma operação offline pelo app e, antes de reconectá-lo, altere o saldo da mesma conta por outro caminho (ex.: pelo frontend web ou via `Invoke-RestMethod`). Reconecte o app e confirme que ele trata o 409 de forma visível, não silenciosa.
6. Faça o commit:

   ```powershell
   git add app_mobile evidencias/sprint3
   git commit -m "feat(mobile): implementa modo offline-first com fila de sincronizacao"
   ```

### 10.3 Perguntas - Parte F

1. Qual biblioteca de armazenamento local você escolheu, e por quê? Quais alternativas você considerou?
2. Na tarefa 5, o que exatamente aconteceu na tela do app quando a sincronização foi recusada? Descreva o comportamento que você implementou e explique por que escolheu essa abordagem em vez de outra.
3. UI otimista significa mostrar o resultado esperado antes de ter certeza de que ele vai acontecer. Que risco isso traz para um aplicativo bancário, especificamente? Como seu design tenta reduzir esse risco?

---

## 11. Adaptando o backend para Java ou Python

O algoritmo de Bully em si (quem vence, quando alguém se torna líder, como reagir a uma eleição recebida) já está completo e testado nas seções 5-6, em Node - a lógica de decisão é curta o bastante para servir de referência direta, independente da linguagem. O que muda, na prática, é a forma de fazer chamadas HTTP com timeout entre as agências:

- **Java:** `HttpClient` (pacote `java.net.http`, nativo desde o Java 11) com `.timeout(Duration.ofSeconds(1))` na requisição, ou `RestTemplate`/`WebClient` se já estiver usando Spring. Atenção: como o heartbeat roda em uma thread periódica (`ScheduledExecutorService`, por exemplo) enquanto requisições HTTP chegam em outras threads, proteja o acesso ao estado `liderAtual` com `synchronized` ou um tipo atômico (`AtomicInteger`), do mesmo jeito que o relógio de Lamport/vetorial precisou de cuidado com concorrência no Sprint 1.
- **Python:** `requests` com o parâmetro `timeout=1` em cada chamada (`requests.post(..., timeout=1)`), capturando `requests.exceptions.RequestException` para tratar tanto timeout quanto conexão recusada. Para o heartbeat periódico, um `threading.Timer` recorrente ou um loop com `time.sleep` em uma thread separada resolve - e, como em Java, proteja o `lider_atual` compartilhado com um `threading.Lock`.

A estrutura de rotas (`POST /bully/eleicao`, `POST /bully/coordenador`, `GET /bully/lider`) e o formato das mensagens (JSON com `origemId`/`liderId` e o vetor de Lamport) devem ser mantidos iguais, para que a lógica de decisão (a parte realmente nova e importante deste sprint) seja a mesma em qualquer linguagem.

O endpoint de sincronização offline-first (seção 9) é ainda mais direto de adaptar: a função `compararVetores` é pura (sem efeitos colaterais, sem chamadas de rede) e pode ser transcrita quase literalmente para Java ou Python - é a mesma lógica já usada no `mesclar-logs.js` do Sprint 2, só que chamada em tempo real dentro de uma rota em vez de rodar sobre um arquivo de log.

---

## 12. Checklist de entrega

- [ ] Mensagens de eleição e coordenador implementadas e funcionando (Parte A)
- [ ] As 3 agências convergem para a mesma líder ao subir, mesmo com a "tempestade" de eleições inicial
- [ ] Heartbeat detectando a queda da líder e disparando reeleição automática (Parte B), sem intervenção manual
- [ ] Script `historico-lideranca.js` reconstruindo corretamente a linha do tempo de lideranças (Parte C)
- [ ] App Flutter com o fluxo bancário completo, reaproveitando a API já existente
- [ ] App Flutter com painel de liderança, atualizado automaticamente - incluindo o failover visível na tela, não só no backend
- [ ] Endpoint de sincronização no backend (Parte E), detectando conflito via relógio vetorial - não só o caminho feliz
- [ ] App Flutter em modo offline-first (Parte F): armazenamento local, fila de pendentes, UI otimista e sincronização automática ao reconectar
- [ ] O conflito de sincronização (HTTP 409) é tratado de forma visível no app, não escondido ou ignorado
- [ ] JWT, frontend web (Sprint 1) e mensageria/relógio vetorial (Sprint 2) continuam funcionando sem regressão
- [ ] Pelo menos uma funcionalidade adicional implementada e documentada (seção 2.1)
- [ ] Pasta `evidencias/sprint3/` com os 8 prints indicados na seção 4.2
- [ ] Arquivo `RESPOSTAS.md` atualizado com as questões das seções 5.5, 6.4, 7.3, 8.3, 9.6 e 10.3, e a descrição da funcionalidade adicional

---

## 13. Critérios de avaliação (20 pontos)

| Critério | Pontos | O que é observado |
|---|---|---|
| Eleição de líder (Bully) entre as 3 agências | 4 | Mensagens de eleição/coordenador corretas; convergência garantida para o ID mais alto |
| Detecção de falha da líder + reeleição automática | 2 | Heartbeat funcionando; nova eleição disparada sem intervenção manual |
| App Flutter - fluxo bancário completo | 2 | Login, saldo, depósito, saque e transferência funcionando pela interface mobile |
| App Flutter - painel da líder + failover na UI | 2 | Líder atual exibida e atualizada automaticamente, inclusive durante uma queda real |
| Sincronização offline-first no backend | 3 | Endpoint de sincronização detectando corretamente conflitos via relógio vetorial, não só o caminho feliz |
| App Flutter - modo offline-first | 3 | Armazenamento local, fila de pendentes, UI otimista e sincronização automática funcionando de ponta a ponta |
| Continuidade (JWT, frontend web, mensageria/vetorial) | 1 | O que já funcionava nos Sprints 1-2 continua funcionando sem regressão |
| Funcionalidade adicional | 1 | Funcionalidade nova e genuína (seção 2.1), funcionando e documentada |
| Commits | 1 | Histórico incremental ao longo do sprint |
| Respostas às questões | 1 | Compreensão demonstrada, com referência ao comportamento observado no código |

A ponderação exata é definida pelo professor responsável pela turma (T1 ou T2), conforme os critérios apresentados em sala.

---

## 14. Referências

- GARCIA-MOLINA, Hector. *Elections in a Distributed Computing System*. IEEE Transactions on Computers, v. C-31, n. 1, 1982. (O artigo original do algoritmo de Bully.)
- COULOURIS, George et al. *Distributed Systems: Concepts and Design*. 5th ed. Addison-Wesley, 2011.
- TANENBAUM, A. S.; VAN STEEN, M. *Sistemas Distribuídos: Princípios e Paradigmas*. Tradução da 2ª edição. Pearson, 2007.
- Flutter. Documentação oficial - Get started. Disponível em: <https://docs.flutter.dev/get-started/install>
- Flutter. Networking e consumo de APIs REST. Disponível em: <https://docs.flutter.dev/cookbook/networking/fetch-data>
- sqflite (Flutter). Pacote de banco de dados local SQLite. Disponível em: <https://pub.dev/packages/sqflite>
- Hive (Flutter). Banco de dados local NoSQL leve. Disponível em: <https://pub.dev/packages/hive>
- connectivity_plus (Flutter). Detecção de conectividade de rede. Disponível em: <https://pub.dev/packages/connectivity_plus>
- KLEPPMANN, Martin. *Designing Data-Intensive Applications*. O'Reilly Media, 2017. (Cap. 5 - Replication - e 9 - Consistency and Consensus - para quem quiser se aprofundar em consistência eventual e resolução de conflitos além do que este sprint exige.)
