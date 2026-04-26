import hashlib
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession

from uuid import UUID

from ..config import get_settings
from ..db import get_session
from ..models import Household, HouseholdInvite, HouseholdMember, RefreshToken, User
from ..schemas import LoginIn, RegisterIn, TokenOut, UserOut, UserPatch
from ..security import hash_password, make_access_token, verify_password
from ..deps import get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])
_settings = get_settings()


def _hash_refresh(t: str) -> str:
    return hashlib.sha256(t.encode("utf-8")).hexdigest()


async def _issue_tokens(session: AsyncSession, user: User, household_id) -> TokenOut:
    access = make_access_token(user_id=user.id, household_id=household_id)
    raw_refresh = secrets.token_urlsafe(48)
    refresh = RefreshToken(
        user_id=user.id,
        token_hash=_hash_refresh(raw_refresh),
        expires_at=datetime.now(timezone.utc) + timedelta(days=_settings.refresh_token_ttl_days),
    )
    session.add(refresh)
    await session.commit()
    return TokenOut(access_token=access, refresh_token=raw_refresh)


@router.post("/register", response_model=TokenOut)
async def register(body: RegisterIn, session: AsyncSession = Depends(get_session)):
    existing = await session.execute(select(User).where(User.email == body.email))
    if existing.scalar_one_or_none() is not None:
        raise HTTPException(status.HTTP_409_CONFLICT, "email already registered")

    if body.invite_code and body.household_name:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Pick one: invite_code (join existing) or household_name (create new). Not both.",
        )

    invite: HouseholdInvite | None = None
    if body.invite_code:
        res = await session.execute(
            select(HouseholdInvite).where(HouseholdInvite.code == body.invite_code)
        )
        invite = res.scalar_one_or_none()
        if invite is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "invalid invite code")
        if invite.expires_at < datetime.now(timezone.utc) or invite.accepted_at is not None:
            raise HTTPException(status.HTTP_410_GONE, "invite expired or used")

    user = User(
        email=body.email,
        password_hash=hash_password(body.password),
        display_name=body.display_name,
        avatar_color="#E8B5A0",
    )
    session.add(user)
    await session.flush()

    household_id: UUID | None = None

    if invite is not None:
        # Join the inviter's household — do not create a new one for this user.
        session.add(
            HouseholdMember(
                household_id=invite.household_id,
                user_id=user.id,
                role=invite.role,
                nickname=body.display_name.split(" ")[0],
                avatar_color="#E8B5A0",
            )
        )
        invite.accepted_by = user.id
        invite.accepted_at = datetime.now(timezone.utc)
        household_id = invite.household_id
    elif body.household_name:
        # Create a brand new household and seat the user as owner.
        household = Household(
            name=body.household_name, created_by=user.id, monthly_budget=18000
        )
        session.add(household)
        await session.flush()
        session.add(
            HouseholdMember(
                household_id=household.id,
                user_id=user.id,
                role="owner",
                nickname=body.display_name.split(" ")[0],
                avatar_color="#E8B5A0",
            )
        )
        await session.execute(
            text(f"SELECT {_settings.database_schema}.seed_default_categories(:hh)"),
            {"hh": household.id},
        )
        household_id = household.id
    # else: user has no household yet — the app will route them to onboarding.

    await session.commit()
    return await _issue_tokens(session, user, household_id)


@router.post("/login", response_model=TokenOut)
async def login(body: LoginIn, session: AsyncSession = Depends(get_session)):
    res = await session.execute(select(User).where(User.email == body.email))
    user = res.scalar_one_or_none()
    if user is None or user.deleted_at is not None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid credentials")
    if not verify_password(body.password, user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid credentials")
    user.last_login_at = datetime.now(timezone.utc)

    res = await session.execute(
        select(HouseholdMember).where(HouseholdMember.user_id == user.id).limit(1)
    )
    member = res.scalar_one_or_none()
    return await _issue_tokens(session, user, member.household_id if member else None)


@router.post("/refresh", response_model=TokenOut)
async def refresh(refresh_token: str, session: AsyncSession = Depends(get_session)):
    th = _hash_refresh(refresh_token)
    res = await session.execute(select(RefreshToken).where(RefreshToken.token_hash == th))
    rt = res.scalar_one_or_none()
    if rt is None or rt.revoked_at is not None or rt.expires_at < datetime.now(timezone.utc):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "refresh expired or invalid")
    user = await session.get(User, rt.user_id)
    if user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "user gone")
    rt.revoked_at = datetime.now(timezone.utc)
    res = await session.execute(
        select(HouseholdMember).where(HouseholdMember.user_id == user.id).limit(1)
    )
    member = res.scalar_one_or_none()
    return await _issue_tokens(session, user, member.household_id if member else None)


@router.get("/me", response_model=UserOut)
async def me(user: User = Depends(get_current_user)):
    return user


@router.patch("/me", response_model=UserOut)
async def patch_me(
    body: UserPatch,
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    data = body.model_dump(exclude_unset=True)
    for k, v in data.items():
        setattr(user, k, v)
    await session.commit()
    return user


@router.post("/logout", status_code=204)
async def logout(refresh_token: str | None = None, session: AsyncSession = Depends(get_session)):
    """Revoke a refresh token (client should also drop access token)."""
    if refresh_token:
        th = _hash_refresh(refresh_token)
        res = await session.execute(select(RefreshToken).where(RefreshToken.token_hash == th))
        rt = res.scalar_one_or_none()
        if rt and rt.revoked_at is None:
            rt.revoked_at = datetime.now(timezone.utc)
            await session.commit()
