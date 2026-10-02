from fastapi import APIRouter
import agencia.src.controllers.contas_controller as contas_controller
import agencia.src.controllers.transferencias_controller as transferencias_controller

router = APIRouter()

# Rotas de contas
router.post("/auth/login")(contas_controller.login)
router.post("/contas", status_code=201)(contas_controller.criar_conta)
router.get("/contas/{id}")(contas_controller.consultar_saldo)
router.post("/contas/{id}/depositar")(contas_controller.depositar)
router.post("/contas/{id}/sacar")(contas_controller.sacar)
router.get("/contas/{id}/historico")(contas_controller.consultar_historico)

# Rotas de transferências
# A rota /contas/{id}/creditar-remoto do Sprint 1 deixou de existir - o crédito
# remoto agora chega via mensageria (RabbitMQ), não mais por chamada REST.
router.post("/transferencias")(transferencias_controller.transferir)
