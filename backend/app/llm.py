"""LLM Gateway client — OpenAI-compatible.

The user can pick any model id supported by https://llmgateway.io
(e.g. 'qwen3-coder-next', 'glm-5.1', 'kimi-k2.6', 'minimax-m2.7').

This module handles:
  * structured JSON extraction for receipts / free-text descriptions
  * graceful fallback to alternate models if a model is rate-limited or unavailable
"""
from __future__ import annotations

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


class LLMError(RuntimeError):
    pass


class LLMClient:
    def __init__(self, *, base_url: str | None = None, api_key: str | None = None, timeout: float = 60.0):
        self.base_url = (base_url or _settings.llm_gateway_base_url).rstrip("/")
        self.api_key = api_key or _settings.llm_gateway_api_key
        self._client = httpx.AsyncClient(timeout=timeout)

    async def aclose(self) -> None:
        await self._client.aclose()

    @property
    def fallback_models(self) -> list[str]:
        return _settings.fallback_model_list

    async def chat_json(
        self,
        *,
        system: str,
        user: str,
        model: str | None = None,
        temperature: float = 0.2,
    ) -> tuple[dict[str, Any], dict[str, Any]]:
        """Call chat completions and parse a JSON object from the response."""
        if not self.api_key:
            raise LLMError(
                "LLM_GATEWAY_API_KEY is not configured. "
                "Set it in backend/.env to enable AI features."
            )
        models_to_try = [model or _settings.llm_default_model, *self.fallback_models]
        last_error: Exception | None = None
        for m in models_to_try:
            try:
                started = time.perf_counter()
                payload = {
                    "model": m,
                    "messages": [
                        {"role": "system", "content": system},
                        {"role": "user", "content": user},
                    ],
                    "temperature": temperature,
                    "response_format": {"type": "json_object"},
                }
                resp = await self._client.post(
                    f"{self.base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json",
                    },
                    json=payload,
                )
                latency_ms = int((time.perf_counter() - started) * 1000)
                if resp.status_code >= 400:
                    text = resp.text[:500]
                    last_error = LLMError(f"{m} returned {resp.status_code}: {text}")
                    logger.warning("llm.gateway.fallback model=%s status=%s", m, resp.status_code)
                    continue
                data = resp.json()
                content = data["choices"][0]["message"]["content"]
                # Some models wrap JSON in ```json fences; strip if present.
                content = content.strip()
                if content.startswith("```"):
                    content = content.strip("`")
                    if content.lower().startswith("json"):
                        content = content[4:]
                    content = content.strip()
                parsed = json.loads(content)
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


_llm_singleton: LLMClient | None = None


def get_llm() -> LLMClient:
    global _llm_singleton
    if _llm_singleton is None:
        _llm_singleton = LLMClient()
    return _llm_singleton
