from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from typing import Dict, Set
import asyncio
from core.database import provide_session
from Domain.Chat.crud import ChatCRUD  # 기존 chat CRUD 사용
from Domain.User.crud import UserCRUD  # 기존 user CRUD 사용
from sqlalchemy.ext.asyncio import AsyncSession
import json
from datetime import datetime

router = APIRouter(
    prefix="/websocket",
    tags=["WebSocket"]
)

class AdvancedCustomerSupportManager:
    def __init__(self):
        # 모든 연결된 사용자 (관리자 + 일반사용자)
        self.all_connections: Dict[int, WebSocket] = {}
        # 관리자 사용자 ID 목록 
        self.admin_user_ids: Set[int] = set()
        # 일반 사용자 ID 목록
        self.customer_user_ids: Set[int] = set()
        
    async def connect(self, websocket: WebSocket, user_pk: int, is_admin: bool):
        # WebSocket 연결 저장
        self.all_connections[user_pk] = websocket
        
        if is_admin:
            self.admin_user_ids.add(user_pk)
            print(f"✅ 관리자 연결 완료: user_pk={user_pk}, 총 관리자 수={len(self.admin_user_ids)}")
        else:
            self.customer_user_ids.add(user_pk)
            print(f"✅ 고객 연결 완료: user_pk={user_pk}, 총 고객 수={len(self.customer_user_ids)}")
            
        print(f"📊 현재 연결 상태 - 관리자: {list(self.admin_user_ids)}, 고객: {list(self.customer_user_ids)}")
            
    def disconnect(self, user_pk: int):
        if user_pk in self.all_connections:
            del self.all_connections[user_pk]
            
        if user_pk in self.admin_user_ids:
            self.admin_user_ids.remove(user_pk)
            print(f"관리자 연결 해제: user_pk={user_pk}")
        elif user_pk in self.customer_user_ids:
            self.customer_user_ids.remove(user_pk)
            print(f"고객 연결 해제: user_pk={user_pk}")
            
    async def send_to_user(self, message: str, user_pk: int):
        if user_pk in self.all_connections:
            await self.all_connections[user_pk].send_text(message)
            print(f"메시지 전송: user_pk={user_pk}")
            return True
        return False
            
    async def send_to_specific_customer(self, message: str, customer_pk: int):
        if customer_pk in self.customer_user_ids and customer_pk in self.all_connections:
            await self.all_connections[customer_pk].send_text(message)
            print(f"관리자 답변을 고객에게 전송: customer_pk={customer_pk}")
            return True
        else:
            print(f"고객이 연결되어 있지 않음: customer_pk={customer_pk}")
            return False
            
    async def send_to_all_admins(self, message: str, from_customer_pk: int):
        message_data = json.loads(message)
        message_data["from_customer_pk"] = from_customer_pk  # 어떤 고객의 문의인지 표시
        
        admin_message = json.dumps(message_data)
        sent_count = 0
        
        for admin_id in self.admin_user_ids:
            if admin_id in self.all_connections:
                await self.all_connections[admin_id].send_text(admin_message)
                sent_count += 1
                
        print(f"관리자들에게 고객 문의 전송: {sent_count}명의 관리자에게 전송")

manager = AdvancedCustomerSupportManager()

async def get_db():
    async for session in provide_session():
        yield session

@router.websocket("/ws/chats")
async def websocket_endpoint(websocket: WebSocket, db: AsyncSession = Depends(get_db)):
    await websocket.accept()  # ✅ 한 번만 호출
    
    # 기존 CRUD 사용
    user_crud = UserCRUD(session=db)
    chat_crud = ChatCRUD(session=db)
    
    user_pk = None
    is_admin = False
    
    try:
        # 첫 메시지 받아서 사용자 정보 확인
        data = await websocket.receive_text()
        print(f"첫 메시지 수신: data={data}")
        
        message_data = json.loads(data)
        user_pk = message_data.get("user_pk")
        
        if user_pk:
            user_data = await user_crud.get_user_by_id(user_id=user_pk)
            is_admin = user_data.get("is_admin", False) if user_data else False
            await manager.connect(websocket, user_pk, is_admin)
            print(f"사용자 연결 등록: user_pk={user_pk}, is_admin={is_admin}")
        
        # 첫 메시지 처리
        await process_message(message_data, user_pk, is_admin, chat_crud)
        
        # 이후 메시지들 처리
        while True:
            data = await websocket.receive_text()
            print(f"메시지 수신: data={data}")
            
            try:
                message_data = json.loads(data)
                await process_message(message_data, user_pk, is_admin, chat_crud)
                
            except json.JSONDecodeError as e:
                print(f"JSON 파싱 에러: {e}")
                await websocket.send_text(json.dumps({"error": "Invalid JSON format"}))
            except Exception as e:
                print(f"메시지 처리 에러: {str(e)}")
                await websocket.send_text(json.dumps({"error": str(e)}))
            
    except WebSocketDisconnect:
        if user_pk:
            manager.disconnect(user_pk)
            print(f"WebSocket 연결 종료: user_pk={user_pk}")
    except Exception as e:
        print(f"WebSocket 에러: {str(e)}")
        if user_pk:
            manager.disconnect(user_pk)


async def process_message(message_data, user_pk, is_admin, chat_crud):
    
    # 연결용 특수 메시지는 DB에 저장하지 않음
    if message_data.get("message") == "__CONNECT__":
        print(f"연결 확인 메시지 - 저장하지 않음: user_pk={user_pk}")
        return
    
    # 기존 chat CRUD의 save_chat_message 사용
    chat_response = await chat_crud.save_chat_message(
        user_pk=message_data.get("user_pk"),
        message=message_data.get("message"),
        is_from_admin=message_data.get("is_from_admin", False)
    )

    # ChatModel을 dict로 변환
    response = {
        "id": chat_response.id,
        "user_pk": chat_response.user_pk,
        "message": chat_response.message,
        "is_from_admin": chat_response.is_from_admin,
        "created_at": chat_response.created_at.isoformat()
    }

    response_str = json.dumps(response)

    # 고급 메시지 전송 로직
    if message_data.get("is_from_admin"):
        # 관리자가 특정 고객에게 답변
        target_customer_pk = message_data.get("user_pk")
        
        print(f"📤 관리자({user_pk})가 고객({target_customer_pk})에게 답변: '{message_data.get('message')}'")
        
        # 특정 고객에게만 답변 전송
        success = await manager.send_to_specific_customer(response_str, target_customer_pk)
        
        if not success:
            # 고객이 오프라인인 경우 관리자에게 알림
            error_msg = {
                "type": "error",
                "message": f"고객 {target_customer_pk}가 현재 오프라인입니다.",
                "timestamp": datetime.now().isoformat()
            }
            await manager.send_to_user(json.dumps(error_msg), user_pk)
        
    else:
        # 고객이 문의 전송
        print(f"📨 고객({user_pk}) 문의: '{message_data.get('message')}'")
        
        # 모든 관리자에게 문의 전송
        await manager.send_to_all_admins(response_str, user_pk)

    print(f"✅ 메시지 처리 완료")