from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_session
from ..deps import get_current_household
from ..models import Category, HouseholdMember
from ..schemas import CategoryCreateIn, CategoryOut, CategoryPatch

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryOut])
async def list_categories(
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    res = await session.execute(
        select(Category)
        .where(Category.household_id == member.household_id, Category.is_archived.is_(False))
        .order_by(Category.kind, Category.sort_order, Category.label)
    )
    return list(res.scalars().all())


@router.post("", response_model=CategoryOut, status_code=status.HTTP_201_CREATED)
async def create_category(
    body: CategoryCreateIn,
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    if member.role not in ("owner", "admin", "member"):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "not allowed")
    cat = Category(household_id=member.household_id, **body.model_dump())
    session.add(cat)
    try:
        await session.commit()
    except Exception as exc:
        await session.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, "slug already exists") from exc
    return cat


@router.patch("/{category_id}", response_model=CategoryOut)
async def patch_category(
    category_id: UUID,
    body: CategoryPatch,
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    cat = await session.get(Category, category_id)
    if cat is None or cat.household_id != member.household_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    data = body.model_dump(exclude_unset=True)
    for k, v in data.items():
        setattr(cat, k, v)
    await session.commit()
    return cat


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def archive_category(
    category_id: UUID,
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
):
    cat = await session.get(Category, category_id)
    if cat is None or cat.household_id != member.household_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    cat.is_archived = True
    await session.commit()
