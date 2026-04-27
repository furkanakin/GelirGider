"""Admin endpoints. NOT for general use.

Guarded by a shared bearer secret (the same `JWT_SECRET` we already deploy).
The intent is to give the operator (Furkan) a way to nuke a stray account
without SSH-ing into the box. If the secret leaks rotate JWT_SECRET — that
also invalidates every issued access token, so it's the right blast radius.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, Header, HTTPException, status
from pydantic import EmailStr
from sqlalchemy import delete, select, text, update
from sqlalchemy.ext.asyncio import AsyncSession

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

    # The schema has NOT-NULL FKs from several tables to users.id without
    # ON DELETE CASCADE (households.created_by, transactions.user_id,
    # ai_jobs.user_id, notifications.user_id, quick_entries.user_id,
    # household_invites.invited_by). Deleting a user fails until those
    # references are gone or pointed elsewhere. Strategy:
    #   1. Delete invites this user issued (kill outright — invited_by
    #      is NOT NULL) and detach invites they accepted.
    #   2. Drop refresh tokens.
    #   3. Drop households they created — CASCADE wipes that household's
    #      categories, accounts, transactions, ai_jobs, notifications,
    #      quick_entries, recurring templates, attachments, invites.
    #   4. Drop their memberships in OTHER households.
    #   5. Best-effort cleanup of cross-household activity (rare).
    #   6. Delete the user.

    await session.execute(
        delete(HouseholdInvite).where(HouseholdInvite.invited_by == user_id)
    )
    await session.execute(
        update(HouseholdInvite)
        .where(HouseholdInvite.accepted_by == user_id)
        .values(accepted_by=None, accepted_at=None)
    )
    await session.execute(delete(RefreshToken).where(RefreshToken.user_id == user_id))

    # Households they created — CASCADEs through everything inside.
    await session.execute(delete(Household).where(Household.created_by == user_id))

    # Cross-household activity. Deleting their actions in someone else's
    # household is a judgment call — for our use case (recently-registered
    # users we want gone), the rows shouldn't exist; the explicit deletes
    # below are insurance against a partially-shared scenario.
    await session.execute(
        text("DELETE FROM evimiz.transactions WHERE user_id = :uid"),
        {"uid": user_id},
    )
    await session.execute(
        text("UPDATE evimiz.transactions SET actor_user_id = NULL WHERE actor_user_id = :uid"),
        {"uid": user_id},
    )
    await session.execute(
        text("DELETE FROM evimiz.ai_jobs WHERE user_id = :uid"),
        {"uid": user_id},
    )
    await session.execute(
        text("DELETE FROM evimiz.notifications WHERE user_id = :uid"),
        {"uid": user_id},
    )
    await session.execute(
        text("DELETE FROM evimiz.quick_entries WHERE user_id = :uid"),
        {"uid": user_id},
    )

    await session.execute(
        delete(HouseholdMember).where(HouseholdMember.user_id == user_id)
    )

    # Finally drop the user row itself.
    await session.execute(delete(User).where(User.id == user_id))

    await session.commit()
    return {"deleted": True, "email": email, "user_id": str(user_id)}
