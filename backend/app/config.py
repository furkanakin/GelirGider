from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    database_url: str
    database_schema: str = "evimiz"

    jwt_secret: str
    jwt_alg: str = "HS256"
    access_token_ttl_minutes: int = 60
    refresh_token_ttl_days: int = 30

    llm_gateway_base_url: str = "https://api.llmgateway.io/v1"
    llm_gateway_api_key: str = ""
    llm_default_model: str = "qwen3-coder-next"
    llm_vision_model: str = "qwen2.5-vl-72b-instruct"
    llm_vision_fallbacks: str = "qwen-vl-max,qwen-vl-plus,gpt-4o-mini,gpt-4o,gemini-1.5-flash"
    # Transcription routes through Groq Cloud — llmgateway.io does not expose
    # /audio/transcriptions, so we keep transcription on a separate
    # OpenAI-compatible endpoint. Groq's whisper-large-v3-turbo handles
    # Turkish and accepts both webm (web) and m4a (mobile) directly.
    transcription_base_url: str = "https://api.groq.com/openai/v1"
    transcription_api_key: str = ""
    llm_transcription_model: str = "whisper-large-v3-turbo"
    llm_transcription_fallbacks: str = "whisper-large-v3"
    llm_fallback_models: str = "qwen3-coder-next,gpt-4o-mini,claude-3-5-haiku-20241022,gemini-1.5-flash,llama-3.3-70b-versatile,glm-5.1,kimi-k2.6,minimax-m2.7"

    attachments_dir: str = "/data/attachments"
    max_upload_mb: int = 20

    environment: str = "development"
    allowed_origins: str = "*"
    log_level: str = "INFO"

    @property
    def fallback_model_list(self) -> list[str]:
        return [m.strip() for m in self.llm_fallback_models.split(",") if m.strip()]

    @property
    def vision_fallback_list(self) -> list[str]:
        return [m.strip() for m in self.llm_vision_fallbacks.split(",") if m.strip()]

    @property
    def transcription_fallback_list(self) -> list[str]:
        return [m.strip() for m in self.llm_transcription_fallbacks.split(",") if m.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]
