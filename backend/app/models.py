from datetime import datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.dialects.postgresql import CITEXT, ENUM as PgEnum, INET, JSONB, UUID as PgUUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship

from .config import get_settings

_settings = get_settings()
_schema = _settings.database_schema


def _enum(name: str, *values: str):
    """Bind to a Postgres ENUM type that already exists in the DB."""
    return PgEnum(*values, name=name, schema=_schema, create_type=False, native_enum=True, validate_strings=True)


household_role_enum = _enum("household_role", "owner", "admin", "member", "child")
account_type_enum = _enum("account_type", "cash", "bank", "credit_card", "savings")
tx_kind_enum = _enum("tx_kind", "expense", "income")
tx_source_enum = _enum("tx_source", "text", "voice", "photo", "manual", "auto", "recurring")
tx_status_enum = _enum("tx_status", "pending_review", "confirmed", "archived")
attachment_kind_enum = _enum("attachment_kind", "receipt", "invoice", "photo", "audio")
ai_job_kind_enum = _enum("ai_job_kind", "classify_text", "transcribe_voice", "extract_receipt", "summarize_period")
ai_job_status_enum = _enum("ai_job_status", "pending", "running", "succeeded", "failed")
recurring_cadence_enum = _enum("recurring_cadence", "daily", "weekly", "monthly", "yearly")
notification_kind_enum = _enum("notification_kind", "budget_warning", "recurring_due", "invite_accepted", "tip", "generic")


class Base(DeclarativeBase):
    metadata_args = {"schema": _schema}


def _uuid_pk():
    return mapped_column(PgUUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))


def _timestamp(server_default: bool = True):
    if server_default:
        return mapped_column(DateTime(timezone=True), nullable=False, server_default=text("now()"))
    return mapped_column(DateTime(timezone=True), nullable=True)


# ==================================================================
# USERS
# ==================================================================
class User(Base):
    __tablename__ = "users"
    __table_args__ = {"schema": _settings.database_schema}

    id: Mapped[UUID] = _uuid_pk()
    email: Mapped[str] = mapped_column(CITEXT, unique=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(Text, nullable=False)
    display_name: Mapped[str] = mapped_column(Text, nullable=False)
    avatar_color: Mapped[str | None] = mapped_column(Text)
    locale: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'tr-TR'"))
    timezone: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'Europe/Istanbul'"))
    preferred_llm: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'qwen3-coder-next'"))
    created_at: Mapped[datetime] = _timestamp()
    updated_at: Mapped[datetime] = _timestamp()
    last_login_at: Mapped[datetime | None] = _timestamp(server_default=False)
    deleted_at: Mapped[datetime | None] = _timestamp(server_default=False)


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"
    __table_args__ = {"schema": _settings.database_schema}

    id: Mapped[UUID] = _uuid_pk()
    user_id: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True), ForeignKey(f"{_settings.database_schema}.users.id", ondelete="CASCADE"), nullable=False
    )
    token_hash: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    user_agent: Mapped[str | None] = mapped_column(Text)
    ip_address: Mapped[str | None] = mapped_column(INET)
    created_at: Mapped[datetime] = _timestamp()
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoked_at: Mapped[datetime | None] = _timestamp(server_default=False)


# ==================================================================
# HOUSEHOLD
# ==================================================================
class Household(Base):
    __tablename__ = "households"
    __table_args__ = {"schema": _settings.database_schema}

    id: Mapped[UUID] = _uuid_pk()
    name: Mapped[str] = mapped_column(Text, nullable=False)
    currency: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'TRY'"))
    monthly_budget: Mapped[Decimal | None] = mapped_column(Numeric(14, 2))
    created_by: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True), ForeignKey(f"{_settings.database_schema}.users.id"), nullable=False
    )
    created_at: Mapped[datetime] = _timestamp()
    updated_at: Mapped[datetime] = _timestamp()


class HouseholdMember(Base):
    __tablename__ = "household_members"
    __table_args__ = {"schema": _settings.database_schema}

    household_id: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True),
        ForeignKey(f"{_settings.database_schema}.households.id", ondelete="CASCADE"),
        primary_key=True,
    )
    user_id: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True),
        ForeignKey(f"{_settings.database_schema}.users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    role: Mapped[str] = mapped_column(household_role_enum, nullable=False, server_default=text("'member'"))
    nickname: Mapped[str | None] = mapped_column(Text)
    avatar_color: Mapped[str | None] = mapped_column(Text)
    joined_at: Mapped[datetime] = _timestamp()


class HouseholdInvite(Base):
    __tablename__ = "household_invites"
    __table_args__ = {"schema": _settings.database_schema}

    id: Mapped[UUID] = _uuid_pk()
    household_id: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True),
        ForeignKey(f"{_settings.database_schema}.households.id", ondelete="CASCADE"),
        nullable=False,
    )
    code: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    role: Mapped[str] = mapped_column(household_role_enum, nullable=False, server_default=text("'member'"))
    invited_email: Mapped[str | None] = mapped_column(CITEXT)
    invited_by: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True), ForeignKey(f"{_settings.database_schema}.users.id"), nullable=False
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    accepted_by: Mapped[UUID | None] = mapped_column(
        PgUUID(as_uuid=True), ForeignKey(f"{_settings.database_schema}.users.id")
    )
    accepted_at: Mapped[datetime | None] = _timestamp(server_default=False)
    created_at: Mapped[datetime] = _timestamp()


# ==================================================================
# ACCOUNTS / CATEGORIES
# ==================================================================
class Account(Base):
    __tablename__ = "accounts"
    __table_args__ = {"schema": _settings.database_schema}

    id: Mapped[UUID] = _uuid_pk()
    household_id: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True),
        ForeignKey(f"{_settings.database_schema}.households.id", ondelete="CASCADE"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(Text, nullable=False)
    type: Mapped[str] = mapped_column(account_type_enum, nullable=False, server_default=text("'cash'"))
    currency: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'TRY'"))
    starting_balance: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False, server_default=text("0"))
    is_archived: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("FALSE"))
    created_at: Mapped[datetime] = _timestamp()
    updated_at: Mapped[datetime] = _timestamp()


class Category(Base):
    __tablename__ = "categories"
    __table_args__ = (
        UniqueConstraint("household_id", "slug"),
        {"schema": _settings.database_schema},
    )

    id: Mapped[UUID] = _uuid_pk()
    household_id: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True),
        ForeignKey(f"{_settings.database_schema}.households.id", ondelete="CASCADE"),
        nullable=False,
    )
    slug: Mapped[str] = mapped_column(Text, nullable=False)
    label: Mapped[str] = mapped_column(Text, nullable=False)
    kind: Mapped[str] = mapped_column(tx_kind_enum, nullable=False)
    icon: Mapped[str] = mapped_column(Text, nullable=False)
    color: Mapped[str] = mapped_column(Text, nullable=False)
    tint: Mapped[str] = mapped_column(Text, nullable=False)
    monthly_budget: Mapped[Decimal | None] = mapped_column(Numeric(14, 2))
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    is_archived: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("FALSE"))
    created_at: Mapped[datetime] = _timestamp()


# ==================================================================
# TRANSACTIONS / ATTACHMENTS / AI JOBS
# ==================================================================
class Transaction(Base):
    __tablename__ = "transactions"
    __table_args__ = (
        CheckConstraint("amount > 0"),
        {"schema": _settings.database_schema},
    )

    id: Mapped[UUID] = _uuid_pk()
    household_id: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True),
        ForeignKey(f"{_settings.database_schema}.households.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_id: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True), ForeignKey(f"{_settings.database_schema}.users.id"), nullable=False
    )
    actor_user_id: Mapped[UUID | None] = mapped_column(
        PgUUID(as_uuid=True), ForeignKey(f"{_settings.database_schema}.users.id")
    )
    account_id: Mapped[UUID | None] = mapped_column(
        PgUUID(as_uuid=True), ForeignKey(f"{_settings.database_schema}.accounts.id", ondelete="SET NULL")
    )
    category_id: Mapped[UUID | None] = mapped_column(
        PgUUID(as_uuid=True), ForeignKey(f"{_settings.database_schema}.categories.id", ondelete="SET NULL")
    )
    kind: Mapped[str] = mapped_column(tx_kind_enum, nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    currency: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'TRY'"))
    merchant: Mapped[str | None] = mapped_column(Text)
    note: Mapped[str | None] = mapped_column(Text)
    occurred_at: Mapped[datetime] = _timestamp()
    source: Mapped[str] = mapped_column(tx_source_enum, nullable=False, server_default=text("'manual'"))
    status: Mapped[str] = mapped_column(tx_status_enum, nullable=False, server_default=text("'confirmed'"))
    ai_job_id: Mapped[UUID | None] = mapped_column(PgUUID(as_uuid=True))
    ai_confidence: Mapped[Decimal | None] = mapped_column(Numeric(4, 3))
    metadata_: Mapped[dict] = mapped_column("metadata", JSONB, nullable=False, server_default=text("'{}'::jsonb"))
    created_at: Mapped[datetime] = _timestamp()
    updated_at: Mapped[datetime] = _timestamp()
    deleted_at: Mapped[datetime | None] = _timestamp(server_default=False)


class Attachment(Base):
    __tablename__ = "attachments"
    __table_args__ = {"schema": _settings.database_schema}

    id: Mapped[UUID] = _uuid_pk()
    household_id: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True),
        ForeignKey(f"{_settings.database_schema}.households.id", ondelete="CASCADE"),
        nullable=False,
    )
    transaction_id: Mapped[UUID | None] = mapped_column(
        PgUUID(as_uuid=True),
        ForeignKey(f"{_settings.database_schema}.transactions.id", ondelete="CASCADE"),
    )
    user_id: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True), ForeignKey(f"{_settings.database_schema}.users.id"), nullable=False
    )
    kind: Mapped[str] = mapped_column(attachment_kind_enum, nullable=False)
    storage_key: Mapped[str] = mapped_column(Text, nullable=False)
    mime_type: Mapped[str] = mapped_column(Text, nullable=False)
    size_bytes: Mapped[int] = mapped_column(BigInteger, nullable=False)
    sha256: Mapped[str | None] = mapped_column(Text)
    ocr_text: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = _timestamp()


class AIJob(Base):
    __tablename__ = "ai_jobs"
    __table_args__ = {"schema": _settings.database_schema}

    id: Mapped[UUID] = _uuid_pk()
    household_id: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True),
        ForeignKey(f"{_settings.database_schema}.households.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_id: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True), ForeignKey(f"{_settings.database_schema}.users.id"), nullable=False
    )
    kind: Mapped[str] = mapped_column(ai_job_kind_enum, nullable=False)
    status: Mapped[str] = mapped_column(ai_job_status_enum, nullable=False, server_default=text("'pending'"))
    model: Mapped[str] = mapped_column(Text, nullable=False)
    input_text: Mapped[str | None] = mapped_column(Text)
    input_attachment_id: Mapped[UUID | None] = mapped_column(
        PgUUID(as_uuid=True),
        ForeignKey(f"{_settings.database_schema}.attachments.id", ondelete="SET NULL"),
    )
    output: Mapped[dict | None] = mapped_column(JSONB)
    error: Mapped[str | None] = mapped_column(Text)
    latency_ms: Mapped[int | None] = mapped_column(Integer)
    cost_usd: Mapped[Decimal | None] = mapped_column(Numeric(10, 6))
    tokens_in: Mapped[int | None] = mapped_column(Integer)
    tokens_out: Mapped[int | None] = mapped_column(Integer)
    created_at: Mapped[datetime] = _timestamp()
    completed_at: Mapped[datetime | None] = _timestamp(server_default=False)


class RecurringTemplate(Base):
    __tablename__ = "recurring_templates"
    __table_args__ = {"schema": _settings.database_schema}

    id: Mapped[UUID] = _uuid_pk()
    household_id: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True),
        ForeignKey(f"{_settings.database_schema}.households.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_id: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True), ForeignKey(f"{_settings.database_schema}.users.id"), nullable=False
    )
    actor_user_id: Mapped[UUID | None] = mapped_column(
        PgUUID(as_uuid=True), ForeignKey(f"{_settings.database_schema}.users.id")
    )
    category_id: Mapped[UUID | None] = mapped_column(
        PgUUID(as_uuid=True), ForeignKey(f"{_settings.database_schema}.categories.id", ondelete="SET NULL")
    )
    account_id: Mapped[UUID | None] = mapped_column(
        PgUUID(as_uuid=True), ForeignKey(f"{_settings.database_schema}.accounts.id", ondelete="SET NULL")
    )
    label: Mapped[str] = mapped_column(Text, nullable=False)
    kind: Mapped[str] = mapped_column(tx_kind_enum, nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    currency: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'TRY'"))
    cadence: Mapped[str] = mapped_column(recurring_cadence_enum, nullable=False)
    day_of_period: Mapped[int | None] = mapped_column(Integer)
    starts_on: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=text("CURRENT_DATE"))
    ends_on: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_run_on: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    is_paused: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("FALSE"))
    note: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = _timestamp()
    updated_at: Mapped[datetime] = _timestamp()


class Notification(Base):
    __tablename__ = "notifications"
    __table_args__ = {"schema": _settings.database_schema}

    id: Mapped[UUID] = _uuid_pk()
    user_id: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True), ForeignKey(f"{_settings.database_schema}.users.id", ondelete="CASCADE"), nullable=False
    )
    household_id: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True),
        ForeignKey(f"{_settings.database_schema}.households.id", ondelete="CASCADE"),
        nullable=False,
    )
    kind: Mapped[str] = mapped_column(notification_kind_enum, nullable=False, server_default=text("'generic'"))
    title: Mapped[str] = mapped_column(Text, nullable=False)
    body: Mapped[str | None] = mapped_column(Text)
    payload: Mapped[dict] = mapped_column(JSONB, nullable=False, server_default=text("'{}'::jsonb"))
    is_read: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("FALSE"))
    created_at: Mapped[datetime] = _timestamp()
    read_at: Mapped[datetime | None] = _timestamp(server_default=False)


class QuickEntry(Base):
    __tablename__ = "quick_entries"
    __table_args__ = {"schema": _settings.database_schema}

    id: Mapped[UUID] = _uuid_pk()
    household_id: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True),
        ForeignKey(f"{_settings.database_schema}.households.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_id: Mapped[UUID] = mapped_column(
        PgUUID(as_uuid=True), ForeignKey(f"{_settings.database_schema}.users.id"), nullable=False
    )
    label: Mapped[str] = mapped_column(Text, nullable=False)
    category_id: Mapped[UUID | None] = mapped_column(
        PgUUID(as_uuid=True), ForeignKey(f"{_settings.database_schema}.categories.id")
    )
    typical_amount: Mapped[Decimal | None] = mapped_column(Numeric(14, 2))
    use_count: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    last_used_at: Mapped[datetime | None] = _timestamp(server_default=False)
    created_at: Mapped[datetime] = _timestamp()
