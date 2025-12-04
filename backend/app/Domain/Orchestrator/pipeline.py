# Domain/Orchestrator/pipeline.py
from __future__ import annotations

import logging
from typing import List

# 🔹 FastAPI 스레드풀 유틸
from fastapi.concurrency import run_in_threadpool

# 🔹 최신 엔진 모듈 (backend/app/engine 안)
# (경로가 맞는지 확인해주세요. 보통 app.engine 또는 engine 등으로 설정됨)
from engine.rag_engine import get_rag_context
from engine.rule_engine import calculate_rule_score
from engine.llm_analyzer import get_final_analysis_from_llm

# 🔹 Orchestrator 유틸 (응답 스키마 + 앙상블)
from .ensemble_slot import combine_scores, _score_to_label
from .models import AnalyzeRequest, AnalyzeResult, RuleHit

logger = logging.getLogger(__name__)

# ==========================================
# 핵심 분석 로직
# ==========================================
async def run_analyze(req: AnalyzeRequest) -> AnalyzeResult:
    """
    Orchestrator 기준 + 최신 엔진 결합 파이프라인
    """
    user_text = req.text

    # 1) RAG 검색 — 동기 함수를 스레드풀에서 실행
    try:
        contexts = await run_in_threadpool(
            get_rag_context,
            user_text,
            top_k=req.top_k,
        )
    except Exception as e:
        logger.exception("RAG 검색 실패: %s", e)
        contexts = []

    # 2) 규칙 기반 점수 — 동기 함수 스레드풀 실행
    try:
        rule_score_raw = await run_in_threadpool(calculate_rule_score, user_text)
        rule_score = float(rule_score_raw)
    except Exception as e:
        logger.exception("규칙 엔진 오류: %s", e)
        rule_score = 0.0

    rule_hits: List[RuleHit] = []
    if rule_score > 0.0:
        rule_hits.append(
            RuleHit(
                category="RuleEngine",
                keyword_hits=[],
                regex_hits=[],
                weight=100.0,
                score=rule_score,
            )
        )

    # 3) LLM 분석 — 가장 오래 걸리는 부분
    llm_score = 0.0
    violated_law = ""
    analysis_text = ""
    try:
        llm_result = await run_in_threadpool(
            get_final_analysis_from_llm,
            user_text,
            contexts,
        )
        llm_score = float(llm_result.get("score_llm", 0.0))
        violated_law = llm_result.get("violated_law", "") or ""
        analysis_text = llm_result.get("analysis", "") or ""
    except Exception as e:
        logger.exception("LLM 분석 엔진 오류: %s", e)

    # 4) 앙상블
    final_score = combine_scores(llm_score, rule_score, w_llm=0.7)
    final_label = _score_to_label(final_score)

    # 5) reasons 구성
    reasons: List[str] = []
    if violated_law:
        reasons.append(f"[관련 법률] {violated_law}")
    if analysis_text:
        reasons.append(analysis_text)

    # 6) 결과 패킹
    return AnalyzeResult(
        risk=final_label,
        score=final_score,
        llm_score=llm_score,
        rule_score=rule_score,
        rule_hits=rule_hits,
        reasons=reasons,
        rewrites=[],    
        contexts=contexts,
    )
