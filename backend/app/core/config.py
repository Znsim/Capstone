from typing import Optional
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict
from dotenv import load_dotenv
from pydantic import Field
import os

load_dotenv()  # .env 파일에서 환경변수 불러오기

class DefaultConfig(BaseSettings):
    # --- DB 설정 ---
    postgresql_endpoint: str = Field(alias="POSTGRESQL_ENDPOINT")
    postgresql_port: int = Field(alias="POSTGRESQL_PORT")
    postgresql_table: str = Field(alias="POSTGRESQL_TABLE")
    postgresql_user: str = Field(alias="POSTGRESQL_USER")
    postgresql_password: str = Field(alias="POSTGRESQL_PASSWORD")

    # --- JWT 설정 ---
    jwt_secret_key: str = Field(alias="JWT_SECRET_KEY")
    jwt_expire_minutes: int = Field(alias="JWT_EXPIRE_MINUTES")

    # --- Orchestrator용 ---
    openai_api_key: Optional[str] = Field(default=None, alias="OPENAI_API_KEY")
    llm_model: str = Field(default="gpt-5-mini", alias="LLM_MODEL")
    retrieval_base_url: str = Field(default="http://localhost:3000", alias="RETRIEVAL_BASE_URL")

    # --- Pydantic v2 설정 ---
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",          # .env에 다른 키가 있어도 에러 안 냄
        populate_by_name=True,   # alias 적용 허용
        case_sensitive=False
    )

@lru_cache
def get_config():
    return DefaultConfig()
