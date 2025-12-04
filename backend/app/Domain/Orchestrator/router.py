# Domain/Orchestrator/router.py
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
import json
import asyncio

# 모델과 파이프라인 함수 가져오기
from .models import AnalyzeRequest
from .pipeline import run_analyze 

router = APIRouter(prefix="/orchestrator", tags=["Orchestrator"])

@router.get("/health")
async def health():
    return {"ok": True}

@router.post("/analyze")
async def analyze(req: AnalyzeRequest):
    """
    스트리밍 방식으로 분석 결과를 반환합니다.
    이를 통해 504 Gateway Time-out을 방지하고, 사용자에게 진행 상황을 알립니다.
    """
    
    # 🔹 제너레이터 함수: 데이터를 조각(Chunk)내서 보냄
    async def response_stream():
        try:
            # [1단계] 연결 즉시 '처리 중' 메시지 전송 (Time-out 방지 핵심!)
            # 이 메시지가 0.1초 만에 전송되므로 게이트웨이는 연결을 유지합니다.
            initial_msg = {
                "status": "progress",
                "message": "법률 데이터셋과 판례를 검색하고 있습니다... 잠시만 기다려주세요."
            }
            # ensure_ascii=False를 해야 한글이 깨지지 않음
            yield json.dumps(initial_msg, ensure_ascii=False) + "\n"

            # [2단계] 무거운 분석 작업 실행 (기존 pipeline.py의 함수 사용)
            # 여기서 시간이 오래 걸려도, 이미 1단계 데이터를 보냈기 때문에 연결이 끊기지 않음
            result = await run_analyze(req)
            
            # [3단계] 분석 완료 후 최종 결과 전송
            final_msg = {
                "status": "completed",
                "data": result.dict()  # Pydantic 모델을 dict로 변환
            }
            yield json.dumps(final_msg, ensure_ascii=False) + "\n"

        except Exception as e:
            # 에러 발생 시에도 JSON 형태로 에러 메시지 전송
            error_msg = {
                "status": "error",
                "message": f"분석 중 오류가 발생했습니다: {str(e)}"
            }
            yield json.dumps(error_msg, ensure_ascii=False) + "\n"

    # 🔹 StreamingResponse로 반환 (media_type은 줄바꿈된 JSON임을 명시)
    return StreamingResponse(response_stream(), media_type="application/x-ndjson")

@router.post("/feedback")
async def feedback(payload: dict):
    return {"ok": True, "message": "Feedback received"}
