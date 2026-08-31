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
## 📁 Estrutura de Pastas do Projeto

Abaixo está o esqueleto de diretórios e arquivos que estruturam o projeto:

```text
ICEIBank/
├── agencia/                     # Backend Python (FastAPI)
│   ├── data/                    # Logs de eventos gerados em runtime (ignorado pelo git)
│   ├── src/
│   │   ├── controllers/
│   │   │   ├── contas_controller.py
│   │   │   └── transferencias_controller.py
│   │   ├── services/
│   │   │   ├── auth.py          # Criptografia, geração e validação de tokens JWT
│   │   │   ├── event_log.py     # Sistema de log de eventos locais da agência
│   │   │   └── lamport_clock.py  # Relógio lógico de Lamport para tempo parcial
│   │   ├── config.py            # Configurações de portas e roteamento de agências
│   │   ├── main.py              # Arquivo principal de execução do backend
│   │   └── routes.py            # Definição e registro das rotas da API
│   ├── GUIA.md                  # Instruções de execução do backend em Python
│   ├── mesclar_logs.py          # Script para mesclar logs em uma linha do tempo unificada
│   └── requirements.txt         # Dependências de bibliotecas Python
├── agencia-express/             # Backend de referência em Node.js (material de consulta)
├── evidencias/
│   └── sprint1/                 # Capturas de tela provando funcionamento do sistema
├── frontend/                    # Frontend Web (React + Vite)
│   ├── src/
│   │   ├── components/          # Componentes React modulares e reutilizáveis
│   │   │   ├── AdminPanel.jsx
│   │   │   ├── AgencySelector.jsx
│   │   │   ├── Footer.jsx
│   │   │   ├── Header.jsx
│   │   │   ├── LoginForm.jsx
│   │   │   ├── StudentPanel.jsx
│   │   │   └── ToastContainer.jsx
│   │   ├── App.jsx              # Estado global, roteamento interno e chamadas à API
│   │   ├── index.css            # Estilização global e injeção do Tailwind CSS
│   │   └── main.jsx             # Ponto de entrada do React
│   ├── index.html               # Ponto de entrada HTML com fontes Nunito e Poppins
│   ├── package.json             # Scripts de build e dependências npm do frontend
│   └── tailwind.config.js       # Configurações de tema e fontes do Tailwind
├── LICENSE
├── README.md
├── RESPOSTAS.md                 # Questionário do roteiro e descrição de funcionalidade extra
└── Roteiro_ICEIBank.md
```

---

## 🛠️ Tecnologias Utilizadas

### Backend
* **Linguagem:** Python 3.12+
* **Framework:** FastAPI (Criação de rotas assíncronas e injeção de dependências)
* **Servidor ASGI:** Uvicorn
* **Autenticação:** PyJWT (Criptografia simétrica com algoritmo `HS256`)
* **Cliente HTTP:** Requests (Comunicação inter-agências)
* **Validação de Dados:** Pydantic

### Frontend
* **Biblioteca:** React 18+ (Arquitetura orientada a componentes modulares)
* **Ferramenta de Build:** Vite
* **Estilização:** Tailwind CSS & PostCSS
* **Ícones:** Lucide React

---

## 🤖 Uso de Inteligência Artificial

Este projeto foi desenvolvido em modelo de *pair programming* (programação em par) em colaboração com o **Antigravity**, uma inteligência artificial do time Google DeepMind. A IA colaborou ativamente na tradução dos conceitos de controle e rotas do Express para FastAPI, na modularização estrutural e responsividade do frontend em React e na escrita da documentação do repositório.

---

## 👥 Autoria

| 👤 Nome                  | 🖼️ Foto | :octocat: GitHub | 💼 LinkedIn | 📤 Gmail |
| :--- | :---: | :---: | :---: | :---: |
| **Eduarda Vieira Gonçalves** | <div align="center"><img src="https://avatars.githubusercontent.com/u/159597766?v=4" width="70px" height="70px" style="object-fit: cover; border-radius: 50%;"></div> | <div align="center"><a href="https://github.com/eduardavieira-dev" target="_blank"><img src="https://arturbomtempo-dev.github.io/arturbomtempo-cdn/assets/icons/github.png" width="40px" height="40px"></a></div> | <div align="center"><a href="https://www.linkedin.com/in/eduarda-vieira-gon%C3%A7alves-01a584297/" target="_blank"><img src="https://arturbomtempo-dev.github.io/arturbomtempo-cdn/assets/icons/linkedin.png" width="40px" height="40px"></a></div> | <div align="center"><a href="mailto:eduarda.vieira.goncalves7@gmail.com"><img src="https://arturbomtempo-dev.github.io/arturbomtempo-cdn/assets/icons/gmail.png" width="40px" height="40px" ></a></div> |

---

## 📄 Licença
Este projeto está sob a licença MIT - consulte o arquivo [LICENSE](LICENSE) para mais detalhes.