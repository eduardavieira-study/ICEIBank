## Como rodar em Python
O equivalente ao exemplo em Node é iniciar o FastAPI com a variável AGENCIA_ID definida antes da execução. O ponto de entrada está em main.py, e as portas de cada agência vêm de config.py.

Cada agência é o mesmo código, identificada por uma variável de ambiente AGENCIA_ID. Abra 3 janelas do PowerShell:

PowerShell
```
# 1. Cria o ambiente virtual
python3 -m venv venv

# 2. Ativa o ambiente virtual no PowerShell
./venv/bin/Activate.ps1

# 3. Instala as dependências nele
python3 -m pip install -r agencia/requirements.txt

# 4. Define a agência e executa
$env:AGENCIA_ID="0"
python3 -m agencia.src.main

$env:AGENCIA_ID="1"
python3 -m agencia.src.main

$env:AGENCIA_ID="2"
python3 -m agencia.src.main
```

Em um quarto terminal, teste com Invoke-RestMethod:
```
# Criar a conta 0 na Agência 0 (0 % 3 == 0)
Invoke-RestMethod -Uri "http://localhost:4074/contas" -Method Post -ContentType "application/json" -Body '{"id":0,"nomeAluno":"Ana","senha":"ana123","saldoInicial":100}'

# Consultar saldo
Invoke-RestMethod -Uri "http://localhost:4074/contas/0" -Method Get

# Depositar
Invoke-RestMethod -Uri "http://localhost:4074/contas/0/depositar" -Method Post -ContentType "application/json" -Body '{"valor":25}'
```

Invoke-RestMethod -Uri "http://localhost:4075/contas" -Method Post -ContentType "application/json" -Body '{"id":1,"nomeAluno":"Helena","senha":"helena123","saldoInicial":300}'

Invoke-RestMethod -Uri "http://localhost:4075/contas" -Method Post -ContentType "application/json" -Body '{"id":4,"nomeAluno":"Lucas","senha":"lucas123","saldoInicial":150}'

Invoke-RestMethod -Uri "http://localhost:4074/transferencias" -Method Post -ContentType "application/json" -Body '{"idOrigem":0,"idDestino":1,"valor":10}'

Invoke-RestMethod -Uri "http://localhost:4075/transferencias" -Method Post -ContentType "application/json" -Body '{"idOrigem":1,"idDestino":4,"valor":15}'

### Testes com autenticação
```
# Sem Token
Invoke-RestMethod -Uri "http://localhost:4074/contas/0" -Method Get
```
---
Token Válido
```
# A. Login como Admin e criação da conta 0
$loginRes = Invoke-RestMethod -Uri "http://localhost:4074/auth/login" -Method Post -ContentType "application/json" -Body '{"usuario": "admin", "senha": "admin"}'
$adminToken = $loginRes.token
$headers = @{ Authorization = "Bearer $adminToken" }
Invoke-RestMethod -Uri "http://localhost:4074/contas" -Method Post -ContentType "application/json" -Body '{"id": 0, "nomeAluno": "Ana", "senha": "ana123", "saldoInicial": 100.0}' -Headers $headers

# B. Login como a Ana e consulta de saldo usando seu próprio token
$loginResUser = Invoke-RestMethod -Uri "http://localhost:4074/auth/login" -Method Post -ContentType "application/json" -Body '{"nomeAluno": "Ana", "senha": "ana123"}'
$userToken = $loginResUser.token
$headersUser = @{ Authorization = "Bearer $userToken" }
Invoke-RestMethod -Uri "http://localhost:4074/contas/0" -Method Get -Headers $headersUser
```
Token Expirado (401)

```
# 1. Faz login como admin pedindo o token já expirado (-10 segundos)
$loginResExp = Invoke-RestMethod -Uri "http://localhost:4074/auth/login" -Method Post -ContentType "application/json" -Body '{"usuario": "admin", "senha": "admin", "expirar_em_segundos": -10}'

# 2. Extrai o token gerado
$expiredToken = $loginResExp.token

# 3. Tenta acessar com o token expirado
$headersExp = @{ Authorization = "Bearer $expiredToken" }
Invoke-RestMethod -Uri "http://localhost:4074/contas/0" -Method Get -Headers $headersExp
```

Testar Historico

Logar e criar conta 
```
# 1. Faz login como admin
$loginRes = Invoke-RestMethod -Uri "http://localhost:4074/auth/login" -Method Post -ContentType "application/json" -Body '{"usuario": "admin", "senha": "admin"}'
$adminToken = $loginRes.token
$headersAdmin = @{ Authorization = "Bearer $adminToken" }

# 2. Cria a conta 0 (Ana) com saldo inicial de 100.0
Invoke-RestMethod -Uri "http://localhost:4074/contas" -Method Post -ContentType "application/json" -Body '{"id": 0, "nomeAluno": "Ana", "senha": "ana123", "saldoInicial": 100.0}' -Headers $headersAdmin
```
Realizar Movimentações na Conta (Gerar Eventos)
```
# 1. Deposita 50.0 na conta 0 (usando token de admin para autorizar)
Invoke-RestMethod -Uri "http://localhost:4074/contas/0/depositar" -Method Post -ContentType "application/json" -Body '{"valor": 50.0}' -Headers $headersAdmin

# 2. Saca 20.0 da conta 0 (usando token de admin para autorizar)
Invoke-RestMethod -Uri "http://localhost:4074/contas/0/sacar" -Method Post -ContentType "application/json" -Body '{"valor": 20.0}' -Headers $headersAdmin
```

Obter o Token da Ana (Dona da Conta)
```
# 1. Faz login como a Ana
$loginResUser = Invoke-RestMethod -Uri "http://localhost:4074/auth/login" -Method Post -ContentType "application/json" -Body '{"nomeAluno": "Ana", "senha": "ana123"}'
$userToken = $loginResUser.token
$headersUser = @{ Authorization = "Bearer $userToken" }
```

Consultar o Histórico Autorizado
```
# Consulta o histórico (extrato) da conta 0
Invoke-RestMethod -Uri "http://localhost:4074/contas/0/historico" -Method Get -Headers $headersUser
```

Testa consultar histórico sem token
```
# Tenta consultar o histórico sem cabeçalho Authorization
Invoke-RestMethod -Uri "http://localhost:4074/contas/0/historico" -Method Get
```

---

## Sprint 2: Mensageria (RabbitMQ) e Relógio Vetorial

Comandos em PowerShell (testados aqui com o PowerShell Preview instalado na máquina - `pwsh`). Use sua instância real do CloudAMQP (não Docker local), conforme pedido pelo professor.

### 1. Variável de ambiente RABBITMQ_URL - via `.env`, não `$env:`

Existe um arquivo `.env` na raiz do repositório com a sua URL real do CloudAMQP:
```
RABBITMQ_URL=amqps://usuario:senha@host.cloudamqp.com/vhost
```
Isso **não** é um script PowerShell (não tem `$env:` nem aspas) - é o formato padrão que `python-dotenv` lê. `main.py` carrega esse arquivo sozinho, então **não precisa rodar `$env:RABBITMQ_URL = "..."` em cada terminal** - só precisa o `.env` existir na raiz (ele já está no `.gitignore`, nunca vai para o commit). Se precisar recriá-lo, use `.env.example` como modelo.

### 2. Instala a dependência nova e sobe as 3 agências

Em cada um dos 3 terminais PowerShell:
```powershell
cd /Users/eduarda/Documents/ICEIBank
./venv/bin/Activate.ps1
python3 -m pip install -r agencia/requirements.txt   # pika (RabbitMQ) e python-dotenv são novos
```

Terminal 1:
```powershell
$env:AGENCIA_ID = "0"
python3 -m agencia.src.main
```
Terminal 2:
```powershell
$env:AGENCIA_ID = "1"
python3 -m agencia.src.main
```
Terminal 3:
```powershell
$env:AGENCIA_ID = "2"
python3 -m agencia.src.main
```

Espere aparecer em cada terminal: `[Agência X] aguardando mensagens na fila 'fila-agencia-X'...` (se não aparecer de imediato, é só buffer de saída - rodando direto no terminal como acima ele aparece na hora).

### 3. Transferência assíncrona entre agências (4º terminal)

```powershell
Get-Date   # evidência de tempo real para o print

$loginRes = Invoke-RestMethod -Uri "http://localhost:4074/auth/login" -Method Post -ContentType "application/json" -Body (@{usuario="admin"; senha="admin"} | ConvertTo-Json)
$headersAdmin = @{ Authorization = "Bearer $($loginRes.token)" }

Invoke-RestMethod -Uri "http://localhost:4074/contas" -Method Post -ContentType "application/json" -Headers $headersAdmin -Body (@{id=0; nomeAluno="Ana"; senha="ana123"; saldoInicial=100} | ConvertTo-Json)
Invoke-RestMethod -Uri "http://localhost:4075/contas" -Method Post -ContentType "application/json" -Headers $headersAdmin -Body (@{id=1; nomeAluno="Bruno"; senha="bruno123"; saldoInicial=50} | ConvertTo-Json)

$loginAna = Invoke-RestMethod -Uri "http://localhost:4074/auth/login" -Method Post -ContentType "application/json" -Body (@{nomeAluno="Ana"; senha="ana123"} | ConvertTo-Json)
$headersAna = @{ Authorization = "Bearer $($loginAna.token)" }

Invoke-RestMethod -Uri "http://localhost:4074/transferencias" -Method Post -ContentType "application/json" -Headers $headersAna -Body (@{idOrigem=0; idDestino=1; valor=30} | ConvertTo-Json)

Start-Sleep -Seconds 2
Write-Host "Saldo da conta 1 na Agencia 1 (esperado 80):"
Invoke-RestMethod -Uri "http://localhost:4075/contas/1" -Method Get -Headers $headersAdmin
```

Resultado esperado: `mensagem: Transferência publicada para a agência de destino (entrega assíncrona).` e depois `saldo: 80`.

📸 **Print `evidencias/sprint2/transferencia-assincrona.png`:** com os 3 terminais das agências visíveis (o terminal da Agência 1 deve mostrar o log `[Vetor [...]] TRANSFERENCIA_CREDITO_REMOTO`) + o terminal de comandos com o `Get-Date` e o saldo final 80.

### 4. Teste de resiliência (agência de destino fora do ar)

Derrube a Agência 1 (`Ctrl+C` no terminal dela), depois rode no 4º terminal:
```powershell
Get-Date
Invoke-RestMethod -Uri "http://localhost:4074/transferencias" -Method Post -ContentType "application/json" -Headers $headersAna -Body (@{idOrigem=0; idDestino=1; valor=15} | ConvertTo-Json)
# -> resposta com "mensagem: ...publicada..." mesmo com a Agência 1 fora do ar (fica retida na fila)
```

Suba a Agência 1 de novo (mesmo comando do passo 2, terminal 2) e observe o log dela ao reconectar. Como as contas vivem só em memória, se você não recriar a conta 1 antes de reiniciar, o log vai mostrar `CREDITO_REMOTO_FALHOU` (a mensagem não se perdeu - chegou certinho pelo RabbitMQ - mas a conta já não existia mais quando ela chegou: é a limitação conhecida descrita na seção 2 do roteiro). Para confirmar, no 4º terminal:
```powershell
Invoke-RestMethod -Uri "http://localhost:4075/contas/1" -Method Get -Headers $headersAdmin
# -> 404 "Conta não encontrada", se você não recriou a conta 1 antes de religar a agência
```

📸 **Print `evidencias/sprint2/resiliencia-fila.png`:** a sequência acima - a resposta publicada com a Agência 1 fora do ar, e o log dela ao religar, processando (ou falhando) o crédito.

### 5. Confirma que o RabbitMQ Manager mostra as filas

No painel do CloudAMQP (cloudamqp.com → sua instância → **RabbitMQ Manager**), confira a exchange `iceibank.eventos` (tipo `topic`) e as 3 filas `fila-agencia-0/1/2`, cada uma com `routing key` `agencia.<id>.creditar` e 1 consumidor ativo enquanto a agência correspondente estiver no ar.

### 6. Regressão (JWT e frontend)

```powershell
try { Invoke-RestMethod -Uri "http://localhost:4074/contas/0" -Method Get } catch { $_.Exception.Response.StatusCode }
# -> 401/403 sem token
```
Abra o frontend e confirme login + uma operação funcionando normalmente.

### 7. Commit

```powershell
git add agencia/src agencia/requirements.txt .env.example evidencias/sprint2
git commit -m "feat(mensageria): substitui chamada REST direta por publish/subscribe via RabbitMQ"
```