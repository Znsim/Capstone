from sqlalchemy import Column, String, Integer, Boolean
from core.database import Base

class UserModel(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    username = Column(String(30), unique=True, nullable=False)  
    password = Column(String(255), nullable=False)              
    email = Column(String(100), unique=True, nullable=False)            
    authenticator = Column(Boolean, default=False)  # 이메일 인증 여부           
