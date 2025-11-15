# Domain/Orchestrator/pipeline.py
from __future__ import annotations

import logging
from typing import List

# 🔹 최신 엔진 모듈 (backend/app/engine 안)
from engine.rag_engine import get_rag_context
from engine.rule_engine import calculate_rule_score
from engine.llm_analyzer import get_final_analysis_from_llm

# 🔹 Orchestrator 유틸 (응답 스키마 + 앙상블)
from .ensemble_slot import combine_scores, _score_to_label
from .models import AnalyzeRequest, AnalyzeResult, RuleHit


logger = logging.getLogger(__name__)


async def run_analyze(req: AnalyzeRequest) -> AnalyzeResult:
    """
    Orchestrator 기준 + 최신 엔진 결합 파이프라인

    1) engine.rag_engine → RAG 컨텍스트 검색
    2) engine.rule_engine → 규칙 점수 계산
    3) engine.llm_analyzer → LLM 점수 / 법률 / 분석 받기
    4) ensemble_slot.combine_scores → 최종 score 계산
    5) score → risk 라벨 매핑 (_score_to_label)
    6) AnalyzeResult 형태로 응답
    """
    user_text = req.text

    # 1) RAG 검색 (동기 함수라 그냥 호출)
    try:
        contexts = get_rag_context(user_text, top_k=req.top_k)
    except Exception as e:
        logger.exception("RAG 검색 실패: %s", e)
        contexts = []

    # 2) 규칙 기반 점수 (0.0 또는 1.0)
    try:
        rule_score = float(calculate_rule_score(user_text))
    except Exception as e:
        logger.exception("규칙 엔진 오류: %s", e)
        rule_score = 0.0

    rule_hits: List[RuleHit] = []
    if rule_score > 0.0:
        # 카테고리/히트 상세까지는 rule_engine에 없으므로 최소 정보만 채움
        rule_hits.append(
            RuleHit(
                category="RuleEngine",
                keyword_hits=[],
                regex_hits=[],
                weight=100.0,
                score=rule_score,
            )
        )

    # 3) LLM 분석
    llm_score = 0.0
    violated_law = ""
    analysis_text = ""
    try:
        llm_result = get_final_analysis_from_llm(user_text, contexts)
        llm_score = float(llm_result.get("score_llm", 0.0))
        violated_law = llm_result.get("violated_law", "") or ""
        analysis_text = llm_result.get("analysis", "") or ""
    except Exception as e:
        logger.exception("LLM 분석 엔진 오류: %s", e)

    # 4) 앙상블 (0.7 * LLM + 0.3 * RULE) — 기존 규칙 유지
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
        rewrites=[],   # llm_analyzer는 rewrites 안 주니까 일단 비움
        contexts=contexts,
    )
