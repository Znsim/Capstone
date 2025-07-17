from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status
from .schema import (UserDTO, LoginDTO)
from core.models import UserModel
from core.dependencies import create_access_token, verify_password

class UserCRUD:
    def __init__(self, session: AsyncSession):
        self._session = session

    async def create_user(self, *, payload: UserDTO):
        new_user = UserModel(
            username=payload.username,  
            email=payload.email,        
            password=payload.password   
           
        )
        self._session.add(new_user)
        await self._session.commit()
        return new_user

    async def Login(self, *, gemail, password):
        user = (await self._session.execute(
            select(UserModel).where(UserModel.email == gemail)  
        )).scalars().first()

        if not user or not verify_password(password, user.password) or not user.authenticator:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials"
            )
        return create_access_token(data={"user_id": user.id})

    async def get_user_by_email(self, *, gemail: str):
        result = await self._session.execute(select(UserModel).where(UserModel.email == gemail))  # 
        user = result.scalars().first()
        return user

    async def get_user_by_nick(self, *, nickname: str):
        result = await self._session.execute(select(UserModel).where(UserModel.username == nickname))  
        user = result.scalars().first()
        return user

    async def user_auth_change(self, *, gemail: str):
        result = await self._session.execute(select(UserModel).where(UserModel.email == gemail))  
        user = result.scalars().first()
        user.authenticator = True
        await self._session.commit()
        return user
