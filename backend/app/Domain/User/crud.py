from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional, Dict, Any, List
from fastapi import HTTPException, status
from .schema import (UserDTO, LoginDTO,LoginResponse)
from core.models import UserModel
from core.dependencies import create_access_token, verify_password

class UserCRUD:
    def __init__(self, session: AsyncSession):
        self._session = session

    # CREATE
    async def create_user(self, *, payload: UserDTO) -> Dict[str, Any]:
        # Check duplicates
        email_check = await self._session.execute(select(UserModel).where(UserModel.email == payload.email))
        if email_check.scalars().first():
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already exists")
        
        nickname_check = await self._session.execute(select(UserModel).where(UserModel.username == payload.username))
        if nickname_check.scalars().first():
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Nickname already exists")
        
        # Create user
        new_user = UserModel(
            username=payload.username,
            email=payload.email,
            password=payload.password,
        )
        self._session.add(new_user)
        await self._session.commit()
        
        return {
            "id": new_user.id,
            "username": new_user.username,
            "email": new_user.email,
            "message": "User created successfully"
        }

    # READ
    async def get_user_by_email(self, *, email: str) -> Optional[Dict[str, Any]]:
        result = await self._session.execute(select(UserModel).where(UserModel.email == email))
        user = result.scalars().first()
        
        if user:
            return {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "is_admin": user.is_admin,
                "authenticated": user.authenticator
            }
        return None

    async def get_user_by_username(self, *, username: str) -> Optional[Dict[str, Any]]:
        result = await self._session.execute(select(UserModel).where(UserModel.username == username))
        user = result.scalars().first()
        
        if user:
            return {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "is_admin": user.is_admin,
                "authenticated": user.authenticator
            }
        return None

    async def get_user_by_id(self, *, user_id: int) -> Optional[Dict[str, Any]]:
        result = await self._session.execute(select(UserModel).where(UserModel.id == user_id))
        user = result.scalars().first()
        
        if user:
            return {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "is_admin": user.is_admin,
                "authenticated": user.authenticator
            }
        return None

    
    async def authenticate_user(self, *, email: str) -> Dict[str, Any]:
        result = await self._session.execute(select(UserModel).where(UserModel.email == email))
        user = result.scalars().first()
        
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        
        user.authenticator = True
        await self._session.commit()
        
        return {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "authenticated": user.authenticator,
            "message": "User authentication updated successfully"
        }

    # BUSINESS LOGIC
    async def login(self, *, email: str, password: str) -> str:
        result = await self._session.execute(select(UserModel).where(UserModel.email == email))
        user = result.scalars().first()
        
        if not user or not verify_password(password, user.password) or not user.authenticator:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
        
        return create_access_token(data={"user_id": user.id})
    
    
