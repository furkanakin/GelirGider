from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_session
from ..deps import get_current_household, get_current_user
from ..models import HouseholdMember, Notification, User
from ..schemas import NotificationOut

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("", response_model=list[NotificationOut])
async def list_notifications(
    only_unread: bool = False,
    user: User = Depends(get_current_user),
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    q = select(Notification).where(
        Notification.user_id == user.id,
        Notification.household_id == member.household_id,
    )
    if only_unread:
        q = q.where(Notification.is_read.is_(False))
    res = await session.execute(q.order_by(Notification.created_at.desc()).limit(100))
    return list(res.scalars().all())


@router.post("/{nid}/read", status_code=204)
async def mark_read(
    nid: UUID,
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    n = await session.get(Notification, nid)
    if n is None or n.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    if not n.is_read:
        n.is_read = True
        n.read_at = datetime.now(timezone.utc)
        await session.commit()


@router.post("/read-all", status_code=204)
async def mark_all_read(
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    await session.execute(
        update(Notification)
        .where(Notification.user_id == user.id, Notification.is_read.is_(False))
        .values(is_read=True, read_at=datetime.now(timezone.utc))
    )
    await session.commit()
