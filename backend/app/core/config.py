from functools import lru_cache
from pydantic_settings import BaseSettings
from dotenv import load_dotenv
import os

load_dotenv()  # .env 파일에서 환경변수 불러오기

class DefaultConfig(BaseSettings):
    postgresql_endpoint: str
    postgresql_port: int
    postgresql_table: str
    postgresql_user: str
    postgresql_password: str
    jwt_secret_key: str
    jwt_expire_minutes: int
    class Config:
        env_file = ".env"  # 📌 .env 파일에서 값 자동으로 읽어옴

@lru_cache
def get_config():
    return DefaultConfig()
