"""AI endpoints — text classify, voice transcribe, photo extract.

Voice and photo are uploaded as multipart files now:
  * `/ai/voice/transcribe`  → Whisper-style STT on the gateway, then LLM extract
  * `/ai/photo/extract`     → Vision LLM directly reads the image

The legacy text-only endpoints (`/ai/transcribe-voice`, `/ai/extract-receipt`)
remain for backwards compatibility — older clients post the already-recognized
text and we just classify it.
"""
from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal
from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..config import get_settings
from ..db import get_session
from ..deps import get_current_household, get_current_user
from ..llm import LLMClient, LLMError, SYSTEM_EXTRACTOR, SYSTEM_VISION_EXTRACTOR, get_llm
from ..models import AIJob, Category, HouseholdMember, User
from ..schemas import AIExtractedLine, AIExtractedReceipt, ClassifyTextIn, OCRIn

router = APIRouter(prefix="/ai", tags=["ai"])
_settings = get_settings()


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


async def _materialize(
    *,
    parsed: dict,
    meta: dict,
    raw_text: str | None,
    job: AIJob,
    member: HouseholdMember,
    session: AsyncSession,
) -> AIExtractedReceipt:
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
    job.model = meta.get("model") or job.model or "auto"
    job.latency_ms = meta.get("latency_ms")
    job.tokens_in = meta.get("tokens_in")
    job.tokens_out = meta.get("tokens_out")
    job.completed_at = datetime.now(timezone.utc)
    await session.commit()

    return AIExtractedReceipt(
        job_id=job.id,
        model=job.model,
        lines=extracted,
        raw_text=raw_text,
        summary=summary,
    )


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
    return await _materialize(
        parsed=parsed, meta=meta, raw_text=text, job=job, member=member, session=session
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
    """Legacy: client sent OCR text. Kept for old clients; new client uses /photo/extract."""
    return await _extract(
        text=body.text, hint=body.hint or "fiş/fatura OCR çıktısı",
        model=body.model, kind_hint="extract_receipt",
        user=user, member=member, session=session, llm=llm,
    )


@router.post("/transcribe-voice", response_model=AIExtractedReceipt)
async def transcribe_voice_legacy(
    body: OCRIn,
    user: Annotated[User, Depends(get_current_user)],
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
    llm: LLMClient = Depends(get_llm),
):
    """Legacy: client transcribed locally. Kept; new client uses /voice/transcribe."""
    return await _extract(
        text=body.text, hint=body.hint or "sesli kayıt transkripti",
        model=body.model, kind_hint="transcribe_voice",
        user=user, member=member, session=session, llm=llm,
    )


# ----- New file-upload endpoints -----------------------------------------------

_MAX_AUDIO_MB = 20
_MAX_IMAGE_MB = 12


@router.post("/voice/transcribe", response_model=AIExtractedReceipt)
async def voice_transcribe(
    file: UploadFile = File(...),
    model: str | None = Form(None),
    user: User = Depends(get_current_user),
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
    llm: LLMClient = Depends(get_llm),
):
    audio = await file.read()
    if not audio:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "empty audio")
    if len(audio) > _MAX_AUDIO_MB * 1024 * 1024:
        raise HTTPException(status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, "audio too large")

    job = AIJob(
        household_id=member.household_id,
        user_id=user.id,
        kind="transcribe_voice",
        status="running",
        model=model or "auto",
        input_text=None,
    )
    session.add(job)
    await session.flush()

    try:
        transcript, stt_meta = await llm.transcribe_audio(
            audio_bytes=audio,
            filename=file.filename or "audio.webm",
            content_type=file.content_type or "audio/webm",
            language="tr",
        )
    except LLMError as exc:
        job.status = "failed"
        job.error = f"stt: {exc}"
        job.completed_at = datetime.now(timezone.utc)
        await session.commit()
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, f"stt: {exc}") from exc

    job.input_text = transcript
    await session.flush()

    try:
        parsed, meta = await llm.chat_json(
            system=SYSTEM_EXTRACTOR,
            user=_user_prompt(transcript, "sesli kayıt transkripti"),
            model=model,
        )
    except LLMError as exc:
        job.status = "failed"
        job.error = f"extract: {exc}"
        job.completed_at = datetime.now(timezone.utc)
        await session.commit()
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, f"extract: {exc}") from exc

    # carry the STT model through latency-wise; report extract model in `meta.model`.
    meta.setdefault("stt_model", stt_meta.get("model"))
    return await _materialize(
        parsed=parsed, meta=meta, raw_text=transcript, job=job, member=member, session=session
    )


@router.post("/photo/extract", response_model=AIExtractedReceipt)
async def photo_extract(
    file: UploadFile = File(...),
    hint: str | None = Form(None),
    model: str | None = Form(None),
    user: User = Depends(get_current_user),
    member: HouseholdMember = Depends(get_current_household),
    session: AsyncSession = Depends(get_session),
    llm: LLMClient = Depends(get_llm),
):
    image = await file.read()
    if not image:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "empty image")
    if len(image) > _MAX_IMAGE_MB * 1024 * 1024:
        raise HTTPException(status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, "image too large")

    job = AIJob(
        household_id=member.household_id,
        user_id=user.id,
        kind="extract_receipt",
        status="running",
        model=model or _settings.llm_vision_model,
        input_text=hint,
    )
    session.add(job)
    await session.flush()

    try:
        parsed, meta = await llm.chat_json_with_image(
            system=SYSTEM_VISION_EXTRACTOR,
            user_text=f"Bağlam: {hint or 'fiş/fatura'}\n\nGörseldeki bilgileri çıkart.",
            image_bytes=image,
            image_mime=file.content_type or "image/jpeg",
            model=model,
        )
    except LLMError as exc:
        job.status = "failed"
        job.error = str(exc)
        job.completed_at = datetime.now(timezone.utc)
        await session.commit()
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, str(exc)) from exc

    return await _materialize(
        parsed=parsed, meta=meta, raw_text=None, job=job, member=member, session=session
    )
