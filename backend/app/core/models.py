from sqlalchemy import Column, String, Integer, Boolean, DateTime, Text, ForeignKey
from core.database import Base
from sqlalchemy.sql import func

class UserModel(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    username = Column(String(30), unique=True, nullable=False)  
    password = Column(String(255), nullable=False)              
    email = Column(String(100), unique=True, nullable=False)            
    authenticator = Column(Boolean, default=False)  # 이메일 인증 여부           

class ChatModel(Base):
    __tablename__ = 'chats'
    id = Column(Integer, primary_key=True, index=True)
    user_pk = Column(Integer, ForeignKey('users.id'))  # 메시지를 보내거나 받는 일반 사용자 고유번호
    message = Column(Text, nullable=False)  # 메시지 내용
    is_from_admin = Column(Boolean, default=False)  # 관리자가 보낸 메시지인지 여부
    created_at = Column(DateTime(timezone=True), server_default=func.now())