import csv
import io
from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import StreamingResponse
from sqlalchemy import and_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_session
from ..deps import get_current_household, get_current_user
from ..models import Category, HouseholdMember, Transaction, User
from ..schemas import TransactionIn, TransactionOut, TransactionPatch

router = APIRouter(prefix="/transactions", tags=["transactions"])


@router.get("", response_model=list[TransactionOut])
async def list_transactions(
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
    kind: Optional[str] = Query(None, pattern="^(expense|income)$"),
    actor_user_id: Optional[UUID] = None,
    category_id: Optional[UUID] = None,
    since: Optional[datetime] = None,
    until: Optional[datetime] = None,
    status_: Optional[str] = Query(None, alias="status"),
    q: Optional[str] = Query(None, description="full-text search on merchant/note"),
    limit: int = Query(100, le=500),
    offset: int = 0,
):
    conds = [Transaction.household_id == member.household_id, Transaction.deleted_at.is_(None)]
    if kind:
        conds.append(Transaction.kind == kind)
    if actor_user_id:
        conds.append(Transaction.actor_user_id == actor_user_id)
    if category_id:
        conds.append(Transaction.category_id == category_id)
    if since:
        conds.append(Transaction.occurred_at >= since)
    if until:
        conds.append(Transaction.occurred_at < until)
    if status_:
        conds.append(Transaction.status == status_)
    if q and q.strip():
        like = f"%{q.strip()}%"
        conds.append(or_(Transaction.merchant.ilike(like), Transaction.note.ilike(like)))
    q = (
        select(Transaction)
        .where(and_(*conds))
        .order_by(Transaction.occurred_at.desc())
        .limit(limit)
        .offset(offset)
    )
    res = await session.execute(q)
    return list(res.scalars().all())


@router.post("", response_model=TransactionOut, status_code=status.HTTP_201_CREATED)
async def create_transaction(
    body: TransactionIn,
    user: User = Depends(get_current_user),
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    tx = Transaction(
        household_id=member.household_id,
        user_id=user.id,
        actor_user_id=body.actor_user_id or user.id,
        account_id=body.account_id,
        category_id=body.category_id,
        kind=body.kind,
        amount=body.amount,
        currency=body.currency,
        merchant=body.merchant,
        note=body.note,
        occurred_at=body.occurred_at or datetime.now(timezone.utc),
        source=body.source,
        ai_job_id=body.ai_job_id,
        ai_confidence=body.ai_confidence,
        status="confirmed",
    )
    session.add(tx)
    await session.commit()
    return tx


@router.post("/bulk", response_model=list[TransactionOut], status_code=status.HTTP_201_CREATED)
async def create_bulk(
    body: list[TransactionIn],
    user: User = Depends(get_current_user),
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    out: list[Transaction] = []
    for item in body:
        tx = Transaction(
            household_id=member.household_id,
            user_id=user.id,
            actor_user_id=item.actor_user_id or user.id,
            account_id=item.account_id,
            category_id=item.category_id,
            kind=item.kind,
            amount=item.amount,
            currency=item.currency,
            merchant=item.merchant,
            note=item.note,
            occurred_at=item.occurred_at or datetime.now(timezone.utc),
            source=item.source,
            ai_job_id=item.ai_job_id,
            ai_confidence=item.ai_confidence,
            status="confirmed",
        )
        session.add(tx)
        out.append(tx)
    await session.commit()
    return out


@router.patch("/{tx_id}", response_model=TransactionOut)
async def patch_transaction(
    tx_id: UUID,
    body: TransactionPatch,
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    tx = await session.get(Transaction, tx_id)
    if tx is None or tx.household_id != member.household_id or tx.deleted_at is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    data = body.model_dump(exclude_unset=True)
    for k, v in data.items():
        setattr(tx, k, v)
    await session.commit()
    return tx


@router.get("/export.csv")
async def export_csv(
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
    since: Optional[datetime] = None,
    until: Optional[datetime] = None,
):
    """Stream a CSV of all confirmed transactions for the household."""
    conds = [
        Transaction.household_id == member.household_id,
        Transaction.deleted_at.is_(None),
        Transaction.status == "confirmed",
    ]
    if since:
        conds.append(Transaction.occurred_at >= since)
    if until:
        conds.append(Transaction.occurred_at < until)

    res = await session.execute(
        select(Transaction, Category.label, Category.slug)
        .join(Category, Category.id == Transaction.category_id, isouter=True)
        .where(and_(*conds))
        .order_by(Transaction.occurred_at.desc())
    )
    rows = res.all()

    buf = io.StringIO()
    writer = csv.writer(buf, dialect="excel")
    writer.writerow([
        "id", "occurred_at", "kind", "amount", "currency",
        "category_slug", "category_label", "merchant", "note", "source",
    ])
    for tx, cat_label, cat_slug in rows:
        writer.writerow([
            str(tx.id),
            tx.occurred_at.isoformat(),
            tx.kind,
            f"{tx.amount}",
            tx.currency,
            cat_slug or "",
            cat_label or "",
            tx.merchant or "",
            (tx.note or "").replace("\n", " "),
            tx.source,
        ])
    buf.seek(0)

    headers = {
        "Content-Disposition": f'attachment; filename="evimiz-{datetime.now(timezone.utc):%Y%m%d}.csv"',
    }
    return StreamingResponse(
        iter([buf.getvalue()]),
        media_type="text/csv; charset=utf-8",
        headers=headers,
    )


@router.get("/{tx_id}", response_model=TransactionOut)
async def get_transaction(
    tx_id: UUID,
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    tx = await session.get(Transaction, tx_id)
    if tx is None or tx.household_id != member.household_id or tx.deleted_at is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return tx


@router.delete("/{tx_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_transaction(
    tx_id: UUID,
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    tx = await session.get(Transaction, tx_id)
    if tx is None or tx.household_id != member.household_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    tx.deleted_at = datetime.now(timezone.utc)
    await session.commit()
