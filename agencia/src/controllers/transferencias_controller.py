from fastapi import Request, HTTPException, status, Depends
from pydantic import BaseModel
import agencia.src.config as config
from agencia.src.services import mensageria
from agencia.src.services.auth import validar_token, verificar_autorizacao


class TransferenciaRequest(BaseModel):
    idOrigem: int
    idDestino: int
    valor: float


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

    # Caso entre agências: em vez de chamar a outra agência diretamente via
    # REST (Sprint 1), publicamos um evento na exchange do RabbitMQ. A agência
    # de destino consome quando puder - mesmo que esteja fora do ar agora, a
    # mensagem fica retida na fila (durable) e é entregue quando ela voltar.
    vetor_envio = relogio.ao_enviar()
    try:
        mensageria.publicar(
            f"agencia.{agencia_destino}.creditar",
            {
                "idConta": id_destino,
                "valor": valor,
                "vetorEnvio": vetor_envio,
                "origemAgencia": id_agencia,
            },
        )
    except Exception as e:
        # Reverte o débito se nem foi possível publicar a mensagem (ex.: RabbitMQ fora do ar)
        conta_origem["saldo"] += valor
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Falha ao publicar mensagem no RabbitMQ: {e}",
        )

    return {
        "mensagem": "Transferência publicada para a agência de destino (entrega assíncrona)."
    }


def processar_credito_remoto(app_state, mensagem: dict) -> None:
    """Chamado pelo consumidor de mensagens (RabbitMQ) ao receber um crédito
    vindo de outra agência. Não passa pela autenticação JWT das rotas HTTP -
    ver Pergunta 3 da Parte C em RESPOSTAS.md."""
    contas = app_state.contas
    relogio = app_state.relogio
    registro = app_state.registro

    id_conta = mensagem["idConta"]
    valor = mensagem["valor"]
    vetor_envio = mensagem["vetorEnvio"]
    origem_agencia = mensagem["origemAgencia"]

    # Ao RECEBER uma mensagem de outra agência, o relógio vetorial funde o
    # vetor recebido com o próprio - é a regra 3 do algoritmo (Parte B).
    vetor = relogio.ao_receber(vetor_envio)

    conta = contas.get(id_conta)
    if not conta:
        registro.registrar(
            "CREDITO_REMOTO_FALHOU",
            vetor,
            {
                "idConta": id_conta,
                "valor": valor,
                "origemAgencia": origem_agencia,
                "motivo": "conta nao encontrada",
            },
        )
        return

    conta["saldo"] += valor
    registro.registrar(
        "TRANSFERENCIA_CREDITO_REMOTO",
        vetor,
        {"idConta": id_conta, "valor": valor, "origemAgencia": origem_agencia},
    )
