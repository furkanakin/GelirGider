from datetime import date, datetime, timedelta, timezone
from decimal import Decimal
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_session
from ..deps import get_current_household
from ..models import Category, HouseholdMember, Transaction, User, HouseholdMember as HM
from ..schemas import (
    CategoryAggregate,
    DailyPoint,
    MemberAggregate,
    ReportOut,
    ReportPeriod,
)

router = APIRouter(prefix="/reports", tags=["reports"])


def _period(scope: str, anchor: Optional[datetime]) -> tuple[datetime, datetime]:
    today = (anchor or datetime.now(timezone.utc)).astimezone(timezone.utc)
    today = today.replace(hour=0, minute=0, second=0, microsecond=0)
    if scope == "weekly":
        # ISO week, Monday start
        start = today - timedelta(days=today.weekday())
        end = start + timedelta(days=7)
    elif scope == "monthly":
        start = today.replace(day=1)
        nm = start.replace(day=28) + timedelta(days=4)
        end = nm.replace(day=1)
    elif scope == "yearly":
        start = today.replace(month=1, day=1)
        end = start.replace(year=start.year + 1)
    else:
        start = today
        end = today + timedelta(days=1)
    return start, end


@router.get("", response_model=ReportOut)
async def report(
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
    scope: str = Query("monthly", pattern="^(weekly|monthly|yearly)$"),
    anchor: Optional[datetime] = None,
):
    start, end = _period(scope, anchor)
    base = (
        select(Transaction)
        .where(
            Transaction.household_id == member.household_id,
            Transaction.deleted_at.is_(None),
            Transaction.status == "confirmed",
            Transaction.occurred_at >= start,
            Transaction.occurred_at < end,
        )
    )

    # Totals by kind
    sums = await session.execute(
        select(Transaction.kind, func.coalesce(func.sum(Transaction.amount), 0))
        .where(
            Transaction.household_id == member.household_id,
            Transaction.deleted_at.is_(None),
            Transaction.status == "confirmed",
            Transaction.occurred_at >= start,
            Transaction.occurred_at < end,
        )
        .group_by(Transaction.kind)
    )
    by_kind = {k: Decimal(v) for k, v in sums.all()}
    total_expense = by_kind.get("expense", Decimal("0"))
    total_income = by_kind.get("income", Decimal("0"))

    # By category
    rows = await session.execute(
        select(
            Transaction.category_id,
            Transaction.kind,
            func.count().label("cnt"),
            func.sum(Transaction.amount).label("total"),
            Category.slug,
            Category.label,
            Category.color,
        )
        .join(Category, Category.id == Transaction.category_id, isouter=True)
        .where(
            Transaction.household_id == member.household_id,
            Transaction.deleted_at.is_(None),
            Transaction.status == "confirmed",
            Transaction.occurred_at >= start,
            Transaction.occurred_at < end,
        )
        .group_by(Transaction.category_id, Transaction.kind, Category.slug, Category.label, Category.color)
        .order_by(func.sum(Transaction.amount).desc())
    )
    by_category: list[CategoryAggregate] = []
    for r in rows.all():
        by_category.append(
            CategoryAggregate(
                category_id=r.category_id,
                category_slug=r.slug,
                category_label=r.label,
                color=r.color,
                kind=r.kind,
                count=int(r.cnt),
                total=Decimal(r.total or 0),
            )
        )

    # By member
    mrows = await session.execute(
        select(
            Transaction.actor_user_id,
            Transaction.kind,
            func.sum(Transaction.amount),
            HM.nickname,
            HM.avatar_color,
        )
        .join(
            HM,
            (HM.user_id == Transaction.actor_user_id) & (HM.household_id == Transaction.household_id),
            isouter=True,
        )
        .where(
            Transaction.household_id == member.household_id,
            Transaction.deleted_at.is_(None),
            Transaction.status == "confirmed",
            Transaction.occurred_at >= start,
            Transaction.occurred_at < end,
        )
        .group_by(Transaction.actor_user_id, Transaction.kind, HM.nickname, HM.avatar_color)
    )
    members_map: dict = {}
    for actor, kind, amt, nickname, color in mrows.all():
        if actor is None:
            continue
        m = members_map.setdefault(
            actor, {"user_id": actor, "nickname": nickname, "avatar_color": color, "expense": Decimal("0"), "income": Decimal("0")}
        )
        m[kind] = Decimal(amt or 0)
    by_member = [MemberAggregate(**v) for v in members_map.values()]

    # Daily points
    drows = await session.execute(
        select(
            func.date(func.timezone("Europe/Istanbul", Transaction.occurred_at)).label("d"),
            Transaction.kind,
            func.sum(Transaction.amount),
        )
        .where(
            Transaction.household_id == member.household_id,
            Transaction.deleted_at.is_(None),
            Transaction.status == "confirmed",
            Transaction.occurred_at >= start,
            Transaction.occurred_at < end,
        )
        .group_by("d", Transaction.kind)
        .order_by("d")
    )
    daily_map: dict[str, dict[str, Decimal]] = {}
    for d, kind, amt in drows.all():
        bucket = daily_map.setdefault(str(d), {"expense": Decimal("0"), "income": Decimal("0")})
        bucket[kind] = Decimal(amt or 0)
    daily = [DailyPoint(date=k, expense=v["expense"], income=v["income"]) for k, v in sorted(daily_map.items())]

    return ReportOut(
        period=ReportPeriod(start=start, end=end),
        total_expense=total_expense,
        total_income=total_income,
        balance=total_income - total_expense,
        by_category=by_category,
        by_member=by_member,
        daily=daily,
    )
