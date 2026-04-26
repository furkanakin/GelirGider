"""AI endpoints — text classify, voice transcript classify, receipt OCR extract.

Voice transcription happens client-side (Flutter speech_to_text + on-device speech recognition).
Receipt OCR happens client-side (Flutter google_mlkit_text_recognition).
The server only receives the resulting TEXT and asks the LLM to extract a structured
list of transactions, returning a `job_id` the client can use when creating transactions.
"""
from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_session
from ..deps import get_current_household, get_current_user
from ..llm import LLMClient, LLMError, SYSTEM_EXTRACTOR, get_llm
from ..models import AIJob, Category, HouseholdMember, User
from ..schemas import AIExtractedLine, AIExtractedReceipt, ClassifyTextIn, OCRIn

router = APIRouter(prefix="/ai", tags=["ai"])


def _user_prompt(text: str, hint: str | None = None) -> str:
    parts = []
    if hint:
        parts.append(f"Bağlam: {hint}")
    parts.append(f"Kullanıcı girdisi:\n{text.strip()}")
    return "\n\n".join(parts)


async def _resolve_categories(slug_set: set[str], household_id, session: AsyncSession) -> dict[str, Category]:
    if not slug_set:
        return {}
    res = await session.execute(
        select(Category).where(Category.household_id == household_id, Category.slug.in_(slug_set))
    )
    return {c.slug: c for c in res.scalars().all()}


def _coerce_lines(parsed: dict) -> list[dict]:
    """LLM may sometimes return {"transactions": [...]} or a single line — normalize."""
    if isinstance(parsed, dict):
        for key in ("lines", "transactions", "items"):
            if isinstance(parsed.get(key), list):
                return parsed[key]
        if "amount" in parsed:
            return [parsed]
    return []


async def _extract(
    *,
    text: str,
    hint: str | None,
    model: str | None,
    kind_hint: str,
    user: User,
    member: HouseholdMember,
    session: AsyncSession,
    llm: LLMClient,
) -> AIExtractedReceipt:
    job = AIJob(
        household_id=member.household_id,
        user_id=user.id,
        kind=kind_hint,
        status="running",
        model=model or "auto",
        input_text=text,
    )
    session.add(job)
    await session.flush()
    try:
        parsed, meta = await llm.chat_json(
            system=SYSTEM_EXTRACTOR,
            user=_user_prompt(text, hint),
            model=model,
        )
    except LLMError as exc:
        job.status = "failed"
        job.error = str(exc)
        job.completed_at = datetime.now(timezone.utc)
        await session.commit()
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, str(exc)) from exc

    lines_raw = _coerce_lines(parsed)
    summary = parsed.get("summary") if isinstance(parsed, dict) else None

    slugs = {ln.get("category_slug") for ln in lines_raw if ln.get("category_slug")}
    cats = await _resolve_categories(slugs, member.household_id, session)

    extracted: list[AIExtractedLine] = []
    for ln in lines_raw:
        try:
            amount = Decimal(str(ln.get("amount")))
        except Exception:
            continue
        slug = ln.get("category_slug")
        if slug and slug not in cats:
            slug = None
        extracted.append(
            AIExtractedLine(
                merchant=ln.get("merchant") or None,
                amount=amount,
                currency=ln.get("currency") or "TRY",
                kind=ln.get("kind") or "expense",
                category_slug=slug,
                actor_nickname=ln.get("actor_nickname"),
                note=ln.get("note"),
                confidence=Decimal(str(ln.get("confidence"))) if ln.get("confidence") is not None else None,
                occurred_at=None,
            )
        )

    job.status = "succeeded"
    job.output = {
        "summary": summary,
        "lines": [ln.model_dump(mode="json") for ln in extracted],
    }
    job.model = meta.get("model") or model or "auto"
    job.latency_ms = meta.get("latency_ms")
    job.tokens_in = meta.get("tokens_in")
    job.tokens_out = meta.get("tokens_out")
    job.completed_at = datetime.now(timezone.utc)
    await session.commit()

    return AIExtractedReceipt(
        job_id=job.id,
        model=job.model,
        lines=extracted,
        raw_text=text,
        summary=summary,
    )


@router.post("/classify-text", response_model=AIExtractedReceipt)
async def classify_text(
    body: ClassifyTextIn,
    user: Annotated[User, Depends(get_current_user)],
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
    llm: LLMClient = Depends(get_llm),
):
    return await _extract(
        text=body.text, hint=None, model=body.model,
        kind_hint="classify_text", user=user, member=member,
        session=session, llm=llm,
    )


@router.post("/extract-receipt", response_model=AIExtractedReceipt)
async def extract_receipt(
    body: OCRIn,
    user: Annotated[User, Depends(get_current_user)],
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
    llm: LLMClient = Depends(get_llm),
):
    return await _extract(
        text=body.text, hint=body.hint or "fiş/fatura OCR çıktısı",
        model=body.model, kind_hint="extract_receipt",
        user=user, member=member, session=session, llm=llm,
    )


@router.post("/transcribe-voice", response_model=AIExtractedReceipt)
async def transcribe_voice(
    body: OCRIn,
    user: Annotated[User, Depends(get_current_user)],
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
    llm: LLMClient = Depends(get_llm),
):
    """Client transcribes voice locally; we only classify the resulting text."""
    return await _extract(
        text=body.text, hint=body.hint or "sesli kayıt transkripti",
        model=body.model, kind_hint="transcribe_voice",
        user=user, member=member, session=session, llm=llm,
    )
