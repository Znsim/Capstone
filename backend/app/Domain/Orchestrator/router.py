# Domain/Orchestrator/router.py
from fastapi import APIRouter, HTTPException, BackgroundTasks # 1. BackgroundTasks 추가
from .models import AnalyzeRequest
# AnalyzeResult는 즉시 반환되지 않으므로 response_model에서 뺍니다.
from .pipeline import process_analysis_background # 2. 백그라운드용 래퍼 함수 임포트

router = APIRouter(prefix="/orchestrator", tags=["Orchestrator"])

@router.get("/health")
async def health():
    return {"ok": True}

# 3. response_model 제거 (결과를 바로 못 줌)
@router.post("/analyze") 
async def analyze(req: AnalyzeRequest, background_tasks: BackgroundTasks):
    try:
        # 4. 백그라운드 작업 등록 (기다리지 않고 즉시 통과됨)
        # run_analyze를 직접 부르는 게 아니라, 결과를 저장까지 해주는 래퍼 함수를 호출합니다.
        background_tasks.add_task(process_analysis_background, req)
        
        # 5. 사용자에게는 "접수됨" 메시지만 즉시 반환 (0.1초 소요)
        return {
            "status": "queued",
            "message": "분석 요청이 백그라운드에서 시작되었습니다. 결과는 나중에 확인하세요."
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/feedback")
async def feedback(payload: dict):
    return {"ok": True, "message": "Feedback received"}
