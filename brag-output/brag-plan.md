# Plano: ICEIBank, Sprints 2 e 3

**O que é:** banco distribuído de 3 agências independentes (conta na agência `id % 3`), com API FastAPI, site React e app Flutter.
**Para quem:** a turma e a banca de Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas. O vídeo apoia a apresentação falada.
**Duração:** 76 s (a skill sugere ~20 s, mas aqui são 5 entregas; combinado com a autora). Formato 1920×1080, 30 fps.
**Tom:** `polished` com energia de `app-store`: cartões limpos, cortes na batida, sem piada forçada.
**Idioma:** português do Brasil.

## Ângulo
"Três agências que não se conhecem, e mesmo assim se entendem." Cada cena responde a uma pergunta de sistemas distribuídos e mostra a coisa de verdade: mensagens na fila, vetores comparados posição a posição, coroa mudando de líder, o app do celular offline.

## Identidade visual (copiada do design system do projeto)
- Roxo `#6D28D9`, rosa `#EC4899`, verde-água `#22B2A3`, fundo roxo muito escuro.
- Fontes Sora (títulos) e Inter (texto), as mesmas de `app_mobile/assets/fonts`.
- Telas reais do app (prints de `evidencias/sprint3`). Os terminais foram refeitos com as linhas reais de log, sem caminhos de pastas nem nome de usuário do computador.
- Os nomes que aparecem nos prints do app (ex.: Helena) são contas de teste fictícias.

## Música
120 bpm (1 compasso = 2 s, 38 compassos), Lá menor: Am – F – C – G. Kick, hat, bass, pad e pluck na mesma grade. Efeitos suaves em notas da mesma escala, sempre sobre a batida.

## Storyboard (todo corte cai no início de um compasso)

| # | Tempo | Cena | Conteúdo | Texto principal |
|---|---|---|---|---|
| 1 | 0–4 s | Gancho | Logo, cartão do app girando com o saldo subindo, 3 agências ligadas | "Um banco com 3 agências independentes." |
| 2 | 4–16 s | Sprint 2 · RabbitMQ | A0 publica, a A1 cai, a mensagem espera na fila, A1 volta e credita | "Transferência sem esperar o destino" |
| 3 | 16–28 s | Sprint 2 · Relógio vetorial | Comparação posição a posição: causal `[5,0,0]` → `[6,3,0]`; concorrente `[7,0,0]` × `[6,4,0]` | "Quem veio antes de quem?" |
| 4 | 28–40 s | Sprint 3 · Bully | Coroa 0→1→2, heartbeat, a 2 cai, a 1 assume | "Quem manda? O maior ID ativo." |
| 5 | 40–50 s | Sprint 3 · App Flutter | Telas reais, painel da líder | "O banco no bolso" |
| 6 | 50–64 s | Sprint 3 · Offline-first | Offline → sincroniza → conflito 409 | "Sem internet, o app continua" |
| 7 | 64–70 s | Extras | Alerta de saldo baixo, painel da líder, histórico de lideranças, testes | "Também entregue" |
| 8 | 70–76 s | Fechamento | Próximo: Sprint 4 (2PC/Saga) e o que ficou em aberto | "A líder passa a coordenar transações" |

## Fatos usados (todos do código ou do roteiro da autora)
Exchange `topic`, fila `durable`, mensagem `persistent`, routing key `agencia.X.creditar`; vetor por agência; heartbeat de 3 s; eventos `LIDER_NAO_RESPONDEU`, `ELEICAO_INICIADA`, `TORNOU_LIDER`, `LIDER_ANUNCIADO`; sincronização em `POST /contas/{id}/sincronizar` com resposta 409 em conflito; alerta de saldo baixo abaixo de R$ 50.
