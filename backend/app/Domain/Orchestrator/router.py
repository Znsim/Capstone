# Domain/Orchestrator/router.py
from fastapi import APIRouter
from fastapi.responses import StreamingResponse
import json
import asyncio

# [테스트] models는 보통 안전하므로 둡니다.
from .models import AnalyzeRequest

# ⚠️ [테스트 핵심] pipeline 연결을 끊습니다. 주석 처리하세요!
from .pipeline import run_analyze 

router = APIRouter(prefix="/orchestrator", tags=["Orchestrator"])

@router.get("/health")
async def health():
    return {"ok": True}

@router.post("/analyze")
async def analyze(req: AnalyzeRequest):
    async def response_stream():
        yield json.dumps({"status": "progress", "message": "분석 시작..."}, ensure_ascii=False) + "\n"
        result = await run_analyze(req)
        yield json.dumps({"status": "completed", "data": result.dict()}, ensure_ascii=False) + "\n"

    return StreamingResponse(response_stream(), media_type="application/x-ndjson")
