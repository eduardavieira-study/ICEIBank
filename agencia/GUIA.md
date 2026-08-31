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
Invoke-RestMethod -Uri "http://localhost:4074/contas" -Method Post -ContentType "application/json" -Body '{"id":0,"nomeAluno":"Ana","saldoInicial":100}'

# Consultar saldo
Invoke-RestMethod -Uri "http://localhost:4074/contas/0" -Method Get

# Depositar
Invoke-RestMethod -Uri "http://localhost:4074/contas/0/depositar" -Method Post -ContentType "application/json" -Body '{"valor":25}'
```

Invoke-RestMethod -Uri "http://localhost:4075/contas" -Method Post -ContentType "application/json" -Body '{"id":1,"nomeAluno":"Helena","saldoInicial":300}'

Invoke-RestMethod -Uri "http://localhost:4075/contas" -Method Post -ContentType "application/json" -Body '{"id":4,"nomeAluno":"Lucas","saldoInicial":150}'

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
Invoke-RestMethod -Uri "http://localhost:4074/contas" -Method Post -ContentType "application/json" -Body '{"id": 0, "nomeAluno": "Ana", "saldoInicial": 100.0}' -Headers $headers

# B. Login como a Ana e consulta de saldo usando seu próprio token
$loginResUser = Invoke-RestMethod -Uri "http://localhost:4074/auth/login" -Method Post -ContentType "application/json" -Body '{"idConta": 0, "nomeAluno": "Ana"}'
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