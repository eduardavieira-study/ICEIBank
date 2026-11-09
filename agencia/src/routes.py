from fastapi import APIRouter, Request
from pydantic import BaseModel
import agencia.src.controllers.contas_controller as contas_controller
import agencia.src.controllers.transferencias_controller as transferencias_controller

router = APIRouter()


class EleicaoRequest(BaseModel):
    origemId: int
    vetorEnvio: list[int]


class CoordenadorRequest(BaseModel):
    liderId: int
    vetorEnvio: list[int]


# Rotas do algoritmo de Bully (eleição de líder entre as agências).
# Sem autenticação: são mensagens internas entre agências (ver RESPOSTAS.md).
@router.post("/bully/eleicao")
def bully_eleicao(request: Request, body: EleicaoRequest):
    request.app.state.bully.receber_eleicao(body.origemId, body.vetorEnvio)
    return {"ok": True}


@router.post("/bully/coordenador")
def bully_coordenador(request: Request, body: CoordenadorRequest):
    request.app.state.bully.receber_coordenador(body.liderId, body.vetorEnvio)
    return {"ok": True}


@router.get("/bully/lider")
def bully_lider(request: Request):
    return {
        "idAgencia": request.app.state.id_agencia,
        "liderAtual": request.app.state.bully.obter_lider_atual(),
    }



# Rotas de contas
router.post("/auth/login")(contas_controller.login)
router.post("/contas", status_code=201)(contas_controller.criar_conta)
router.get("/contas/{id}")(contas_controller.consultar_saldo)
router.post("/contas/{id}/depositar")(contas_controller.depositar)
router.post("/contas/{id}/sacar")(contas_controller.sacar)
router.get("/contas/{id}/historico")(contas_controller.consultar_historico)
# Sincronização de operações feitas offline (detecta conflito via relógio vetorial)
router.post("/contas/{id}/sincronizar")(contas_controller.sincronizar_operacao_pendente)

# Rotas de transferências
# A rota /contas/{id}/creditar-remoto do Sprint 1 deixou de existir - o crédito
# remoto agora chega via mensageria (RabbitMQ), não mais por chamada REST.
router.post("/transferencias")(transferencias_controller.transferir)
