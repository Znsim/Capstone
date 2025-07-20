from typing import List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status
from core.models import ChatModel, UserModel


class ChatCRUD:
    def __init__(self, session: AsyncSession):
        self._session = session

    # ✅ 채팅 메시지 저장
    async def save_chat_message(self, *, user_pk: int, message: str, is_from_admin: bool = False) -> ChatModel:
        user = await self._session.get(UserModel, user_pk)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        chat = ChatModel(
            user_pk=user_pk,
            message=message,
            is_from_admin=is_from_admin
        )
        self._session.add(chat)
        await self._session.commit()
        await self._session.refresh(chat)
        return chat

    # ✅ 특정 사용자 채팅 조회
    async def get_messages_by_user_pk(self, *, user_pk: int) -> List[ChatModel]:
        result = await self._session.execute(
            select(ChatModel)
            .where(ChatModel.user_pk == user_pk)
            .order_by(ChatModel.created_at)
        )
        return result.scalars().all()

    # ✅ 모든 대화 조회 (관리자용)
    async def get_all_conversations(self) -> Dict[str, Any]:
        message_query = (
            select(ChatModel)
            .join(UserModel, ChatModel.user_pk == UserModel.id)
            .where(UserModel.authenticator == True)  # 인증된 유저만
            .order_by(ChatModel.user_pk, ChatModel.created_at)
        )
        message_result = await self._session.execute(message_query)
        all_messages = message_result.scalars().all()

        user_query = select(UserModel).where(UserModel.authenticator == True)
        user_result = await self._session.execute(user_query)
        users = user_result.scalars().all()

        user_info = {
            user.id: {
                "user_id": user.id,
                "username": user.username,
                "email": user.email
            }
            for user in users
        }

        conversations = {}
        for message in all_messages:
            user_pk = message.user_pk
            if user_pk in user_info:
                if user_pk not in conversations:
                    conversations[user_pk] = {
                        "user_info": user_info[user_pk],
                        "messages": []
                    }

                conversations[user_pk]["messages"].append({
                    "id": message.id,
                    "user_pk": message.user_pk,
                    "message": message.message,
                    "is_from_admin": message.is_from_admin,
                    "created_at": message.created_at.isoformat()
                })

        return {
            "conversations": conversations,
            "total_conversations": len(conversations)
        }
