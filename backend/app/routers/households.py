import secrets
from datetime import datetime, timedelta, timezone
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_session
from ..deps import get_current_household, get_current_user
from ..models import Household, HouseholdInvite, HouseholdMember, User
from ..schemas import HouseholdMemberOut, HouseholdMemberPatch, HouseholdOut, HouseholdPatch, InviteAcceptIn, InviteCreateIn, InviteOut

router = APIRouter(prefix="/household", tags=["household"])


@router.get("", response_model=HouseholdOut)
async def get_my_household(
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    hh = await session.get(Household, member.household_id)
    if hh is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "household not found")
    return hh


@router.patch("", response_model=HouseholdOut)
async def patch_household(
    body: HouseholdPatch,
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    if member.role not in ("owner", "admin"):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "only owner/admin")
    hh = await session.get(Household, member.household_id)
    if hh is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    data = body.model_dump(exclude_unset=True)
    for k, v in data.items():
        setattr(hh, k, v)
    await session.commit()
    return hh


@router.patch("/members/{user_id}", response_model=HouseholdMemberOut)
async def patch_member(
    user_id: UUID,
    body: HouseholdMemberPatch,
    me: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    res = await session.execute(
        select(HouseholdMember).where(
            HouseholdMember.household_id == me.household_id,
            HouseholdMember.user_id == user_id,
        )
    )
    target = res.scalar_one_or_none()
    if target is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    if target.user_id != me.user_id and me.role not in ("owner", "admin"):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "cannot edit other members")
    data = body.model_dump(exclude_unset=True)
    if "role" in data and me.role != "owner":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "only owner can change roles")
    for k, v in data.items():
        setattr(target, k, v)
    await session.commit()
    user = await session.get(User, target.user_id)
    return HouseholdMemberOut(
        user_id=target.user_id,
        display_name=user.display_name if user else "",
        nickname=target.nickname,
        role=target.role,
        avatar_color=target.avatar_color,
    )


@router.delete("/members/{user_id}", status_code=204)
async def remove_member(
    user_id: UUID,
    me: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    if user_id != me.user_id and me.role not in ("owner", "admin"):
        raise HTTPException(status.HTTP_403_FORBIDDEN)
    res = await session.execute(
        select(HouseholdMember).where(
            HouseholdMember.household_id == me.household_id,
            HouseholdMember.user_id == user_id,
        )
    )
    target = res.scalar_one_or_none()
    if target is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    if target.role == "owner":
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "cannot remove owner")
    await session.delete(target)
    await session.commit()


@router.get("/members", response_model=list[HouseholdMemberOut])
async def list_members(
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    q = (
        select(HouseholdMember, User)
        .join(User, User.id == HouseholdMember.user_id)
        .where(HouseholdMember.household_id == member.household_id)
    )
    rows = await session.execute(q)
    out: list[HouseholdMemberOut] = []
    for hm, user in rows.all():
        out.append(
            HouseholdMemberOut(
                user_id=user.id,
                display_name=user.display_name,
                nickname=hm.nickname,
                role=hm.role,
                avatar_color=hm.avatar_color or user.avatar_color,
            )
        )
    return out


@router.post("/invite", response_model=InviteOut)
async def create_invite(
    body: InviteCreateIn,
    user: Annotated[User, Depends(get_current_user)],
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    if member.role not in ("owner", "admin"):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "only owner/admin can invite")
    code = secrets.token_urlsafe(8)
    invite = HouseholdInvite(
        household_id=member.household_id,
        code=code,
        role=body.role,
        invited_email=body.email,
        invited_by=user.id,
        expires_at=datetime.now(timezone.utc) + timedelta(days=14),
    )
    session.add(invite)
    await session.commit()
    return InviteOut(code=code, expires_at=invite.expires_at)


@router.post("/accept", response_model=HouseholdOut)
async def accept_invite(
    body: InviteAcceptIn,
    user: Annotated[User, Depends(get_current_user)],
    session: AsyncSession = Depends(get_session),
):
    res = await session.execute(select(HouseholdInvite).where(HouseholdInvite.code == body.code))
    invite = res.scalar_one_or_none()
    if invite is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "invalid code")
    if invite.expires_at < datetime.now(timezone.utc) or invite.accepted_at is not None:
        raise HTTPException(status.HTTP_410_GONE, "invite expired or used")
    existing = await session.execute(
        select(HouseholdMember).where(
            HouseholdMember.household_id == invite.household_id,
            HouseholdMember.user_id == user.id,
        )
    )
    if existing.scalar_one_or_none() is None:
        session.add(
            HouseholdMember(
                household_id=invite.household_id,
                user_id=user.id,
                role=invite.role,
                nickname=user.display_name.split(" ")[0],
            )
        )
    invite.accepted_by = user.id
    invite.accepted_at = datetime.now(timezone.utc)
    await session.commit()
    hh = await session.get(Household, invite.household_id)
    return hh
