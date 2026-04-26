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
    llm_vision_model: str = "qwen3-coder-next"
    llm_fallback_models: str = "glm-5.1,kimi-k2.6,minimax-m2.7"

    attachments_dir: str = "/data/attachments"
    max_upload_mb: int = 20

    environment: str = "development"
    allowed_origins: str = "*"
    log_level: str = "INFO"

    @property
    def fallback_model_list(self) -> list[str]:
        return [m.strip() for m in self.llm_fallback_models.split(",") if m.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]
