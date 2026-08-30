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