"""Admin endpoints. NOT for general use.

Guarded by a shared bearer secret (the same `JWT_SECRET` we already deploy).
The intent is to give the operator (Furkan) a way to nuke a stray account
without SSH-ing into the box. If the secret leaks rotate JWT_SECRET — that
also invalidates every issued access token, so it's the right blast radius.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy import delete, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import EmailStr

from ..config import get_settings
from ..db import get_session
from ..models import (
    Household,
    HouseholdInvite,
    HouseholdMember,
    RefreshToken,
    User,
)

router = APIRouter(prefix="/admin", tags=["admin"])
_settings = get_settings()


def _check(authorization: str | None) -> None:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "missing bearer")
    token = authorization.split(" ", 1)[1]
    if token != _settings.jwt_secret:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "wrong secret")


@router.delete("/users/by-email/{email}")
async def admin_delete_user(
    email: EmailStr,
    authorization: str | None = Header(default=None),
    session: AsyncSession = Depends(get_session),
):
    _check(authorization)
    res = await session.execute(select(User).where(User.email == email))
    user = res.scalar_one_or_none()
    if user is None:
        return {"deleted": False, "reason": "not found"}

    user_id = user.id

    # 1. wipe sessions
    await session.execute(delete(RefreshToken).where(RefreshToken.user_id == user_id))

    # 2. invites — `invited_by` is NOT NULL, so we drop any invites this user
    #    issued (they're useless without the inviter anyway). For invites
    #    they accepted, just clear `accepted_by` so the historical row stays.
    await session.execute(
        update(HouseholdInvite)
        .where(HouseholdInvite.accepted_by == user_id)
        .values(accepted_by=None, accepted_at=None)
    )
    await session.execute(
        delete(HouseholdInvite).where(HouseholdInvite.invited_by == user_id)
    )

    # 3. household_members rows for this user (cascade keeps their txs intact —
    # if you also need to drop empty households, do it manually).
    await session.execute(
        delete(HouseholdMember).where(HouseholdMember.user_id == user_id)
    )

    # 4. null out households they created (so we don't break FKs)
    await session.execute(
        update(Household)
        .where(Household.created_by == user_id)
        .values(created_by=None)
    )

    # 5. drop the user row itself
    await session.execute(delete(User).where(User.id == user_id))

    await session.commit()
    return {"deleted": True, "email": email, "user_id": str(user_id)}
