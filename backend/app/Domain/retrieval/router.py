from fastapi import APIRouter
from pydantic import BaseModel
from .search_service import search_jsonl  # 그대로 유지 (이제 Supabase 내부 호출)

router = APIRouter(prefix="/retrieval", tags=["Retrieval"])

class SearchRequest(BaseModel):
    query: str
    top_k: int = 5  # 기본 5개 정도면 적당

@router.post("/search")
def search(req: SearchRequest):
    # ✅ Supabase 버전 search_jsonl은 (query, top_k)만 받음
    results = search_jsonl(req.query, req.top_k)
    return results
