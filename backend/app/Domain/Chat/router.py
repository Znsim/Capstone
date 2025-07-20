from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from core.dependencies import get_db
from .crud import ChatCRUD
from .schema import (
    ChatCreateDTO,
    ChatResponseDTO,
    AllConversationsDTO
)

router = APIRouter(
    prefix="/chat",
    tags=["Chat"]
)

# ✅ 채팅 메시지 저장 (일반 사용자 또는 관리자)
@router.post("/send", response_model=ChatResponseDTO, status_code=status.HTTP_201_CREATED)
async def send_message(
    payload: ChatCreateDTO,
    db: AsyncSession = Depends(get_db)
):
    chat_crud = ChatCRUD(db)
    chat = await chat_crud.save_chat_message(
        user_pk=payload.user_pk,
        message=payload.message,
        is_from_admin=payload.is_from_admin
    )
    return chat


# ✅ 특정 사용자 메시지 목록 조회
@router.get("/user/{user_pk}", response_model=list[ChatResponseDTO])
async def get_user_messages(
    user_pk: int,
    db: AsyncSession = Depends(get_db)
):
    chat_crud = ChatCRUD(db)
    return await chat_crud.get_messages_by_user_pk(user_pk=user_pk)


# ✅ 전체 대화 조회 (관리자용)
@router.get("/all", response_model=AllConversationsDTO)
async def get_all_conversations(
    db: AsyncSession = Depends(get_db)
):
    chat_crud = ChatCRUD(db)
    return await chat_crud.get_all_conversations()
