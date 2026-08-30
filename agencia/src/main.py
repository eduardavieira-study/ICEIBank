import os
import sys
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from urllib.parse import urlparse

import agencia.src.config as config
from agencia.src.services.lamport_clock import RelogioLamport
from agencia.src.services.event_log import RegistroEventos
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
app.state.relogio = RelogioLamport()
app.state.registro = RegistroEventos(f"agencia-{id_agencia}")
app.state.contas = {}

app.include_router(router)

# Extrai a porta da URL da agência configurada
parsed_url = urlparse(agencia_config["url"])
porta = parsed_url.port

if __name__ == "__main__":
    print(f"[Agência {id_agencia}] ouvindo na porta {porta}")
    uvicorn.run("agencia.src.main:app", host="0.0.0.0", port=porta, reload=False)
