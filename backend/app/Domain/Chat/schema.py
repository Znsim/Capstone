from pydantic import BaseModel
from typing import Optional
from datetime import datetime


# ✅ 채팅 메시지 생성 요청용 (POST용)
class ChatCreateDTO(BaseModel):
    user_pk: int
    message: str
    is_from_admin: Optional[bool] = False


# ✅ 채팅 메시지 단일 응답용
class ChatResponseDTO(BaseModel):
    id: int
    user_pk: int
    message: str
    is_from_admin: bool
    created_at: datetime

    class Config:
        orm_mode = True


# ✅ 유저 정보 응답용 (대화 전체 조회에 포함)
class UserInfoDTO(BaseModel):
    user_id: int
    username: str
    email: str


# ✅ 관리자용 전체 대화 응답용
class ConversationDTO(BaseModel):
    user_info: UserInfoDTO
    messages: list[ChatResponseDTO]


class AllConversationsDTO(BaseModel):
    conversations: dict[int, ConversationDTO]
    total_conversations: int
