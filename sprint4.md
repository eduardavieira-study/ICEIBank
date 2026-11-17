# Roteiro de Projeto - Sprint 4: ICEIBank

**Disciplina:** Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas
**Unidade:** U5 - Computação em Nuvem
**Professores:** T1 - Cleiton Silva Tavares · T2 - Cristiano de Macedo Neto
**Modalidade:** Projeto individual, ao longo do sprint (não é uma atividade de aula única)
**Valor:** 20 pontos (Sprint 4 de 4)
**Pré-requisito:** ter concluído os Sprints 1, 2 e 3 (particionamento, relógios de Lamport e vetorial, API REST/MVC, autenticação JWT, frontend web, mensageria via RabbitMQ, eleição de líder pelo algoritmo de Bully e app Flutter offline-first do ICEIBank).

> **Nota de transparência (uso de IA):** este roteiro foi diagramado e organizado com apoio do Claude (Anthropic), utilizado de forma responsável apenas para redação, estruturação e revisão do material - incluindo a validação do código de exemplo, que foi executado e testado (3 agências reais como processos separados, com quedas injetadas no coordenador e nos participantes, em 41 verificações automatizadas repetidas 3 vezes) antes da publicação. **O que NÃO foi testado de ponta a ponta:** (1) o build das imagens Docker e o `docker compose up`: só a sintaxe do `Dockerfile` e do `docker-compose.yml` foi validada; (2) a Parte F rodando em um **LocalStack real**: o código de nuvem (publicação no SNS, função Lambda, criação dos recursos) foi exercitado contra um emulador diferente (moto), que fala a mesma API da AWS, mas **não** é o LocalStack, e as Lambdas nunca foram executadas dentro dele. Se algo falhar nessas partes, trate como um possível erro do roteiro e avise o professor. O aluno pode utilizar ferramentas de IA para apoiar rascunhos e revisões de código, **desde que declare o uso** na entrega e seja capaz de explicar e defender qualquer trecho entregue. Copiar e colar sem entender o funcionamento do código caracteriza uso não responsável e será tratado como falta de integridade acadêmica.

---

## 1. Visão geral do projeto: ICEIBank

Relembrando o mapeamento completo dos 4 sprints:

| Sprint | Unidade da ementa | Tecnologia | Conceito de Sistemas Distribuídos aplicado |
| --- | --- | --- | --- |
| 1 | U2 - Desenvolvimento Web | API REST / MVC | Relógio lógico de Lamport |
| 2 | U3 - Comunicação indireta | Mensageria / Pub-Sub | Relógio vetorial |
| 3 | U4 - Desenvolvimento Móvel | App Flutter | Consenso (eleição de líder) |
| **4 (este)** | U5 - Computação em Nuvem | Containers | Transações distribuídas (2PC/Saga) |

---

## 2. Escopo desta entrega (Sprint 4)

Desde o Sprint 1 existe uma falha escondida no ICEIBank. Quando uma transferência cruza agências, o Sprint 2 **debita a conta de origem primeiro e só depois publica a mensagem de crédito** no RabbitMQ. Se a agência cair, ou a mensagem se perder, entre essas duas etapas, o dinheiro sai de uma conta e nunca chega na outra. O roteiro do Sprint 1 já avisava: esse é "exatamente o problema que o Sprint 4 vai resolver".

Neste sprint você resolve esse problema com um **protocolo de transação distribuída**: o **Two-Phase Commit (2PC)**. E a líder eleita pelo Bully no Sprint 3, que até aqui era só informativa, ganha finalmente um trabalho: ela é a **coordenadora** de cada transferência. As duas agências envolvidas (a do débito e a do crédito) são as **participantes**.

O 2PC só tem sentido se os participantes conseguem **lembrar de promessas depois de uma queda**. Por isso, o sprint também introduz **persistência em disco** (até agora as contas viviam em um `Map` na memória) e **containers com volumes** (Docker), que é o que permite derrubar e reiniciar uma agência de verdade, e ainda assim preservar o estado. Por fim, o sistema ganha uma **nuvem**: usando o **LocalStack** (um emulador local da AWS), as agências continuam em **containers** e passam a conviver com componentes **serverless** (função Lambda, fila, tópico, bucket e tabela), exatamente como seriam na AWS real.

**O que este sprint entrega:**

- Estado das agências (contas, reservas e transações) persistido em disco de forma atômica
- As 3 agências rodando em containers Docker, orquestradas com `docker compose`, com volumes e reinício automático
- 2PC completo: fase de votação, fase de decisão, reserva de fundos, idempotência
- Recuperação após falhas: do coordenador (aborto presumido) e dos participantes (consulta ao coordenador)
- Rotas internas (Bully e 2PC) protegidas por um segredo compartilhado entre as agências
- Testes de falha reproduzíveis, com injeção de quedas em pontos exatos do protocolo
- Um script que mostra o estado das transações em cada agência
- Nuvem local com LocalStack: as agências em containers e um fluxo **serverless** (SNS, SQS, Lambda, S3 e DynamoDB) que emite o comprovante de cada transferência

**O que este sprint deliberadamente NÃO resolve:**

- **O bloqueio do 2PC.** Se o coordenador cair *depois* de os participantes votarem SIM, eles ficam "em dúvida" e **não podem decidir sozinhos**: o dinheiro reservado fica preso até o coordenador voltar. Você vai provocar e observar isso na Parte D. Resolver de verdade exigiria outro protocolo (3PC, Paxos/Raft) e está fora do escopo.
- **A líder como ponto único de falha.** Se a líder cair, as transferências param até o Bully eleger outra. Transações em andamento são resolvidas na recuperação, não por quem assume a liderança.
- **Persistência de nível de produção.** Gravar o arquivo de estado inteiro a cada mudança é uma simplificação didática. Um banco real usaria um banco de dados com *write-ahead log*.
- **O relógio vetorial reinicia em zero** quando a agência reinicia (ele não é persistido). Isso é uma limitação conhecida e é tema da Pergunta 3 da Parte A.

### 2.1 Funcionalidade adicional (obrigatória)

Mesma regra dos sprints anteriores (detalhes no roteiro do Sprint 1, seção 2.1). Documente em `RESPOSTAS.md`, evidencie com print em `evidencias/sprint4/`, e faça um commit próprio.

Exemplos possíveis para este sprint:

- **Saga com compensação:** implementar a transferência alternativa pelo padrão Saga (debita; credita; se o crédito falhar, **estorna** o débito), selecionável por um parâmetro, e comparar com o 2PC no `RESPOSTAS.md`.
- **Dead-letter queue:** na fila SQS da Parte F (ou no RabbitMQ do Sprint 2), mensagens que falham repetidamente vão para uma fila separada, para inspeção.
- **Padrão outbox:** garantir que nenhum evento de comprovante se perca se a coordenadora cair entre decidir e publicar (veja a Pergunta 3 da Parte F).
- **Implantação na AWS real:** repetir a Parte F em uma conta AWS de verdade (cuidado com custos e com credenciais).
- **Containers gerenciados:** rodar as agências no ECS emulado, se o seu plano do LocalStack incluir esse serviço.
- **Timeouts configuráveis:** o prazo do voto, o intervalo de reentrega e o de resolução de dúvida passam a vir de variáveis de ambiente.
- **Endpoint de saúde:** `GET /saude` (público) que o `docker compose` usa em um `healthcheck`.

### 2.2 Linguagens

O **backend** continua na mesma linguagem escolhida no Sprint 1 (Java ou Python). O código de exemplo deste roteiro está em **Node.js/Express**, apenas como referência ilustrativa dos materiais da disciplina (a seção 11 traz orientações para adaptar às duas linguagens de entrega).

O **app Flutter** não muda neste sprint, mas **não pode quebrar**: a transferência agora passa pelo 2PC e pode demorar um pouco mais ou voltar com `422` (abortada). Confirme que o app trata esses casos. Não há código do app neste roteiro.

---

## 4. Preparação do ambiente

Mesma convenção dos sprints anteriores: **Windows** com **PowerShell**.

- **Docker Desktop** instalado e em execução (`docker --version` e `docker compose version` respondendo)
- Uma **conta no LocalStack** e o seu **token de autenticação** (veja a Parte F). Desde 2026 o LocalStack exige conta e token até para o uso gratuito. **Confira as condições vigentes na página de preços antes de começar**: elas mudam. Não é preciso conta na AWS nem cartão de crédito.
- O backend dos Sprints 1 a 3 continua sendo a base. Neste sprint você o reorganiza, não o descarta.

### 4.1 Estrutura do repositório

```
iceibank/
├── agencia/
│   ├── Dockerfile                          (novo)
│   ├── .dockerignore                       (novo)
│   ├── package.json
│   ├── transacoes.js                       (novo)
│   └── src/
│       ├── app.js                          (atualizado)
│       ├── config.js                       (atualizado)
│       ├── routes.js                       (atualizado)
│       ├── middlewares/
│       │   └── autenticacaoInterna.js      (novo)
│       ├── controllers/
│       │   ├── contasController.js         (atualizado - persiste em disco)
│       │   ├── transferenciasController.js (atualizado - usa o 2PC)
│       │   └── protocoloController.js      (novo - rotas do Bully e do 2PC)
│       └── services/
│           ├── armazenamento.js            (novo - estado durável)
│           ├── saldo.js                    (novo)
│           ├── clienteInterno.js           (novo)
│           ├── falhas.js                   (novo - injeção de falhas)
│           ├── eventosNuvem.js             (novo - publica no SNS)
│           ├── participante.js             (novo)
│           ├── coordenador.js              (novo)
│           ├── bullyService.js             (atualizado)
│           ├── vectorClock.js
│           └── eventLog.js
├── serverless/
│   └── gerar-comprovante/
│       └── index.mjs                       (novo - função Lambda)
├── localstack/
│   └── init.sh                             (novo - cria os recursos "AWS")
├── docker-compose.yml                      (novo)
├── .env                                    (novo - NÃO versionar)
├── frontend/
├── app_mobile/
├── evidencias/
│   ├── sprint1/ ... sprint3/
│   └── sprint4/
├── RESPOSTAS.md
├── .gitignore
└── README.md
```

```powershell
New-Item -ItemType Directory -Force -Path evidencias/sprint4
```

Adicione `.env`, `agencia/data/` e `serverless/build/` ao `.gitignore`: o primeiro contém segredos (inclusive o token do LocalStack), o segundo contém estado de teste e o terceiro, arquivos gerados.

> **Atenção ao seu código dos sprints anteriores.** O código deste roteiro substitui `contasController.js` e `transferenciasController.js` e assume que as contas vivem em `estado.contas`. Se o seu projeto tem JWT nas rotas públicas, o middleware de autenticação continua exatamente onde está: acrescente-o às rotas públicas de `routes.js` como você já fazia. Os exemplos omitem o JWT apenas para ficarem curtos.

### 4.2 Evidências de teste

Mesma convenção: prints reais, com `Get-Date` visível em algum terminal.

- `evidencias/sprint4/compose-up.png` - `docker compose ps` com as 3 agências no ar
- `evidencias/sprint4/persistencia-volume.png` - uma agência reiniciada (`docker compose restart`) mantendo o saldo
- `evidencias/sprint4/token-interno-401.png` - uma rota interna recusando a chamada sem o token (401)
- `evidencias/sprint4/2pc-commit.png` - uma transferência entre agências concluída, com os logs mostrando as duas fases
- `evidencias/sprint4/2pc-abort.png` - uma transferência abortada (saldo insuficiente) sem nenhum efeito residual
- `evidencias/sprint4/falha-participante.png` - a queda de um participante e a resolução automática (seção 8.2)
- `evidencias/sprint4/falha-coordenador.png` - a queda do coordenador e a recuperação (seção 8.3)
- `evidencias/sprint4/bloqueio.png` - o bloqueio do 2PC: reserva presa com o coordenador fora do ar (seção 8.4)
- `evidencias/sprint4/transacoes-js.png` - a saída do script `transacoes.js`
- `evidencias/sprint4/localstack-saude.png` - o LocalStack no ar, com os serviços usados disponíveis (`/_localstack/health`)
- `evidencias/sprint4/comprovante-s3-dynamo.png` - o comprovante de uma transferência no S3 e o registro no DynamoDB, gerados pela Lambda
- `evidencias/sprint4/api-comprovante.png` - a consulta de um comprovante pela API (sua segunda Lambda)
- `evidencias/sprint4/nuvem-fora-do-ar.png` - uma transferência concluindo normalmente com o LocalStack parado

### 4.3 Portas exclusivas

Em containers, cada agência escuta em sua porta (4000, 4001, 4002), mapeada para a sua máquina. O `OFFSET` pessoal só é necessário se você ainda rodar fora de containers em uma máquina compartilhada do laboratório.

### 4.4 Disciplina de commits

Mesma orientação: trabalho individual, commits pequenos e incrementais ao longo das 3 semanas.

---

## 5. Parte A: Persistência, containers e rotas internas protegidas

**Conceito:** um participante de 2PC que vota SIM está fazendo uma **promessa**: "eu garanto que consigo aplicar essa operação quando você mandar". Se a agência cai e **esquece** a promessa, o protocolo quebra. Por isso a promessa precisa estar em **disco** *antes* de o voto ser enviado.

Gravar um arquivo de forma segura exige cuidado: se a agência cair no meio da escrita, o arquivo não pode ficar pela metade. A solução clássica é escrever em um arquivo temporário, forçar a gravação em disco (`fsync`) e só então **renomear** o temporário para o nome definitivo (a operação de renomear é atômica).

Em seguida, containers: um container tem um disco **efêmero**, que desaparece quando o container é recriado. Para o estado sobreviver, ele precisa ficar em um **volume**.

### 5.1 `agencia/src/config.js` (atualizado)

A configuração passa a vir de variáveis de ambiente: em containers, as agências se enxergam pelo **nome do serviço** (`agencia-1`), não por `localhost`.

```javascript
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// TODO: substitua pelo seu OFFSET pessoal (dois últimos dígitos da matrícula/RA),
// necessário apenas se for rodar em uma máquina compartilhada do laboratório.
const OFFSET = 0;

const NUMERO_AGENCIAS = 3;
const PORTA_BASE = parseInt(process.env.PORTA_BASE || String(4000 + OFFSET), 10);

// Em containers, as agências se enxergam pelo nome do serviço (ex.: agencia-1).
// Fora de containers, tudo é localhost.
const HOSTS = (process.env.AGENCIAS_HOSTS || 'localhost,localhost,localhost').split(',');

// Onde ficam os arquivos que precisam sobreviver a um reinício (estado e logs).
// Em containers, aponte para um volume (ex.: /dados).
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, '..', 'data');

// Segredo compartilhado entre as agências para as rotas internas (Bully e 2PC).
const TOKEN_INTERNO = process.env.TOKEN_INTERNO || '';

// AGENCIA_URL_<id> permite sobrescrever a URL completa de uma agência
// (útil na nuvem, onde cada agência tem uma URL pública própria).
const AGENCIAS = [0, 1, 2].map((id) => ({
  id,
  url: process.env[`AGENCIA_URL_${id}`] || `http://${HOSTS[id]}:${PORTA_BASE + id}`,
}));

function agenciaResponsavel(idConta) {
  return idConta % NUMERO_AGENCIAS;
}

export { NUMERO_AGENCIAS, AGENCIAS, agenciaResponsavel, OFFSET, DATA_DIR, TOKEN_INTERNO };
```

### 5.2 `agencia/src/services/armazenamento.js`

Tudo que precisa sobreviver a uma queda (contas, reservas e o estado das transações) fica em **um único arquivo** por agência. Assim, uma mudança de saldo e a mudança do estado da transação são gravadas **juntas**, ou nenhuma das duas é.

```javascript
import fs from 'fs';
import path from 'path';
import * as config from '../config.js';

// Tudo que precisa sobreviver a uma queda (contas, reservas e o estado das
// transações distribuídas) vive em UM único arquivo, gravado de forma atômica:
// escreve num arquivo temporário, força a gravação em disco (fsync) e só então
// troca o nome para o arquivo definitivo (rename é atômico).
class EstadoDuravel {
  constructor(idAgencia) {
    fs.mkdirSync(config.DATA_DIR, { recursive: true });
    this.caminho = path.join(config.DATA_DIR, `estado-agencia-${idAgencia}.json`);
    this.contas = new Map();
    this.coordenacoes = new Map();
    this.participacoes = new Map();
    this.carregar();
  }

  carregar() {
    if (!fs.existsSync(this.caminho)) return;
    const dados = JSON.parse(fs.readFileSync(this.caminho, 'utf-8'));
    this.contas = new Map(dados.contas);
    this.coordenacoes = new Map(dados.coordenacoes);
    this.participacoes = new Map(dados.participacoes);
  }

  salvar() {
    const dados = {
      contas: [...this.contas],
      coordenacoes: [...this.coordenacoes],
      participacoes: [...this.participacoes],
    };
    const temporario = this.caminho + '.tmp';
    const fd = fs.openSync(temporario, 'w');
    fs.writeSync(fd, JSON.stringify(dados));
    fs.fsyncSync(fd);
    fs.closeSync(fd);
    fs.renameSync(temporario, this.caminho);
  }
}

export default EstadoDuravel;
```

### 5.3 `agencia/src/services/saldo.js`

Quando uma agência vota SIM para um débito, ela **reserva** o valor: o dinheiro continua na conta (`saldo`), mas não pode mais ser gasto por outra operação. O que pode ser gasto é o `saldoDisponivel`:

```javascript
// Saldo que realmente pode ser gasto agora: o saldo menos o que está
// reservado por transações distribuídas que ainda não terminaram.
function saldoDisponivel(conta) {
  return conta.saldo - (conta.reservado || 0);
}

export { saldoDisponivel };
```

### 5.4 `agencia/src/controllers/contasController.js` (atualizado)

As contas agora vivem em `estado.contas` e **todo** endpoint que muda saldo chama `estado.salvar()`. Note também que o saque respeita o `saldoDisponivel`:

```javascript
import * as config from '../config.js';
import { saldoDisponivel } from '../services/saldo.js';

function criarContasController({ idAgencia, estado, relogio, registro }) {
  function proximoId() {
    // ids das contas desta agência: idAgencia, idAgencia+3, idAgencia+6...
    const existentes = [...estado.contas.keys()];
    if (existentes.length === 0) return idAgencia;
    return Math.max(...existentes) + config.NUMERO_AGENCIAS;
  }

  function visao(conta) {
    return { id: conta.id, titular: conta.titular, saldo: conta.saldo, reservado: conta.reservado || 0, disponivel: saldoDisponivel(conta) };
  }

  function criar(req, res) {
    const { titular, saldoInicial = 0 } = req.body;
    if (!titular || typeof saldoInicial !== 'number' || saldoInicial < 0) {
      return res.status(400).json({ erro: 'Informe titular e saldoInicial (número >= 0).' });
    }
    const conta = { id: proximoId(), titular, saldo: saldoInicial, reservado: 0 };
    estado.contas.set(conta.id, conta);
    estado.salvar();
    registro.registrar('CONTA_CRIADA', relogio.eventoLocal(), { id: conta.id });
    res.status(201).json(visao(conta));
  }

  function obter(req, res) {
    const conta = estado.contas.get(Number(req.params.id));
    if (!conta) return res.status(404).json({ erro: 'Conta não encontrada nesta agência.' });
    res.json(visao(conta));
  }

  function depositar(req, res) {
    const conta = estado.contas.get(Number(req.params.id));
    const { valor } = req.body;
    if (!conta) return res.status(404).json({ erro: 'Conta não encontrada nesta agência.' });
    if (typeof valor !== 'number' || valor <= 0) return res.status(400).json({ erro: 'Valor inválido.' });
    conta.saldo += valor;
    estado.salvar();
    registro.registrar('DEPOSITO', relogio.eventoLocal(), { id: conta.id, valor });
    res.json(visao(conta));
  }

  function sacar(req, res) {
    const conta = estado.contas.get(Number(req.params.id));
    const { valor } = req.body;
    if (!conta) return res.status(404).json({ erro: 'Conta não encontrada nesta agência.' });
    if (typeof valor !== 'number' || valor <= 0) return res.status(400).json({ erro: 'Valor inválido.' });
    if (saldoDisponivel(conta) < valor) return res.status(422).json({ erro: 'Saldo insuficiente.' });
    conta.saldo -= valor;
    estado.salvar();
    registro.registrar('SAQUE', relogio.eventoLocal(), { id: conta.id, valor });
    res.json(visao(conta));
  }

  return { criar, obter, depositar, sacar };
}

export default criarContasController;
```

### 5.5 Rotas internas protegidas

Até o Sprint 3, qualquer pessoa que descobrisse a URL de uma agência podia chamar `/bully/eleicao`. Agora existem rotas que **movimentam dinheiro** (`/2pc/preparar`, `/2pc/decidir`), então elas precisam ser fechadas. Usaremos um **segredo compartilhado** entre as agências, enviado no cabeçalho `x-token-interno`.

`agencia/src/middlewares/autenticacaoInterna.js`:

```javascript
import * as config from '../config.js';

// Protege as rotas que só outras agências deveriam chamar.
function autenticacaoInterna(req, res, next) {
  if (req.get('x-token-interno') !== config.TOKEN_INTERNO) {
    return res.status(401).json({ erro: 'Token interno ausente ou inválido.' });
  }
  next();
}

export default autenticacaoInterna;
```

`agencia/src/services/clienteInterno.js`:

```javascript
import axios from 'axios';
import * as config from '../config.js';

// Cliente HTTP para falar com as OUTRAS agências nas rotas internas (Bully e 2PC).
// Já anexa o token compartilhado em todas as requisições.
const clienteInterno = axios.create({
  headers: { 'x-token-interno': config.TOKEN_INTERNO },
});

export default clienteInterno;
```

> O `GET /bully/lider` **continua público**: o app Flutter do Sprint 3 consulta essa rota para exibir a líder, e fechá-la quebraria o app. Fechar rotas é sempre uma decisão com custo: quem as consome precisa ser atualizado.

### 5.6 `agencia/Dockerfile` e `agencia/.dockerignore`

`agencia/Dockerfile`:

```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY src ./src
ENV DATA_DIR=/dados
VOLUME /dados
CMD ["node", "src/app.js"]
```

`agencia/.dockerignore`:

```text
node_modules
data
test
*.log
```

### 5.7 `docker-compose.yml` e `.env`

```yaml
services:
  agencia-0:
    build: ./agencia
    environment: &comum
      AGENCIA_ID: "0"
      FALHA_2PC: "${FALHA_2PC_0:-}"
      TOKEN_INTERNO: ${TOKEN_INTERNO:?defina TOKEN_INTERNO no arquivo .env}
      PORTA_BASE: "4000"
      AGENCIAS_HOSTS: agencia-0,agencia-1,agencia-2
      # Nuvem local (Parte F). Com SNS_TOPIC_ARN vazio, a agência não publica eventos.
      AWS_ENDPOINT_URL: http://localstack:4566
      AWS_REGION: us-east-1
      AWS_ACCESS_KEY_ID: test
      AWS_SECRET_ACCESS_KEY: test
      SNS_TOPIC_ARN: ${SNS_TOPIC_ARN:-}
    ports: ["4000:4000"]
    volumes: ["dados-0:/dados"]
    restart: on-failure
  agencia-1:
    build: ./agencia
    environment:
      <<: *comum
      AGENCIA_ID: "1"
      FALHA_2PC: "${FALHA_2PC_1:-}"
    ports: ["4001:4001"]
    volumes: ["dados-1:/dados"]
    restart: on-failure
  agencia-2:
    build: ./agencia
    environment:
      <<: *comum
      AGENCIA_ID: "2"
      FALHA_2PC: "${FALHA_2PC_2:-}"
    ports: ["4002:4002"]
    volumes: ["dados-2:/dados"]
    restart: on-failure
  localstack:
    profiles: ["nuvem"]   # só sobe com: docker compose --profile nuvem up
    image: localstack/localstack
    ports: ["4566:4566"]
    environment:
      LOCALSTACK_AUTH_TOKEN: ${LOCALSTACK_AUTH_TOKEN:-}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock   # o LocalStack cria containers para executar as Lambdas
      - ./localstack:/scripts:ro
      - ./serverless/build:/serverless:ro

volumes:
  dados-0:
  dados-1:
  dados-2:
```

Crie o arquivo `.env` na mesma pasta do `docker-compose.yml` (e **não o versione**):

```text
TOKEN_INTERNO=troque-este-segredo
```

(Na Parte F você acrescentará outras duas linhas a este arquivo.)

Pontos de atenção:

- Cada agência tem seu **volume nomeado** (`dados-0`, `dados-1`, `dados-2`), montado em `/dados`, onde ficam o estado e os logs.
- `restart: on-failure` reinicia o container se o processo terminar com erro. É assim que a "queda" injetada na Parte D vira uma recuperação automática.
- O serviço `localstack` pertence à **Parte F**: ele está em um *profile* (`nuvem`) e **não sobe** com o `docker compose up` comum. Ignore-o por enquanto.
- `FALHA_2PC_0`, `FALHA_2PC_1` e `FALHA_2PC_2` são variáveis que você usará na Parte D para derrubar uma agência em um ponto exato do protocolo. Vazias, não fazem nada.

### 5.8 `agencia/src/app.js` (integração, versão final)

Este é o `app.js` final do sprint, já com as partes B e C encaixadas. **Volte aqui quando chegar nelas.** Observe a linha `coordenador.recuperar()`: a recuperação roda **antes** de a agência aceitar requisições.

```javascript
import express from 'express';
import * as config from './config.js';
import EstadoDuravel from './services/armazenamento.js';
import RelogioVetorial from './services/vectorClock.js';
import RegistroEventos from './services/eventLog.js';
import criarEventosNuvem from './services/eventosNuvem.js';
import criarServicoBully from './services/bullyService.js';
import criarCoordenador from './services/coordenador.js';
import criarParticipante from './services/participante.js';
import criarContasController from './controllers/contasController.js';
import criarTransferenciasController from './controllers/transferenciasController.js';
import criarProtocoloController from './controllers/protocoloController.js';
import criarRotas from './routes.js';

const idAgencia = parseInt(process.env.AGENCIA_ID, 10);
if (![0, 1, 2].includes(idAgencia)) {
  console.error('Defina AGENCIA_ID com 0, 1 ou 2.');
  process.exit(1);
}
if (!config.TOKEN_INTERNO) {
  console.error('Defina TOKEN_INTERNO (segredo compartilhado entre as agências).');
  process.exit(1);
}

const estado = new EstadoDuravel(idAgencia);
const relogio = new RelogioVetorial(idAgencia, config.NUMERO_AGENCIAS);
const registro = new RegistroEventos(`agencia-${idAgencia}`);
const bully = criarServicoBully(idAgencia, relogio, registro);
const eventosNuvem = criarEventosNuvem({ idAgencia, relogio, registro });
const coordenador = criarCoordenador({ idAgencia, relogio, registro, estado, eventosNuvem });
const participante = criarParticipante({ idAgencia, relogio, registro, estado });

// Recuperação ANTES de aceitar requisições: decide o destino das transações
// que estavam em andamento quando a agência caiu.
coordenador.recuperar();

const app = express();
app.use(express.json());
app.use(
  criarRotas({
    contas: criarContasController({ idAgencia, estado, relogio, registro }),
    transferencias: criarTransferenciasController({ idAgencia, bully, coordenador }),
    protocolo: criarProtocoloController({ bully, participante, coordenador, estado, relogio }),
  })
);

const porta = new URL(config.AGENCIAS[idAgencia].url).port || process.env.PORT;
const escutar = process.env.PORT || porta;
app.listen(escutar, () => {
  console.log(`Agência ${idAgencia} no ar na porta ${escutar}`);
  participante.iniciarResolucao();
  coordenador.iniciarReentrega();
  bully.iniciarEleicao();
  bully.iniciarHeartbeat();
});
```

### 5.9 Tarefa

1. Reorganize seu backend conforme a seção 4.1 e atualize `config.js`, `armazenamento.js`, `saldo.js` e `contasController.js`.
2. Suba o conjunto: `docker compose up --build`.
3. Crie uma conta em cada agência e consulte os saldos:

```powershell
Invoke-RestMethod -Uri "http://localhost:4000/contas" -Method Post -ContentType "application/json" -Body '{"titular":"Ana","saldoInicial":1000}'
Invoke-RestMethod -Uri "http://localhost:4000/contas/0" -Method Get
```

4. Reinicie **uma** agência e confirme que a conta continua lá (o volume funcionou):

```powershell
docker compose restart agencia-0
Invoke-RestMethod -Uri "http://localhost:4000/contas/0" -Method Get
```

5. Confirme a proteção das rotas internas. A primeira chamada deve responder **401**; a segunda, **200**:

```powershell
Invoke-RestMethod -Uri "http://localhost:4000/2pc/transacoes" -Method Get
Invoke-RestMethod -Uri "http://localhost:4000/2pc/transacoes" -Method Get -Headers @{ "x-token-interno" = "troque-este-segredo" }
```

6. Capture os prints `compose-up.png`, `persistencia-volume.png` e `token-interno-401.png`.
7. Faça o commit:

```powershell
git add agencia docker-compose.yml evidencias/sprint4 .gitignore
git commit -m "feat(sprint4): persistencia atomica, containers e rotas internas protegidas"
```

### 5.10 Perguntas - Parte A

1. Por que o arquivo é gravado em um temporário e depois **renomeado**, em vez de sobrescrever o arquivo definitivo diretamente? O que poderia ficar no disco se a agência caísse no meio de uma escrita direta?
2. Se você removesse o volume do `docker-compose.yml` e recriasse os containers (`docker compose down` seguido de `up`), o que aconteceria com as contas? E se, no meio de uma transação 2PC, um participante perdesse o disco dessa forma: o que ele "esqueceria" e que problema isso causaria ao protocolo?
3. O relógio vetorial (Sprint 2) **não** foi persistido: ao reiniciar, a agência volta a contar de `[0,0,0]`. Isso pode violar a causalidade registrada nos logs? Descreva um cenário concreto e proponha uma correção simples.
4. O token interno é um segredo **compartilhado**: qualquer agência (ou quem o descobrir) pode chamar qualquer rota interna de qualquer outra. Quais são os limites dessa proteção? O que seria mais robusto (ex.: TLS mútuo, rede privada)?

---

## 6. Parte B: O participante do 2PC

**Conceito:** no Two-Phase Commit, uma transação distribuída passa por duas fases.

1. **Fase 1 (votação):** o coordenador pergunta a cada participante: "você consegue aplicar esta operação?". Cada um responde SIM ou NAO. Quem responde SIM **se compromete**: não pode mais mudar de ideia sozinho.
2. **Fase 2 (decisão):** se **todos** votaram SIM, o coordenador decide **COMMIT**. Se **qualquer um** votou NAO (ou não respondeu), decide **ABORT**. Em ambos os casos, comunica a decisão a todos.

Em uma transferência do ICEIBank, os dois participantes são: a agência da conta de **origem** (operação `DEBITO`) e a agência da conta de **destino** (operação `CREDITO`). Se as duas contas estão na mesma agência, ela participa duas vezes da mesma transação.

Regras do participante:

- Ao votar **SIM** em um débito, **reserva** o valor e **grava em disco antes de responder**.
- Ao votar **NAO**, registra o aborto e não reserva nada.
- Ao receber a decisão, **aplica** (COMMIT: move o dinheiro) ou **descarta** (ABORT: libera a reserva).
- Tudo é **idempotente**: receber a mesma pergunta ou a mesma decisão duas vezes não pode duplicar o efeito (a rede pode repetir mensagens).
- Se votou SIM e a decisão **não chega**, está **em dúvida**: não decide sozinho. Pergunta ao coordenador, repetidamente, até obter resposta.

### 6.1 `agencia/src/services/falhas.js`

Para testar recuperação você precisa derrubar uma agência em um **ponto exato** do protocolo, e isso precisa ser repetível. Este módulo derruba o processo (`exit(1)`) quando a variável `FALHA_2PC` contém o nome do ponto, **uma única vez**: um arquivo marcador impede que a agência caia de novo toda vez que o Docker a reiniciar (o que causaria um loop de quedas).

```javascript
import fs from 'fs';
import path from 'path';
import * as config from '../config.js';

// Injeção de falhas para os testes da Parte C: derruba o processo em um ponto
// exato do protocolo, UMA única vez (um arquivo marcador impede que a agência
// caia de novo toda vez que for reiniciada, o que causaria um loop de quedas).
//
// Uso (PowerShell): $env:FALHA_2PC="participante-apos-votar"
// Para repetir um cenário, apague o arquivo data/falha-*.consumida.
function falhar(ponto) {
  if (process.env.FALHA_2PC !== ponto) return;
  const idAgencia = process.env.AGENCIA_ID || '0';
  const marcador = path.join(config.DATA_DIR, `falha-${idAgencia}-${ponto}.consumida`);
  if (fs.existsSync(marcador)) return;
  fs.writeFileSync(marcador, new Date().toISOString());
  console.error(`[FALHA INJETADA] ${ponto}: derrubando a agência ${idAgencia} agora`);
  process.exit(1);
}

export { falhar };
```

### 6.2 `agencia/src/services/participante.js`

```javascript
import * as config from '../config.js';
import clienteInterno from './clienteInterno.js';
import { saldoDisponivel } from './saldo.js';
import { falhar } from './falhas.js';

const TIMEOUT_MS = 2000;
const INTERVALO_RESOLUCAO_MS = 3000;

// Papel de PARTICIPANTE no 2PC: cada agência envolvida na transferência
// (a do débito e a do crédito) responde a "preparar" e "decidir".
function criarParticipante({ idAgencia, relogio, registro, estado }) {
  const avisouBloqueio = new Set();
  let resolvendo = false;

  // FASE 1: o participante vota. Só vota SIM se tem certeza de que conseguirá
  // aplicar a operação quando o coordenador mandar. E, ao votar SIM, ele se
  // COMPROMETE: grava a promessa em disco ANTES de responder.
  function preparar({ txId, operacao, coordenador, vetorEnvio }) {
    if (vetorEnvio) relogio.aoReceber(vetorEnvio);

    // A chave inclui o tipo porque, numa transferência entre contas da MESMA
    // agência, ela participa duas vezes da mesma transação (débito e crédito).
    const chave = `${txId}:${operacao.tipo}`;
    const existente = estado.participacoes.get(chave);
    if (existente) {
      // idempotência: o coordenador pode repetir a pergunta
      return { voto: existente.estado === 'ABORTADO' ? 'NAO' : 'SIM', vetorEnvio: relogio.aoEnviar() };
    }

    const conta = estado.contas.get(operacao.idConta);
    let motivo = null;
    if (!conta) {
      motivo = 'Conta não encontrada nesta agência.';
    } else if (operacao.tipo === 'DEBITO' && saldoDisponivel(conta) < operacao.valor) {
      motivo = 'Saldo insuficiente.';
    }

    if (motivo) {
      estado.participacoes.set(chave, { txId, coordenador, operacao, estado: 'ABORTADO', motivo });
      estado.salvar();
      registro.registrar('2PC_VOTO_NAO', relogio.eventoLocal(), { txId, motivo });
      return { voto: 'NAO', motivo, vetorEnvio: relogio.aoEnviar() };
    }

    if (operacao.tipo === 'DEBITO') {
      conta.reservado = (conta.reservado || 0) + operacao.valor; // o dinheiro fica "travado"
    }
    estado.participacoes.set(chave, { txId, coordenador, operacao, estado: 'PREPARADO' });
    estado.salvar(); // promessa durável ANTES de responder SIM
    registro.registrar('2PC_VOTO_SIM', relogio.eventoLocal(), { txId, operacao });
    falhar('participante-apos-votar'); // caiu depois de se comprometer, antes de responder
    return { voto: 'SIM', vetorEnvio: relogio.aoEnviar() };
  }

  // FASE 2: o coordenador comunica a decisão final. Aplica (ou descarta) a
  // operação preparada. Idempotente: receber a mesma decisão duas vezes é seguro.
  function decidir({ txId, decisao, vetorEnvio }) {
    if (vetorEnvio) relogio.aoReceber(vetorEnvio);

    const minhas = [...estado.participacoes.values()].filter((x) => x.txId === txId);
    if (minhas.length === 0) {
      if (decisao === 'ABORT') return { ok: true, vetorEnvio: relogio.aoEnviar() };
      return { erro: 'Transação desconhecida por este participante.' };
    }

    falhar('participante-antes-de-aplicar'); // caiu com a decisão em mãos, sem aplicá-la
    for (const p of minhas) {
      if (p.estado !== 'PREPARADO') continue;
      const conta = estado.contas.get(p.operacao.idConta);
      const { tipo, valor } = p.operacao;
      if (decisao === 'COMMIT') {
        if (tipo === 'DEBITO') {
          conta.saldo -= valor;
          conta.reservado -= valor;
        } else {
          conta.saldo += valor;
        }
        p.estado = 'COMMITADO';
      } else {
        if (tipo === 'DEBITO') conta.reservado -= valor;
        p.estado = 'ABORTADO';
      }
      registro.registrar(`2PC_${decisao}_APLICADO`, relogio.eventoLocal(), { txId, tipo, valor });
    }
    estado.salvar(); // saldo, reserva e estado da transação mudam juntos, de forma atômica
    return { ok: true, vetorEnvio: relogio.aoEnviar() };
  }

  // Se este participante votou SIM e nunca recebeu a decisão (o coordenador caiu,
  // a rede falhou...), ele está "em dúvida": não pode decidir sozinho. Só resta
  // perguntar ao coordenador, repetidamente, até conseguir resposta.
  async function resolverEmDuvida() {
    if (resolvendo) return;
    resolvendo = true;
    try {
      for (const p of estado.participacoes.values()) {
        if (p.estado !== 'PREPARADO') continue;
        const coord = config.AGENCIAS.find((a) => a.id === p.coordenador);
        try {
          const resp = await clienteInterno.get(`${coord.url}/2pc/status/${p.txId}`, { timeout: TIMEOUT_MS });
          const { decisao } = resp.data;
          if (decisao === 'COMMIT' || decisao === 'ABORT') {
            registro.registrar('2PC_RESOLVIDA_POR_CONSULTA', relogio.eventoLocal(), { txId: p.txId, decisao });
            decidir({ txId: p.txId, decisao });
            avisouBloqueio.delete(p.txId);
          }
        } catch (erro) {
          if (!avisouBloqueio.has(p.txId)) {
            avisouBloqueio.add(p.txId);
            registro.registrar('2PC_BLOQUEADA_AGUARDANDO_COORDENADOR', relogio.eventoLocal(), {
              txId: p.txId,
              coordenador: p.coordenador,
            });
          }
        }
      }
    } finally {
      resolvendo = false;
    }
  }

  function iniciarResolucao() {
    resolverEmDuvida();
    setInterval(resolverEmDuvida, INTERVALO_RESOLUCAO_MS);
  }

  return { preparar, decidir, iniciarResolucao };
}

export default criarParticipante;
```

Leia os comentários com atenção, especialmente:

- a **chave** `txId:tipo` (por que o tipo faz parte da chave?);
- o `estado.salvar()` **antes** do `return` do voto SIM;
- a função `resolverEmDuvida`.

### 6.3 `agencia/src/controllers/protocoloController.js` e `routes.js`

Os handlers das rotas internas do Bully e do 2PC ficam juntos:

`agencia/src/controllers/protocoloController.js`:

```javascript
// Rotas internas do Bully e do 2PC (chamadas apenas por outras agências).
function criarProtocoloController({ bully, participante, coordenador, estado, relogio }) {
  return {
    eleicao(req, res) {
      bully.receberEleicao(req.body.origemId, req.body.vetorEnvio);
      res.json({ ok: true, vetorEnvio: relogio.aoEnviar() });
    },
    coordenadorAnunciado(req, res) {
      bully.receberCoordenador(req.body.liderId, req.body.vetorEnvio);
      res.json({ ok: true });
    },
    lider(req, res) {
      res.json({ lider: bully.obterLiderAtual() });
    },
    preparar(req, res) {
      res.json(participante.preparar(req.body));
    },
    decidir(req, res) {
      const r = participante.decidir(req.body);
      res.status(r.erro ? 409 : 200).json(r);
    },
    status(req, res) {
      res.json(coordenador.statusDe(req.params.txId));
    },
    transacoes(req, res) {
      res.json({
        coordenacoes: [...estado.coordenacoes.values()],
        participacoes: [...estado.participacoes.values()],
        vetor: relogio.obterVetorAtual(),
      });
    },
  };
}

export default criarProtocoloController;
```

`agencia/src/routes.js`:

```javascript
import express from 'express';
import autenticacaoInterna from './middlewares/autenticacaoInterna.js';

function criarRotas({ contas, transferencias, protocolo }) {
  const r = express.Router();

  // Rotas públicas (clientes e app Flutter). GET /bully/lider continua público
  // para o app descobrir o líder sem precisar do segredo interno.
  r.post('/contas', contas.criar);
  r.get('/contas/:id', contas.obter);
  r.post('/contas/:id/depositar', contas.depositar);
  r.post('/contas/:id/sacar', contas.sacar);
  r.post('/transferencias', transferencias.transferir);
  r.get('/bully/lider', protocolo.lider);

  // Rotas internas: só com o token compartilhado entre agências.
  r.post('/bully/eleicao', autenticacaoInterna, protocolo.eleicao);
  r.post('/bully/coordenador', autenticacaoInterna, protocolo.coordenadorAnunciado);
  r.post('/2pc/coordenar', autenticacaoInterna, transferencias.coordenarARequisicao);
  r.post('/2pc/preparar', autenticacaoInterna, protocolo.preparar);
  r.post('/2pc/decidir', autenticacaoInterna, protocolo.decidir);
  r.get('/2pc/status/:txId', autenticacaoInterna, protocolo.status);
  r.get('/2pc/transacoes', autenticacaoInterna, protocolo.transacoes);

  return r;
}

export default criarRotas;
```

### 6.4 Atualização do Bully

Ao testar com as 3 agências subindo ao mesmo tempo, o código de Bully do Sprint 3 revela uma fragilidade: se uma agência sobe **antes** das outras, ela se autoproclama líder. Esse anúncio pode chegar **depois** de uma agência de ID maior já ter assumido, e a de ID maior aceitava o anúncio, ficando com a líder errada. A regra do Bully que faltava: **um líder anunciado com ID menor que o meu não vale; eu disputo a liderança.**

Substitua `receberCoordenador` em `bullyService.js` por:

```javascript
  function receberCoordenador(liderId, vetorRecebido) {
    const vetor = relogio.aoReceber(vetorRecebido);
    // Regra do Bully: um líder com id MENOR que o meu não vale. Isso acontece
    // quando uma agência sobe antes das outras e se autoproclama líder. Em vez
    // de aceitar, disputo a liderança (e vou vencer, pois meu id é maior).
    if (liderId < idAgencia) {
      registro.registrar('LIDER_MENOR_REJEITADO', vetor, { liderId, agencia: idAgencia });
      iniciarEleicao();
      return;
    }
    liderAtual = liderId;
    registro.registrar('LIDER_ANUNCIADO', vetor, { liderId, agencia: idAgencia });
  }
```

Além disso, no `bullyService.js`, troque a importação de `axios` por `import axios from './clienteInterno.js';` para que as mensagens do Bully levem o token interno.

### 6.5 Tarefa

1. Implemente `falhas.js`, `participante.js`, `protocoloController.js` e as rotas.
2. Com as agências no ar, simule o papel do coordenador **à mão**, chamando as rotas internas. Primeiro a votação:

```powershell
$h = @{ "x-token-interno" = "troque-este-segredo" }
$corpo = '{"txId":"teste-1","operacao":{"tipo":"DEBITO","idConta":0,"valor":100},"coordenador":2}'
Invoke-RestMethod -Uri "http://localhost:4000/2pc/preparar" -Method Post -ContentType "application/json" -Headers $h -Body $corpo
Invoke-RestMethod -Uri "http://localhost:4000/contas/0" -Method Get
```

Observe o `reservado` e o `disponivel` da conta. Depois, a decisão, **duas vezes** (para ver a idempotência):

```powershell
$d = '{"txId":"teste-1","decisao":"COMMIT"}'
Invoke-RestMethod -Uri "http://localhost:4000/2pc/decidir" -Method Post -ContentType "application/json" -Headers $h -Body $d
Invoke-RestMethod -Uri "http://localhost:4000/2pc/decidir" -Method Post -ContentType "application/json" -Headers $h -Body $d
Invoke-RestMethod -Uri "http://localhost:4000/contas/0" -Method Get
```

3. Repita com `"decisao":"ABORT"` em outra transação (`teste-2`) e confirme que a reserva é liberada e o saldo não muda.
4. Faça o commit:

```powershell
git add agencia evidencias/sprint4
git commit -m "feat(2pc): participante com reserva de fundos, idempotencia e resolucao de duvida"
```

### 6.6 Perguntas - Parte B

1. Por que o participante grava a promessa em disco **antes** de responder SIM? Descreva o que poderia dar errado se gravasse **depois**.
2. O que significa a operação ser **idempotente** aqui? Por que a rede torna isso obrigatório, e não opcional?
3. Por que o participante, depois de votar SIM, **não pode** decidir sozinho abortar (por exemplo, por timeout), mesmo que o coordenador esteja demorando?
4. Por que o débito reserva o valor na fase 1 em vez de simplesmente debitar? O que poderia acontecer com duas transferências simultâneas da mesma conta sem a reserva?

---

## 7. Parte C: O coordenador, a recuperação e a nova `transferir`

**Conceito:** o coordenador conduz a transação e é quem **decide**. Pontos críticos:

- A decisão só vale depois de **gravada em disco**. Esse é o "ponto sem volta": se o coordenador cai logo depois de gravar, ele sabe, ao voltar, qual foi a decisão.
- **COMMIT só se todos votaram SIM.** Timeout conta como NAO.
- A decisão precisa ser **entregue** a todos os participantes. Se algum estiver fora do ar, o coordenador **insiste periodicamente** até receber a confirmação.
- **Aborto presumido:** se o coordenador cai *antes* de decidir e volta, ele não tem registro de uma decisão. Ele decide **ABORT** para essas transações. Isso é seguro porque nenhum participante pode ter recebido COMMIT (a decisão nunca foi tomada), e ninguém pode ter aplicado nada.
- Quando um participante em dúvida pergunta sobre uma transação que o coordenador **desconhece**, a resposta é ABORT, pela mesma lógica.

### 7.1 `agencia/src/services/coordenador.js`

```javascript
import crypto from 'crypto';
import * as config from '../config.js';
import clienteInterno from './clienteInterno.js';
import { falhar } from './falhas.js';

const TIMEOUT_MS = 2000;
const INTERVALO_REENTREGA_MS = 3000;

// Papel de COORDENADOR no 2PC: quem conduz a transação. No ICEIBank, é a
// agência que o Bully elegeu como líder.
function criarCoordenador({ idAgencia, relogio, registro, estado, eventosNuvem }) {
  let reentregando = false;

  function urlDe(idAg) {
    return config.AGENCIAS.find((a) => a.id === idAg).url;
  }

  async function pedirVoto(txId, p) {
    try {
      const vetorEnvio = relogio.aoEnviar();
      registro.registrar('2PC_PREPARAR_ENVIADO', vetorEnvio, { txId, para: p.agencia, operacao: p.operacao });
      const resp = await clienteInterno.post(
        `${urlDe(p.agencia)}/2pc/preparar`,
        { txId, operacao: p.operacao, coordenador: idAgencia, vetorEnvio },
        { timeout: TIMEOUT_MS }
      );
      relogio.aoReceber(resp.data.vetorEnvio);
      p.voto = resp.data.voto;
      p.motivo = resp.data.motivo || null;
    } catch (erro) {
      // sem resposta dentro do prazo conta como voto NAO
      p.voto = 'NAO';
      p.motivo = 'Agência não respondeu a tempo.';
      registro.registrar('2PC_VOTO_TIMEOUT', relogio.eventoLocal(), { txId, agencia: p.agencia });
    }
  }

  async function entregarDecisao(txId, coord, p) {
    if (p.confirmou) return;
    try {
      const vetorEnvio = relogio.aoEnviar();
      registro.registrar('2PC_DECISAO_ENVIADA', vetorEnvio, { txId, para: p.agencia, decisao: coord.decisao });
      const resp = await clienteInterno.post(
        `${urlDe(p.agencia)}/2pc/decidir`,
        { txId, decisao: coord.decisao, vetorEnvio },
        { timeout: TIMEOUT_MS }
      );
      if (resp.data.vetorEnvio) relogio.aoReceber(resp.data.vetorEnvio);
      p.confirmou = true;
    } catch (erro) {
      // participante fora do ar: a reentrega periódica tenta de novo
    }
  }

  function concluirSeTudoConfirmado(coord) {
    if (coord.estado === 'DECIDIDA' && coord.participantes.every((p) => p.confirmou)) {
      coord.estado = 'CONCLUIDA';
      estado.salvar();
      registro.registrar('2PC_CONCLUIDA', relogio.eventoLocal(), { txId: coord.txId, decisao: coord.decisao });
    }
  }

  function resumo(coord) {
    return {
      txId: coord.txId,
      resultado: coord.decisao,
      motivos: coord.participantes.filter((p) => p.voto !== 'SIM').map((p) => p.motivo),
      pendentesDeConfirmacao: coord.participantes.filter((p) => !p.confirmou).map((p) => p.agencia),
    };
  }

  async function coordenar({ idOrigem, idDestino, valor }) {
    const txId = crypto.randomUUID();
    const coord = {
      txId,
      estado: 'PREPARANDO',
      decisao: null,
      participantes: [
        {
          agencia: config.agenciaResponsavel(idOrigem),
          operacao: { tipo: 'DEBITO', idConta: idOrigem, valor },
          voto: null,
          motivo: null,
          confirmou: false,
        },
        {
          agencia: config.agenciaResponsavel(idDestino),
          operacao: { tipo: 'CREDITO', idConta: idDestino, valor },
          voto: null,
          motivo: null,
          confirmou: false,
        },
      ],
    };
    estado.coordenacoes.set(txId, coord);
    estado.salvar();
    registro.registrar('2PC_INICIO', relogio.eventoLocal(), { txId, idOrigem, idDestino, valor });

    // FASE 1: pergunta a todos os participantes se podem se comprometer
    await Promise.all(coord.participantes.map((p) => pedirVoto(txId, p)));
    falhar('coordenador-antes-de-decidir');

    // DECISÃO: commit só se TODOS votaram SIM; qualquer outra coisa é abort.
    // Gravar a decisão em disco é o ponto sem volta da transação.
    coord.decisao = coord.participantes.every((p) => p.voto === 'SIM') ? 'COMMIT' : 'ABORT';
    coord.estado = 'DECIDIDA';
    estado.salvar();
    registro.registrar(`2PC_DECISAO_${coord.decisao}`, relogio.eventoLocal(), { txId });
    falhar('coordenador-apos-decidir');
    eventosNuvem?.publicarDecisao(coord); // notificação opcional, fora do caminho crítico

    // FASE 2: comunica a decisão a todos
    await Promise.all(coord.participantes.map((p) => entregarDecisao(txId, coord, p)));
    concluirSeTudoConfirmado(coord);
    return resumo(coord);
  }

  // Reenvia decisões que algum participante ainda não confirmou.
  async function reentregarPendentes() {
    if (reentregando) return;
    reentregando = true;
    try {
      for (const coord of estado.coordenacoes.values()) {
        if (coord.estado !== 'DECIDIDA') continue;
        await Promise.all(
          coord.participantes.filter((p) => !p.confirmou).map((p) => entregarDecisao(coord.txId, coord, p))
        );
        concluirSeTudoConfirmado(coord);
      }
    } finally {
      reentregando = false;
    }
  }

  // Chamado UMA vez, ao subir, antes de aceitar requisições. Transações que
  // estavam na fase 1 quando a agência caiu nunca chegaram a uma decisão:
  // por segurança, são abortadas ("aborto presumido").
  function recuperar() {
    let mudou = false;
    for (const coord of estado.coordenacoes.values()) {
      if (coord.estado === 'PREPARANDO') {
        coord.decisao = 'ABORT';
        coord.estado = 'DECIDIDA';
        mudou = true;
        registro.registrar('2PC_ABORTO_PRESUMIDO', relogio.eventoLocal(), { txId: coord.txId });
      }
    }
    if (mudou) estado.salvar();
  }

  // Resposta à pergunta de um participante em dúvida: "qual foi a decisão?"
  function statusDe(txId) {
    const coord = estado.coordenacoes.get(txId);
    if (!coord) return { decisao: 'ABORT', observacao: 'transação desconhecida (aborto presumido)' };
    if (coord.decisao) return { decisao: coord.decisao };
    return { decisao: 'EM_ANDAMENTO' };
  }

  function iniciarReentrega() {
    setInterval(reentregarPendentes, INTERVALO_REENTREGA_MS);
  }

  return { coordenar, recuperar, statusDe, iniciarReentrega };
}

export default criarCoordenador;
```

Observe os dois pontos de `falhar(...)`: um **antes** de decidir e outro **depois** de decidir (mas antes de entregar). Eles serão os alvos dos seus testes.

> A linha `eventosNuvem?.publicarDecisao(coord)` e o parâmetro `eventosNuvem` pertencem à **Parte F** (nuvem local). Enquanto você não chegar lá, o `?.` faz com que nada aconteça: pode deixá-los no código ou omiti-los por ora.

### 7.2 `agencia/src/controllers/transferenciasController.js` (atualizado)

Qualquer agência pode receber o pedido do cliente, mas **quem coordena é sempre a líder do Bully**. Se a agência que recebeu não é a líder, ela encaminha o pedido.

```javascript
import * as config from '../config.js';
import clienteInterno from '../services/clienteInterno.js';

// Qualquer agência recebe o pedido do cliente, mas quem COORDENA o 2PC é sempre
// o líder eleito pelo Bully. Se não for o líder, encaminha o pedido a ele.
function criarTransferenciasController({ idAgencia, bully, coordenador }) {
  async function transferir(req, res) {
    const { idOrigem, idDestino, valor } = req.body;
    if (!Number.isInteger(idOrigem) || !Number.isInteger(idDestino) || typeof valor !== 'number' || valor <= 0) {
      return res.status(400).json({ erro: 'Informe idOrigem, idDestino (inteiros) e valor (> 0).' });
    }
    if (idOrigem === idDestino) return res.status(400).json({ erro: 'Origem e destino devem ser diferentes.' });

    const lider = bully.obterLiderAtual();
    if (lider === null) return res.status(503).json({ erro: 'Sem líder eleito no momento. Tente novamente.' });

    try {
      if (lider === idAgencia) {
        const r = await coordenador.coordenar({ idOrigem, idDestino, valor });
        return res.status(r.resultado === 'COMMIT' ? 200 : 422).json(r);
      }
      const url = config.AGENCIAS.find((a) => a.id === lider).url;
      const resp = await clienteInterno.post(`${url}/2pc/coordenar`, { idOrigem, idDestino, valor }, { timeout: 15000, validateStatus: () => true });
      return res.status(resp.status).json(resp.data);
    } catch (erro) {
      return res.status(503).json({ erro: 'Coordenador indisponível. Nada foi aplicado; tente novamente.' });
    }
  }

  // Rota interna: outra agência pede para este líder coordenar.
  async function coordenarARequisicao(req, res) {
    if (bully.obterLiderAtual() !== idAgencia) return res.status(409).json({ erro: 'Esta agência não é a líder.' });
    const { idOrigem, idDestino, valor } = req.body;
    const r = await coordenador.coordenar({ idOrigem, idDestino, valor });
    res.status(r.resultado === 'COMMIT' ? 200 : 422).json(r);
  }

  return { transferir, coordenarARequisicao };
}

export default criarTransferenciasController;
```

Veja o que o cliente recebe: `200` com `COMMIT` se concluiu, `422` com `ABORT` e os motivos se foi abortada, `503` se não há líder ou o coordenador está inacessível (e, nesse caso, **nada foi aplicado ou o 2PC resolverá sozinho**).

### 7.3 Tarefa

1. Implemente `coordenador.js` e o novo `transferenciasController.js`, e confira o `app.js` da seção 5.8.
2. Suba tudo (`docker compose up --build`) e faça uma transferência **pela rota pública**, em uma agência que **não** é a líder:

```powershell
Invoke-RestMethod -Uri "http://localhost:4000/transferencias" -Method Post -ContentType "application/json" -Body '{"idOrigem":0,"idDestino":1,"valor":100}'
```

3. Consulte os saldos das duas contas e confirme **débito e crédito aplicados**.
4. Tente uma transferência com saldo insuficiente e confirme o `ABORT` com os motivos, sem nenhuma mudança nos saldos.
5. Tente uma transferência para uma conta inexistente (`idDestino` = 99) e confirme que o **débito não ficou aplicado**. Compare com o comportamento do Sprint 2: esse era justamente o caso em que o dinheiro sumia.
6. Capture `2pc-commit.png` e `2pc-abort.png` (com os logs dos containers visíveis: `docker compose logs -f`).
7. Faça o commit:

```powershell
git add agencia evidencias/sprint4
git commit -m "feat(2pc): coordenador com decisao duravel, reentrega e aborto presumido"
```

### 7.4 Perguntas - Parte C

1. O coordenador grava a decisão em disco **antes** de comunicá-la aos participantes. Por quê? O que poderia acontecer se a ordem fosse inversa e ele caísse entre as duas etapas?
2. Explique por que o **aborto presumido** é seguro para transações que ficaram na fase 1, mas **não seria seguro** presumir COMMIT para elas.
3. A mesma agência pode ser coordenadora **e** participante da mesma transação (ex.: a líder é a agência 2 e a conta de destino está nela). Isso causa algum problema para o protocolo? Como o código lida com isso?
4. Compare com o Sprint 2 (debita e depois publica no RabbitMQ). Que garantia o 2PC dá e a abordagem anterior não dava? Que **custo** o 2PC introduz (latência, disponibilidade)?

---

## 8. Parte D: Testes de falha

**Conceito:** um protocolo de recuperação que você nunca viu funcionar não é confiável. Aqui você vai derrubar agências em pontos exatos e **verificar um invariante**: **a soma dos saldos de todas as contas nunca muda** (dinheiro não é criado nem destruído), e depois que tudo se acalma, **nenhuma reserva fica presa**.

Os pontos de falha disponíveis (variável `FALHA_2PC`):

| Ponto | Onde cai | Agência |
| --- | --- | --- |
| `participante-apos-votar` | Depois de gravar a promessa (voto SIM), antes de responder | qualquer participante |
| `participante-antes-de-aplicar` | Ao receber a decisão, antes de aplicá-la | qualquer participante |
| `coordenador-antes-de-decidir` | Depois da fase 1, antes de gravar a decisão | a líder |
| `coordenador-apos-decidir` | Depois de gravar a decisão, antes de entregá-la | a líder |

Como ativar um ponto de falha no Docker Compose (exemplo: derrubar a agência 0 depois de votar):

```powershell
docker compose down
$env:FALHA_2PC_0 = "participante-apos-votar"
docker compose up -d
```

Cada ponto só dispara **uma vez**, pois grava um arquivo marcador no volume. Para repetir o cenário, apague o marcador:

```powershell
docker compose exec agencia-0 sh -c "rm -f /dados/falha-*"
```

E, ao terminar um cenário, limpe a variável (`Remove-Item Env:FALHA_2PC_0`) e recrie os containers.

Antes de cada cenário, anote a **soma dos saldos** (use `transacoes.js`, seção 9, e consultas às contas).

### 8.1 Cenário 1: participante fora do ar na fase 1

Pare uma agência **antes** da transferência (`docker compose stop agencia-1`) e transfira para uma conta dela. **Esperado:** `ABORT` por timeout; o débito é desfeito (reserva liberada). Suba a agência de novo (`docker compose start agencia-1`).

### 8.2 Cenário 2: participante cai depois de votar (`participante-apos-votar`) e antes de responder

**Esperado:** o coordenador não recebe o voto, conta como NAO e decide ABORT. Mas o participante **gravou uma promessa**. Quando o Docker o reinicia, ele está em dúvida, pergunta ao coordenador e descobre o ABORT. Nos logs da agência que caiu, procure `2PC_RESOLVIDA_POR_CONSULTA`. Ao final, **nenhuma reserva presa**, saldos inalterados. Capture `falha-participante.png`.

### 8.3 Cenário 3: coordenador cai antes de decidir (`coordenador-antes-de-decidir`)

Ative o ponto na **agência líder** (normalmente a 2). **Esperado:** os participantes votaram SIM e estão em dúvida, com o dinheiro reservado. A líder reinicia, executa `recuperar()` e registra `2PC_ABORTO_PRESUMIDO`; os participantes perguntam, recebem ABORT, liberam as reservas. Saldos inalterados. Capture `falha-coordenador.png`.

### 8.4 Cenário 4: coordenador cai depois de decidir COMMIT (`coordenador-apos-decidir`)

**Esperado:** a decisão COMMIT já estava gravada, então, ao reiniciar, o coordenador a **entrega**, e a transferência **se completa** mesmo que o cliente tenha recebido um erro (503). Esse é o motivo de a decisão ser gravada antes de ser comunicada. **Atenção para o que o cliente vê:** ele recebeu um erro, mas a transferência aconteceu. Anote isso para a Pergunta 3.

### 8.5 Cenário 5: o bloqueio do 2PC

Repita o cenário 3, mas **não deixe o coordenador voltar**: com o `restart: on-failure` o Docker o reinicia sozinho, então derrube-o de forma que não volte (por exemplo, `docker compose stop agencia-2` assim que ele cair). Espere alguns segundos e observe:

- as agências participantes registram `2PC_BLOQUEADA_AGUARDANDO_COORDENADOR`;
- `GET /contas/:id` mostra `reservado` > 0 e `disponivel` menor que `saldo`;
- um **saque** do valor reservado é **recusado** (422), pois esse dinheiro está em dúvida.

Depois, suba o coordenador de novo (`docker compose start agencia-2`) e veja o bloqueio terminar. Capture `bloqueio.png`. Esse é o defeito fundamental do 2PC: **enquanto o coordenador está fora, os participantes não têm como progredir**.

### 8.6 Tarefa

1. Execute os 5 cenários e, para cada um, registre no `RESPOSTAS.md`: o que você fez, o que **esperava**, o que **observou** (trecho de log) e se o invariante (soma dos saldos, nenhuma reserva presa) foi respeitado.
2. Se algum cenário **não** se comportar como o esperado, investigue: pode ser um defeito no seu código ou uma suposição deste roteiro que não vale na sua implementação. Documente, não esconda.
3. Faça o commit:

```powershell
git add evidencias/sprint4 RESPOSTAS.md
git commit -m "test(2pc): cenarios de falha de participante e coordenador, e bloqueio"
```

### 8.7 Perguntas - Parte D

1. No cenário 2, o coordenador decidiu ABORT por timeout, mas o participante **tinha votado SIM** em disco. Por que isso não gera inconsistência? Quem "vence" e como o participante fica sabendo?
2. No cenário 5, o dinheiro fica preso enquanto o coordenador está fora. Isso é uma **falha de segurança** (safety) ou de **disponibilidade** (liveness) do protocolo? Justifique.
3. No cenário 4, o cliente recebeu um erro, mas a transferência se completou depois. Isso é aceitável para um banco? O que a API poderia oferecer para que o cliente descubra o resultado real? (Dica: na Parte F você cria justamente um comprovante consultável por `txId`.)
4. Se a líder cair e o Bully eleger **outra** agência, quem resolve as transações em andamento da líder antiga? O código deste roteiro cobre esse caso? Explique o que acontece e o que faltaria.

---

## 9. Parte E: Observabilidade das transações

### 9.1 `agencia/transacoes.js`

Este script consulta as 3 agências e mostra, para cada uma, as transações que ela conhece e em que estado estão. É a ferramenta que você usará para *ver* o que o protocolo está fazendo durante os testes da Parte D.

```javascript
// Mostra, para cada agência, as transações 2PC que ela conhece e em que estado
// estão. Uso (PowerShell):  $env:TOKEN_INTERNO="seu-segredo"; node transacoes.js
import * as config from './src/config.js';

for (const agencia of config.AGENCIAS) {
  console.log(`\n=== Agência ${agencia.id} (${agencia.url}) ===`);
  try {
    const resp = await fetch(`${agencia.url}/2pc/transacoes`, {
      headers: { 'x-token-interno': config.TOKEN_INTERNO },
      signal: AbortSignal.timeout(2000),
    });
    if (!resp.ok) {
      console.log(`  resposta ${resp.status} (token interno correto?)`);
      continue;
    }
    const { coordenacoes, participacoes } = await resp.json();
    for (const c of coordenacoes) {
      console.log(`  [coordenador] ${c.txId.slice(0, 8)}  estado=${c.estado}  decisao=${c.decisao}`);
    }
    for (const p of participacoes) {
      console.log(`  [participante] ${p.txId.slice(0, 8)}  ${p.operacao.tipo} conta ${p.operacao.idConta} valor ${p.operacao.valor}  estado=${p.estado}`);
    }
    if (coordenacoes.length + participacoes.length === 0) console.log('  (nenhuma transação)');
  } catch (erro) {
    console.log('  fora do ar');
  }
}
```

Uso (PowerShell, com as agências em `localhost`, como no `docker compose`):

```powershell
$env:TOKEN_INTERNO = "troque-este-segredo"
node transacoes.js
```

### 9.2 Tarefa

1. Rode o script depois de uma transferência bem-sucedida: o que cada agência mostra? Quem é o `coordenador`? Quais estados aparecem?
2. Rode-o **durante** o cenário de bloqueio (8.5): que estado aparece nos participantes? E no coordenador?
3. Capture `transacoes-js.png` e faça o commit:

```powershell
git add agencia/transacoes.js evidencias/sprint4
git commit -m "feat(observabilidade): script de estado das transacoes 2pc"
```

### 9.3 Perguntas - Parte E

1. O estado das transações só cresce: nada é removido. Num sistema real, isso é um problema? Que política de limpeza (e que cuidado com o aborto presumido) você proporia?
2. Os logs de eventos usam o relógio vetorial do Sprint 2. Em que situação o vetor ajuda a entender uma falha do 2PC que o horário de parede não ajudaria?

---

## 10. Parte F: Nuvem local com LocalStack (containers + serverless)

**Conceito:** há três grandes modelos de execução na nuvem. Em **IaaS** você aluga a máquina virtual e cuida de tudo acima dela. Em **containers gerenciados** (CaaS/PaaS) você entrega uma imagem e o provedor a executa. Em **serverless/FaaS** você entrega apenas uma **função**, que o provedor executa quando um **evento** acontece, sem você enxergar servidor algum. O ICEIBank já usa containers (as agências). Agora ele ganha uma parte serverless.

O **LocalStack** é um emulador das APIs da AWS que roda em um container na sua máquina. Você usa o mesmo SDK e a mesma linha de comando que usaria na AWS real, só trocando o **endpoint** (a variável `AWS_ENDPOINT_URL`). O que você aprender aqui vale para a AWS de verdade, sem conta na AWS, sem cartão e sem risco de cobrança.

### 10.1 Conta e token do LocalStack

1. Crie uma conta no site do LocalStack e escolha o plano gratuito **Hobby** (uso não comercial). Quem tem o **GitHub Student Developer Pack** pode solicitar o plano para estudantes.
2. Copie o seu **token de autenticação** (*auth token*) no painel da conta.
3. Guarde-o no `.env` (que **não** é versionado), na variável `LOCALSTACK_AUTH_TOKEN`.

> **Confira as condições vigentes antes de começar.** Em março de 2026 o LocalStack passou a exigir conta e token até para o uso gratuito, e a lista de serviços de cada plano pode mudar. Na página de preços consultada na preparação deste roteiro, **Lambda, SQS, DynamoDB e API Gateway** apareciam em todos os planos, e o **ECS** (containers gerenciados) apenas nos planos pagos. Por isso, neste sprint as agências rodam como containers do **Docker Compose**, e o ECS fica como funcionalidade adicional opcional (seção 2.1). Se algum serviço citado aqui não estiver disponível no seu plano, avise o professor.

### 10.2 A arquitetura

```
cliente -> qualquer agência -> a líder (Bully) coordena o 2PC
                                   |  decide COMMIT ou ABORT e grava em disco
                                   |  (FORA do caminho crítico) publica um evento
                                   v
                            tópico SNS -> fila SQS -> Lambda "gerar-comprovante"
                                                         |-> S3: comprovante em JSON
                                                         '-> DynamoDB: índice por txId
                                                                 ^
cliente <- API Gateway <- Lambda "consultar-comprovante" ---------'   (você implementa)
```

Três decisões de projeto que valem ser discutidas:

- **A nuvem não está no caminho crítico.** Se o LocalStack estiver fora do ar, a transferência conclui do mesmo jeito; só o comprovante deixa de ser gerado. Por isso a publicação é "melhor esforço", com timeout curto.
- **SQS entrega "pelo menos uma vez".** A mesma mensagem pode chegar duas vezes, então a Lambda precisa ser **idempotente** (a mesma lógica da Parte B, agora na nuvem).
- **Falhas parciais.** Se uma mensagem do lote falhar, só ela deve voltar para a fila, não o lote inteiro (`batchItemFailures`).

### 10.3 `agencia/src/services/eventosNuvem.js`

A coordenadora chama este módulo logo depois de gravar a decisão (veja a linha `eventosNuvem?.publicarDecisao(coord)` em `coordenador.js`). Ele só fica ativo se `SNS_TOPIC_ARN` estiver definido, então **não afeta** nada do que você já testou nas partes B a D.

```javascript
import { SNSClient, PublishCommand } from '@aws-sdk/client-sns';

// Publica, em um tópico SNS (na nuvem local, o LocalStack), o resultado de cada
// transferência decidida. É uma notificação "melhor esforço": acontece FORA do
// caminho crítico do 2PC. Se a nuvem estiver fora do ar, a transferência não é
// afetada (só o comprovante deixa de ser gerado).
//
// Só fica ativo se SNS_TOPIC_ARN estiver definido. O endpoint vem de
// AWS_ENDPOINT_URL (ex.: http://localstack:4566), lido pelo próprio SDK.
const TOPICO = process.env.SNS_TOPIC_ARN || '';
const cliente = TOPICO ? new SNSClient({}) : null;

function criarEventosNuvem({ idAgencia, relogio, registro }) {
  function publicarDecisao(coord) {
    if (!cliente) return;
    const debito = coord.participantes.find((p) => p.operacao.tipo === 'DEBITO').operacao;
    const credito = coord.participantes.find((p) => p.operacao.tipo === 'CREDITO').operacao;
    const evento = {
      txId: coord.txId,
      resultado: coord.decisao, // COMMIT ou ABORT
      idOrigem: debito.idConta,
      idDestino: credito.idConta,
      valor: debito.valor,
      coordenador: idAgencia,
      decididaEm: new Date().toISOString(),
    };
    cliente
      .send(new PublishCommand({ TopicArn: TOPICO, Message: JSON.stringify(evento) }), {
        abortSignal: AbortSignal.timeout(2000),
      })
      .then(() => registro.registrar('NUVEM_EVENTO_PUBLICADO', relogio.eventoLocal(), { txId: coord.txId }))
      .catch((erro) =>
        registro.registrar('NUVEM_PUBLICACAO_FALHOU', relogio.eventoLocal(), { txId: coord.txId, erro: erro.name })
      );
  }

  return { publicarDecisao };
}

export default criarEventosNuvem;
```

Instale a dependência: `npm install @aws-sdk/client-sns` (na pasta `agencia`).

### 10.4 `serverless/gerar-comprovante/index.mjs`

A função Lambda: recebe um lote de mensagens da fila, grava o comprovante no S3 e um índice no DynamoDB.

```javascript
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';

// Função Lambda acionada por uma fila SQS. Cada mensagem é o resultado de uma
// transferência (publicado pela agência coordenadora via SNS). Para cada uma:
//   1. grava o comprovante (JSON) em um bucket S3;
//   2. registra um índice no DynamoDB, com chave txId.
// SQS entrega "pelo menos uma vez", então a função precisa ser IDEMPOTENTE.
const BUCKET = process.env.BUCKET || 'iceibank-comprovantes';
const TABELA = process.env.TABELA || 'comprovantes';
const ENDPOINT = process.env.AWS_ENDPOINT_URL; // definido no LocalStack; ausente na AWS real

const s3 = new S3Client({ forcePathStyle: Boolean(ENDPOINT) });
const dynamo = DynamoDBDocumentClient.from(new DynamoDBClient({}));

function lerEvento(corpo) {
  const externo = JSON.parse(corpo);
  // Sem "raw message delivery", o SNS embrulha o evento em um envelope com o campo Message.
  return externo.Message ? JSON.parse(externo.Message) : externo;
}

export async function handler(event) {
  const falhas = [];
  for (const registro of event.Records) {
    try {
      const ev = lerEvento(registro.body);
      const comprovante = {
        ...ev,
        emitidoEm: new Date().toISOString(),
        mensagem: ev.resultado === 'COMMIT' ? 'Transferencia concluida.' : 'Transferencia nao realizada.',
      };
      await s3.send(
        new PutObjectCommand({
          Bucket: BUCKET,
          Key: `comprovantes/${ev.txId}.json`,
          Body: JSON.stringify(comprovante),
          ContentType: 'application/json',
        })
      );
      try {
        await dynamo.send(
          new PutCommand({
            TableName: TABELA,
            Item: { txId: ev.txId, resultado: ev.resultado, valor: ev.valor, idOrigem: ev.idOrigem, idDestino: ev.idDestino, emitidoEm: comprovante.emitidoEm },
            ConditionExpression: 'attribute_not_exists(txId)', // reentrega da mesma mensagem: ignora
          })
        );
      } catch (erro) {
        if (erro.name !== 'ConditionalCheckFailedException') throw erro;
      }
    } catch (erro) {
      console.error('falha ao processar', registro.messageId, erro);
      falhas.push({ itemIdentifier: registro.messageId }); // só esta mensagem volta para a fila
    }
  }
  return { batchItemFailures: falhas };
}
```

Observe: o `forcePathStyle` (necessário para o S3 funcionar contra um endpoint local), a condição `attribute_not_exists(txId)` (idempotência) e o retorno de `batchItemFailures`. O SDK da AWS v3 já vem embutido no *runtime* Node.js da Lambda, então a função não precisa de `node_modules`.

### 10.5 `localstack/init.sh` e o serviço `localstack`

O LocalStack começa vazio e **não guarda estado entre reinícios**. Este script cria todos os recursos: tópico, fila, inscrição, bucket, tabela, papel (IAM), função e a ligação entre a fila e a função (*event source mapping*). Ele roda **dentro** do container, onde o comando `awslocal` já existe.

```bash
#!/bin/sh
# Cria, dentro do LocalStack, os recursos "AWS" do ICEIBank.
# Rode UMA vez a cada vez que o LocalStack subir (ele não guarda estado entre
# reinícios):  docker compose exec localstack sh /scripts/init.sh
set -e
CONTA=000000000000
REGIAO=us-east-1

echo "Criando tópico SNS, fila SQS e a inscrição entre eles..."
awslocal sns create-topic --name iceibank-transferencias-concluidas
awslocal sqs create-queue --queue-name comprovantes
awslocal sns subscribe \
  --topic-arn arn:aws:sns:$REGIAO:$CONTA:iceibank-transferencias-concluidas \
  --protocol sqs \
  --notification-endpoint arn:aws:sqs:$REGIAO:$CONTA:comprovantes \
  --attributes RawMessageDelivery=true

echo "Criando bucket S3 e tabela DynamoDB..."
awslocal s3 mb s3://iceibank-comprovantes
awslocal dynamodb create-table \
  --table-name comprovantes \
  --attribute-definitions AttributeName=txId,AttributeType=S \
  --key-schema AttributeName=txId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

echo "Criando o papel (IAM) e a função Lambda, e ligando a fila a ela..."
awslocal iam create-role \
  --role-name lambda-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
awslocal lambda create-function \
  --function-name gerar-comprovante \
  --runtime nodejs20.x \
  --handler index.handler \
  --role arn:aws:iam::$CONTA:role/lambda-role \
  --zip-file fileb:///serverless/gerar-comprovante.zip \
  --environment "Variables={BUCKET=iceibank-comprovantes,TABELA=comprovantes}"
awslocal lambda create-event-source-mapping \
  --function-name gerar-comprovante \
  --event-source-arn arn:aws:sqs:$REGIAO:$CONTA:comprovantes \
  --batch-size 5 \
  --function-response-types ReportBatchItemFailures

echo "Pronto."
```

O serviço `localstack` já está no `docker-compose.yml` da seção 5.7, em um *profile*. Atenção a dois pontos dele: o **socket do Docker** é montado porque o LocalStack cria containers para executar as suas Lambdas; e a pasta `serverless/build` é montada em `/serverless` para ele encontrar o `.zip` da função.

### 10.6 Tarefa

1. Acrescente ao `.env` (use `.env.example` como modelo):

```text
LOCALSTACK_AUTH_TOKEN=cole-aqui-o-seu-token
SNS_TOPIC_ARN=arn:aws:sns:us-east-1:000000000000:iceibank-transferencias-concluidas
```

2. Empacote a função (um `.zip` com o `index.mjs` na raiz):

```powershell
New-Item -ItemType Directory -Force -Path serverless/build
Compress-Archive -Path serverless/gerar-comprovante/index.mjs -DestinationPath serverless/build/gerar-comprovante.zip -Force
```

3. Suba tudo, **incluindo** o LocalStack, e confira a saúde dele:

```powershell
docker compose --profile nuvem up --build -d
Invoke-RestMethod -Uri "http://localhost:4566/_localstack/health"
```

4. Crie os recursos (a cada vez que o LocalStack subir):

```powershell
docker compose exec localstack sh /scripts/init.sh
```

5. Faça uma transferência entre agências (como na seção 7.3) e confira o resultado **na nuvem**. A primeira execução da Lambda pode demorar, pois o LocalStack prepara o ambiente de execução:

```powershell
docker compose exec localstack awslocal s3 ls s3://iceibank-comprovantes/comprovantes/
docker compose exec localstack awslocal dynamodb scan --table-name comprovantes
```

6. Faça também uma transferência **abortada** (saldo insuficiente) e confirme que o comprovante dela existe, com `resultado` ABORT.
7. **Implemente a segunda função**, `consultar-comprovante`: dado um `txId`, devolve o comprovante. Requisitos: lê do DynamoDB e/ou do S3; devolve `404` se o `txId` não existir; é exposta por um **API Gateway** do LocalStack; você escolhe a linguagem da função. Aqui não há código de exemplo: use a documentação e o que viu na `gerar-comprovante`. Teste com o `txId` devolvido por uma transferência real.
8. **A nuvem fora do caminho crítico:** pare o LocalStack (`docker compose stop localstack`) e faça uma transferência. Ela deve **concluir normalmente**; nos logs da coordenadora deve aparecer `NUVEM_PUBLICACAO_FALHOU`. Suba o LocalStack de novo e observe: o comprovante daquela transferência existe? Por quê?
9. Capture `localstack-saude.png`, `comprovante-s3-dynamo.png`, `api-comprovante.png` e `nuvem-fora-do-ar.png`.
10. Repita pelo menos os cenários 2 e 3 da Parte D com `SNS_TOPIC_ARN` ativo e confirme que **nada regrediu**.
11. Faça o commit:

```powershell
git add agencia serverless localstack docker-compose.yml evidencias/sprint4 .gitignore
git commit -m "feat(nuvem): localstack com sns, sqs, lambda, s3 e dynamodb"
```

### 10.7 Perguntas - Parte F

1. A Lambda `gerar-comprovante` é idempotente. Mostre no código **onde** isso é garantido e descreva um cenário concreto em que a mesma mensagem chega duas vezes.
2. Por que usar `batchItemFailures` em vez de simplesmente lançar uma exceção quando uma mensagem do lote falha? O que aconteceria com as outras mensagens do lote?
3. Se a coordenadora cair **depois** de gravar a decisão e **antes** de publicar o evento, esse comprovante nunca será gerado (a recuperação da Parte C não republica). Isso é aceitável? Pesquise o **padrão outbox** e descreva como o aplicaria aqui.
4. Compare, para o ICEIBank, rodar a coordenação em **containers** e rodar o comprovante em **serverless**. O que cada modelo facilita ou dificulta (escala, custo, estado, latência de partida)? Por que o 2PC seria uma má ideia dentro de uma função serverless?
5. O LocalStack é um emulador. Cite um aspecto em que a AWS real **pode** se comportar de forma diferente e que você só descobriria ao implantar de verdade (pense em permissões, limites, latência e custos).

---

## 11. Adaptando o backend para Java ou Python

O **protocolo** (fases, regras do participante e do coordenador, recuperação) está completo e testado nas seções 6 e 7, em Node. A lógica é curta o bastante para servir de referência direta. O que muda na adaptação:

- **Estado durável com escrita atômica.** O padrão é o mesmo em qualquer linguagem: serializar para JSON, escrever em arquivo temporário, `fsync`, renomear.
  - **Java:** `Files.write` em um arquivo temporário seguido de `Files.move(tmp, destino, StandardCopyOption.ATOMIC_MOVE)`; para o `fsync`, `FileChannel.force(true)`.
  - **Python:** `os.fsync(f.fileno())` antes de `os.replace(tmp, destino)` (que é atômico).
- **Concorrência.** No Node, o código do participante é síncrono dentro de cada requisição, e por isso não há *race* entre duas transferências simultâneas. Em Java (threads) e Python com várias threads, as operações `preparar` e `decidir` e o `salvar()` precisam ser protegidas (`synchronized`/`ReentrantLock` em Java, `threading.Lock` em Python). **Esquecer isso é o erro mais provável de quem adapta.**
- **Timeouts.** `HttpClient` com `.timeout(Duration.ofSeconds(2))` em Java; `requests` com `timeout=2` em Python. Todo timeout deve ser tratado como NAO na votação.
- **Tarefas periódicas** (reentrega, resolução de dúvida): `ScheduledExecutorService` em Java; `threading.Timer` recursivo, ou `asyncio`, em Python.
- **Formato das mensagens:** mantenha as rotas e o JSON iguais (`/2pc/preparar`, `/2pc/decidir`, `/2pc/status/:txId`, cabeçalho `x-token-interno`), para que as suas agências e as dos colegas possam, em tese, conversar entre si.
- **Função serverless (Parte F):** a Lambda pode ser escrita em **Node.js, Python ou Java**: use a linguagem do seu backend. O contrato é o mesmo: receber o evento da fila SQS (`event.Records`), gravar no S3 e no DynamoDB, e devolver `batchItemFailures` para as mensagens que falharem. Em Python, use `boto3` (já incluído no runtime da Lambda); em Java, o AWS SDK v2. Lembre-se de que a função precisa ser **idempotente**.
- **Publicação no SNS (`eventosNuvem.js`):** use o AWS SDK da sua linguagem (`boto3` em Python; AWS SDK v2 em Java), configurando o endpoint pela variável `AWS_ENDPOINT_URL`, e mantenha a publicação **fora do caminho crítico** do 2PC, com timeout curto e sem lançar exceção para o coordenador.
- **Docker:** troque a imagem base e o comando de início (`eclipse-temurin` + `java -jar`, ou `python:3.12-slim` + `python app.py`); o `docker-compose.yml` não muda quase nada.
- **Injeção de falhas:** `System.exit(1)` / `os._exit(1)` no mesmo ponto do protocolo, com o mesmo arquivo marcador.

---

## 12. Checklist de entrega

- [ ] Estado das agências persistido em disco com escrita atômica (Parte A)
- [ ] 3 agências em containers, com volumes e reinício automático (`docker compose up` funcionando do zero)
- [ ] Rotas internas protegidas por token, com `GET /bully/lider` mantido público
- [ ] Participante do 2PC: reserva de fundos, voto durável, idempotência (Parte B)
- [ ] Coordenador: decisão durável, reentrega e aborto presumido (Parte C)
- [ ] A transferência entre agências usa o 2PC e **não** debita sem creditar (compare com o Sprint 2)
- [ ] Os 5 cenários de falha executados e documentados, com o invariante verificado (Parte D)
- [ ] Bloqueio do 2PC provocado e observado de propósito
- [ ] Script `transacoes.js` funcionando (Parte E)
- [ ] LocalStack no ar e a função `gerar-comprovante` produzindo comprovantes no S3 e no DynamoDB após cada transferência (Parte F)
- [ ] Segunda função Lambda (consulta de comprovante) exposta por API, implementada por você (Parte F)
- [ ] Uma transferência concluindo normalmente com o LocalStack parado (a nuvem não está no caminho crítico)
- [ ] Segredos fora do repositório (`.env` no `.gitignore`)
- [ ] JWT, frontend web, mensageria (Sprint 2), Bully e app Flutter (Sprint 3) continuam funcionando sem regressão
- [ ] Pelo menos **uma funcionalidade adicional** implementada e documentada (seção 2.1)
- [ ] Pasta `evidencias/sprint4/` com os 12 prints indicados na seção 4.2
- [ ] Arquivo `RESPOSTAS.md` atualizado com as questões das seções 5.10, 6.6, 7.4, 8.7, 9.3 e 10.4, os registros dos cenários da Parte D e a descrição da funcionalidade adicional
- [ ] Declaração de uso de IA, se houver (conforme a nota de transparência no início)

---

## 13. Critérios de avaliação (20 pontos)

| Critério | Pontos | O que é observado |
| --- | --- | --- |
| Persistência e containerização | 3 | Escrita atômica; `docker compose` funcionando do zero; volumes preservando o estado após reinício |
| 2PC: participante e coordenador | 4 | Duas fases corretas; reserva de fundos; decisão e voto duráveis; idempotência; commit só com todos SIM |
| Recuperação e testes de falha | 3 | Os cenários da Parte D executados e documentados; invariante verificado; o bloqueio explicado, não escondido |
| Nuvem local com LocalStack: containers + serverless | 4 | Fluxo SNS, SQS, Lambda, S3 e DynamoDB funcionando; segunda função implementada; idempotência; nuvem fora do caminho crítico; segredos tratados conscientemente |
| Segurança das rotas internas e integração com o Bully | 1 | Token interno funcionando; líder realmente coordenando as transferências |
| Observabilidade | 1 | `transacoes.js` e logs permitindo acompanhar o protocolo |
| Continuidade (JWT, frontend, mensageria, app) | 1 | O que já funcionava continua funcionando sem regressão |
| Funcionalidade adicional | 1 | Funcionalidade nova e genuína (seção 2.1), funcionando e documentada |
| Commits | 1 | Histórico incremental ao longo do sprint |
| Respostas às questões | 1 | Compreensão demonstrada, com referência ao comportamento observado nos testes |

A ponderação exata é definida pelo professor responsável pela turma (T1 ou T2), conforme os critérios apresentados em sala.
