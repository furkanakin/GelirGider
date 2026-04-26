from typing import Annotated
from uuid import UUID

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .db import get_session
from .models import HouseholdMember, User
from .security import decode_token


async def get_current_user(
    authorization: Annotated[str | None, Header()] = None,
    session: AsyncSession = Depends(get_session),
) -> User:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "missing bearer token")
    token = authorization.split(" ", 1)[1]
    try:
        payload = decode_token(token)
    except ValueError as exc:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, str(exc)) from exc
    if payload.get("type") != "access":
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "wrong token type")
    user_id = UUID(payload["sub"])
    user = await session.get(User, user_id)
    if user is None or user.deleted_at is not None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "user not found")
    return user


async def get_current_household(
    user: Annotated[User, Depends(get_current_user)],
    x_household_id: Annotated[str | None, Header()] = None,
    session: AsyncSession = Depends(get_session),
) -> HouseholdMember:
    """Resolve and authorize the active household for the current request.

    Client sends `X-Household-Id` header; if absent we pick the user's first membership.
    """
    q = select(HouseholdMember).where(HouseholdMember.user_id == user.id)
    if x_household_id:
        try:
            hh_id = UUID(x_household_id)
        except ValueError as exc:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "invalid household id") from exc
        q = q.where(HouseholdMember.household_id == hh_id)
    res = await session.execute(q.limit(1))
    member = res.scalar_one_or_none()
    if member is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "no household membership")
    return member
