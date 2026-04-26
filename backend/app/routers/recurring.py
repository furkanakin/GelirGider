from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession

from ..config import get_settings
from ..db import get_session
from ..deps import get_current_household
from ..models import HouseholdMember, RecurringTemplate
from ..schemas import RecurringIn, RecurringOut, RecurringPatch, TransactionOut

router = APIRouter(prefix="/recurring", tags=["recurring"])
_settings = get_settings()


@router.get("", response_model=list[RecurringOut])
async def list_recurring(
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    res = await session.execute(
        select(RecurringTemplate)
        .where(RecurringTemplate.household_id == member.household_id)
        .order_by(RecurringTemplate.created_at.desc())
    )
    return list(res.scalars().all())


@router.post("", response_model=RecurringOut, status_code=201)
async def create_recurring(
    body: RecurringIn,
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    t = RecurringTemplate(
        household_id=member.household_id,
        user_id=member.user_id,
        actor_user_id=body.actor_user_id or member.user_id,
        category_id=body.category_id,
        account_id=body.account_id,
        label=body.label,
        kind=body.kind,
        amount=body.amount,
        currency=body.currency,
        cadence=body.cadence,
        day_of_period=body.day_of_period,
        note=body.note,
    )
    session.add(t)
    await session.commit()
    return t


@router.patch("/{rec_id}", response_model=RecurringOut)
async def patch_recurring(
    rec_id: UUID,
    body: RecurringPatch,
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    t = await session.get(RecurringTemplate, rec_id)
    if t is None or t.household_id != member.household_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(t, k, v)
    await session.commit()
    return t


@router.delete("/{rec_id}", status_code=204)
async def delete_recurring(
    rec_id: UUID,
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    t = await session.get(RecurringTemplate, rec_id)
    if t is None or t.household_id != member.household_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    await session.delete(t)
    await session.commit()


@router.post("/{rec_id}/run", response_model=TransactionOut)
async def run_recurring(
    rec_id: UUID,
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    """Manually materialize one occurrence — useful for testing or 'apply now' UX."""
    t = await session.get(RecurringTemplate, rec_id)
    if t is None or t.household_id != member.household_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    if t.is_paused:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "template is paused")
    res = await session.execute(
        text(f"SELECT {_settings.database_schema}.materialize_recurring(:rid, :ts) AS tx_id"),
        {"rid": rec_id, "ts": datetime.now(timezone.utc)},
    )
    tx_id = res.scalar_one()
    if tx_id is None:
        raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, "materialize failed")
    from ..models import Transaction
    tx = await session.get(Transaction, tx_id)
    return tx
