# Respostas - Sprint 1: ICEIBank


### 6.4 Perguntas - Parte B (Relógio de Lamport e Eventos)
1. **Por que o relógio de Lamport usa `max(contador_local, timestampRecebido) + 1` ao receber uma mensagem, em vez de simplesmente adotar o timestamp recebido diretamente?**
    * *Resposta:* O relógio de Lamport serve para garantir a propriedade da ordem causal parcial: se o evento de envio \(A\) causou o evento de recepção \(B\), então o timestamp de \(A\) deve ser estritamente menor que o de \(B\). Para assegurar essa relação causal (\(timestamp(A) < timestamp(B)\)), o receptor da mensagem de timestamp \(t\) deve ajustar seu relógio interno para um valor que seja estritamente maior do que o recebido e do que o seu próprio relógio atual. Portanto, usamos \(\max(contador\_local, t) + 1\). Se apenas adotássemos o timestamp recebido \(t\), o evento de recepção teria o mesmo timestamp que o envio, violando a ordenação estrita. Se o receptor adotasse \(t\) diretamente mesmo quando \(contador\_local > t\), o relógio local andaria "para trás", o que é impossível em eventos sequenciais locais.

2. **Se a Agência 0 está no evento de contador 10 e recebe uma mensagem com timestamp 3 (de uma agência mais “atrasada”), qual o novo valor do contador da Agência 0? O que isso implica sobre agências que processam muitos eventos rapidamente versus agências mais lentas?**

    * *Resposta:* O novo valor do contador da Agência 0 será \(\max(10, 3) + 1 = 11\). Isso implica que processos rápidos (com alto volume de eventos) não sofrem grandes perturbações nem têm seus relógios inflados desnecessariamente ao interagir com processos mais lentos. Por outro lado, as agências mais lentas (com contadores lógicos baixos), ao receberem mensagens de agências rápidas, darão grandes "saltos" adiante em seus contadores. Isso assegura que a consistência lógica causal seja reestabelecida globalmente a partir da agência mais ativa.

---

## 8.3 Perguntas - Parte D (Transferências e Limitações)
1. **No trecho `agenciaDestino === idAgencia`, por que a transferência local não precisa da lógica de `aoEnviar()`/`aoReceber()` do relógio de Lamport, enquanto a transferência entre agências precisa?**
   * *Resposta:* A transferência local ocorre inteiramente no contexto de um único processo e de uma única agência. Sendo executada localmente, o processo pode simplesmente incrementar sequencialmente seu próprio relógio (como eventos locais) para o débito e o crédito, mantendo a consistência do tempo lógico interno. Por outro lado, a transferência entre agências exige a comunicação entre dois processos distribuídos e independentes, cada um com seu próprio relógio lógico local. Segundo o algoritmo de Lamport, a passagem de mensagens físicas deve ser registrada como uma relação causal global: o ato de enviar é um evento local que deve ter seu timestamp anexado à mensagem (`aoEnviar()`), e o ato de receber é uma sincronização de relógio (`aoReceber()`) que ajusta o tempo lógico do receptor para garantir que o evento de recepção seja registrado causalmente após o evento de envio.

2. **Reproduza a falha conhecida (tarefa 5) e observe o saldo da conta de origem depois do erro. Ele foi revertido? O que isso significa em termos de consistência do sistema bancário?**
   * *Resposta:* O saldo da conta de origem **não foi revertido**. O valor foi debitado localmente e o dinheiro "desapareceu" do sistema, pois a agência de destino estava offline e não pôde aplicar o crédito. Em termos de consistência do sistema bancário, isso representa uma grave violação dos princípios **ACID**, especificamente a **Atomicidade** (onde uma transação deve ser executada por completo ou não ser executada sob hipótese alguma) e a **Consistência** (o saldo total global deveria permanecer conservado, mas diminuiu).

3. **Pensando à frente para o Sprint 4: cite, em alto nível, duas formas possíveis de corrigir esse problema (não precisa implementar agora, só descrever a ideia).**
   * *Resposta:* Duas soluções comuns para garantir consistência em transações distribuídas são:
     * **Protocolo de Commit de Duas Fases (2PC - Two-Phase Commit):** Um coordenador centralizado envia uma requisição de preparação ("prepare") para todas as agências envolvidas. Se a agência de origem puder debitar e a agência de destino puder creditar (e estiver ativa), ambas respondem com um voto positivo. Se todas concordarem, o coordenador envia a confirmação final ("commit") para efetivar os saldos. Se qualquer uma falhar ou não responder, toda a transação é cancelada ("abort").
     * **Padrão Saga (Saga Pattern):** Uma série de transações locais sequenciais. A agência de origem debita o dinheiro e faz a chamada de crédito na de destino. Caso a chamada falhe (por tempo limite de rede ou por queda da outra agência), um mecanismo de compensação é disparado de volta para a agência de origem. Esse mecanismo executa uma transação compensatória de estorno (crédito corretivo), restabelecendo o saldo original e garantindo consistência eventual.

---
