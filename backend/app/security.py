from datetime import datetime, timedelta, timezone
from typing import Any
from uuid import UUID

from jose import JWTError, jwt
from passlib.context import CryptContext

from .config import get_settings

_settings = get_settings()
_pwd = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return _pwd.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return _pwd.verify(plain, hashed)


def make_access_token(*, user_id: UUID, household_id: UUID | None = None, extra: dict | None = None) -> str:
    now = datetime.now(timezone.utc)
    payload: dict[str, Any] = {
        "sub": str(user_id),
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=_settings.access_token_ttl_minutes)).timestamp()),
        "type": "access",
    }
    if household_id:
        payload["hh"] = str(household_id)
    if extra:
        payload.update(extra)
    return jwt.encode(payload, _settings.jwt_secret, algorithm=_settings.jwt_alg)


def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, _settings.jwt_secret, algorithms=[_settings.jwt_alg])
    except JWTError as exc:
        raise ValueError(f"invalid token: {exc}") from exc
