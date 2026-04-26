from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_session
from ..deps import get_current_household
from ..models import Account, HouseholdMember
from ..schemas import AccountIn, AccountOut, AccountPatch

router = APIRouter(prefix="/accounts", tags=["accounts"])


@router.get("", response_model=list[AccountOut])
async def list_accounts(
    include_archived: bool = False,
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    q = select(Account).where(Account.household_id == member.household_id)
    if not include_archived:
        q = q.where(Account.is_archived.is_(False))
    res = await session.execute(q.order_by(Account.created_at))
    return list(res.scalars().all())


@router.post("", response_model=AccountOut, status_code=201)
async def create_account(
    body: AccountIn,
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    if member.role not in ("owner", "admin", "member"):
        raise HTTPException(status.HTTP_403_FORBIDDEN)
    a = Account(household_id=member.household_id, **body.model_dump())
    session.add(a)
    await session.commit()
    return a


@router.patch("/{account_id}", response_model=AccountOut)
async def patch_account(
    account_id: UUID,
    body: AccountPatch,
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    a = await session.get(Account, account_id)
    if a is None or a.household_id != member.household_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(a, k, v)
    await session.commit()
    return a


@router.delete("/{account_id}", status_code=204)
async def delete_account(
    account_id: UUID,
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    a = await session.get(Account, account_id)
    if a is None or a.household_id != member.household_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    a.is_archived = True
    await session.commit()
