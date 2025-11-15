from fastapi import APIRouter, HTTPException
from .models import AnalyzeRequest, AnalyzeResult
from .pipeline import run_analyze

router = APIRouter(prefix="/orchestrator", tags=["Orchestrator"])

@router.get("/health")
async def health():
    return {"ok": True}

@router.post("/analyze", response_model=AnalyzeResult)
async def analyze(req: AnalyzeRequest):
    try:
        return await run_analyze(req)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/feedback")
async def feedback(payload: dict):
    # 나중에 Redis나 DB로 피드백 저장 예정
    return {"ok": True, "message": "Feedback received"}
