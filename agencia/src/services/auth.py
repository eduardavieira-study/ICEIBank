from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt
from datetime import datetime, timedelta
import hashlib
import hmac
import os

# Configurações do JWT
SECRET_KEY = "sua_chave_secreta_super_secreta"
ALGORITHM = "HS256"

security = HTTPBearer(auto_error=False)

def gerar_token(id_usuario: str | int, role: str, expires_in_seconds: int = 1800) -> str:
    payload = {
        "sub": str(id_usuario),
        "role": role,
        "exp": datetime.utcnow() + timedelta(seconds=expires_in_seconds)
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def validar_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> dict:
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token ausente."
        )
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expirado."
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido."
        )

def verificar_autorizacao(payload: dict, id_conta: int) -> bool:
    if payload.get("role") == "admin":
        return True
    return payload.get("sub") == str(id_conta)


def gerar_hash_senha(senha: str) -> str:
    salt = os.urandom(16)
    hash_senha = hashlib.pbkdf2_hmac("sha256", senha.encode("utf-8"), salt, 100_000)
    return f"{salt.hex()}${hash_senha.hex()}"


def verificar_senha(senha: str, senha_armazenada: str) -> bool:
    salt_hex, hash_hex = senha_armazenada.split("$")
    hash_senha = hashlib.pbkdf2_hmac("sha256", senha.encode("utf-8"), bytes.fromhex(salt_hex), 100_000)
    return hmac.compare_digest(hash_senha.hex(), hash_hex)
