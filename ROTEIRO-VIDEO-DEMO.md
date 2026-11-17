# Roteiro do vídeo de demonstração — ICEIBank (Sprints 2 e 3)

**Duração do vídeo:** ~2 min 30 s. Ele entra no meio dos 5 min de apresentação, então você fala por cima dele, com o vídeo mudo ou só com o som ambiente.
**Dica de ouro:** grave a tela **sem narração** e fale ao vivo enquanto o vídeo roda. Assim você controla o ritmo e não precisa regravar se errar uma frase. As falas abaixo são o que você diz ao vivo.

---

## Antes de gravar (checklist)

- [ ] RabbitMQ (CloudAMQP) acessível e `.env` com `RABBITMQ_URL`.
- [ ] 3 terminais lado a lado, um por agência, com fonte grande (zoom do terminal em 150%).
- [ ] Um 4º terminal pequeno para `curl` e scripts.
- [ ] Emulador do celular aberto ao lado, **tema claro**, sem notificações.
- [ ] Conta de aluno já criada, com saldo acima de R$ 100 (ex.: Ana, conta 0, Agência 0).
- [ ] Subir as agências **antes** de gravar e confirmar a líder: `curl http://localhost:4074/bully/lider`. A líder esperada é a Agência 2.
- [ ] Gravador de tela com resolução 1080p e sem janelas pessoais abertas.
- [ ] Faça um ensaio completo. Se algo falhar ao vivo, o vídeo é o seu plano B.

**Subir as agências (3 terminais, na raiz do projeto):**
```bash
AGENCIA_ID=0 python3 -m agencia.src.main   # porta 4074
AGENCIA_ID=1 python3 -m agencia.src.main   # porta 4075
AGENCIA_ID=2 python3 -m agencia.src.main   # porta 4076
```
**App:** `cd app_mobile && flutter run`

---

## Cena 1 — Visão geral (0:00 – 0:15)

**Mostrar:** os 3 terminais das agências com "Uvicorn running" e o app aberto na tela principal.

**Falar:**
> "Aqui estão as 3 agências do ICEIBank rodando de forma independente, cada uma na sua porta, e o app Flutter conectado nelas. Vou mostrar quatro coisas: mensageria, eleição de líder, failover e o modo offline."

---

## Cena 2 — Transferência assíncrona via RabbitMQ (0:15 – 0:50) · Sprint 2

**Mostrar:**
1. No app, logado como Ana (Agência 0), abrir **Transferir**, escolher uma conta da **Agência 1** (ex.: conta 1) e enviar um valor pequeno (R$ 10).
2. Olhar o terminal da Agência 0 (`TRANSFERENCIA_DEBITO`) e depois o da Agência 1 (`TRANSFERENCIA_CREDITO_REMOTO`), destacando o **vetor** `[Vetor [x, y, z]]` no começo de cada linha.
3. *(Opcional, +15 s)* Rodar `python3 agencia/mesclar_logs.py` e apontar a seção **"Pares de eventos CONCORRENTES"**.

**Falar:**
> "Na Sprint 1 essa transferência era uma chamada REST direta e falhava se a outra agência caísse. Agora a Agência 0 só publica uma mensagem no RabbitMQ e a Agência 1 consome quando puder. Repare que cada linha de log tem um vetor: é o relógio vetorial, com uma posição por agência."
>
> *(se rodar o script)* "O script junta os logs das três agências e mostra quais eventos são comprovadamente concorrentes, o que o relógio de Lamport não conseguia afirmar."

> **Plano B:** se a transferência não aparecer no log, mostre o print `evidencias/sprint2/transferencia-assincrona.png`.

---

## Cena 3 — Painel da líder e failover (0:50 – 1:35) · Sprint 3

**Mostrar:**
1. No app, rolar até o card **"Líder atual"**: Agência 2 com coroa e as 3 agências **Ativas**.
2. No terminal da **Agência 2** (a líder), apertar **Ctrl+C**. Deixar o app visível ao lado, **sem tocar na tela**.
3. Esperar ~3 a 6 s: o cartão da Agência 2 fica vermelho (**Fora do ar**) e a coroa passa para a Agência 1, com "Antes: Agência 2".
4. Apontar nos terminais das Agências 0 e 1 as linhas `LIDER_NAO_RESPONDEU`, `ELEICAO_INICIADA` e `TORNOU_LIDER`.
5. Subir a Agência 2 de novo (`AGENCIA_ID=2 python3 -m agencia.src.main`). Ela retoma a liderança, porque tem o maior ID.
6. *(Opcional)* Rodar `python3 agencia/historico_lideranca.py` e mostrar a "Linha do tempo de líderes".

**Falar:**
> "As agências elegem uma líder com o algoritmo de Bully: vence a de maior ID entre as ativas. O app consulta as três a cada 3 segundos e mostra quem é a líder e quem está no ar."
>
> "Agora vou derrubar a líder de verdade. Sem eu mexer no app, o cartão dela fica vermelho e a coroa passa para a Agência 1. Foi o heartbeat que detectou a queda e disparou uma nova eleição automaticamente."
>
> "Quando a Agência 2 volta, ela retoma a liderança, porque tem o maior ID. Isso é correto no Bully, mas na Sprint 4 vai ser um ponto de atenção, porque trocar de líder no meio de uma transação pode causar problemas."

> **Atenção:** derrube a líder **com o app já aberto na tela principal**. Se o token expirar, o app volta para o login.

---

## Cena 4 — Offline-first (1:35 – 2:25) · Sprint 3

**Mostrar:**
1. Ativar o **modo avião** no emulador (ou o interruptor **"Simular sem conexão"** no fim da tela, que aparece em builds de desenvolvimento).
2. Aparece o aviso laranja "Sem conexão com a agência. Mostrando o último saldo conhecido".
3. Fazer um **depósito de R$ 25**. Mostrar o saldo virando **"Saldo provisório"** e o cartão **"Aguardando sincronização"** com o depósito **pendente**.
4. Desativar o modo avião: o app sincroniza sozinho e aparece "Sincronizado com a agência".
5. **Conflito:** com o app offline, fazer um depósito pelo app. Antes de reconectar, alterar a mesma conta por outro caminho (frontend web ou `curl`/`Invoke-RestMethod`). Reconectar e mostrar o cartão vermelho **"Conflito de sincronização"** com o **saldo real na agência** e os botões **Reenviar com o saldo atual** e **Descartar**.

**Falar:**
> "Sem conexão, o app continua funcionando: mostra o último saldo conhecido e guarda as operações numa fila local. O saldo vira provisório para a pessoa não achar que o dinheiro já está confirmado."
>
> "Ao reconectar, a fila é enviada sozinha. Mas se a conta mudou enquanto o app estava offline, a agência percebe pelo relógio vetorial e responde com conflito, o erro 409. O app não decide sozinho: ele mostra o saldo real e pergunta à pessoa se quer reenviar ou descartar. Num banco, perder ou duplicar uma operação em silêncio seria pior do que perguntar."

> **Plano B:** se o conflito não sair, mostre `evidencias/sprint3/app-conflito.png`. O conflito é a parte mais sensível de reproduzir, então ensaie.

---

## Cena 5 — Fechamento (2:25 – 2:30)

**Falar:**
> "Resumindo: mensageria e relógio vetorial na Sprint 2; eleição de líder, app mobile e offline-first na Sprint 3. A líder ainda é só informativa, e na Sprint 4 ela vai coordenar transações distribuídas."

---

## Resumo rápido: cena → o que o vídeo prova

| Tempo | Cena | Prova |
|---|---|---|
| 0:15 | Transferência entre agências | Pub/Sub assíncrono e vetor nos logs |
| 0:50 | Painel da líder | Bully e consenso visível no app |
| 1:00 | Ctrl+C na líder | Heartbeat, failover e reeleição automática |
| 1:35 | Modo avião + depósito | Cache local, fila e saldo provisório |
| 2:00 | Reconectar | Sincronização automática |
| 2:10 | Conflito 409 | Relógio vetorial detectando mudança offline |

## Dicas de gravação

- Use o **mesmo tema (claro)** no app durante todo o vídeo para ficar consistente.
- Não corte a espera do failover (3 a 6 s): é o momento "uau". Enquanto espera, fale: "agora o heartbeat vai perceber…".
- Aumente o zoom do terminal, porque os logs são longos e pequenos demais em slide.
- Se o vídeo ficar acima de 2:30, tire o `mesclar_logs.py` (cena 2) e o histórico de líderes (cena 3). São opcionais.
- Grave cada cena separada e junte depois. Assim, se uma falhar, você regrava só ela.
