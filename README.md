# ICEI Bank
O ICEIBank é o primeiro de quatro sprints de um sistema bancário distribuído, criado para aplicar na prática conceitos de Sistemas Distribuídos e Desenvolvimento Web. O objetivo desta etapa é construir o backend de agências bancárias independentes e um frontend funcional, garantindo a consistência e o rastreamento das transações.

**Principais Características e Requisitos**

* **Arquitetura e Particionamento:** O sistema opera com três agências independentes (partições). Cada conta pertence exclusivamente a uma agência, determinada pelo cálculo `id_conta % 3`.
* **Relógio Lógico de Lamport:** Toda operação (criação de conta, depósito, saque, transferência) recebe um carimbo de tempo (*timestamp*) baseado no algoritmo de Lamport, permitindo ordenar de forma lógica os eventos descentralizados do sistema.
* **Operações REST e Autenticação:** A API deve suportar um CRUD de contas e transferências locais e remotas (via chamadas diretas entre agências). Todas as rotas de operação exigem autenticação via token JWT.
* **Frontend:** Uma interface web funcional que consuma a API, gerencie o login, realize transferências e exiba erros de forma clara para o usuário.
* **Observabilidade e Falhas:** Existe uma limitação intencional neste sprint: se a agência de destino falhar no meio de uma transferência, o débito da origem não é revertido. Todos os eventos geram logs locais que podem ser mesclados em uma linha do tempo unificada.
* **Funcionalidade Adicional:** É obrigatório criar ao menos um recurso extra de autoria própria (ex: limite de saque, histórico de transações).
--- 
## Estrutura de Pastas do Projeto

* **`agencia/`**: O código do backend desenvolvido em Python com FastAPI. Aqui ficam as configurações de rotas, os *controllers* (operações bancárias) e os serviços (implementação do Relógio de Lamport e registro de eventos).
* **`agencia-express/`**: O código de exemplo em Node.js e Express deixado pelo professor, servindo estritamente como material de consulta e referência estrutural.
* **`frontend/`**: Onde reside o código da interface web, ideal para ser estruturado com frameworks modernos como React ou Next.js.
* **`evidencias/sprint1/`**: Diretório para armazenar as capturas de tela (prints) que comprovam o funcionamento das transferências, falhas propositais, login JWT e telas do frontend.
* **`RESPOSTAS.md`**: Arquivo para responder aos questionamentos teóricos do roteiro e documentar a sua funcionalidade adicional.
* **`data/`** (dentro do backend): Pasta ignorada pelo versionamento (`.gitignore`), destinada a guardar os arquivos de log `.jsonl` gerados dinamicamente durante a execução.


## 👥 Autoria

| 👤 Nome                  | 🖼️ Foto | :octocat: GitHub | 💼 LinkedIn | 📤 Gmail |
| :--- | :---: | :---: | :---: | :---: |
| **Eduarda Vieira Gonçalves** | <div align="center"><img src="https://avatars.githubusercontent.com/u/159597766?v=4" width="70px" height="70px" style="object-fit: cover; border-radius: 50%;"></div> | <div align="center"><a href="https://github.com/eduardavieira-dev" target="_blank"><img src="https://arturbomtempo-dev.github.io/arturbomtempo-cdn/assets/icons/github.png" width="40px" height="40px"></a></div> | <div align="center"><a href="https://www.linkedin.com/in/eduarda-vieira-gon%C3%A7alves-01a584297/" target="_blank"><img src="https://arturbomtempo-dev.github.io/arturbomtempo-cdn/assets/icons/linkedin.png" width="40px" height="40px"></a></div> | <div align="center"><a href="mailto:eduarda.vieira.goncalves7@gmail.com"><img src="https://arturbomtempo-dev.github.io/arturbomtempo-cdn/assets/icons/gmail.png" width="40px" height="40px" ></a></div> |

---

## 📄 Licença
Este projeto está sob a licença MIT - consulte o arquivo [LICENSE](LICENSE) para mais detalhes.