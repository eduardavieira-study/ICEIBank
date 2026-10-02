Como executar (por enquanto só cria/consulta/deposita/saca - transferências vêm na Parte D)
Cada agência é o mesmo código, identificada por uma variável de ambiente AGENCIA_ID. Abra 3 janelas do PowerShell:
```
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
Em um quarto terminal, teste com Invoke-RestMethod:
```
# Criar a conta 0 na Agência 0 (0 % 3 == 0)
Invoke-RestMethod -Uri "http://localhost:4000/contas" -Method Post -ContentType "application/json" -Body '{"id":0,"nomeAluno":"Ana","saldoInicial":100}'

# Consultar saldo
Invoke-RestMethod -Uri "http://localhost:4000/contas/0" -Method Get

# Depositar
Invoke-RestMethod -Uri "http://localhost:4000/contas/0/depositar" -Method Post -ContentType "application/json" -Body '{"valor":25}'
Se preferir Postman em vez de Invoke-RestMethod, os mesmos endpoints funcionam normalmente - use o corpo JSON equivalente.
```

> Nota: `config.js` já aplica um `OFFSET` pessoal às portas (`PORTA_BASE = 4000 + OFFSET`), então na prática as agências sobem em `4074`, `4075` e `4076` (não `4000`/`4001`/`4002`) - os comandos da seção abaixo (Sprint 2) já usam as portas corretas.

---

## Sprint 2: Mensageria (RabbitMQ) e Relógio Vetorial

Esta pasta é só a referência ilustrativa em Node (o roteiro deixa claro que a entrega é em Java ou Python) - mas como o próprio roteiro traz o código de mensageria em Node, ela também foi atualizada para comparação. Sem JWT aqui, só os endpoints simples.

### 1. Variável de ambiente RABBITMQ_URL

Existe um `.env` na raiz do repositório com `RABBITMQ_URL=amqps://...` (sua instância CloudAMQP). `app.js` carrega esse arquivo sozinho com `process.loadEnvFile(...)` (recurso nativo do Node, sem precisar da lib `dotenv`) - não precisa exportar nada manualmente. Se quiser testar contra um RabbitMQ local, suba via Docker e sobrescreva a variável só neste terminal:
```bash
docker run -d --name rabbitmq-iceibank -p 5672:5672 -p 15672:15672 rabbitmq:3-management
export RABBITMQ_URL="amqp://localhost"
```

### 2. Instala a dependência nova (`amqplib`) e sobe as 3 agências

```bash
cd agencia-express
npm install

# Terminal 1
export AGENCIA_ID=0
node src/app.js

# Terminal 2
export AGENCIA_ID=1
node src/app.js

# Terminal 3
export AGENCIA_ID=2
node src/app.js
```

Espere aparecer em cada terminal: `[Agência X] aguardando mensagens na fila 'fila-agencia-X'...`.

### 3. Transferência assíncrona entre agências (4º terminal)

```bash
date   # evidência de tempo real para o print

curl -s -X POST http://localhost:4074/contas -H "Content-Type: application/json" -d '{"id":0,"nomeAluno":"Ana","saldoInicial":100}'
curl -s -X POST http://localhost:4075/contas -H "Content-Type: application/json" -d '{"id":1,"nomeAluno":"Bruno","saldoInicial":50}'

curl -s -X POST http://localhost:4074/transferencias -H "Content-Type: application/json" -d '{"idOrigem":0,"idDestino":1,"valor":30}'

# Confere na Agência 1 - deve mostrar saldo 80
curl -s http://localhost:4075/contas/1
```

### 4. Teste de resiliência

```bash
# Derruba a Agência 1 (Ctrl+C), depois:
date
curl -s -X POST http://localhost:4074/transferencias -H "Content-Type: application/json" -d '{"idOrigem":0,"idDestino":1,"valor":15}'
# -> resposta 200 mesmo com a Agência 1 fora do ar

# Sobe a Agência 1 de novo (mesmo comando do passo 2) e observe o log dela ao reconectar
```

Como as contas vivem só em memória, se a conta 1 não for recriada antes de religar a agência, o log mostrará `CREDITO_REMOTO_FALHOU` - a mensagem chegou (RabbitMQ não perde nada), mas não havia onde aplicar o crédito.

> ⚠️ **Não rode esta pasta (`agencia-express`) ao mesmo tempo que `agencia` (Python) contra a mesma `RABBITMQ_URL`.** As duas usam a mesma exchange (`iceibank.eventos`) e os mesmos nomes de fila (`fila-agencia-0/1/2`) no broker real - se ambas estiverem no ar juntas, o RabbitMQ distribui as mensagens entre quem estiver consumindo primeiro (Python ou Node), não necessariamente a agência "certa" pra quem está testando. Encerre um lado antes de subir o outro.

### Parte D (linha do tempo causal)

`mesclar-logs.js` também foi atualizado para a Parte D (compara vetores e aponta pares concorrentes, igual à versão Python). Rode com:
```bash
node mesclar-logs.js
```
Os comandos de teste (criar contas independentes, fazer uma transferência, conferir que o par causal não aparece como concorrente) e o guia de como tirar os prints estão detalhados em `agencia/GUIA.md` - a lógica e os passos são os mesmos, só troca `Invoke-RestMethod ... -Headers $headersAdmin` por chamadas sem token (este app de referência não tem JWT).