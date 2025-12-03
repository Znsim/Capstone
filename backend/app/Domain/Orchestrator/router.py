# Domain/Orchestrator/router.py
from fastapi import APIRouter, HTTPException, BackgroundTasks
from .models import AnalyzeRequest, AnalyzeResult
# process_analysis_background 함수를 import 합니다.
from .pipeline import run_analyze, process_analysis_background 

router = APIRouter(prefix="/orchestrator", tags=["Orchestrator"])

@router.get("/health")
async def health():
    return {"ok": True}

# ⚠️ 주의: response_model=AnalyzeResult를 제거했습니다. 
# 이제 결과 객체를 바로 반환하지 않고 단순 메시지만 반환하기 때문입니다.
@router.post("/analyze")
async def analyze(req: AnalyzeRequest, background_tasks: BackgroundTasks):
    try:
        # 1. 백그라운드 작업 등록 (기다리지 않음)
        # process_analysis_background 함수에 req 데이터를 넘겨서 실행시킵니다.
        background_tasks.add_task(process_analysis_background, req)
        
        # 2. 클라이언트에게는 즉시 응답 (0.1초 소요)
        return {
            "status": "queued",
            "message": "분석 요청이 접수되었습니다. 결과는 서버 로그 또는 DB를 확인하세요."
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/feedback")
async def feedback(payload: dict):
    # 나중에 Redis나 DB로 피드백 저장 예정
    return {"ok": True, "message": "Feedback received"}
