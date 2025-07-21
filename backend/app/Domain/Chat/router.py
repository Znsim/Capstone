from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from core.dependencies import get_db
from core.database import provide_session
from .crud import ChatCRUD
from .schema import ChatCreateDTO,ChatResponseDTO,AllConversationsDTO,UserInfoDTO,ConversationDTO


router = APIRouter(
    prefix="/chat",
    tags=["Chat"]
)


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


# ✅ 특정 사용자 메시지 목록 조회<-웹 소켓 연결 안되길래 바꿨음
@router.post("/get_messages", response_model=list[ChatResponseDTO])
async def get_messages(
    payload: ChatCreateDTO,  # 스키마 필요
    db=Depends(provide_session)  # get_db → provide_session 변경
):
    chat_crud = ChatCRUD(session=db)
    return await chat_crud.get_messages_by_user_pk(user_pk=payload.user_pk)


# ✅ 전체 대화 조회 (관리자용)
@router.get("/all", response_model=AllConversationsDTO)
async def get_all_conversations(
    db: AsyncSession = Depends(get_db)
):
    chat_crud = ChatCRUD(db)
    return await chat_crud.get_all_conversations()
