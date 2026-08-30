# Roteiro de Projeto - Sprint 1: ICEIBank

**Disciplina:** Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas  
**Unidade:** U2 - Desenvolvimento Web (arquitetura MVC e serviços REST)  
**Professores:** T1 - Cleiton Tavares Silva · T2 - Cristiano de Macedo Neto  
**Modalidade:** Projeto individual, ao longo do sprint (não é uma atividade de aula única)  
**Valor:** 20 pontos (Sprint 1 de 4)  
**Pré-requisito:** ter concluído os roteiros de Revisão de Redes e de Transparências/gRPC.  

> **Nota de transparência (uso de IA):** este roteiro foi diagramado e organizado com apoio do Claude (Anthropic), utilizado de forma responsável apenas para redação, estruturação e revisão do material - incluindo a validação do código de exemplo, que foi executado e testado antes da publicação. O aluno pode utilizar ferramentas de IA para apoiar rascunhos e revisões de código, desde que declare o uso na entrega e seja capaz de explicar e defender qualquer trecho entregue. Copiar e colar sem entender o funcionamento do código caracteriza uso não responsável e será tratado como falta de integridade acadêmica.

---

## 1. Visão geral do projeto: ICEIBank

Este é o primeiro de 4 sprints de um único projeto que evolui ao longo do semestre - cada sprint parte do código do anterior, não recomeça do zero. A aplicação é o ICEIBank, um banco simplificado dividido em agências: cada agência é uma partição independente de contas, e o sistema evolui conforme a ementa avança:

| Sprint | Unidade da ementa | Tecnologia | Conceito de Sistemas Distribuídos aplicado |
| :--- | :--- | :--- | :--- |
| **1 (este)** | U2 - Desenvolvimento Web | API REST / MVC | Relógio lógico de Lamport |
| **2** | U3 - Comunicação indireta | Mensageria / Pub-Sub | Relógio vetorial |
| **3** | U4 - Desenvolvimento Móvel | App Flutter | Consenso (eleição de líder) |
| **4** | U5 - Computação em Nuvem | Containers | Transações distribuídas (2PC/Saga) |

Os quatro temas de Sistemas Distribuídos (Lamport, vetorial, consenso, transações) já foram vistos na disciplina teórica - aqui o foco é aplicá-los em um sistema real, não reaprendê-los do zero. Cada roteiro de sprint abre com uma revisão curta do conceito, não uma aula completa sobre o tema.

### 1.1 Por que um banco?
Transferência de dinheiro entre contas é o exemplo clássico para esses quatro temas - inclusive é literalmente o exemplo usado por Lamport no artigo original sobre relógios lógicos (1978). O domínio deixa erros de concorrência e de atomicidade extremamente visíveis: ou o saldo bate, ou não bate.

---

## 2. Escopo desta entrega (Sprint 1)

Nesta etapa, cada agência é um serviço REST independente (arquitetura MVC), com endpoints para criar conta, consultar saldo, depositar, sacar e transferir. Toda operação é registrada com um timestamp de relógio lógico de Lamport. Além do backend, este sprint também exige um frontend que consuma essa API e um mecanismo de autenticação via JWT protegendo as rotas - detalhados nas Partes F e G (seções 12 e 13). Ainda não existe um app mobile (isso é do Sprint 3, com Flutter) - o frontend deste sprint é web. Enquanto o backend (Partes A a E) ainda está em construção, o teste é feito via curl/Postman/Invoke-RestMethod; a partir da Parte G, o frontend passa a ser a forma normal de usar o sistema.

**O que este sprint entrega:**
* 1 serviço de agência (código único, executado 3 vezes com identidades diferentes = 3 agências)
* Partição de contas entre as 3 agências
* CRUD de contas + depósito/saque, tudo carimbado com relógio de Lamport
* Transferência dentro da mesma agência (local) e entre agências diferentes (via chamada REST direta entre agências)
* Um script que mescla os logs das 3 agências em uma única linha do tempo ordenada por relógio de Lamport, para você observar o algoritmo funcionando de verdade
* Autenticação via JWT protegendo as rotas da API (Parte F)
* Um frontend funcional que consome a API autenticada (Parte G)

**O que este sprint deliberadamente NÃO resolve ainda:** se uma transferência entre agências falhar no meio do caminho (agência de destino fora do ar, rede caiu), o débito já aplicado não é revertido automaticamente - o dinheiro “some” temporariamente. Isso é intencional: é exatamente o problema que o Sprint 4 (transações distribuídas) vai resolver de verdade, com 2PC ou Saga. Por enquanto, o sistema apenas registra a inconsistência no log.

### 2.1 Funcionalidade adicional (obrigatória)
Além de tudo o que este roteiro pede, cada sprint exige pelo menos uma funcionalidade adicional, de sua autoria, que vá além do escopo descrito aqui. Essa exigência vale para os 4 sprints do semestre, não só este.

O que conta como funcionalidade adicional: algo que adicione comportamento novo e observável ao ICEIBank - um endpoint novo, uma regra de negócio nova, uma validação que hoje não existe. Não conta: refatoração, comentários, testes automatizados sozinhos (embora sejam bem-vindos), ou pequenos ajustes cosméticos. Autenticação e frontend não contam como funcionalidade adicional - a partir deste sprint, eles já são escopo obrigatório (Partes F e G), não um extra.

**Alguns exemplos possíveis para o Sprint 1** (escolha um, ou proponha outro - não precisa ser desta lista):
* **Histórico de transações por conta:** um endpoint que lista os últimos eventos registrados para uma conta específica.
* **Limite de saque ou de transferência:** uma regra de negócio nova (ex.: valor máximo por operação, ou por dia).
* **Extrato consolidado:** um endpoint que soma os saldos de várias contas do mesmo aluno, mesmo que estejam em agências diferentes.
* **Idempotência de transferências:** evitar que a mesma transferência seja aplicada duas vezes caso a requisição seja reenviada (ex.: usando um identificador único por operação).
* **Rota de status/health-check por agência**, retornando o relógio de Lamport atual e a quantidade de contas sob sua responsabilidade.

**Como documentar:** descreva a funcionalidade escolhida em `RESPOSTAS.md` (o que ela faz e por que você escolheu implementá-la), inclua evidência de teste em `evidencias/sprint1/funcionalidade-adicional.png`, e faça um commit próprio para ela (não misture com os commits das partes obrigatórias):

```bash
git add agencia/src evidencias/sprint1/funcionalidade-adicional.png RESPOSTAS.md
git commit -m "feat(extra): <descreva sua funcionalidade adicional aqui>"
```

### 2.2 Escolha de linguagem
Atenção: o código deste roteiro está em Node.js/Express porque é a linguagem usada como referência nos materiais da disciplina - serve para você entender a lógica com clareza. A entrega não pode ser em Node.js. Escolha uma das duas linguagens abaixo e mantenha-a do Sprint 1 ao Sprint 4:

* Java (ex.: Spring Boot)
* Python (ex.: FastAPI ou Flask)

Os conceitos e a arquitetura deste roteiro (partição, relógio de Lamport, estrutura de eventos, endpoints) devem ser seguidos da mesma forma na linguagem escolhida - só a sintaxe muda. A seção 9 traz a implementação completa do relógio de Lamport e do registro de eventos (as duas peças realmente novas deste sprint) já adaptadas para Java e para Python, testadas e prontas para você usar como ponto de partida.

---

## 3. Cronograma sugerido

Diferente dos laboratórios de aula única, este é um projeto de sprint (várias semanas). O ritmo abaixo é intenso - com autenticação e frontend somados ao backend, este sprint tem bastante conteúdo para 3 semanas, então comece cedo e não deixe partes acumulando para o fim:

| Etapa | Quando | Conteúdo |
| :--- | :--- | :--- |
| **Preparação do ambiente** | Semana 1 (início) | Seção 4: ambiente, estrutura do repositório, evidências, portas |
| **Modelagem e partição de contas** | Semana 1 | Seção 5: Parte A |
| **Relógio de Lamport + eventos** | Semana 1 | Seção 6: Parte B - implementar e testar isoladamente, antes de plugar na API |
| **API REST/MVC (contas)** | Semana 1 (fim) | Seção 7: Parte C - CRUD de contas |
| **Transferências** | Semana 2 (início) | Seção 8: Parte D - local, entre agências, e a limitação conhecida |
| **Linha do tempo** | Semana 2 | Seção 10: Parte E - mesclar logs, observar concorrência |
| **Autenticação JWT** | Semana 2 (fim) | Seção 11: Parte F - protege a API que já está pronta e testada |
| **Frontend** | Semana 3 (início) | Seção 12: Parte G - só faz sentido depois que a API (com autenticação) já está estável |
| **Funcionalidade adicional** | Ao longo do sprint | Seção 2.1 - encaixe onde fizer sentido, não precisa esperar o fim |
| **Revisão de respostas e commits** | Semana 3 | Revisar `RESPOSTAS.md` e o histórico de commits antes de entregar |
| **Entrega** | Fim da Semana 3 | Checklist da seção 13 |

---

## 4. Preparação do ambiente

Este roteiro assume Windows, usando o PowerShell como terminal padrão (mesma convenção dos laboratórios anteriores).
* Node.js 20 LTS ou superior, com o instalador padrão do site oficial (já inclui o npm) - confirme com `node --version` e `npm --version`
* Git for Windows configurado (`git config --global user.name` / `user.email`)
* Um editor de sua preferência (VS Code é o mais comum para Node.js)
* Um cliente REST: `Invoke-RestMethod` do próprio PowerShell (usado neste roteiro) ou Postman, se preferir interface gráfica
* Alerta do Firewall do Windows: como nos laboratórios anteriores, ao rodar cada agência pela primeira vez o Firewall do Windows Defender deve pedir permissão de rede - clique em “Permitir acesso”.

### 4.1 Estrutura do repositório
Este repositório vai crescer ao longo dos 4 sprints - crie a estrutura já pensando nisso:

```text
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
│   │       ├── lamportClock.js
│   │       └── eventLog.js
│   ├── data/                      (logs gerados em tempo de execução - não versionar)
│   └── mesclar-logs.js
├── frontend/                      (Parte G - estrutura interna livre, depende do framework escolhido)
├── evidencias/
│   └── sprint1/
├── RESPOSTAS.md
├── .gitignore
└── README.md
```

```powershell
$pastas = @(
  "iceibank/agencia/src/controllers",
  "iceibank/agencia/src/services",
  "iceibank/agencia/data",
  "iceibank/evidencias/sprint1"
)
New-Item -ItemType Directory -Force -Path $pastas

cd iceibank
git init
Set-Content -Path README.md -Value "# ICEIBank" -Encoding utf8
New-Item -ItemType File -Name RESPOSTAS.md

@"
# Node
node_modules/
agencia/data/*.jsonl

# Sistema
Thumbs.db
desktop.ini
"@ | Set-Content -Path .gitignore -Encoding utf8

git add .
git commit -m "chore: estrutura inicial do repositorio"
```

Os logs em `agencia/data/*.jsonl` ficam de fora do Git de propósito - são gerados a cada execução e não fazem sentido versionados. Quando precisar entregar uma evidência que dependa deles, é o print de tela que vai para `evidencias/`, não o arquivo `.jsonl` em si.

### 4.2 Evidências de teste
Mesma convenção dos laboratórios anteriores: prints de tela reais (não só código), com a saída de `Get-Date` visível em algum terminal para comprovar que é uma execução recente:
* `evidencias/sprint1/transferencia-local.png` - uma transferência dentro da mesma agência
* `evidencias/sprint1/transferencia-entre-agencias.png` - uma transferência entre agências diferentes, incluindo os logs das duas agências envolvidas
* `evidencias/sprint1/falha-conhecida.png` - a agência de destino sendo derrubada no meio de uma transferência, mostrando a resposta de erro e o log da inconsistência
* `evidencias/sprint1/linha-do-tempo.png` - a saída do script `mesclar-logs.js` (seção 10)

### 4.3 Portas exclusivas
Se for testar em uma máquina compartilhada do laboratório, use o mesmo OFFSET pessoal dos roteiros anteriores (dois últimos dígitos da matrícula/RA) - já embutido no `config.js` da seção 7.

### 4.4 Disciplina de commits (trabalho individual)
Como este é um projeto individual, todos os commits devem ser seus. Como este projeto dura o sprint inteiro, o histórico de commits incremental ao longo das semanas é ainda mais importante do que nos laboratórios de aula única - um repositório com um único commit gigante no fim do sprint é um sinal de alerta para quem for avaliar, tanto pela falta de granularidade quanto por não permitir verificar que o trabalho foi feito ao longo do tempo (e não copiado de outra pessoa às pressas antes da entrega). Faça pelo menos um commit por parte concluída (as seções 5 a 10 já indicam o momento certo de cada um).

---

## 5. Parte A: Modelagem e partição de contas

Cada conta pertence a exatamente uma agência (partição, não replicação): dado o número da conta, a agência responsável é `id_conta % número_de_agências`. Neste sprint, o número de agências é fixado em 3.

### 5.1 agencia/src/config.js

```javascript
// TODO: substitua pelo seu OFFSET pessoal (dois últimos dígitos da matrícula/RA),
// necessário apenas se for rodar em uma máquina compartilhada do laboratório.
const OFFSET = 0;
const NUMERO_AGENCIAS = 3;
const PORTA_BASE = 4000 + OFFSET;
const AGENCIAS = [
  { id: 0, url: `http://localhost:${PORTA_BASE}` },
  { id: 1, url: `http://localhost:${PORTA_BASE + 1}` },
  { id: 2, url: `http://localhost:${PORTA_BASE + 2}` },
];

function agenciaResponsavel(idConta) {
  return idConta % NUMERO_AGENCIAS;
}

export { NUMERO_AGENCIAS, AGENCIAS, agenciaResponsavel, OFFSET };
```
Ou seja: conta 0 pertence à Agência 0, conta 1 à Agência 1, conta 2 à Agência 2, conta 3 de volta à Agência 0, e assim por diante.

### 5.2 Commit desta parte

```bash
git add agencia/src/config.js
git commit -m "feat(config): define particionamento de contas entre 3 agencias"
```

---

## 6. Parte B: Relógio de Lamport e registro de eventos

Revisão rápida (já visto na teórica): o relógio de Lamport é um contador inteiro por processo, com três regras:
1. Antes de qualquer evento local, o processo incrementa seu contador.
2. Ao enviar uma mensagem, o processo incrementa o contador e anexa o valor à mensagem.
3. Ao receber uma mensagem com timestamp `t`, o processo ajusta seu contador para `max(contador_local, t) + 1`.

Essas três regras garantem que, se o evento A “aconteceu antes” do evento B causalmente, então `timestamp(A) < timestamp(B)` - mas não garantem a volta: dois timestamps iguais (ou fora de ordem causal) podem representar eventos genuinamente concorrentes. Essa limitação é o motivo de existir o relógio vetorial, que vocês implementam no Sprint 2.

### 6.1 agencia/src/services/lamportClock.js

```javascript
class RelogioLamport {
  constructor() {
    this.contador = 0;
  }

  eventoLocal() {
    this.contador += 1;
    return this.contador;
  }

  aoEnviar() {
    this.contador += 1;
    return this.contador;
  }

  aoReceber(timestampRecebido) {
    this.contador = Math.max(this.contador, timestampRecebido) + 1;
    return this.contador;
  }
}

export default RelogioLamport;
```

### 6.2 agencia/src/services/eventLog.js

Cada agência registra todo evento em um arquivo `.jsonl` (uma linha JSON por evento) - isso vai ser a matéria-prima da linha do tempo unificada na seção 10.

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

  registrar(tipo, timestampLamport, detalhes) {
    const evento = {
      agencia: this.nomeAgencia,
      tipo,
      timestampLamport,
      horaParede: new Date().toISOString(),
      detalhes,
    };
    fs.appendFileSync(this.caminhoArquivo, JSON.stringify(evento) + '
');
    console.log(`[Lamport ${timestampLamport}] ${tipo}`, detalhes);
    return evento;
  }
}

export default RegistroEventos;
```

Em ES Modules, `__dirname` não existe por padrão (diferente do CommonJS) - por isso as duas linhas com `fileURLToPath` acima, que recriam esse valor a partir de `import.meta.url`.

Note que cada evento guarda dois carimbos de tempo: `timestampLamport` (o relógio lógico) e `horaParede` (o relógio físico da máquina, só para fins de comparação na seção 11 - não é usado para nenhuma decisão do sistema).

### 6.3 Commit desta parte

```bash
git add agencia/src/services
git commit -m "feat(lamport): implementa relogio logico e registro de eventos"
```

### 6.4 Perguntas - Parte B (responder em RESPOSTAS.md)
1. Por que o relógio de Lamport usa `max(contador_local, timestampRecebido) + 1` ao receber uma mensagem, em vez de simplesmente adotar o timestamp recebido diretamente?
2. Se a Agência 0 está no evento de contador 10 e recebe uma mensagem com timestamp 3 (de uma agência mais “atrasada”), qual o novo valor do contador da Agência 0? O que isso implica sobre agências que processam muitos eventos rapidamente versus agências mais lentas?

---

## 7. Parte C: API REST/MVC - contas

### 7.1 agencia/package.json

```json
{
  "name": "iceibank-agencia",
  "version": "1.0.0",
  "description": "Agencia do ICEIBank - Sprint 1 (REST/MVC + Relogio de Lamport)",
  "type": "module",
  "main": "src/app.js",
  "scripts": {
    "start": "node src/app.js"
  },
  "dependencies": {
    "express": "^5.0.0",
    "axios": "^1.7.2"
  }
}
```

O campo `"type": "module"` é o que diz ao Node.js para tratar todos os arquivos `.js` deste projeto como ES Modules (`import/export`), em vez do padrão CommonJS (`require/module.exports`).

```bash
cd agencia
npm install
```

### 7.2 agencia/src/controllers/contasController.js

```javascript
import * as config from '../config.js';

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
  const { contas } = req.app.locals;
  const id = parseInt(req.params.id, 10);
  const conta = contas.get(id);
  if (!conta) return res.status(404).json({ erro: 'Conta não encontrada nesta agência.' });
  res.json(conta);
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

export { criarConta, consultarSaldo, depositar, sacar };
```

Este sprint guarda as contas em memória (um `Map`, criado em `app.js`) - não há banco de dados ainda. Isso é proposital: o foco aqui é REST/MVC e o relógio de Lamport, não persistência. Se o processo da agência for reiniciado, as contas somem - é esperado.

### 7.3 agencia/src/routes.js

```javascript
import express from 'express';
import * as contasController from './controllers/contasController.js';
import * as transferenciasController from './controllers/transferenciasController.js';

const router = express.Router();

router.post('/contas', contasController.criarConta);
router.get('/contas/:id', contasController.consultarSaldo);
router.post('/contas/:id/depositar', contasController.depositar);
router.post('/contas/:id/sacar', contasController.sacar);

router.post('/transferencias', transferenciasController.transferir);
router.post('/contas/:id/creditar-remoto', transferenciasController.creditarRemoto);

export default router;
```

As rotas de `transferenciasController` são implementadas na Parte D - por enquanto o import acima já aponta para o arquivo que você vai criar na próxima seção. Note que, em ES Modules, o caminho do import precisa incluir a extensão `.js` explicitamente - isso é diferente do CommonJS, onde `require('./routes')` funciona sem a extensão.

### 7.4 agencia/src/app.js

```javascript
import express from 'express';
import * as config from './config.js';
import RelogioLamport from './services/lamportClock.js';
import RegistroEventos from './services/eventLog.js';
import routes from './routes.js';

const idAgencia = parseInt(process.env.AGENCIA_ID || '0', 10);
const agenciaConfig = config.AGENCIAS.find((a) => a.id === idAgencia);

if (!agenciaConfig) {
  console.error(`Agência ${idAgencia} não configurada em config.js`);
  process.exit(1);
}

const app = express();
app.use(express.json());

app.locals.idAgencia = idAgencia;
app.locals.relogio = new RelogioLamport();
app.locals.registro = new RegistroEventos(`agencia-${idAgencia}`);
app.locals.contas = new Map();

app.use('/', routes);

const porta = new URL(agenciaConfig.url).port;
app.listen(porta, () => {
  console.log(`[Agência ${idAgencia}] ouvindo na porta ${porta}`);
});
```

### 7.5 Como executar (por enquanto só cria/consulta/deposita/saca - transferências vêm na Parte D)

Cada agência é o mesmo código, identificada por uma variável de ambiente `AGENCIA_ID`. Abra 3 janelas do PowerShell:

```powershell
# Terminal 1
cd iceibank/agencia
$env:AGENCIA_ID=0; node src/app.js

# Terminal 2
cd iceibank/agencia
$env:AGENCIA_ID=1; node src/app.js

# Terminal 3
cd iceibank/agencia
$env:AGENCIA_ID=2; node src/app.js
```

Em um quarto terminal, teste com `Invoke-RestMethod`:

```powershell
# Criar a conta 0 na Agência 0 (0 % 3 == 0)
Invoke-RestMethod -Uri "http://localhost:4000/contas" -Method Post -ContentType "application/json" -Body '{"id":0,"nomeAluno":"Ana","saldoInicial":100}'

# Consultar saldo
Invoke-RestMethod -Uri "http://localhost:4000/contas/0" -Method Get

# Depositar
Invoke-RestMethod -Uri "http://localhost:4000/contas/0/depositar" -Method Post -ContentType "application/json" -Body '{"valor":25}'
```

Se preferir Postman em vez de `Invoke-RestMethod`, os mesmos endpoints funcionam normalmente - use o corpo JSON equivalente.

### 7.6 Commit desta parte

```bash
git add agencia/package.json agencia/src/controllers/contasController.js agencia/src/routes.js agencia/src/app.js
git commit -m "feat(contas): implementa API REST/MVC de contas com relogio de Lamport"
```

---

## 8. Parte D: Transferências (local, entre agências, e a limitação conhecida)

### 8.1 agencia/src/controllers/transferenciasController.js

```javascript
import axios from 'axios';
import * as config from '../config.js';

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

  // Caso entre agências: chama a agência de destino diretamente via REST
  const tsEnvio = relogio.aoEnviar();
  const urlDestino = config.AGENCIAS.find((a) => a.id === agenciaDestino).url;

  try {
    await axios.post(`${urlDestino}/contas/${idDestino}/creditar-remoto`, {
      valor,
      timestampLamport: tsEnvio,
      origemAgencia: idAgencia,
    });
    res.json({ mensagem: 'Transferência concluída (entre agências).' });
  } catch (erro) {
    // LIMITAÇÃO CONHECIDA: se esta chamada falhar, o débito já aplicado acima
    // NÃO é revertido - o dinheiro "desaparece" temporariamente. Resolver isso
    // de forma correta (garantir atomicidade mesmo sob falha) é o assunto do
    // Sprint 4, com uma transação distribuída de verdade (2PC/Saga). Por
    // enquanto, só registramos a inconsistência no log.
    registro.registrar('TRANSFERENCIA_FALHOU', relogio.eventoLocal(), {
      idOrigem, idDestino, valor, erro: erro.message,
    });
    res.status(502).json({
      erro: 'Falha ao contatar agência de destino. Débito já aplicado - inconsistência conhecida (ver Sprint 4).',
    });
  }
}

async function creditarRemoto(req, res) {
  const { contas, relogio, registro } = req.app.locals;
  const idConta = parseInt(req.params.id, 10);
  const { valor, timestampLamport, origemAgencia } = req.body;

  // Ao RECEBER uma mensagem de outra agência, o relógio de Lamport é
  // atualizado com base no timestamp recebido - é a regra 3 do algoritmo.
  const ts = relogio.aoReceber(timestampLamport);

  const conta = contas.get(idConta);
  if (!conta) return res.status(404).json({ erro: 'Conta não encontrada nesta agência.' });

  conta.saldo += valor;
  registro.registrar('TRANSFERENCIA_CREDITO_REMOTO', ts, { idConta, valor, origemAgencia });

  res.json({ mensagem: 'Crédito remoto aplicado.', saldoAtual: conta.saldo });
}

export { transferir, creditarRemoto };
```

### 8.2 Tarefa
1. Com as 3 agências rodando, crie ao menos duas contas em agências diferentes (ex.: conta 0 na Agência 0, conta 1 na Agência 1).
2. Faça uma transferência entre agências diferentes e confirme os saldos em ambas:
   ```powershell
   Invoke-RestMethod -Uri "http://localhost:4000/transferencias" -Method Post -ContentType "application/json" -Body '{"idOrigem":0,"idDestino":1,"valor":30}'
   ```
3. Crie uma terceira conta na mesma agência de uma conta existente e faça uma transferência local, comparando o comportamento (e o log gerado) com o da transferência entre agências.
4. Capture prints para `evidencias/sprint1/transferencia-local.png` e `evidencias/sprint1/transferencia-entre-agencias.png`.
5. Reproduza a falha conhecida: feche o terminal de uma das agências de destino e tente transferir para uma conta dela. Observe a resposta 502 e o log de `TRANSFERENCIA_FALHOU`. Capture um print para `evidencias/sprint1/falha-conhecida.png`.
6. Faça o commit:
   ```bash
   git add agencia/src/controllers/transferenciasController.js evidencias/sprint1
   git commit -m "feat(transferencias): implementa transferencia local e entre agencias"
   ```

### 8.3 Perguntas - Parte D
1. No trecho `agenciaDestino === idAgencia`, por que a transferência local não precisa da lógica de `aoEnviar()`/`aoReceber()` do relógio de Lamport, enquanto a transferência entre agências precisa?
2. Reproduza a falha conhecida (tarefa 5) e observe o saldo da conta de origem depois do erro. Ele foi revertido? O que isso significa em termos de consistência do sistema bancário?
3. Pensando à frente para o Sprint 4: cite, em alto nível, duas formas possíveis de corrigir esse problema (não precisa implementar agora, só descrever a ideia).

---

## 9. Adaptando o ICEIBank para Java ou Python

O relógio de Lamport e o registro de eventos são as duas peças realmente novas deste sprint (a API REST/MVC em si é conteúdo já visto na Unidade 2, só que aplicado aqui). Por isso, esta seção traz as duas já implementadas e testadas em Java e em Python - use como base e encaixe na estrutura de projeto da sua linguagem (Spring Boot ou FastAPI/Flask).

### 9.1 Relógio de Lamport

**Java (RelogioLamport.java):**
```java
public class RelogioLamport {
    private int contador = 0;

    public synchronized int eventoLocal() {
        contador += 1;
        return contador;
    }

    public synchronized int aoEnviar() {
        contador += 1;
        return contador;
    }

    public synchronized int aoReceber(int timestampRecebido) {
        contador = Math.max(contador, timestampRecebido) + 1;
        return contador;
    }
}
```
O `synchronized` importa aqui: um servidor Spring Boot atende requisições em várias threads ao mesmo tempo, e o contador do relógio é um estado compartilhado entre elas. Sem isso, duas requisições simultâneas poderiam ler e incrementar o contador de forma inconsistente (uma condição de corrida clássica - o mesmo problema que vocês viram no laboratório de Threads e Semáforos).

**Python (relogio_lamport.py):**
```python
class RelogioLamport:
    def __init__(self):
        self.contador = 0

    def evento_local(self):
        self.contador += 1
        return self.contador

    def ao_enviar(self):
        self.contador += 1
        return self.contador

    def ao_receber(self, timestamp_recebido):
        self.contador = max(self.contador, timestamp_recebido) + 1
        return self.contador
```
Em Python, se usar Flask em modo multi-thread (`threaded=True`) ou vários workers, o mesmo cuidado de concorrência do Java se aplica - proteja o contador com um `threading.Lock` em volta das três operações. Com FastAPI + Uvicorn em um único worker (o padrão para um projeto deste porte), não é necessário.

### 9.2 Registro de eventos

**Java (RegistroEventos.java)** - sem depender de nenhuma biblioteca externa de JSON, só para manter o exemplo simples de compilar; em um projeto maior, prefira Jackson (já incluso no Spring Boot):
```java
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

public class RegistroEventos {
    private final String nomeAgencia;
    private final Path caminhoArquivo;

    public RegistroEventos(String nomeAgencia) throws IOException {
        this.nomeAgencia = nomeAgencia;
        Path pastaDados = Paths.get("data");
        Files.createDirectories(pastaDados);
        this.caminhoArquivo = pastaDados.resolve("eventos-" + nomeAgencia + ".jsonl");
    }

    public Map<String, Object> registrar(String tipo, int timestampLamport, Map<String, Object> detalhes) throws IOException {
        Map<String, Object> evento = new LinkedHashMap<>();
        evento.put("agencia", nomeAgencia);
        evento.put("tipo", tipo);
        evento.put("timestampLamport", timestampLamport);
        evento.put("horaParede", Instant.now().toString());
        evento.put("detalhes", detalhes);

        String linha = paraJson(evento);
        try (FileWriter writer = new FileWriter(caminhoArquivo.toFile(), true)) {
            writer.write(linha + System.lineSeparator());
        }
        System.out.println("[Lamport " + timestampLamport + "] " + tipo + " " + detalhes);
        return evento;
    }

    // Serializador simples, só para os tipos usados neste projeto (String, Number, Map aninhado).
    @SuppressWarnings("unchecked")
    private String paraJson(Object valor) {
        if (valor == null) {
            return "null";
        }
        if (valor instanceof Map) {
            StringBuilder sb = new StringBuilder("{");
            Map<String, Object> mapa = (Map<String, Object>) valor;
            boolean primeiro = true;
            for (Map.Entry<String, Object> entrada : mapa.entrySet()) {
                if (!primeiro) sb.append(",");
                sb.append(""").append(entrada.getKey()).append("":");
                sb.append(paraJson(entrada.getValue()));
                primeiro = false;
            }
            sb.append("}");
            return sb.toString();
        }
        if (valor instanceof Number) {
            return valor.toString();
        }
        String texto = valor.toString().replace("\", "\\").replace(""", "\"");
        return """ + texto + """;
    }
}
```

**Python (registro_eventos.py):**
```python
import json
import os
from datetime import datetime, timezone

class RegistroEventos:
    def __init__(self, nome_agencia):
        self.nome_agencia = nome_agencia
        pasta_dados = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")
        os.makedirs(pasta_dados, exist_ok=True)
        self.caminho_arquivo = os.path.join(pasta_dados, f"eventos-{nome_agencia}.jsonl")

    def registrar(self, tipo, timestamp_lamport, detalhes):
        evento = {
            "agencia": self.nome_agencia,
            "tipo": tipo,
            "timestampLamport": timestamp_lamport,
            "horaParede": datetime.now(timezone.utc).isoformat(),
            "detalhes": detalhes,
        }
        with open(self.caminho_arquivo, "a", encoding="utf-8") as arquivo:
            arquivo.write(json.dumps(evento, ensure_ascii=False) + "
")
        print(f"[Lamport {timestamp_lamport}] {tipo} {detalhes}")
        return evento
```
Os três exemplos (Node, Java, Python) produzem exatamente a mesma sequência de timestamps para a mesma sequência de chamadas, e gravam o mesmo formato de linha JSON.

### 9.3 O resto da arquitetura
* **API REST/MVC:** FastAPI ou Flask (Python) e Spring Boot (Java) seguem a mesma separação de rotas/controllers/models usada no exemplo Node - crie o equivalente a `contasController` e `transferenciasController` como controllers/routers da sua linguagem.
* **Chamada entre agências:** `requests.post(...)` em Python, `RestTemplate` ou `HttpClient` em Java, no lugar do `axios.post(...)`.
* **Configuração e partição:** o `config.js` da seção 5.1 vira uma classe/módulo equivalente - o cálculo `id_conta % NUMERO_AGENCIAS` é idêntico em qualquer linguagem.

O importante é que a lógica do relógio de Lamport e a estrutura de eventos sejam equivalentes ao exemplo Node, para que a linha do tempo unificada da próxima seção funcione da mesma forma, independentemente da linguagem escolhida.

---

## 10. Parte E: Linha do tempo unificada (observando o relógio de Lamport na prática)

### 10.1 agencia/mesclar-logs.js
Este script lê os `.jsonl` de todas as agências e monta uma única linha do tempo, ordenada por relógio de Lamport:

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
    .split('
')
    .filter(Boolean);
  todosEventos.push(...linhas.map((l) => JSON.parse(l)));
}

todosEventos.sort((a, b) => a.timestampLamport - b.timestampLamport);

console.log('=== Linha do tempo unificada (ordenada por relogio de Lamport) ===');
for (const evento of todosEventos) {
  console.log(
    `[Lamport ${evento.timestampLamport}] (${evento.horaParede}) ${evento.agencia} - ${evento.tipo}`,
    JSON.stringify(evento.detalhes)
  );
}
```

Como executar (depois de já ter gerado alguns eventos nas seções anteriores):
```bash
cd iceibank/agencia
node mesclar-logs.js
```

### 10.2 Tarefa
1. Rode o script e observe a linha do tempo unificada das 3 agências.
2. Procure por dois eventos com o mesmo valor de `timestampLamport`, vindos de agências diferentes (é bem provável que apareça, especialmente entre operações que não têm relação causal entre si - por exemplo, criar uma conta na Agência 0 enquanto a Agência 1 processa um crédito remoto ao mesmo tempo). Se não aparecer no seu teste, gere mais eventos concorrentes (rode operações em terminais diferentes quase ao mesmo tempo) até conseguir um caso.
3. Para esse par de eventos empatados: eles são realmente causalmente relacionados (um influenciou o outro) ou são concorrentes (aconteceram de forma independente)? Compare também com o campo `horaParede` de cada um - a ordem por hora de parede bate com a ordem por Lamport?
4. Capture um print da linha do tempo para `evidencias/sprint1/linha-do-tempo.png`.
5. Responda em `RESPOSTAS.md` o que observou no passo 3.
6. Faça o commit final do sprint:
   ```bash
   git add agencia/mesclar-logs.js evidencias/sprint1 RESPOSTAS.md
   git commit -m "feat(observabilidade): adiciona script de linha do tempo unificada"
   ```

### 10.3 Perguntas - Parte E
1. O relógio de Lamport garante que, se A aconteceu antes de B causalmente, `timestamp(A) < timestamp(B)`. Ele não garante a volta. O que isso significa na prática quando você vê dois eventos com timestamps diferentes na linha do tempo, mas sem saber se um realmente influenciou o outro?
2. Baseado no que você observou no passo 3 da tarefa: o relógio de Lamport, sozinho, seria suficiente para um sistema que precisa distinguir com certeza “A e B são concorrentes” de “A aconteceu antes de B”? Por que isso motiva o relógio vetorial do Sprint 2?

---

## 11. Parte F: Autenticação (JWT)

**Conceito:** um JWT (JSON Web Token) é um token assinado digitalmente que carrega informações sobre quem está autenticado. Como a assinatura pode ser verificada matematicamente, o servidor não precisa consultar um banco de dados a cada requisição só para saber “quem é esse usuário” - basta validar a assinatura do token.

Esta parte não vem com código de exemplo. Diferente do resto do roteiro, aqui a implementação é 100% sua - inclusive as decisões de design (formato das credenciais, tempo de expiração do token, biblioteca usada). Pesquise a biblioteca de JWT da sua linguagem escolhida e implemente a partir dos requisitos abaixo.

### 11.1 Requisitos obrigatórios
* Um endpoint de login (ex.: `POST /auth/login`) que recebe credenciais e, se válidas, retorna um token JWT. O formato das credenciais (usuário e senha, id de conta e senha, ou outro modelo) é decisão sua - documente e justifique a escolha em `RESPOSTAS.md`.
* O token deve ter um tempo de expiração definido (não pode ser eterno).
* Todas as rotas que leem ou modificam contas (consultar saldo, depositar, sacar, transferir, criar conta) devem passar a exigir um token JWT válido, enviado no cabeçalho `Authorization: Bearer <token>`.
* Requisições sem token, com token inválido, ou com token expirado devem ser rejeitadas com HTTP 401.
* A chamada entre agências (`creditar-remoto`, da Parte D) também precisa continuar funcionando. Pense e decida: essa chamada interna, agência-a-agência, deveria carregar um token igual às chamadas vindas do frontend, ou é aceitável tratá-la de forma diferente? Justifique sua decisão em `RESPOSTAS.md`.

Bibliotecas para pesquisar (nenhum código é fornecido aqui - a pesquisa e a implementação são parte da tarefa):
* **Java:** `io.jsonwebtoken:jjwt`, ou o suporte a JWT do Spring Security.
* **Python:** `PyJWT`, ou o suporte a JWT do FastAPI (via `python-jose` ou biblioteca equivalente).

### 11.2 Tarefa
1. Implemente o endpoint de login e a geração do token.
2. Proteja as rotas indicadas acima.
3. Teste três cenários: (a) requisição sem token, confirmando o 401; (b) requisição com token válido, confirmando que a operação funciona normalmente; (c) requisição com token expirado (espere o tempo de expiração passar, ou gere um token já expirado de propósito), confirmando o 401.
4. Capture prints para `evidencias/sprint1/auth-sem-token.png`, `evidencias/sprint1/auth-com-token.png` e `evidencias/sprint1/auth-token-expirado.png`.
5. Faça o commit:
   ```bash
   git add agencia evidencias/sprint1 RESPOSTAS.md
   git commit -m "feat(auth): protege a API com autenticacao JWT"
   ```

### 11.3 Perguntas - Parte F
1. Qual a diferença entre autenticação e autorização? Sua implementação verifica só uma das duas, ou as duas? Por exemplo: um usuário autenticado consegue sacar de uma conta que não é dele, na sua implementação atual?
2. Por que o servidor não precisa consultar um banco de dados para validar a assinatura de um JWT a cada requisição? O que isso implica sobre escalabilidade, comparado a guardar sessões em memória no servidor?
3. O que aconteceria com a segurança do sistema se a chave secreta usada para assinar o JWT vazasse?

---

## 12. Parte G: Frontend

**Conceito:** um frontend web que consome a API do ICEIBank, respeitando a autenticação implementada na Parte F. A tecnologia é livre - React, Vue, Angular, Svelte, ou até HTML/CSS/JavaScript puro, sem framework. O único requisito de plataforma é que seja web - o app mobile fica reservado para o Sprint 3, com Flutter.

Esta parte também não vem com código de exemplo. A escolha do framework, a estrutura das telas e a forma de guardar o token são decisões suas.

### 12.1 Requisitos obrigatórios
* Tela de login: campo(s) de credenciais, chamando o endpoint de login da Parte F e guardando o token recebido (ex.: `localStorage`) para reenviar nas próximas requisições.
* Consulta de saldo de uma conta.
* Depósito e saque, via formulário.
* Transferência, funcionando tanto para transferência local quanto entre agências - o frontend não precisa saber a diferença entre as duas (isso é resolvido no backend), mas deve exibir claramente o resultado de cada uma.
* Tratamento visível de erros retornados pela API - saldo insuficiente, conta não encontrada, 401 por token ausente/expirado, falha de transferência entre agências. A mensagem deve aparecer para quem está usando a tela, não só no console do navegador.
* O frontend deve conseguir apontar para qualquer uma das 3 agências (ex.: um campo ou uma configuração indicando qual agência é a “porta de entrada” daquele acesso), já que cada agência só responde pelas contas sob sua responsabilidade.

O que não é exigido: design elaborado, responsividade, testes automatizados de interface. Funcional já é suficiente.

### 12.2 Tarefa
1. Implemente as telas e funcionalidades acima.
2. Execute o fluxo completo pela interface, não mais via curl/Postman: login, consulta de saldo, depósito, saque, transferência local, transferência entre agências, e um caso de erro (ex.: tentar sacar mais do que o saldo disponível).
3. Capture prints do frontend em uso para cada uma dessas ações e salve em `evidencias/sprint1/frontend-login.png`, `evidencias/sprint1/frontend-transferencia.png` e `evidencias/sprint1/frontend-erro.png` (pelo menos esses três; adicione mais se quiser documentar melhor).
4. Faça o commit:
   ```bash
   git add frontend evidencias/sprint1
   git commit -m "feat(frontend): implementa interface web para o ICEIBank"
   ```

### 12.3 Perguntas - Parte G
1. Como o frontend “lembra” de reenviar o token em cada requisição depois do login? Descreva, em alto nível, o mecanismo que você implementou.
2. Se o token expirar enquanto alguém está usando o frontend no meio de uma operação, o que acontece na sua implementação? A interface avisa a pessoa usuária, ou ela só vê um erro genérico?
3. Esta unidade da disciplina trata de arquitetura MVC. No seu frontend, onde fica o “M” (Model), o “V” (View) e o “C” (Controller)? Eles existem de forma clara na sua implementação, ou o código ficou mais misturado do que o padrão sugere?

---

## 13. Checklist de entrega

- [ ] Repositório Git com a estrutura de pastas indicada, com histórico de commits incremental ao longo do sprint (não um único commit no fim)
- [ ] As 3 agências rodando simultaneamente (mesmo código, `AGENCIA_ID` diferente), cada uma respondendo pela sua partição de contas
- [ ] CRUD de contas + depósito/saque funcionando, cada operação registrada com timestamp de Lamport
- [ ] Transferência local (mesma agência) e entre agências funcionando
- [ ] A falha conhecida (Parte D) reproduzida e documentada, não escondida
- [ ] Script `mesclar-logs.js` funcionando e usado para observar concorrência real
- [ ] Autenticação JWT protegendo as rotas da API (Parte F), com os três cenários de teste (sem token, com token válido, com token expirado)
- [ ] Frontend funcional consumindo a API autenticada (Parte G), cobrindo login, saldo, depósito, saque e as duas formas de transferência
- [ ] Pelo menos uma funcionalidade adicional implementada e documentada (seção 2.1)
- [ ] Pasta `evidencias/sprint1/` com os prints indicados nas seções 4.2, 2.1, 11.2 e 12.2
- [ ] Arquivo `RESPOSTAS.md` completo, com as questões das seções 6.4, 8.3, 10.3, 11.3 e 12.3, a descrição da funcionalidade adicional escolhida, e as justificativas de design pedidas nas Partes F e G

---

## 14. Critérios de avaliação (20 pontos)

| Critério | Pontos | O que é observado |
| :--- | :--- | :--- |
| **API REST/MVC de contas** | 3 | Criar, consultar, depositar e sacar funcionando corretamente, com separação clara de rotas/controllers |
| **Particionamento correto** | 2 | Contas atribuídas à agência certa; agência recusa operar contas que não são suas |
| **Relógio de Lamport** | 3 | As três regras (evento local, ao enviar, ao receber) implementadas e aplicadas corretamente em cada operação, inclusive nas chamadas entre agências |
| **Transferências e limitação conhecida** | 2 | Transferência local e entre agências funcionando; a falha sob queda de agência é reproduzida e registrada corretamente, não ignorada |
| **Autenticação JWT** | 2 | Login, expiração, proteção das rotas e os três cenários de teste funcionando; decisões de design justificadas |
| **Frontend** | 3 | Fluxo completo funcionando pela interface, com tratamento visível de erros |
| **Funcionalidade adicional** | 1 | Funcionalidade nova e genuína (seção 2.1), funcionando, evidenciada e documentada em `RESPOSTAS.md` |
| **Commits** | 1 | Histórico incremental ao longo do sprint, mensagens claras |
| **Respostas às questões** | 1 | Compreensão demonstrada, com referência ao comportamento observado no código |
| **Video de apresentação** | 2 | Funcionalidades e principais decisões do projeto |

---

## 15. Referências

* LAMPORT, Leslie. Time, Clocks, and the Ordering of Events in a Distributed System. Communications of the ACM, v. 21, n. 7, 1978.
* COULOURIS, George et al. Distributed Systems: Concepts and Design. 5th ed. Addison-Wesley, 2011.
* TANENBAUM, A. S.; VAN STEEN, M. Sistemas Distribuídos: Princípios e Paradigmas. Tradução da 2ª edição. Pearson, 2007.
* MARTIN, Robert C. Arquitetura Limpa: o guia do artesão para estrutura e design de software. Alta Books, 2019. (Padrões arquiteturais, incluindo MVC.)
* Express.js. Documentação oficial. Disponível em: https://expressjs.com/
* JONES, M.; BRADLEY, J.; SAKIMURA, N. RFC 7519 - JSON Web Token (JWT). IETF, 2015. Disponível em: https://datatracker.ietf.org/doc/html/rfc7519
