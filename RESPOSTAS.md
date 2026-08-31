# Respostas - Sprint 1: ICEIBank

## 2.1 Funcionalidade Adicional
- **Funcionalidade Escolhida:** Histórico de Transações por Conta
- **Descrição:** Endpoint `GET /contas/{id}/historico` que lista ordenadamente (pelo Relógio de Lamport) todos os eventos de depósito, saque, transferência débito e transferência crédito associados à conta especificada.
- **Justificativa:** Permite que o usuário consulte seu extrato e acompanhe a ordem lógica de suas transações com clareza no frontend.

---

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

## 10.2 Observações - Passo 3
* **Observação dos eventos empatados:**
  Analisando os logs unificados, encontramos múltiplos eventos empatados com o mesmo timestamp lógico (como `[Lamport 2]`). Por exemplo:
  * `[Lamport 2] (19:15:53) agencia-1 - CRIAR_CONTA (Lucas)`
  * `[Lamport 2] (19:06:33) agencia-0 - DEPOSITO`
  * `[Lamport 2] (19:17:11) agencia-0 - TRANSFERENCIA_DEBITO`
  
  Esses eventos são **concorrentes (independentes)**, pois a criação da conta de Lucas na Agência 1 não influenciou e nem foi influenciada pelo depósito ou transferência ocorridos na Agência 0.
  Comparando com o campo `horaParede`, a ordenação física real não condiz com a ordem listada pelo relógio de Lamport. O depósito ocorreu às `19:06:33` (mais cedo), mas foi listado após a criação de conta (`19:15:53`). Isso comprova que, para eventos concorrentes, o relógio de Lamport gera uma ordenação total arbitrária que pode não refletir o tempo físico real.

---

### 10.3 Perguntas - Parte E (Linha do Tempo Unificada)
1. **O relógio de Lamport garante que, se A aconteceu antes de B causalmente, `timestamp(A) < timestamp(B)`. Ele não garante a volta. O que isso significa na prática quando você vê dois eventos com timestamps diferentes na linha do tempo, mas sem saber se um realmente influenciou o outro?**
   * *Resposta:* Significa que, ao visualizar dois eventos na linha do tempo com `timestamp(A) < timestamp(B)` (como um evento com Lamport 2 e outro com Lamport 3), não podemos afirmar que \(A\) causou ou influenciou \(B\). Eles podem ter ocorrido de forma concorrente e isolada. O relógio de Lamport garante a ordem temporal lógica apenas no sentido direto (causa $\rightarrow$ efeito implica timestamp menor), mas a relação inversa (timestamp menor $\rightarrow$ causa) não é garantida.

2. **Baseado no que você observou no passo 3 da tarefa: o relógio de Lamport, sozinho, seria suficiente para um sistema que precisa distinguir com certeza “A e B são concorrentes” de “A aconteceu antes de B”? Por que isso motiva o relógio vetorial do Sprint 2?**
   * *Resposta:* Não, o relógio de Lamport não é suficiente. Como ele reduz o tempo lógico de todo o sistema a um único número escalar, perdemos a capacidade de rastrear a história causal de forma independente em cada nó. Por causa disso, eventos concorrentes podem receber timestamps menores, maiores ou iguais sem qualquer distinção.
   * Isso motiva o **Relógio Vetorial** no Sprint 2, onde cada processo mantém um vetor com o estado de tempo de todos os nós. Comparando os vetores de dois eventos, podemos identificar de forma inequívoca se há uma dominância de um vetor sobre o outro (relação causal de anterioridade) ou se os vetores são incomparáveis (relação de concorrência).

---

## 11.3 Perguntas - Parte F (Autenticação JWT)

1. **Qual a diferença entre autenticação e autorização? Sua implementação verifica só uma das duas, ou as duas? Por exemplo: um usuário autenticado consegue sacar de uma conta que não é dele, na sua implementação atual?**
   * *Resposta:* A **autenticação** consiste no processo de identificar um usuário (ex.: confirmar que ele de fato é quem diz ser a partir de uma senha ou token). A **autorização** é o processo seguinte que valida se o usuário autenticado de fato possui permissão para executar a ação solicitada sobre aquele recurso específico (ex.: verificar privilégios de acesso).
   * Nossa implementação realiza **ambas as verificações**: primeiro o token JWT é decodificado e validado (autenticação). Em seguida, a função `verificar_autorizacao` valida se o `sub` do token confere com o ID da conta informada na rota (ou se possui a role `"admin"`). Portanto, na nossa implementação atual, um usuário comum autenticado **não consegue** sacar de uma conta que não seja a dele (a API retorna HTTP 403 Forbidden).

2. **Por que o servidor não precisa consultar um banco de dados para validar a assinatura de um JWT a cada requisição? O que isso implica sobre escalabilidade, comparado a guardar sessões em memória no servidor?**
   * *Resposta:* O JWT é assinado digitalmente com uma chave secreta mantida no servidor usando algoritmos de hashing criptográfico. Quando uma requisição chega com o token, o servidor pode verificar se o conteúdo não foi adulterado simplesmente recalculando a assinatura localmente e comparando-a com a assinatura contida no próprio token. Como a validação é puramente local e matemática, não há necessidade de consultas a banco de dados a cada requisição.
   * Isso implica em uma **escalabilidade massivamente superior** se comparada a sessões em memória. Em um sistema com sessões no servidor, os dados das sessões precisam ser mantidos na memória RAM de um nó ou sincronizados/consultados em um cache centralizado (como Redis). Consequentemente, o uso de JWT torna a arquitetura totalmente *stateless* (sem estado), o que permite adicionar novos nós de servidor sem qualquer necessidade de compartilhamento ou sincronização de sessões, pois qualquer nó com acesso à chave secreta pode validar qualquer token de forma 100% autônoma.

3. **O que aconteceria com a segurança do sistema se a chave secreta usada para assinar o JWT vazasse?**
   * *Resposta:* Se a chave secreta vazasse, a segurança do sistema estaria **completamente comprometida**. Um atacante de posse da chave poderia criar e assinar tokens válidos à sua escolha, fingindo ser qualquer usuário (incluindo administrador) com acesso total de criação, débito, saque e alteração de saldo em todas as agências sem restrições. Para reestabelecer a segurança, a chave secreta deveria ser rotacionada imediatamente no ambiente e todas as instâncias do servidor seriam reiniciadas, o que invalidaria instantaneamente todos os tokens antigos em circulação.


---

## 11.4 Justificativas de Design (Parte F)

* **Escolha do Formato de Credenciais de Login:**
  * *Decisão:* Para o administrador, foi utilizado o par de usuário/senha fixos (`"admin"` / `"admin"`). Para os usuários (alunos), optou-se por um modelo baseado no identificador da conta (`idConta`) e no nome do aluno (`nomeAluno`), sem a exigência de uma senha neste estágio.
  * *Justificativa:* Como as contas do ICEIBank são criadas em memória durante a execução do servidor e não possuem campos de senha persistidos na modelagem inicial (definida na Parte C), o par `idConta` + `nomeAluno` funciona como uma credencial inicial perfeitamente adequada para o escopo educacional do laboratório, evitando adicionar a complexidade de gerenciar e persistir hashes de senhas antes da introdução de bancos de dados persistentes.

* **Decisão sobre Token na Chamada entre Agências (`creditar-remoto`):**
  * *Decisão:* Optou-se por **não exigir** o token JWT do usuário final nas chamadas internas do endpoint `/creditar-remoto` executadas entre os servidores das agências.
  * *Justificativa:* A chamada entre agências é uma operação interna de backend (comunicação máquina-a-máquina). A agência de origem do cliente já realizou toda a autenticação do usuário, validou seus saldos e efetuou o débito local antes de disparar o crédito. Exigir o envio e validação do token do usuário na agência de destino introduziria um acoplamento desnecessário (como compartilhar a mesma chave secreta JWT entre nós ou gerenciar assinaturas assimétricas complexas). Portanto, a transação inter-agências é tratada como confiável por pertencer à infraestrutura de backend.
