# Respostas - Sprint 1: ICEIBank


### 6.4 Perguntas - Parte B (Relógio de Lamport e Eventos)
1. **Por que o relógio de Lamport usa `max(contador_local, timestampRecebido) + 1` ao receber uma mensagem, em vez de simplesmente adotar o timestamp recebido diretamente?**
    * *Resposta:* O relógio de Lamport serve para garantir a propriedade da ordem causal parcial: se o evento de envio \(A\) causou o evento de recepção \(B\), então o timestamp de \(A\) deve ser estritamente menor que o de \(B\). Para assegurar essa relação causal (\(timestamp(A) < timestamp(B)\)), o receptor da mensagem de timestamp \(t\) deve ajustar seu relógio interno para um valor que seja estritamente maior do que o recebido e do que o seu próprio relógio atual. Portanto, usamos \(\max(contador\_local, t) + 1\). Se apenas adotássemos o timestamp recebido \(t\), o evento de recepção teria o mesmo timestamp que o envio, violando a ordenação estrita. Se o receptor adotasse \(t\) diretamente mesmo quando \(contador\_local > t\), o relógio local andaria "para trás", o que é impossível em eventos sequenciais locais.

2. **Se a Agência 0 está no evento de contador 10 e recebe uma mensagem com timestamp 3 (de uma agência mais “atrasada”), qual o novo valor do contador da Agência 0? O que isso implica sobre agências que processam muitos eventos rapidamente versus agências mais lentas?**

    * *Resposta:* O novo valor do contador da Agência 0 será \(\max(10, 3) + 1 = 11\). Isso implica que processos rápidos (com alto volume de eventos) não sofrem grandes perturbações nem têm seus relógios inflados desnecessariamente ao interagir com processos mais lentos. Por outro lado, as agências mais lentas (com contadores lógicos baixos), ao receberem mensagens de agências rápidas, darão grandes "saltos" adiante em seus contadores. Isso assegura que a consistência lógica causal seja reestabelecida globalmente a partir da agência mais ativa.

---