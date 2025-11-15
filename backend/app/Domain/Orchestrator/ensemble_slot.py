# ensemble_slot.py
# Orchestrator 최종 점수 앙상블 + 위험도 라벨링

from __future__ import annotations


def combine_scores(llm_score: float, rule_score: float, w_llm: float = 0.7) -> float:
    """
    최종 위험도 점수 계산:
      final = w_llm * LLM + (1 - w_llm) * RULE
    모든 입력값은 0~1 범위로 클램프 처리
    """
    w_llm = max(0.0, min(1.0, float(w_llm)))
    llm_score = max(0.0, min(1.0, float(llm_score)))
    rule_score = max(0.0, min(1.0, float(rule_score)))

    final = (llm_score * w_llm) + (rule_score * (1.0 - w_llm))
    return round(min(1.0, max(0.0, final)), 3)


def _score_to_label(score: float) -> str:
    """
    최종 점수를 위험도 등급으로 매핑
    """
    if score >= 0.75:
        return "High Risk"
    if score >= 0.50:
        return "Threat"
    if score >= 0.20:
        return "Caution"
    return "Safe"