from fastapi import Request, HTTPException, status, Depends
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import agencia.src.config as config
import os
import json
from agencia.src.services import mensageria
from agencia.src.services.comparar_vetores import comparar_vetores
from agencia.src.services.auth import (
    gerar_token,
    validar_token,
    verificar_autorizacao,
    gerar_hash_senha,
    verificar_senha,
)


def notificar_saldo_baixo(app_state, id_conta: int, saldo: float) -> None:
    if saldo >= config.LIMITE_SALDO_BAIXO:
        return
    vetor = app_state.relogio.ao_enviar()
    try:
        mensageria.publicar(
            f"alerta.agencia.{app_state.id_agencia}.saldo.baixo",
            {
                "idConta": id_conta,
                "saldo": saldo,
                "vetorEnvio": vetor,
                "agencia": app_state.id_agencia,
            },
        )
    except Exception as e:
        # O alerta é complementar: a operação já foi concluída, então uma falha
        # ao publicar não deve desfazer o saque/transferência.
        print(f"Falha ao publicar alerta de saldo baixo: {e}")


def processar_alerta_saldo_baixo(app_state, mensagem: dict) -> None:
    vetor = app_state.relogio.ao_receber(mensagem["vetorEnvio"])
    app_state.registro.registrar(
        "ALERTA_SALDO_BAIXO",
        vetor,
        {"idConta": mensagem["idConta"], "saldo": mensagem["saldo"]},
    )


class CriarContaRequest(BaseModel):
    id: int
    nomeAluno: str
    senha: str
    saldoInicial: float = 0.0


class TransacaoRequest(BaseModel):
    valor: float


class SincronizarRequest(BaseModel):
    tipo: str
    valor: float
    vetorConhecido: list[int]


class LoginRequest(BaseModel):
    usuario: str = None
    senha: str = None
    nomeAluno: str = None
    expirar_em_segundos: int = 1800


def buscar_conta_por_nome(contas: dict, nome_aluno: str):
    nome = nome_aluno.strip().lower()
    return next(
        (c for c in contas.values() if c["nomeAluno"].strip().lower() == nome), None
    )


def login(request: Request, body: LoginRequest):
    contas = request.app.state.contas
    id_agencia = request.app.state.id_agencia
    exp_seconds = body.expirar_em_segundos

    # Login de Administrador
    if body.usuario == "admin" and body.senha == "admin":
        token = gerar_token("admin", role="admin", expires_in_seconds=exp_seconds)
        return {"token": token, "role": "admin", "usuario": "admin"}

    # Login de Aluno
    if body.nomeAluno and body.senha:
        conta = buscar_conta_por_nome(contas, body.nomeAluno)
        senha_armazenada = request.app.state.senhas.get(conta["id"]) if conta else None
        if not senha_armazenada or not verificar_senha(body.senha, senha_armazenada):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Nome ou senha inválidos na Agência {id_agencia}. Verifique se selecionou a agência correta.",
            )

        id_conta = conta["id"]

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

    if not body.senha.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A senha da conta não pode ser vazia.",
        )

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

    # O nome é usado no login, então precisa ser único dentro da agência
    if buscar_conta_por_nome(contas, nome_aluno):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Já existe uma conta com o nome '{nome_aluno}' nesta agência.",
        )

    ts = relogio.evento_local()
    conta = {"id": id_conta, "nomeAluno": nome_aluno, "saldo": saldo_inicial}
    contas[id_conta] = conta
    request.app.state.senhas[id_conta] = gerar_hash_senha(body.senha)

    registro.registrar(
        "CRIAR_CONTA",
        ts,
        {"id": id_conta, "nomeAluno": nome_aluno, "saldoInicial": saldo_inicial},
    )

    return conta


def listar_contas(request: Request, payload: dict = Depends(validar_token)):
    # Autorização: apenas administradores listam as contas da agência
    if payload.get("role") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Apenas administradores podem listar as contas da agência.",
        )
    # Nunca devolve as senhas (ficam em app.state.senhas, separadas das contas)
    contas = sorted(request.app.state.contas.values(), key=lambda c: c["id"])
    return {"contas": contas}


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
    # O app guarda o vetorAtual para devolvê-lo ao sincronizar operações feitas offline
    return {**contas[id], "vetorAtual": request.app.state.relogio.obter_vetor_atual()}


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

    notificar_saldo_baixo(request.app.state, id, conta["saldo"])
    return conta


def consultar_historico(
    request: Request, id: int, payload: dict = Depends(validar_token)
):
    # Autorização: Apenas o dono ou admin podem ver o histórico
    if not verificar_autorizacao(payload, id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Você não tem permissão para consultar o histórico desta conta.",
        )

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

    def chave_ordenacao(evento):
        vetor = evento.get("timestampVetorial", [])
        # Normaliza para lista: logs antigos (de antes do relógio vetorial estar
        # ligado no main.py) gravaram timestampVetorial como um número único,
        # e não dá para comparar int com list diretamente no sort.
        if not isinstance(vetor, list):
            vetor = [vetor]
        return (vetor, evento.get("dataHora", ""))

    # Ordena por timestampVetorial (comparação lexicográfica) e depois por dataHora (tempo físico)
    eventos_filtrados.sort(key=chave_ordenacao)
    return eventos_filtrados



def sincronizar_operacao_pendente(
    request: Request,
    id: int,
    body: SincronizarRequest,
    payload: dict = Depends(validar_token),
):
    """Aplica uma operação feita offline pelo app, mas só se a agência não mudou
    desde a última leitura do app: o vetor que o app conhecia precisa ser IGUAL
    ao vetor atual da agência. Caso contrário devolve 409 com o estado atual,
    para o app decidir o que fazer (não resolve o conflito sozinha)."""
    if not verificar_autorizacao(payload, id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Você não tem permissão para sincronizar operações desta conta.",
        )

    contas = request.app.state.contas
    relogio = request.app.state.relogio
    registro = request.app.state.registro

    conta = contas.get(id)
    if not conta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conta não encontrada nesta agência.",
        )

    if body.tipo not in ("DEPOSITO", "SAQUE"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tipo de operação pendente não suportado.",
        )
    if body.valor <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="O valor da operação deve ser maior que zero.",
        )
    if len(body.vetorConhecido) != config.NUMERO_AGENCIAS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"O vetor conhecido deve ter {config.NUMERO_AGENCIAS} posições.",
        )

    # Comparar e aplicar precisam ser atômicos: sem a trava, duas sincronizações
    # com o mesmo vetor poderiam passar juntas e a operação seria aplicada duas vezes.
    with relogio.bloquear():
        vetor_atual = relogio.obter_vetor_atual()
        relacao = comparar_vetores(body.vetorConhecido, vetor_atual)

        if relacao != "IGUAIS":
            # Qualquer diferença conta como conflito: a agência avançou enquanto o
            # app estava offline (ANTES), foi reiniciada e perdeu o estado (DEPOIS)
            # ou os dois divergiram (CONCORRENTES). Não aplica às cegas.
            return JSONResponse(
                status_code=status.HTTP_409_CONFLICT,
                content={
                    "detail": "Conflito detectado: o estado da conta mudou desde a última sincronização do app.",
                    "relacao": relacao,
                    "vetorConhecido": body.vetorConhecido,
                    "vetorAtual": vetor_atual,
                    "contaAtual": conta,
                },
            )

        if body.tipo == "SAQUE" and conta["saldo"] < body.valor:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Saldo insuficiente."
            )

        vetor = relogio.evento_local()
        if body.tipo == "DEPOSITO":
            conta["saldo"] += body.valor
        else:
            conta["saldo"] -= body.valor

    registro.registrar(
        "SINCRONIZACAO_OFFLINE",
        vetor,
        {"id": id, "tipo": body.tipo, "valor": body.valor, "novoSaldo": conta["saldo"]},
    )

    if body.tipo == "SAQUE":
        notificar_saldo_baixo(request.app.state, id, conta["saldo"])

    # Devolve o vetor novo: o app precisa dele para a próxima sincronização
    return {**conta, "vetorAtual": vetor}
