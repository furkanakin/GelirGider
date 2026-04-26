from datetime import datetime
from decimal import Decimal
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class ORMModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)


# ----- Auth -----
class RegisterIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)
    display_name: str = Field(min_length=1, max_length=120)
    # Exactly one path is taken at registration:
    #   - household_name set (and invite_code empty) → create a brand new household
    #   - invite_code set (and household_name empty) → join the inviter's household
    # If both are empty the user is registered with no household and must pick a path
    # later from the in-app onboarding screen.
    household_name: Optional[str] = Field(default=None, min_length=1, max_length=120)
    invite_code: Optional[str] = Field(default=None, min_length=1, max_length=128)


class LoginIn(BaseModel):
    email: EmailStr
    password: str


class TokenOut(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserOut(ORMModel):
    id: UUID
    email: EmailStr
    display_name: str
    avatar_color: Optional[str] = None
    locale: str
    timezone: str
    preferred_llm: str


# ----- Profile patch -----
class UserPatch(BaseModel):
    display_name: Optional[str] = Field(default=None, min_length=1, max_length=120)
    avatar_color: Optional[str] = Field(default=None, max_length=16)
    locale: Optional[str] = Field(default=None, max_length=16)
    preferred_llm: Optional[str] = Field(default=None, max_length=64)


class HouseholdPatch(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=120)
    monthly_budget: Optional[Decimal] = Field(default=None, ge=0)
    currency: Optional[str] = Field(default=None, max_length=8)


# ----- Household -----
class HouseholdOut(ORMModel):
    id: UUID
    name: str
    currency: str
    monthly_budget: Optional[Decimal] = None


class HouseholdMemberOut(BaseModel):
    user_id: UUID
    display_name: str
    nickname: Optional[str] = None
    role: str
    avatar_color: Optional[str] = None


class HouseholdMemberPatch(BaseModel):
    nickname: Optional[str] = Field(default=None, max_length=80)
    avatar_color: Optional[str] = Field(default=None, max_length=16)
    role: Optional[Literal["admin", "member", "child"]] = None


class InviteCreateIn(BaseModel):
    email: Optional[EmailStr] = None
    role: Literal["admin", "member", "child"] = "member"


class InviteOut(BaseModel):
    code: str
    expires_at: datetime


class InviteAcceptIn(BaseModel):
    code: str


# ----- Category -----
class CategoryOut(ORMModel):
    id: UUID
    slug: str
    label: str
    kind: Literal["expense", "income"]
    icon: str
    color: str
    tint: str
    monthly_budget: Optional[Decimal] = None
    sort_order: int


class CategoryCreateIn(BaseModel):
    slug: str = Field(min_length=2, max_length=40, pattern=r"^[a-z][a-z0-9_]*$")
    label: str
    kind: Literal["expense", "income"]
    icon: str = "tag"
    color: str = "#7A6F65"
    tint: str = "#EFE8DA"
    monthly_budget: Optional[Decimal] = None


class CategoryPatch(BaseModel):
    label: Optional[str] = Field(default=None, min_length=1, max_length=80)
    icon: Optional[str] = None
    color: Optional[str] = None
    tint: Optional[str] = None
    monthly_budget: Optional[Decimal] = Field(default=None, ge=0)
    sort_order: Optional[int] = None


# ----- Account -----
class AccountIn(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    type: Literal["cash", "bank", "credit_card", "savings"] = "cash"
    currency: str = "TRY"
    starting_balance: Decimal = Field(default=Decimal("0"))


class AccountPatch(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=80)
    type: Optional[Literal["cash", "bank", "credit_card", "savings"]] = None
    starting_balance: Optional[Decimal] = None
    is_archived: Optional[bool] = None


class AccountOut(ORMModel):
    id: UUID
    name: str
    type: str
    currency: str
    starting_balance: Decimal
    is_archived: bool


# ----- Recurring template -----
class RecurringIn(BaseModel):
    label: str = Field(min_length=1, max_length=120)
    kind: Literal["expense", "income"]
    amount: Decimal = Field(gt=0)
    currency: str = "TRY"
    cadence: Literal["daily", "weekly", "monthly", "yearly"]
    day_of_period: Optional[int] = Field(default=None, ge=1, le=31)
    category_id: Optional[UUID] = None
    actor_user_id: Optional[UUID] = None
    account_id: Optional[UUID] = None
    note: Optional[str] = None


class RecurringPatch(BaseModel):
    label: Optional[str] = None
    amount: Optional[Decimal] = Field(default=None, gt=0)
    cadence: Optional[Literal["daily", "weekly", "monthly", "yearly"]] = None
    day_of_period: Optional[int] = None
    category_id: Optional[UUID] = None
    actor_user_id: Optional[UUID] = None
    account_id: Optional[UUID] = None
    note: Optional[str] = None
    is_paused: Optional[bool] = None


class RecurringOut(ORMModel):
    id: UUID
    label: str
    kind: Literal["expense", "income"]
    amount: Decimal
    currency: str
    cadence: str
    day_of_period: Optional[int] = None
    category_id: Optional[UUID] = None
    actor_user_id: Optional[UUID] = None
    account_id: Optional[UUID] = None
    note: Optional[str] = None
    is_paused: bool


# ----- Notifications -----
class NotificationOut(ORMModel):
    id: UUID
    kind: str
    title: str
    body: Optional[str]
    is_read: bool
    created_at: datetime


# ----- Transaction -----
class TransactionIn(BaseModel):
    kind: Literal["expense", "income"]
    amount: Decimal = Field(gt=0)
    currency: str = "TRY"
    category_id: Optional[UUID] = None
    actor_user_id: Optional[UUID] = None
    account_id: Optional[UUID] = None
    merchant: Optional[str] = None
    note: Optional[str] = None
    occurred_at: Optional[datetime] = None
    source: Literal["text", "voice", "photo", "manual", "auto", "recurring"] = "manual"
    ai_job_id: Optional[UUID] = None
    ai_confidence: Optional[Decimal] = None


class TransactionPatch(BaseModel):
    amount: Optional[Decimal] = Field(default=None, gt=0)
    category_id: Optional[UUID] = None
    actor_user_id: Optional[UUID] = None
    account_id: Optional[UUID] = None
    merchant: Optional[str] = None
    note: Optional[str] = None
    occurred_at: Optional[datetime] = None
    status: Optional[Literal["pending_review", "confirmed", "archived"]] = None


class TransactionOut(ORMModel):
    id: UUID
    kind: Literal["expense", "income"]
    amount: Decimal
    currency: str
    merchant: Optional[str] = None
    note: Optional[str] = None
    occurred_at: datetime
    source: str
    status: str
    category_id: Optional[UUID] = None
    actor_user_id: Optional[UUID] = None
    account_id: Optional[UUID] = None
    ai_confidence: Optional[Decimal] = None


# ----- AI -----
class ClassifyTextIn(BaseModel):
    text: str = Field(min_length=2, max_length=4000)
    model: Optional[str] = None


class AIExtractedLine(BaseModel):
    merchant: Optional[str] = None
    amount: Decimal
    currency: str = "TRY"
    kind: Literal["expense", "income"] = "expense"
    category_slug: Optional[str] = None
    actor_nickname: Optional[str] = None
    note: Optional[str] = None
    confidence: Optional[Decimal] = None
    occurred_at: Optional[datetime] = None


class AIExtractedReceipt(BaseModel):
    job_id: UUID
    model: str
    lines: list[AIExtractedLine]
    raw_text: Optional[str] = None
    summary: Optional[str] = None


class OCRIn(BaseModel):
    text: str = Field(min_length=2)
    model: Optional[str] = None
    hint: Optional[str] = Field(default=None, description="optional context, e.g. 'fiş', 'fatura'")


# ----- Reports -----
class ReportPeriod(BaseModel):
    start: datetime
    end: datetime


class CategoryAggregate(BaseModel):
    category_id: Optional[UUID]
    category_slug: Optional[str]
    category_label: Optional[str]
    color: Optional[str]
    kind: Literal["expense", "income"]
    total: Decimal
    count: int


class MemberAggregate(BaseModel):
    user_id: UUID
    nickname: Optional[str]
    avatar_color: Optional[str]
    expense: Decimal
    income: Decimal


class DailyPoint(BaseModel):
    date: str            # YYYY-MM-DD
    expense: Decimal
    income: Decimal


class ReportOut(BaseModel):
    period: ReportPeriod
    total_expense: Decimal
    total_income: Decimal
    balance: Decimal
    by_category: list[CategoryAggregate]
    by_member: list[MemberAggregate]
    daily: list[DailyPoint]
