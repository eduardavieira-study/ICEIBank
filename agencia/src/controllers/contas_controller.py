from fastapi import Request, HTTPException, status, Depends
from pydantic import BaseModel
import agencia.src.config as config
import os
import json
from agencia.src.services.auth import gerar_token, validar_token, verificar_autorizacao


class CriarContaRequest(BaseModel):
    id: int
    nomeAluno: str
    saldoInicial: float = 0.0


class TransacaoRequest(BaseModel):
    valor: float


class LoginRequest(BaseModel):
    usuario: str = None
    senha: str = None
    idConta: int = None
    nomeAluno: str = None
    expirar_em_segundos: int = 1800


def login(request: Request, body: LoginRequest):
    contas = request.app.state.contas
    id_agencia = request.app.state.id_agencia
    exp_seconds = body.expirar_em_segundos

    # Login de Administrador
    if body.usuario == "admin" and body.senha == "admin":
        token = gerar_token("admin", role="admin", expires_in_seconds=exp_seconds)
        return {"token": token, "role": "admin", "usuario": "admin"}

    # Login de Aluno
    if body.idConta is not None and body.nomeAluno is not None:
        id_conta = body.idConta
        nome_aluno = body.nomeAluno

        # Verifica se esta agência é responsável pela conta
        if config.agencia_responsavel(id_conta) != id_agencia:
            agencia_correta = config.agencia_responsavel(id_conta)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Esta conta pertence à Agência {agencia_correta}. Por favor, faça login na porta correspondente.",
            )

        conta = contas.get(id_conta)
        if (
            not conta
            or conta["nomeAluno"].strip().lower() != nome_aluno.strip().lower()
        ):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Credenciais inválidas para a conta informada nesta agência.",
            )

        token = gerar_token(id_conta, role="user", expires_in_seconds=exp_seconds)
        return {
            "token": token,
            "role": "user",
            "idConta": id_conta,
            "nomeAluno": conta["nomeAluno"],
        }

    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail="Credenciais de login incompletas.",
    )


def criar_conta(
    request: Request, body: CriarContaRequest, payload: dict = Depends(validar_token)
):
    # Autorização: Apenas administradores podem criar contas
    if payload.get("role") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Apenas administradores podem criar contas no sistema.",
        )

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


def consultar_saldo(request: Request, id: int, payload: dict = Depends(validar_token)):
    # Autorização: O próprio dono ou admin podem ver o saldo
    if not verificar_autorizacao(payload, id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Você não tem permissão para consultar o saldo desta conta.",
        )

    contas = request.app.state.contas
    if id not in contas:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conta não encontrada nesta agência.",
        )
    return contas[id]


def depositar(
    request: Request,
    id: int,
    body: TransacaoRequest,
    payload: dict = Depends(validar_token),
):
    # Autorização: Qualquer pessoa autenticada pode depositar para qualquer pessoa no banco, ou limitamos ao dono?
    # Para o laboratório, vamos permitir que apenas o próprio dono ou o admin façam a transação.
    if not verificar_autorizacao(payload, id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Você não tem permissão para realizar depósitos nesta conta.",
        )

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


def sacar(
    request: Request,
    id: int,
    body: TransacaoRequest,
    payload: dict = Depends(validar_token),
):
    # Autorização: Apenas o dono ou admin podem sacar
    if not verificar_autorizacao(payload, id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Você não tem permissão para realizar saques nesta conta.",
        )

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

