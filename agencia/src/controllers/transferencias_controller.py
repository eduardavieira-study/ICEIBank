from fastapi import Request, HTTPException, status, Depends
from pydantic import BaseModel
import requests
import agencia.src.config as config
from agencia.src.services.auth import validar_token, verificar_autorizacao


class TransferenciaRequest(BaseModel):
    idOrigem: int
    idDestino: int
    valor: float


class CreditoRemotoRequest(BaseModel):
    valor: float
    timestampLamport: int
    origemAgencia: int


def transferir(
    request: Request, body: TransferenciaRequest, payload: dict = Depends(validar_token)
):
    # Autorização: Apenas o dono da conta de origem (ou admin) pode transferir
    if not verificar_autorizacao(payload, body.idOrigem):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Você não tem permissão para realizar transferências a partir desta conta.",
        )

    id_origem = body.idOrigem
    id_destino = body.idDestino
    valor = body.valor

    contas = request.app.state.contas
    id_agencia = request.app.state.id_agencia
    relogio = request.app.state.relogio
    registro = request.app.state.registro

    conta_origem = contas.get(id_origem)
    if not conta_origem:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conta de origem não encontrada nesta agência.",
        )

    if conta_origem["saldo"] < valor:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Saldo insuficiente."
        )

    if valor <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="O valor da transferência deve ser maior que zero.",
        )

    agencia_destino = config.agencia_responsavel(id_destino)

    # O débito é sempre local, pois esta agência é a dona da conta de origem
    ts_debito = relogio.evento_local()
    conta_origem["saldo"] -= valor
    registro.registrar(
        "TRANSFERENCIA_DEBITO",
        ts_debito,
        {"idOrigem": id_origem, "idDestino": id_destino, "valor": valor},
    )

    if agencia_destino == id_agencia:
        # Caso simples: mesma agência, credita direto
        conta_destino = contas.get(id_destino)
        if not conta_destino:
            # Reverte o débito em caso de destino não existir
            conta_origem["saldo"] += valor
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Conta de destino não encontrada.",
            )
        ts_credito = relogio.evento_local()
        conta_destino["saldo"] += valor
        registro.registrar(
            "TRANSFERENCIA_CREDITO",
            ts_credito,
            {"idOrigem": id_origem, "idDestino": id_destino, "valor": valor},
        )
        return {"mensagem": "Transferência concluída (mesma agência)."}

    # Caso entre agências: chama a agência de destino diretamente via REST
    ts_envio = relogio.ao_enviar()
    agencia_info = next(
        (a for a in config.AGENCIAS if a["id"] == agencia_destino), None
    )
    if not agencia_info:
        # Reverte o débito se a agência de destino não for encontrada nas configurações
        conta_origem["saldo"] += valor
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Configuração da agência de destino não encontrada.",
        )
    url_destino = agencia_info["url"]

    try:
        response = requests.post(
            f"{url_destino}/contas/{id_destino}/creditar-remoto",
            json={
                "valor": valor,
                "timestampLamport": ts_envio,
                "origemAgencia": id_agencia,
            },
            timeout=5.0,
        )
        if response.status_code != 200:
            response.raise_for_status()
        return {"mensagem": "Transferência concluída (entre agências)."}
    except Exception as e:
        # LIMITAÇÃO CONHECIDA: se esta chamada falhar, o débito já aplicado acima
        # NÃO é revertido - o dinheiro "desaparece" temporariamente. Por enquanto, só registramos no log.
        ts_falha = relogio.evento_local()
        registro.registrar(
            "TRANSFERENCIA_FALHOU",
            ts_falha,
            {
                "idOrigem": id_origem,
                "idDestino": id_destino,
                "valor": valor,
                "erro": str(e),
            },
        )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Falha ao contatar agência de destino. Débito já aplicado - inconsistência conhecida (ver Sprint 4).",
        )


def creditar_remoto(request: Request, id: int, body: CreditoRemotoRequest):
    contas = request.app.state.contas
    relogio = request.app.state.relogio
    registro = request.app.state.registro

    # Ao RECEBER uma mensagem de outra agência, o relógio de Lamport é
    # atualizado com base no timestamp recebido - é a regra 3 do algoritmo.
    ts = relogio.ao_receber(body.timestampLamport)

    conta = contas.get(id)
    if not conta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conta não encontrada nesta agência.",
        )

    conta["saldo"] += body.valor
    registro.registrar(
        "TRANSFERENCIA_CREDITO_REMOTO",
        ts,
        {"idConta": id, "valor": body.valor, "origemAgencia": body.origemAgencia},
    )

    return {"mensagem": "Crédito remoto aplicado.", "saldoAtual": conta["saldo"]}
