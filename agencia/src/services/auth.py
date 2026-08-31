from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt
from datetime import datetime, timedelta

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
