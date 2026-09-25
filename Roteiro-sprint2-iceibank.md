# Roteiro de Projeto - Sprint 2: ICEIBank

| | |
|---|---|
| **Disciplina** | Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas |
| **Unidade** | U3 - Comunicação Indireta (Middlewares Orientados a Mensagens, arquitetura Publish/Subscribe) |
| **Professores** | T1 - Cleiton Tavares Silva · T2 - Cristiano de Macedo Neto |
| **Modalidade** | Projeto individual, ao longo do sprint (não é uma atividade de aula única) |
| **Valor** | 20 pontos (Sprint 2 de 4) |
| **Pré-requisito** | Ter concluído o Sprint 1 (particionamento, relógio de Lamport, API REST/MVC, autenticação JWT e frontend do ICEIBank) |

> **Nota de transparência (uso de IA):** este roteiro foi diagramado e organizado com apoio do Claude (Anthropic), utilizado de forma responsável apenas para redação, estruturação e revisão do material - incluindo a validação do código de exemplo, que foi executado e testado (com um broker RabbitMQ real) antes da publicação. O aluno pode utilizar ferramentas de IA para apoiar rascunhos e revisões de código, desde que declare o uso na entrega e seja capaz de explicar e defender qualquer trecho entregue. Copiar e colar sem entender o funcionamento do código caracteriza uso não responsável e será tratado como falta de integridade acadêmica.

---

## 1. Visão geral do projeto: ICEIBank

Relembrando o mapeamento completo dos 4 sprints:

| Sprint | Unidade da ementa | Tecnologia | Conceito de Sistemas Distribuídos aplicado |
|---|---|---|---|
| 1 | U2 - Desenvolvimento Web | API REST / MVC | Relógio lógico de Lamport |
| **2 (este)** | **U3 - Comunicação indireta** | **Mensageria / Pub-Sub** | **Relógio vetorial** |
| 3 | U4 - Desenvolvimento Móvel | App Flutter | Consenso (eleição de líder) |
| 4 | U5 - Computação em Nuvem | Containers | Transações distribuídas (2PC/Saga) |

---

## 2. Escopo desta entrega (Sprint 2)

No Sprint 1, quando uma agência precisava creditar uma conta de outra agência, ela fazia uma chamada REST direta (síncrona) à outra agência. Se a agência de destino estivesse fora do ar, a chamada falhava na hora, e o débito já aplicado ficava "pendurado" - uma inconsistência conhecida, deixada de propósito.

Neste sprint, essa chamada direta é substituída por **mensageria assíncrona**: a agência de origem publica um evento numa fila/exchange (RabbitMQ), e a agência de destino consome esse evento quando puder - mesmo que esteja temporariamente fora do ar no momento da publicação. Como consequência direta dessa mudança, o relógio de Lamport (que só captura uma direção da causalidade) dá lugar ao **relógio vetorial**, que permite determinar com certeza se dois eventos são causalmente relacionados ou genuinamente concorrentes - algo que Lamport, sozinho, não garante.

**O que este sprint entrega:**

- RabbitMQ configurado (exchange do tipo `topic`, uma fila por agência)
- Relógio vetorial substituindo o relógio de Lamport do Sprint 1
- Transferência entre agências publicada como mensagem, consumida de forma assíncrona pela agência de destino
- Um script atualizado de linha do tempo que, além de listar os eventos, identifica pares de eventos comprovadamente concorrentes entre agências diferentes

**O que continua do Sprint 1 (e deve seguir funcionando - não é opcional):**

- Particionamento de contas entre as 3 agências
- Autenticação JWT protegendo a API
- O frontend consumindo a API

**O que este sprint melhora, e o que ainda não resolve:** a mensageria durável resolve o problema mais visível do Sprint 1 - uma mensagem publicada para uma agência fora do ar não se perde mais, ela fica retida na fila até a agência voltar. Mas isso não resolve tudo: como as contas ainda vivem em memória (sem persistência em disco/banco), se a agência de destino reiniciar antes de consumir a mensagem, a conta que deveria receber o crédito não existe mais quando a agência volta - a mensagem chega, mas não encontra onde aplicar o valor. Você vai reproduzir esse cenário exato na Parte C e refletir sobre ele nas perguntas.

### 2.1 Funcionalidade adicional (obrigatória)

Mesma regra dos sprints anteriores - vale a pena reler se não lembra os detalhes (o que conta e o que não conta como funcionalidade adicional está no roteiro do Sprint 1, seção 2.1). Documente em `RESPOSTAS.md`, evidencie com print em `evidencias/sprint2/`, e faça um commit próprio.

Exemplos possíveis para este sprint (escolha um, ou proponha outro):

- **Fila de auditoria:** uma agência adicional (ou consumidor extra) que escuta todos os eventos publicados, de todas as agências, e mantém um log central de auditoria.
- **Notificação de saldo baixo:** ao processar uma operação que deixa o saldo abaixo de um limite, a agência publica um evento de alerta num tópico separado.
- **Fila de mensagens não processadas (dead-letter):** configure uma dead-letter queue no RabbitMQ para mensagens que falham repetidamente ao processar (ex.: conta não encontrada), em vez de simplesmente descartá-las.
- **Confirmação de entrega:** a agência de origem assina um segundo evento de "confirmação de crédito" publicado pela agência de destino, fechando o ciclo.

### 2.2 Escolha de linguagem

Use a mesma linguagem escolhida no Sprint 1 (Java ou Python) - este projeto evolui o código já existente, não recomeça do zero. Assim como no Sprint 1, o código de exemplo deste roteiro está em Node.js/Express apenas como referência ilustrativa dos materiais da disciplina - a entrega continua sendo em Java ou Python (seção 9 traz o relógio vetorial já adaptado e testado nas duas linguagens).

---

## 3. Cronograma sugerido

Assim como no Sprint 1, planeje 3 semanas, começando cedo:

| Etapa | Quando | Conteúdo |
|---|---|---|
| RabbitMQ configurado e testado (fora da aplicação) | Semana 1 (início) | Seção 5: Parte A |
| Relógio vetorial | Semana 1 | Seção 6: Parte B - implemente e teste isoladamente antes de integrar |
| Publish/Subscribe entre agências | Semana 1-2 | Seção 7: Parte C - substitui a chamada REST direta do Sprint 1 |
| Teste de resiliência (agência fora do ar) | Semana 2 | Seção 7 - reproduza o cenário descrito na seção 2 |
| Linha do tempo causal | Semana 2-3 | Seção 8: Parte D - identificar pares concorrentes |
| Funcionalidade adicional | Ao longo do sprint | Seção 2.1 |
| Revisão de respostas, commits e regressão (JWT/frontend ainda funcionam?) | Semana 3 | Antes de entregar |
| Entrega | Fim da Semana 3 | Checklist da seção 10 |

---

## 4. Preparação do ambiente

Mesma convenção dos sprints anteriores: Windows com PowerShell.

### 4.1 RabbitMQ (via CloudAMQP)

Em vez de instalar e rodar o RabbitMQ localmente, este roteiro usa o **CloudAMQP** - um RabbitMQ gerenciado na nuvem, com um plano gratuito ("Little Lemur") suficiente para este projeto. Isso evita depender de Docker ou de instalar o Erlang/OTP no Windows, e cada aluno já fica com sua própria instância isolada, sem risco de conflito com colegas numa máquina compartilhada.

**Como criar sua instância:**

1. Acesse <https://www.cloudamqp.com/> e crie uma conta gratuita (dá para entrar com Google ou GitHub).
2. Clique em **Create New Instance**.
3. Escolha o plano **Little Lemur - Free**, dê um nome à instância (ex.: `iceibank`) e selecione uma região (qualquer uma próxima já serve).
4. Após a instância ser criada, clique nela para abrir os detalhes. Copie o campo **AMQP URL** - algo como:

   ```
   amqps://usuario:senha@host.cloudamqp.com/vhost
   ```

Essa URL já inclui usuário, senha e o vhost da sua instância - é só isso que a aplicação precisa para se conectar.

**Configurando a aplicação:**

Antes de rodar cada agência, defina a variável de ambiente `RABBITMQ_URL` com a URL copiada:

```powershell
$env:RABBITMQ_URL="amqps://usuario:senha@host.cloudamqp.com/vhost"
```

Essa variável precisa estar definida em **cada terminal** onde você rodar uma agência (os três terminais da seção 7.4 e das demais tarefas) - se abrir um terminal novo, defina de novo antes de rodar `node src/app.js`.

Para visualizar exchanges, filas e mensagens (útil para depurar), o próprio painel do CloudAMQP tem um botão **RabbitMQ Manager**, que abre a interface de administração da sua instância - não precisa mais de `http://localhost:15672`.

> **Sem internet confiável durante a aula, ou preferência por rodar localmente?** O RabbitMQ também roda via Docker (`docker run -d --name rabbitmq-iceibank -p 5672:5672 -p 15672:15672 rabbitmq:3-management`, com `RABBITMQ_URL=amqp://localhost`) ou via instalador nativo do Windows (requer Erlang/OTP antes) - veja os links na seção de Referências. A aplicação funciona igual nos dois casos: só muda o valor de `RABBITMQ_URL`.

### 4.2 Estrutura do repositório

Você continua no mesmo repositório do Sprint 1 - não crie um novo. A estrutura ganha uma nova pasta de evidências:

```
iceibank/
├── agencia/
│   ├── package.json
│   ├── src/
│   │   ├── app.js
│   │   ├── config.js
│   │   ├── routes.js
│   │   ├── controllers/
│   │   │   ├── contasController.js
│   │   │   └── transferenciasController.js
│   │   └── services/
│   │       ├── vectorClock.js         (novo - substitui lamportClock.js)
│   │       ├── mensageria.js          (novo)
│   │       └── eventLog.js            (atualizado para vetor)
│   ├── data/
│   └── mesclar-logs.js                (atualizado)
├── frontend/
├── evidencias/
│   ├── sprint1/
│   └── sprint2/
├── RESPOSTAS.md
├── .gitignore
└── README.md
```

```powershell
New-Item -ItemType Directory -Force -Path evidencias/sprint2
```

### 4.3 Evidências de teste

Mesma convenção: prints reais, com `Get-Date` visível em algum terminal.

- `evidencias/sprint2/transferencia-assincrona.png` - uma transferência entre agências completando via mensageria, com o log das duas agências visível
- `evidencias/sprint2/resiliencia-fila.png` - o cenário da seção 7.4: agência de destino derrubada, transferência publicada mesmo assim, e o que acontece quando ela volta
- `evidencias/sprint2/linha-do-tempo-causal.png` - a saída do `mesclar-logs.js` mostrando ao menos um par de eventos identificados como concorrentes

### 4.4 Portas exclusivas

Mesmo `OFFSET` pessoal dos sprints anteriores, aplicável às portas HTTP das 3 agências (`4000-4002 + OFFSET`), como já era no Sprint 1. Como o RabbitMQ agora roda no CloudAMQP (cada aluno com sua própria instância na nuvem, seção 4.1), não há mais porta local de RabbitMQ para se preocupar em isolar de colegas numa máquina compartilhada.

### 4.5 Disciplina de commits

Mesma orientação do Sprint 1: trabalho individual, commits pequenos e incrementais ao longo das 3 semanas, não um único commit no fim.

---

## 5. Parte A: Configurando o RabbitMQ

**Conceito:** um *message broker* como o RabbitMQ recebe mensagens de quem publica (*producer*) e as entrega a quem consome (*consumer*), sem que um precise conhecer o outro diretamente - é essa indireção que dá nome à unidade "Comunicação Indireta". Nesta arquitetura usaremos:

- Uma **exchange** do tipo `topic`, chamada `iceibank.eventos` - é para ela que as agências publicam.
- Uma **fila por agência** (`fila-agencia-0`, `fila-agencia-1`, `fila-agencia-2`), cada uma vinculada (*bound*) à exchange por uma **routing key** no formato `agencia.<id>.creditar`.
- Quando a Agência 0 quer creditar uma conta da Agência 1, ela publica na exchange com a routing key `agencia.1.creditar` - só a fila da Agência 1 recebe essa mensagem, mesmo a exchange sendo compartilhada por todas.

Isso é o padrão **Publish/Subscribe**: quem publica não sabe (nem precisa saber) quem vai consumir.

### 5.1 Dependência

```powershell
cd agencia
npm install amqplib
```

### 5.2 Tarefa

1. Crie sua instância CloudAMQP (seção 4.1) e confirme que consegue abrir o **RabbitMQ Manager** a partir do painel do CloudAMQP.
2. Ainda sem integrar com a aplicação, é um bom momento para se familiarizar com o painel: você vai ver as exchanges e filas aparecerem ali conforme as agências rodarem (Parte C).

---

## 6. Parte B: Relógio vetorial

**Revisão rápida (já visto na teórica):** o relógio vetorial resolve a limitação do relógio de Lamport (Sprint 1) - com Lamport, dois eventos com timestamps diferentes podem ou não ser causalmente relacionados, e não há como saber com certeza. O relógio vetorial usa um vetor de contadores, um por processo (aqui, um por agência), com três regras:

1. Antes de um evento local, o processo incrementa sua própria posição no vetor.
2. Ao enviar uma mensagem, o processo incrementa sua própria posição e anexa o vetor inteiro à mensagem.
3. Ao receber uma mensagem com vetor `V_recebido`, o processo faz, para cada posição `i`: `vetor[i] = max(vetor[i], V_recebido[i])`, e então incrementa sua própria posição.

Com dois vetores `V1` e `V2`, dá para determinar a relação entre os eventos que eles representam comparando posição a posição:

- Se `V1[i] <= V2[i]` para todo `i` (e são diferentes): o evento de `V1` aconteceu **antes** do de `V2`.
- Se nem `V1 <= V2` nem `V2 <= V1`: os eventos são **concorrentes** - nenhum influenciou o outro.

### 6.1 `agencia/src/services/vectorClock.js`

```javascript
class RelogioVetorial {
  constructor(idAgencia, numeroAgencias) {
    this.idAgencia = idAgencia;
    this.vetor = new Array(numeroAgencias).fill(0);
  }

  eventoLocal() {
    this.vetor[this.idAgencia] += 1;
    return [...this.vetor];
  }

  aoEnviar() {
    this.vetor[this.idAgencia] += 1;
    return [...this.vetor];
  }

  aoReceber(vetorRecebido) {
    for (let i = 0; i < this.vetor.length; i++) {
      this.vetor[i] = Math.max(this.vetor[i], vetorRecebido[i]);
    }
    this.vetor[this.idAgencia] += 1;
    return [...this.vetor];
  }
}

export default RelogioVetorial;
```

Este arquivo substitui o `lamportClock.js` do Sprint 1 (pode apagá-lo, ou manter para consulta - sua escolha).

### 6.2 `agencia/src/services/eventLog.js` (atualizado)

O registro de eventos passa a guardar o vetor completo em vez de um único número:

```javascript
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class RegistroEventos {
  constructor(nomeAgencia) {
    this.nomeAgencia = nomeAgencia;
    this.caminhoArquivo = path.join(__dirname, '..', '..', 'data', `eventos-${nomeAgencia}.jsonl`);
    fs.mkdirSync(path.dirname(this.caminhoArquivo), { recursive: true });
  }

  registrar(tipo, timestampVetorial, detalhes) {
    const evento = {
      agencia: this.nomeAgencia,
      tipo,
      timestampVetorial,
      horaParede: new Date().toISOString(),
      detalhes,
    };
    fs.appendFileSync(this.caminhoArquivo, JSON.stringify(evento) + '\n');
    console.log(`[Vetor ${JSON.stringify(timestampVetorial)}] ${tipo}`, detalhes);
    return evento;
  }
}

export default RegistroEventos;
```

### 6.3 Commit desta parte

```powershell
git add agencia/src/services/vectorClock.js agencia/src/services/eventLog.js
git commit -m "feat(vetorial): substitui relogio de Lamport por relogio vetorial"
```

### 6.4 Perguntas - Parte B

1. Com 3 agências, o vetor tem 3 posições. Se o sistema crescesse para 10 agências, o que aconteceria com o tamanho de cada vetor anexado a cada mensagem? Isso é um problema? Por quê (ou por que não)?
2. Dado `V1 = [3, 1, 0]` e `V2 = [3, 2, 0]`: qual evento aconteceu primeiro, ou eles são concorrentes? Justifique comparando posição a posição.
3. Dado `V1 = [3, 1, 0]` e `V2 = [1, 3, 0]`: qual evento aconteceu primeiro, ou eles são concorrentes? Justifique.

---

## 7. Parte C: Publish/Subscribe entre agências

### 7.1 `agencia/src/services/mensageria.js`

```javascript
import amqp from 'amqplib';

const URL_RABBITMQ = process.env.RABBITMQ_URL;
const EXCHANGE = 'iceibank.eventos';

if (!URL_RABBITMQ) {
  console.error('Defina a variável de ambiente RABBITMQ_URL com a URL AMQP da sua instância CloudAMQP antes de iniciar.');
  process.exit(1);
}

let canalCache = null;

async function obterCanal() {
  if (canalCache) return canalCache;
  const conexao = await amqp.connect(URL_RABBITMQ);
  const canal = await conexao.createChannel();
  await canal.assertExchange(EXCHANGE, 'topic', { durable: true });
  canalCache = canal;
  return canal;
}

async function publicar(routingKey, mensagem) {
  const canal = await obterCanal();
  canal.publish(EXCHANGE, routingKey, Buffer.from(JSON.stringify(mensagem)), { persistent: true });
}

async function assinar(idAgencia, aoReceberMensagem) {
  const canal = await obterCanal();
  const nomeFila = `fila-agencia-${idAgencia}`;
  await canal.assertQueue(nomeFila, { durable: true });
  await canal.bindQueue(nomeFila, EXCHANGE, `agencia.${idAgencia}.creditar`);
  canal.consume(nomeFila, (msg) => {
    if (msg) {
      const conteudo = JSON.parse(msg.content.toString());
      aoReceberMensagem(conteudo);
      canal.ack(msg);
    }
  });
}

export { publicar, assinar };
```

A checagem no início do arquivo evita um erro confuso de conexão caso você esqueça de definir `RABBITMQ_URL` no terminal antes de rodar a agência - fica claro logo de cara qual é o problema.

`durable: true` na exchange e na fila, e `persistent: true` na mensagem, são o que garante que uma mensagem publicada para uma agência fora do ar não se perde - ela fica gravada em disco pelo RabbitMQ até alguém consumir.

### 7.2 `agencia/src/controllers/transferenciasController.js` (atualizado)

```javascript
import * as config from '../config.js';
import { publicar } from '../services/mensageria.js';

async function transferir(req, res) {
  const { contas, relogio, registro, idAgencia } = req.app.locals;
  const { idOrigem, idDestino, valor } = req.body;

  const contaOrigem = contas.get(idOrigem);
  if (!contaOrigem) return res.status(404).json({ erro: 'Conta de origem não encontrada nesta agência.' });
  if (contaOrigem.saldo < valor) return res.status(400).json({ erro: 'Saldo insuficiente.' });

  const agenciaDestino = config.agenciaResponsavel(idDestino);

  const vetorDebito = relogio.eventoLocal();
  contaOrigem.saldo -= valor;
  registro.registrar('TRANSFERENCIA_DEBITO', vetorDebito, { idOrigem, idDestino, valor });

  if (agenciaDestino === idAgencia) {
    const contaDestino = contas.get(idDestino);
    if (!contaDestino) {
      contaOrigem.saldo += valor;
      return res.status(404).json({ erro: 'Conta de destino não encontrada.' });
    }
    const vetorCredito = relogio.eventoLocal();
    contaDestino.saldo += valor;
    registro.registrar('TRANSFERENCIA_CREDITO', vetorCredito, { idOrigem, idDestino, valor });
    return res.json({ mensagem: 'Transferência concluída (mesma agência).' });
  }

  // Em vez de chamar a outra agência diretamente (Sprint 1), publicamos um
  // evento na exchange do RabbitMQ. A agência de destino consome quando
  // estiver disponível - mesmo que esteja fora do ar agora, a mensagem fica
  // retida na fila (durable) e é entregue quando ela voltar.
  const vetorEnvio = relogio.aoEnviar();
  await publicar(`agencia.${agenciaDestino}.creditar`, {
    idConta: idDestino,
    valor,
    vetorEnvio,
    origemAgencia: idAgencia,
  });

  res.json({ mensagem: 'Transferência publicada para a agência de destino (entrega assíncrona).' });
}

export { transferir };
```

Note que a rota `/contas/:id/creditar-remoto` do Sprint 1 deixa de existir - o crédito remoto agora chega via mensageria, não mais por uma chamada REST de outra agência. Atualize seu `routes.js` removendo essa rota.

Repare também que a resposta ao cliente muda de sentido: no Sprint 1, uma resposta `200` significava "o crédito já foi aplicado na outra agência". Agora, `200` significa apenas "a mensagem foi publicada" - a aplicação efetiva do crédito acontece de forma assíncrona, em um momento que o chamador não controla nem confirma na hora.

### 7.3 `agencia/src/app.js` (atualizado)

```javascript
import express from 'express';
import * as config from './config.js';
import RelogioVetorial from './services/vectorClock.js';
import RegistroEventos from './services/eventLog.js';
import { assinar } from './services/mensageria.js';
import routes from './routes.js';

const idAgencia = parseInt(process.env.AGENCIA_ID || '0', 10);
const agenciaConfig = config.AGENCIAS.find((a) => a.id === idAgencia);

if (!agenciaConfig) {
  console.error(`Agência ${idAgencia} não configurada em config.js`);
  process.exit(1);
}

const app = express();
app.use(express.json());

const relogio = new RelogioVetorial(idAgencia, config.NUMERO_AGENCIAS);
const registro = new RegistroEventos(`agencia-${idAgencia}`);
const contas = new Map();

app.locals.idAgencia = idAgencia;
app.locals.relogio = relogio;
app.locals.registro = registro;
app.locals.contas = contas;

app.use('/', routes);

// Consumidor: processa creditos vindos de outras agencias via RabbitMQ
assinar(idAgencia, (mensagem) => {
  const { idConta, valor, vetorEnvio, origemAgencia } = mensagem;
  const vetor = relogio.aoReceber(vetorEnvio);

  const conta = contas.get(idConta);
  if (!conta) {
    registro.registrar('CREDITO_REMOTO_FALHOU', vetor, { idConta, valor, origemAgencia, motivo: 'conta nao encontrada' });
    return;
  }

  conta.saldo += valor;
  registro.registrar('TRANSFERENCIA_CREDITO_REMOTO', vetor, { idConta, valor, origemAgencia });
});

const porta = new URL(agenciaConfig.url).port;
app.listen(porta, () => {
  console.log(`[Agência ${idAgencia}] ouvindo na porta ${porta}`);
});
```

> **Lembrete:** a proteção JWT das rotas (Sprint 1, Parte F) continua necessária aqui - aplique-a normalmente em `routes.js`. O consumidor de mensagens (`assinar`), por outro lado, não passa pelo Express e não tem como carregar um token HTTP - ele consome mensagens que já foram publicadas por outra agência dentro do próprio sistema. Isso é retomado na Pergunta 3 desta parte.

### 7.4 Tarefa

1. Em cada terminal, antes de rodar `node src/app.js`, defina `$env:RABBITMQ_URL` com a URL da sua instância CloudAMQP (seção 4.1). Suba as 3 agências e teste uma transferência normal entre agências diferentes (ambas no ar). Confirme que o crédito chega à agência de destino e que o vetor dela foi atualizado corretamente via `aoReceber`.
2. Capture um print para `evidencias/sprint2/transferencia-assincrona.png`.
3. **Teste de resiliência:** com a Agência 1 já tendo uma conta criada, derrube-a (feche o terminal). Com ela fora do ar, faça uma transferência para uma conta dela. Observe que a resposta ainda é `200` (a mensagem foi publicada, mesmo sem ninguém para consumi-la agora).
4. Suba a Agência 1 de novo. Observe o que acontece no log dela quando reconecta. Anote: a mensagem foi entregue? A conta ainda existia para receber o crédito?
5. Capture um print da sequência do passo 3-4 para `evidencias/sprint2/resiliencia-fila.png`.
6. Confirme que a autenticação JWT e o frontend do Sprint 1 continuam funcionando normalmente com as mudanças desta parte (teste ao menos uma operação pelo frontend).
7. Faça o commit:

   ```powershell
   git add agencia/src evidencias/sprint2
   git commit -m "feat(mensageria): substitui chamada REST direta por publish/subscribe via RabbitMQ"
   ```

### 7.5 Perguntas - Parte C

1. No passo 4 da tarefa, o que aconteceu exatamente quando a Agência 1 voltou? Se a mensagem "sumiu" (não foi aplicada), isso foi porque a mensageria falhou, ou por outro motivo? Explique com base no que você observou no log.
2. Compare esse comportamento com o do Sprint 1 (chamada REST direta): o que melhorou com a mensageria, e o que continua sendo um problema em aberto (dica: pense na diferença entre "a mensagem não se perde" e "o sistema está correto")?
3. O consumidor de mensagens (`assinar`) processa créditos sem passar por nenhuma verificação de token JWT. Isso é um problema de segurança? Por que sim, ou por que não - pense em quem consegue publicar uma mensagem na exchange do RabbitMQ hoje, no seu ambiente de desenvolvimento.

---

## 8. Parte D: Linha do tempo causal

### 8.1 `agencia/mesclar-logs.js` (atualizado)

Além de listar os eventos, o script agora compara vetores para apontar quais pares de eventos (de agências diferentes) são comprovadamente concorrentes:

```javascript
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const pastaDados = path.join(__dirname, 'data');
const arquivos = fs.readdirSync(pastaDados).filter((f) => f.endsWith('.jsonl'));

let todosEventos = [];
for (const arquivo of arquivos) {
  const linhas = fs
    .readFileSync(path.join(pastaDados, arquivo), 'utf-8')
    .trim()
    .split('\n')
    .filter(Boolean);
  todosEventos.push(...linhas.map((l) => JSON.parse(l)));
}

todosEventos.sort((a, b) => new Date(a.horaParede) - new Date(b.horaParede));

console.log('=== Linha do tempo (ordenada por hora de parede) ===');
for (const evento of todosEventos) {
  console.log(
    `[${evento.agencia}] vetor=${JSON.stringify(evento.timestampVetorial)} ${evento.tipo}`,
    JSON.stringify(evento.detalhes)
  );
}

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

console.log('\n=== Pares de eventos CONCORRENTES entre agências diferentes ===');
let encontrouConcorrente = false;
for (let i = 0; i < todosEventos.length; i++) {
  for (let j = i + 1; j < todosEventos.length; j++) {
    const e1 = todosEventos[i];
    const e2 = todosEventos[j];
    if (e1.agencia === e2.agencia) continue;
    const relacao = compararVetores(e1.timestampVetorial, e2.timestampVetorial);
    if (relacao === 'CONCORRENTES') {
      encontrouConcorrente = true;
      console.log(
        `[${e1.agencia}] ${e1.tipo} (${JSON.stringify(e1.timestampVetorial)})  x  [${e2.agencia}] ${e2.tipo} (${JSON.stringify(e2.timestampVetorial)})`
      );
    }
  }
}
if (!encontrouConcorrente) {
  console.log('(nenhum par concorrente encontrado nesta execução - gere mais eventos em paralelo e rode de novo)');
}
```

### 8.2 Tarefa

1. Gere uma sequência de eventos que inclua operações independentes acontecendo em agências diferentes sem relação causal entre si (ex.: criar contas em duas agências ao mesmo tempo, sem nenhuma transferência entre elas).
2. Rode `node mesclar-logs.js` e confirme que pelo menos um par desses eventos aparece na lista de concorrentes.
3. Gere também uma transferência entre agências (que tem relação causal - o débito acontece antes do crédito) e confirme que esse par **não** aparece na lista de concorrentes.
4. Capture um print para `evidencias/sprint2/linha-do-tempo-causal.png`.
5. Faça o commit:

   ```powershell
   git add agencia/mesclar-logs.js evidencias/sprint2
   git commit -m "feat(observabilidade): identifica pares de eventos concorrentes via relogio vetorial"
   ```

### 8.3 Perguntas - Parte D

1. No Sprint 1, o relógio de Lamport não permitia essa análise (dois timestamps diferentes não davam certeza sobre concorrência). O que exatamente, no relógio vetorial, torna possível essa comparação confiável?
2. Encontre, no seu próprio teste, um par de eventos que o script classificou como concorrente. Faz sentido, olhando para o que cada evento representa? Explique por que eles realmente não têm relação de causa e efeito entre si.
3. O algoritmo de comparação de vetores neste script é O(n²) no número de eventos (compara todos os pares). Isso seria um problema em um sistema real com milhões de eventos? O que se poderia fazer para tornar essa análise mais escalável?

---

## 9. Adaptando o ICEIBank para Java ou Python

O relógio vetorial é a peça conceitualmente nova deste sprint - por isso vem implementada e testada abaixo, nas duas linguagens. A integração com o RabbitMQ segue a mesma arquitetura do exemplo em Node (uma exchange `topic`, uma fila por agência, routing keys `agencia.<id>.creditar`) - só muda a biblioteca cliente.

### 9.1 Relógio vetorial

**Java (`RelogioVetorial.java`):**

```java
import java.util.Arrays;

public class RelogioVetorial {
    private final int idAgencia;
    private final int[] vetor;

    public RelogioVetorial(int idAgencia, int numeroAgencias) {
        this.idAgencia = idAgencia;
        this.vetor = new int[numeroAgencias];
    }

    public synchronized int[] eventoLocal() {
        vetor[idAgencia] += 1;
        return vetor.clone();
    }

    public synchronized int[] aoEnviar() {
        vetor[idAgencia] += 1;
        return vetor.clone();
    }

    public synchronized int[] aoReceber(int[] vetorRecebido) {
        for (int i = 0; i < vetor.length; i++) {
            vetor[i] = Math.max(vetor[i], vetorRecebido[i]);
        }
        vetor[idAgencia] += 1;
        return vetor.clone();
    }
}
```

**Python (`relogio_vetorial.py`):**

```python
class RelogioVetorial:
    def __init__(self, id_agencia, numero_agencias):
        self.id_agencia = id_agencia
        self.vetor = [0] * numero_agencias

    def evento_local(self):
        self.vetor[self.id_agencia] += 1
        return list(self.vetor)

    def ao_enviar(self):
        self.vetor[self.id_agencia] += 1
        return list(self.vetor)

    def ao_receber(self, vetor_recebido):
        for i in range(len(self.vetor)):
            self.vetor[i] = max(self.vetor[i], vetor_recebido[i])
        self.vetor[self.id_agencia] += 1
        return list(self.vetor)
```

Os três exemplos (Node, Java, Python) produzem exatamente a mesma sequência de vetores para a mesma sequência de chamadas - foi assim que validei os três antes de publicar este roteiro.

### 9.2 Bibliotecas de RabbitMQ para pesquisar

Nenhum código de mensageria é fornecido em Java/Python aqui - a pesquisa e a adaptação fazem parte da tarefa, seguindo a mesma arquitetura (exchange `topic` `iceibank.eventos`, routing keys `agencia.<id>.creditar`) do exemplo em Node:

- **Java:** `com.rabbitmq.client` (cliente oficial), ou o suporte a RabbitMQ do Spring AMQP/Spring Boot (`spring-boot-starter-amqp`), que integra bem com o restante da aplicação Spring já construída no Sprint 1.
- **Python:** `pika`, a biblioteca cliente mais usada para RabbitMQ em Python; se estiver usando FastAPI, vale pesquisar como rodar o consumo de mensagens em paralelo ao servidor HTTP (ex.: em uma thread ou processo separado).

### 9.3 O resto da arquitetura

- **Registro de eventos:** o campo que antes guardava um número (`timestampLamport`) passa a guardar uma lista/array de números (`timestampVetorial`) - ajuste sua classe de log de eventos do Sprint 1 de acordo.
- **Controller de transferências:** a chamada HTTP direta à outra agência (Sprint 1) é substituída pela publicação de uma mensagem - a lógica de decidir "local ou remota" (por partição) continua igual.

---

## 10. Checklist de entrega

- [ ] RabbitMQ rodando, exchange `iceibank.eventos` (`topic`) e 3 filas (uma por agência) configuradas corretamente
- [ ] Relógio vetorial substituindo o relógio de Lamport, com as três regras implementadas
- [ ] Transferência entre agências publicada como mensagem e consumida de forma assíncrona
- [ ] Teste de resiliência (Parte C, tarefa 3-4) reproduzido e documentado - incluindo o que acontece com a conta ausente, não só o "caminho feliz"
- [ ] Script `mesclar-logs.js` identificando corretamente ao menos um par de eventos concorrentes
- [ ] Autenticação JWT e frontend do Sprint 1 continuam funcionando (regressão verificada, não presumida)
- [ ] Pelo menos uma funcionalidade adicional implementada e documentada (seção 2.1)
- [ ] Pasta `evidencias/sprint2/` com os 3 prints indicados na seção 4.3 (mais o da funcionalidade adicional)
- [ ] Arquivo `RESPOSTAS.md` atualizado com as questões das seções 6.4, 7.5 e 8.3, e a descrição da funcionalidade adicional

---

## 11. Critérios de avaliação (20 pontos)

| Critério | Pontos | O que é observado |
|---|:---:|---|
| RabbitMQ configurado corretamente | 3 | Exchange `topic`, filas por agência, routing keys corretas, mensagens duráveis |
| Relógio vetorial | 5 | As três regras implementadas corretamente, inclusive na integração com as mensagens |
| Publish/Subscribe entre agências | 4 | Transferência entre agências funcionando de ponta a ponta via mensageria |
| Linha do tempo causal | 3 | Script identifica corretamente pares concorrentes e pares causalmente relacionados |
| Continuidade (JWT, frontend, particionamento) | 2 | O que já funcionava no Sprint 1 continua funcionando sem regressão |
| Funcionalidade adicional | 1 | Funcionalidade nova e genuína (seção 2.1), funcionando e documentada |
| Commits | 1 | Histórico incremental ao longo do sprint |
| Respostas às questões | 1 | Compreensão demonstrada, com referência ao comportamento observado no código |

A ponderação exata é definida pelo professor responsável pela turma (T1 ou T2), conforme os critérios apresentados em sala.
