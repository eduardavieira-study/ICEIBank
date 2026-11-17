# ICEIBank — Apresentação das Sprints 2 e 3 (5 minutos)

> **Apresentação pronta:** [apresentacao-sprints-2-3.html](apresentacao-sprints-2-3.html). Abra no Chrome.
> **Teclas:** `←` `→` trocam de slide · `N` mostra o roteiro (fala) do slide · `F` tela cheia · `T` zera o cronômetro · clique em um print para ampliar.
> O cronômetro no canto inferior esquerdo começa quando você sai da capa e mostra o tempo até 5:00.

**Identidade visual:** roxo `#6D28D9`, rosa `#EC4899`, fontes **Sora** (títulos) e **Inter** (texto), ícones Lucide, o mesmo design system do site e do app. As fontes ficam embutidas em `app_mobile/assets/fonts`, então funciona sem internet.

**Autora:** Eduarda Vieira Gonçalves · Disciplina: Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas.

---

## Resumo em uma frase

O ICEIBank é um banco distribuído de 3 agências independentes. Na **Sprint 2** ganhou **mensageria assíncrona (RabbitMQ) e relógio vetorial**. Na **Sprint 3** ganhou **eleição de líder (Bully), app Flutter e modo offline-first**.

## Animações (uma por slide, nos momentos que importam)

| Slide | Animação | O que ela mostra |
|---|---|---|
| 1 | Cartão 3D que sobe o saldo, vira e mostra o verso | É o cartão do app; clique nele para virar |
| 2 | Linha do tempo que se desenha até a Sprint 3 | Onde o projeto está |
| 3 | Mensagem viaja, fica retida na fila e é entregue | Pub/Sub e resiliência |
| 5 | Comparação de vetores posição a posição | Causal x concorrente |
| 6 | Coroa pulando 0 → 1 → 2, líder cai e a coroa vai para a 1 | Bully e failover |
| 8 | Celulares aparecendo em sequência com setas | Offline, sincroniza, conflito |

---

## Roteiro slide a slide

### Slide 1 · Capa (0:00–0:15)
- Cartão do app girando, com os selos RabbitMQ, Bully, Flutter e Offline-first.
- **Fala:** "Oi, eu sou a Eduarda. O ICEIBank é um banco distribuído com três agências independentes. Vou mostrar o que evoluiu nas sprints 2 e 3: mensageria, relógio vetorial, eleição de líder e um app que funciona offline."

### Slide 2 · Onde estamos (0:15–0:35)
- Linha do tempo: Sprint 1 (Web + Lamport), **2 (Pub/Sub + vetorial)**, **3 (Mobile + Bully)**, 4 (Nuvem + 2PC).
- Base herdada: 3 agências, conta na agência `id_conta % 3`.
- **Fala:** "São quatro sprints, cada uma ligada a um conceito de sistemas distribuídos. A base vem da primeira: contas divididas em três agências. A 2 trouxe comunicação indireta, e a 3 trouxe consenso e mobile."

### Slide 3 · Sprint 2: Pub/Sub (0:35–1:15)
- Antes: REST direto. Se o destino estava fora do ar, a chamada falhava e o débito ficava pendurado.
- Agora: a origem **publica** no RabbitMQ e o destino **consome quando puder**.
- Animação: mensagem sai da Agência 0 → Agência 1 cai → mensagem fica na fila → Agência 1 volta e credita.
- Detalhes: exchange `topic`, fila `durable`, mensagem `persistent`, routing key `agencia.X.creditar`.
- Botão "Ver evidência": `evidencias/sprint2/transferencia-assincrona.png`.
- **Fala:** "Na sprint 1 a transferência era REST direto: se a agência de destino estava fora do ar, a chamada falhava e o débito ficava pendurado. Troquei por Pub/Sub. A origem publica o evento e segue a vida, e o destino consome quando puder. Olhem a animação: a agência 1 cai, a mensagem fica retida na fila, e quando ela volta o crédito chega."

### Slide 4 · Sprint 2: resiliência (1:15–1:45)
- **Deu certo:** derrubei a Agência 1, a API respondeu "mensagem publicada" e a mensagem ficou retida.
- **Falta:** contas só em memória (a conta sumiu no restart, log `CREDITO_REMOTO_FALHOU`), sem estorno e sem deduplicação.
- **Extra da sprint:** alerta de saldo baixo (< R$ 50) em fila própria `fila-alertas-<id>`, *best-effort*.
- Botão: `evidencias/sprint2/resiliencia-fila.png`.
- **Fala:** "A mensagem não se perde, mas não perder a mensagem não é o mesmo que o sistema estar correto. Com a agência reiniciada, a conta não existia mais e o log registrou CREDITO_REMOTO_FALHOU. Isso vira o gancho para a sprint 4. Como funcionalidade extra, fiz um alerta de saldo baixo em fila própria."

### Slide 5 · Sprint 2: relógio vetorial (1:45–2:35)
- Lamport = 1 número. Vetor = **1 posição por agência**, comparado posição a posição.
- `[3,1,0]` × `[3,2,0]` → **causal**. `[3,1,0]` × `[1,3,0]` → **concorrentes**.
- Exemplo real: `CRIAR_CONTA` Fernanda `[7,0,0]` × Gustavo `[6,4,0]`.
- Botão: `evidencias/sprint2/linha-do-tempo-causal.png` (script `mesclar_logs.py`).
- **Fala:** "Troquei o relógio de Lamport, que é um número só, por um vetor com uma posição por agência. Com Lamport, dois timestamps diferentes não provam causalidade. Com o vetor eu comparo posição a posição: se todas são menores ou iguais e uma é menor, um aconteceu antes do outro. Se uma sobe e outra desce, são concorrentes. No meu teste, duas contas criadas de forma independente aparecem como concorrentes."

### Slide 6 · Sprint 3: Bully (2:35–3:25)
- Vence o **maior ID entre as ativas**. Mensagens `/bully/eleicao` e `/bully/coordenador`.
- Heartbeat de 3 s: líder não responde → `LIDER_NAO_RESPONDEU` → nova eleição.
- Animação: coroa passa 0 → 1 → 2 (convergem na 2), a 2 cai (Ctrl+C), a coroa vai para a 1.
- Botão: `evidencias/sprint3/failover.png`.
- **Fala:** "Na sprint 3, as agências elegem uma líder com o algoritmo de Bully: vence o maior ID entre as ativas. Na subida, várias se declaram líder em sequência, zero, um, dois, e convergem na 2. Isso é esperado. Cada agência faz heartbeat a cada 3 segundos. Derrubei a líder com Ctrl+C, o heartbeat falhou e a reeleição foi automática: a agência 1 virou líder."

### Slide 7 · Sprint 3: app Flutter (3:25–4:05)
- Mesma API REST da web: login (aluno e admin), saldo, depósito, saque e transferência.
- **Painel da líder** (extra da sprint): a cada 3 s, 3 agências em paralelo, timeout de 2 s.
- Design system próprio: roxo e rosa, Sora + Inter, ícones Lucide, tema claro e escuro.
- Prints: `app-lider-atual.png` (antes) e `app-failover.png` (depois).
- **Fala:** "O primeiro cliente mobile é um app Flutter que reaproveita a mesma API REST da web. Como funcionalidade adicional, o painel da líder atualiza a cada 3 segundos. Quando a líder cai, o cartão dela fica vermelho e a coroa passa sozinha para a nova líder."

### Slide 8 · Sprint 3: offline-first (4:05–4:45)
- 1 **Offline:** último saldo conhecido, saldo provisório e operação na fila de pendentes.
- 2 **Reconectou:** sincroniza sozinho (`POST /contas/{id}/sincronizar`).
- 3 **Conflito (409):** o `vetorConhecido` está desatualizado; o app pergunta "Reenviar com o saldo atual" ou "Descartar".
- Prints: `app-offline.png`, `app-sincronizacao.png`, `app-conflito.png`.
- **Fala:** "Sem conexão, o app mostra o último saldo conhecido e aceita operações, que entram numa fila. O saldo vira provisório. Ao reconectar, ele sincroniza sozinho. O vetor da sprint 2 foi reaproveitado: o app envia o vetor que conhece e, se a agência avançou, ela devolve 409. Aí o app pergunta à pessoa. Nada é perdido nem aplicado em silêncio."

### Slide 9 · Próximos passos e demonstração (4:45–5:00, depois o vídeo)
- A líder ainda é só informativa. Na **Sprint 4** ela coordena transações distribuídas (2PC/Saga).
- Em aberto: persistência e estorno, vetor por conta (falsos conflitos).
- Selo final com botão de play: **"Agora, a demonstração: vídeo da aplicação funcionando, passo a passo"**. Dê o play no vídeo e explique ao vivo enquanto ele roda.
- **Fala:** "A líder ainda é só informativa. Na sprint 4 ela vai coordenar transações distribuídas. A sprint 4 também ataca o que ficou em aberto: persistência, estorno e os falsos conflitos, porque o vetor é por agência e não por conta. O código, as evidências e as respostas estão no repositório. Agora vou mostrar um vídeo da aplicação funcionando, e vou explicando passo a passo enquanto ele roda."

---

## Números e fatos para citar

- **3 agências**, portas `4074`, `4075`, `4076`; conta pertence à agência `id % 3`.
- **Backend:** Python, FastAPI, RabbitMQ (CloudAMQP). **Web:** React + Vite. **Mobile:** Flutter 3 / Dart.
- **Serviços novos:** `mensageria.py`, `vector_clock.py`, `comparar_vetores.py`, `bully_service.py`.
- **App:** 3 telas (login, home, admin), 16 arquivos de teste (`flutter test`).
- **Heartbeat e painel do app:** 3 s. **Timeout** da eleição e do heartbeat: 1 s. **Alerta de saldo baixo:** R$ 50.
- **Uso de IA (transparência):** Sprints 1 e 2 com Antigravity; Sprint 3 com Claude Code, com código revisado e testado pela autora.

## Possíveis perguntas da banca

- **Por que o Bully elege o maior ID?** É convenção. O algoritmo só exige uma ordem total entre os processos.
- **Mais de uma agência se declarou líder na subida. É bug?** Não. Cada uma conclui corretamente que é a maior ativa no momento e converge quando a de ID maior sobe.
- **Por que vetor e não só comparar saldo?** O saldo pode voltar ao mesmo valor por caminhos diferentes. O vetor mostra se houve eventos que o app nunca viu.
- **Por que todo avanço do vetor vira conflito?** O vetor é por agência, não por conta. Uma eleição do Bully também o avança, gerando falsos conflitos. Seria preciso um vetor por conta.
- **Por que `shared_preferences` e não SQLite?** Os dados são poucos e sempre lidos inteiros por chave. Não havia consultas nem relações que justificassem um banco.
- **Por que o app pergunta ao usuário no conflito?** Descartar perde uma ação intencional, e reenviar sozinho pode aplicar uma operação feita sobre um saldo que já não é real.
- **Problema de segurança?** Quem tem a `RABBITMQ_URL` publica crédito, e `/bully/eleicao` e `/bully/coordenador` não têm autenticação. O risco é baixo hoje porque a líder é só informativa.
