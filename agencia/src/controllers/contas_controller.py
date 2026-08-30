from fastapi import Request, HTTPException, status
from pydantic import BaseModel
import agencia.src.config as config
import os
import json


class CriarContaRequest(BaseModel):
    id: int
    nomeAluno: str
    saldoInicial: float = 0.0


class TransacaoRequest(BaseModel):
    valor: float


def criar_conta(request: Request, body: CriarContaRequest):
    id_conta = body.id
    nome_aluno = body.nomeAluno
    saldo_inicial = body.saldoInicial

    id_agencia = request.app.state.id_agencia
    contas = request.app.state.contas
    relogio = request.app.state.relogio
    registro = request.app.state.registro

    if config.agencia_responsavel(id_conta) != id_agencia:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Conta {id_conta} não pertence a esta agência.",
        )

    if id_conta in contas:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="Conta já existe."
        )

    ts = relogio.evento_local()
    conta = {"id": id_conta, "nomeAluno": nome_aluno, "saldo": saldo_inicial}
    contas[id_conta] = conta

    registro.registrar(
        "CRIAR_CONTA",
        ts,
        {"id": id_conta, "nomeAluno": nome_aluno, "saldoInicial": saldo_inicial},
    )

    return conta


def consultar_saldo(request: Request, id: int):
    contas = request.app.state.contas
    if id not in contas:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conta não encontrada nesta agência.",
        )
    return contas[id]


def depositar(request: Request, id: int, body: TransacaoRequest):
    valor = body.valor
    contas = request.app.state.contas
    relogio = request.app.state.relogio
    registro = request.app.state.registro

    if id not in contas:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conta não encontrada nesta agência.",
        )

    if valor <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="O valor do depósito deve ser maior que zero.",
        )

    ts = relogio.evento_local()
    conta = contas[id]
    conta["saldo"] += valor

    registro.registrar(
        "DEPOSITO", ts, {"id": id, "valor": valor, "novoSaldo": conta["saldo"]}
    )

    return conta


def sacar(request: Request, id: int, body: TransacaoRequest):
    valor = body.valor
    contas = request.app.state.contas
    relogio = request.app.state.relogio
    registro = request.app.state.registro

    if id not in contas:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conta não encontrada nesta agência.",
        )

    conta = contas[id]
    if conta["saldo"] < valor:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Saldo insuficiente."
        )

    if valor <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="O valor do saque deve ser maior que zero.",
        )

    ts = relogio.evento_local()
    conta["saldo"] -= valor

    registro.registrar(
        "SAQUE", ts, {"id": id, "valor": valor, "novoSaldo": conta["saldo"]}
    )

    return conta


def consultar_historico(request: Request, id: int):
    contas = request.app.state.contas
    if id not in contas:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conta não encontrada nesta agência.",
        )

    registro = request.app.state.registro
    caminho_arquivo = registro.caminho_arquivo
    eventos_filtrados = []

    if os.path.exists(caminho_arquivo):
        with open(caminho_arquivo, "r", encoding="utf-8") as f:
            for linha in f:
                linha = linha.strip()
                if not linha:
                    continue
                try:
                    evento = json.loads(linha)
                    detalhes = evento.get("detalhes", {})
                    tipo = evento.get("tipo", "")

                    # Filtra eventos associados a esta conta
                    envolvido = False
                    if tipo == "CRIAR_CONTA" and detalhes.get("id") == id:
                        envolvido = True
                    elif tipo == "DEPOSITO" and detalhes.get("id") == id:
                        envolvido = True
                    elif tipo == "SAQUE" and detalhes.get("id") == id:
                        envolvido = True
                    elif (
                        tipo == "TRANSFERENCIA_DEBITO"
                        and detalhes.get("idOrigem") == id
                    ):
                        envolvido = True
                    elif tipo == "TRANSFERENCIA_CREDITO" and (
                        detalhes.get("idDestino") == id
                        or detalhes.get("idOrigem") == id
                    ):
                        envolvido = True
                    elif (
                        tipo == "TRANSFERENCIA_CREDITO_REMOTO"
                        and detalhes.get("idConta") == id
                    ):
                        envolvido = True
                    elif (
                        tipo == "TRANSFERENCIA_FALHOU"
                        and detalhes.get("idOrigem") == id
                    ):
                        envolvido = True

                    if envolvido:
                        eventos_filtrados.append(evento)
                except Exception:
                    pass

    # Ordena por timestampLamport
    eventos_filtrados.sort(key=lambda x: x.get("timestampLamport", 0))
    return eventos_filtrados
