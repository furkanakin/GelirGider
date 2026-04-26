"""LLM Gateway client — OpenAI-compatible.

The user can pick any model id supported by https://llmgateway.io. We accept any
slug the user picks in Settings; if the chosen model is rate-limited or
unavailable, we cascade through the configured fallback list.

This module handles three call types:
  * `chat_json`            — structured JSON extraction from text
  * `chat_json_with_image` — same, but with an inline image (multimodal)
  * `transcribe_audio`     — OpenAI-style /audio/transcriptions for voice
"""
from __future__ import annotations

import base64
import json
import logging
import time
from typing import Any

import httpx

from .config import get_settings

logger = logging.getLogger(__name__)
_settings = get_settings()


CATEGORY_SCHEMA_HINT = (
    "Available expense categories (slug → label):\n"
    "- market: Market\n"
    "- fatura: Faturalar\n"
    "- ulasim: Ulaşım\n"
    "- yemek: Yemek\n"
    "- cocuk: Çocuklar\n"
    "- saglik: Sağlık\n"
    "- eglence: Eğlence\n"
    "- kira: Kira\n"
    "Income categories:\n"
    "- maas: Maaş\n"
    "- ek: Ek Gelir\n"
)


SYSTEM_EXTRACTOR = f"""You are a Turkish household-finance assistant for the Evimiz app.

Given a user's free-form text OR an OCR-extracted receipt, return a strict JSON object with ALL transactions found.

Output schema (no markdown, no prose, JUST JSON):
{{
  "lines": [
    {{
      "merchant": string | null,
      "amount": number,                     // positive
      "currency": "TRY",
      "kind": "expense" | "income",
      "category_slug": string | null,       // pick from list below
      "actor_nickname": string | null,      // who spent (e.g. "Ayşe", "Mehmet"), if mentioned
      "note": string | null,
      "confidence": number,                 // 0..1
      "occurred_at": string | null          // ISO 8601 if explicit, else null
    }}
  ],
  "summary": string                         // 1-line Turkish summary of what was extracted
}}

{CATEGORY_SCHEMA_HINT}

Rules:
- Numbers like "320 lira", "847,50 TL", "1.250 ₺" → amount in NUMBER form (847.50, 1250).
- Use period as decimal separator in JSON.
- If the user mentions multiple items, return one line per logical purchase (don't split single-receipt items unless asked).
- For receipts, use the GRAND TOTAL as one line unless user explicitly wants line-by-line.
- If unsure of category, set null. Never invent slugs not in the list.
- Output MUST be valid JSON. No backticks, no commentary.
"""


SYSTEM_VISION_EXTRACTOR = SYSTEM_EXTRACTOR + (
    "\n\nThe user input is an IMAGE of a receipt, invoice, or handwritten note. "
    "Read the visible text on the image (Turkish), figure out what was bought / "
    "received, and produce the same JSON structure. Always use the GRAND TOTAL "
    "for receipts unless the user asked for line items. If the image is unreadable, "
    "return {\"lines\": [], \"summary\": \"Görsel okunamadı\"}."
)


class LLMError(RuntimeError):
    pass


class LLMClient:
    def __init__(
        self,
        *,
        base_url: str | None = None,
        api_key: str | None = None,
        timeout: float = 90.0,
    ):
        self.base_url = (base_url or _settings.llm_gateway_base_url).rstrip("/")
        self.api_key = api_key or _settings.llm_gateway_api_key
        self._client = httpx.AsyncClient(timeout=timeout)

    async def aclose(self) -> None:
        await self._client.aclose()

    @property
    def fallback_models(self) -> list[str]:
        return _settings.fallback_model_list

    @property
    def vision_fallbacks(self) -> list[str]:
        return _settings.vision_fallback_list

    @property
    def transcription_fallbacks(self) -> list[str]:
        return _settings.transcription_fallback_list

    def _auth_headers(self, content_type: str | None = "application/json") -> dict[str, str]:
        h = {"Authorization": f"Bearer {self.api_key}"}
        if content_type:
            h["Content-Type"] = content_type
        return h

    def _strip_json_fences(self, content: str) -> str:
        content = content.strip()
        if content.startswith("```"):
            content = content.strip("`")
            if content.lower().startswith("json"):
                content = content[4:]
            content = content.strip()
        return content

    async def _post_chat(
        self, model: str, messages: list[dict], temperature: float
    ) -> tuple[dict, int]:
        started = time.perf_counter()
        payload = {
            "model": model,
            "messages": messages,
            "temperature": temperature,
            "response_format": {"type": "json_object"},
        }
        resp = await self._client.post(
            f"{self.base_url}/chat/completions",
            headers=self._auth_headers(),
            json=payload,
        )
        latency = int((time.perf_counter() - started) * 1000)
        return resp, latency  # type: ignore[return-value]

    async def chat_json(
        self,
        *,
        system: str,
        user: str,
        model: str | None = None,
        temperature: float = 0.2,
    ) -> tuple[dict[str, Any], dict[str, Any]]:
        if not self.api_key:
            raise LLMError(
                "LLM_GATEWAY_API_KEY is not configured. Set it in backend/.env to enable AI features."
            )
        models_to_try = [model or _settings.llm_default_model, *self.fallback_models]
        # de-dupe but preserve order
        seen: set[str] = set()
        ordered: list[str] = []
        for m in models_to_try:
            if m and m not in seen:
                seen.add(m)
                ordered.append(m)
        last_error: Exception | None = None
        for m in ordered:
            try:
                messages = [
                    {"role": "system", "content": system},
                    {"role": "user", "content": user},
                ]
                resp, latency_ms = await self._post_chat(m, messages, temperature)
                if resp.status_code >= 400:
                    text_body = resp.text[:500]
                    last_error = LLMError(f"{m} returned {resp.status_code}: {text_body}")
                    logger.warning("llm.gateway.fallback model=%s status=%s", m, resp.status_code)
                    continue
                data = resp.json()
                content = data["choices"][0]["message"]["content"]
                parsed = json.loads(self._strip_json_fences(content))
                meta = {
                    "model": m,
                    "latency_ms": latency_ms,
                    "tokens_in": data.get("usage", {}).get("prompt_tokens"),
                    "tokens_out": data.get("usage", {}).get("completion_tokens"),
                }
                return parsed, meta
            except (httpx.TransportError, json.JSONDecodeError, KeyError) as exc:
                last_error = exc
                logger.warning("llm.gateway.error model=%s err=%s", m, exc)
                continue
        raise LLMError(f"All LLM gateway attempts failed: {last_error}")

    async def chat_json_with_image(
        self,
        *,
        system: str,
        user_text: str,
        image_bytes: bytes,
        image_mime: str = "image/jpeg",
        model: str | None = None,
        temperature: float = 0.2,
    ) -> tuple[dict[str, Any], dict[str, Any]]:
        """Multimodal call — image goes inline as a data URL, OpenAI-compatible."""
        if not self.api_key:
            raise LLMError(
                "LLM_GATEWAY_API_KEY is not configured. Set it in backend/.env to enable AI features."
            )
        b64 = base64.b64encode(image_bytes).decode("ascii")
        data_url = f"data:{image_mime};base64,{b64}"

        models_to_try = [model or _settings.llm_vision_model, *self.vision_fallbacks]
        seen: set[str] = set()
        ordered: list[str] = []
        for m in models_to_try:
            if m and m not in seen:
                seen.add(m)
                ordered.append(m)
        last_error: Exception | None = None
        for m in ordered:
            try:
                messages = [
                    {"role": "system", "content": system},
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": user_text},
                            {"type": "image_url", "image_url": {"url": data_url}},
                        ],
                    },
                ]
                resp, latency_ms = await self._post_chat(m, messages, temperature)
                if resp.status_code >= 400:
                    text_body = resp.text[:500]
                    last_error = LLMError(f"{m} returned {resp.status_code}: {text_body}")
                    logger.warning("llm.vision.fallback model=%s status=%s", m, resp.status_code)
                    continue
                data = resp.json()
                content = data["choices"][0]["message"]["content"]
                parsed = json.loads(self._strip_json_fences(content))
                meta = {
                    "model": m,
                    "latency_ms": latency_ms,
                    "tokens_in": data.get("usage", {}).get("prompt_tokens"),
                    "tokens_out": data.get("usage", {}).get("completion_tokens"),
                }
                return parsed, meta
            except (httpx.TransportError, json.JSONDecodeError, KeyError) as exc:
                last_error = exc
                logger.warning("llm.vision.error model=%s err=%s", m, exc)
                continue
        raise LLMError(f"All vision attempts failed: {last_error}")

    async def transcribe_audio(
        self,
        *,
        audio_bytes: bytes,
        filename: str = "audio.webm",
        content_type: str = "audio/webm",
        language: str = "tr",
        model: str | None = None,
    ) -> tuple[str, dict[str, Any]]:
        """OpenAI-style /audio/transcriptions multipart upload."""
        if not self.api_key:
            raise LLMError(
                "LLM_GATEWAY_API_KEY is not configured. Set it in backend/.env to enable AI features."
            )
        models_to_try = [model or _settings.llm_transcription_model, *self.transcription_fallbacks]
        seen: set[str] = set()
        ordered: list[str] = []
        for m in models_to_try:
            if m and m not in seen:
                seen.add(m)
                ordered.append(m)
        last_error: Exception | None = None
        for m in ordered:
            try:
                started = time.perf_counter()
                files = {"file": (filename, audio_bytes, content_type)}
                data = {"model": m, "language": language, "response_format": "json"}
                resp = await self._client.post(
                    f"{self.base_url}/audio/transcriptions",
                    headers={"Authorization": f"Bearer {self.api_key}"},
                    files=files,
                    data=data,
                )
                latency_ms = int((time.perf_counter() - started) * 1000)
                if resp.status_code >= 400:
                    text_body = resp.text[:500]
                    last_error = LLMError(f"{m} returned {resp.status_code}: {text_body}")
                    logger.warning(
                        "llm.transcribe.fallback model=%s status=%s body=%s", m, resp.status_code, text_body[:200]
                    )
                    continue
                payload = resp.json()
                text = payload.get("text") or ""
                if not text.strip():
                    last_error = LLMError(f"{m} returned empty transcript")
                    continue
                meta = {"model": m, "latency_ms": latency_ms}
                return text.strip(), meta
            except (httpx.TransportError, json.JSONDecodeError, KeyError) as exc:
                last_error = exc
                logger.warning("llm.transcribe.error model=%s err=%s", m, exc)
                continue
        raise LLMError(f"All transcription attempts failed: {last_error}")


_llm_singleton: LLMClient | None = None


def get_llm() -> LLMClient:
    global _llm_singleton
    if _llm_singleton is None:
        _llm_singleton = LLMClient()
    return _llm_singleton
