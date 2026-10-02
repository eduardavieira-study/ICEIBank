import os
import sys
import uvicorn
from dotenv import load_dotenv

# Carrega o .env da raiz do repositório antes de qualquer módulo ler
# RABBITMQ_URL (ex.: mensageria.py, importado logo abaixo).
load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from urllib.parse import urlparse

import agencia.src.config as config
from agencia.src.services.vector_clock import RelogioVetorial
from agencia.src.services.event_log import RegistroEventos
from agencia.src.services import mensageria
from agencia.src.controllers.transferencias_controller import processar_credito_remoto
from agencia.src.routes import router

id_agencia = int(os.environ.get("AGENCIA_ID", "0"))
agencia_config = next((a for a in config.AGENCIAS if a["id"] == id_agencia), None)

if not agencia_config:
    print(f"Agência {id_agencia} não configurada em config.py")
    sys.exit(1)

app = FastAPI(title=f"ICEIBank - Agência {id_agencia}")

# Adicionando CORS middleware para o frontend poder acessar o backend de portas diferentes
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Inicializando estado global da agência
app.state.id_agencia = id_agencia
app.state.relogio = RelogioVetorial(id_agencia, config.NUMERO_AGENCIAS)
app.state.registro = RegistroEventos(f"agencia-{id_agencia}")
app.state.contas = {}
# Hashes das senhas ficam separados das contas para nunca serem retornados nas respostas
app.state.senhas = {}

app.include_router(router)


# Consumidor: processa créditos vindos de outras agências via RabbitMQ.
# Roda em uma thread separada para não bloquear o servidor HTTP (uvicorn).
@app.on_event("startup")
def iniciar_consumidor_mensageria():
    def ao_receber_mensagem(mensagem: dict):
        processar_credito_remoto(app.state, mensagem)

    mensageria.iniciar_consumidor_em_thread(id_agencia, ao_receber_mensagem)

# Extrai a porta da URL da agência configurada
parsed_url = urlparse(agencia_config["url"])
porta = parsed_url.port

if __name__ == "__main__":
    print(f"[Agência {id_agencia}] ouvindo na porta {porta}")
    uvicorn.run("agencia.src.main:app", host="0.0.0.0", port=porta, reload=False)
