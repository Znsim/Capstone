import smtplib
import time
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from jose import JWTError, jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta
from typing import Optional
from .config import get_config
# core/dependencies.py 에 추가할 것
from core.database import provide_session
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import Depends
import os

config = get_config()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
SENDER_EMAIL = "sjusju9868@gmail.com"
SENDER_PASSWORD = "ezvt gpdw pkcp xnod"  


SECRET_KEY = config.jwt_secret_key
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = config.jwt_expire_minutes
TOKEN_TYPE = "ARK3321"



def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        raise JWTError("Invalid token or expired token.")


def create_email_verification_token(email: str) -> str:
    expiration = datetime.utcnow() + timedelta(hours=1)
    token_data = {"email": email, "exp": expiration}
    token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)
    return token


def send_verification_email(user_email: str):
    token = create_email_verification_token(user_email)

    # 환경변수 DOMAIN 값 가져오기 (없으면 로컬 기본값 사용)
    base_url = os.getenv("DOMAIN", "http://localhost:8000")

    verification_link = f"{base_url}/users/verify-email?token={token}"

    subject = "Email Verification"
    body = f"Please click the following link to verify your email: {verification_link}"

    send_email(user_email, subject, body)

def send_email(to_email: str, subject: str, body: str):
    msg = MIMEMultipart()
    msg['From'] = SENDER_EMAIL
    msg['To'] = to_email
    msg['Subject'] = subject

    msg.attach(MIMEText(body, 'plain'))

    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SENDER_EMAIL, SENDER_PASSWORD)
            text = msg.as_string()
            server.sendmail(SENDER_EMAIL, to_email, text)
        print(f"✅ Email sent to {to_email}")
    except Exception as e:
        print(f"❌ Failed to send email: {e}")


def verify_email(token: str) -> str:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload["email"]
        print(f"✅ Email {email} verified successfully!")
        return f"Email {email} verified successfully!"
    except JWTError:
        return "Invalid token!"


def get_email_by_token(token: str) -> Optional[str]:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload["email"]
    except JWTError:
        return "Invalid token!"


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async for session in provide_session():
        yield session