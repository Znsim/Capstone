# engine/llm_analyzer.py
# GPT-5-mini 분석 엔진 (LLM 기반)

from __future__ import annotations

import json
from typing import List, Dict, Any

from openai import OpenAI
from core.config import get_config


# ----- 설정 및 OpenAI 클라이언트 -----
_cfg = get_config()
_CLIENT = OpenAI(api_key=_cfg.openai_api_key)
_MODEL_LLM = _cfg.llm_model or "gpt-5-mini"


def _build_prompt(user_query: str, rag_context_list: List[Dict[str, Any]]) -> tuple[str, str]:
    """
    시스템/유저 프롬프트를 생성해서 반환.
    (예전 llm_analyzer.py의 프롬프트 형식을 최대한 유지)
    """
    context_str = "\n\n".join([str(item.get("text", "")) for item in (rag_context_list or [])])

    system_prompt = """
당신은 AI 법률 리스크 분석가입니다.
사용자의 [입력 문장]과 [관련 법률 근거]를 참고하여, 법적 위험도를 0.0~1.0 사이로 평가하고,
위험도 기준표에 따라 'violated_law'와 'analysis_and_cases'를 작성해 주세요.

[위험도 기준표]
- 0.8 ~ 1.0 (High Risk): 명예훼손, 모욕, 협박 등 형법상 처벌 위험이 명백함. 
- 0.6 ~ 0.8 (Threat): 욕설, 비하, 위협적 표현이 포함되어 형사적 위험 가능성이 있음. 
- 0.3 ~ 0.6 (Caution): 오해의 여지가 있거나, 경미한 비방이 포함됨. 
- 0.0 ~ 0.3 (Safe): 법적 문제 없음. 

오직 아래와 같은 JSON 형식으로만 응답해야 합니다:
{
  "score_llm": 0.9,
  "violated_law": "형법 제311조(모욕)",
  "analysis_and_cases": "입력 문장에 포함된 특정 표현이 어떤 법률에 저촉될 수 있는지와, 관련 판례/사례를 간단히 설명합니다."
}
""".strip()

    user_prompt = f"""
[관련 법률 근거]:
{context_str}

[입력 문장]:
"{user_query}"

[응답 JSON]:
""".strip()

    return system_prompt, user_prompt


def get_final_analysis_from_llm(
    user_query: str,
    rag_context_list: List[Dict[str, Any]],
) -> Dict[str, Any]:
    """
    사용자 쿼리와 RAG 근거를 받아 'LLM 점수'와 '분석 리포트'를 반환.

    반환 형식 예:
    {
      "score_llm": 0.9,
      "violated_law": "형법 제311조(모욕)",
      "analysis": "..."
    }
    """
    print("LLM이 문맥 위험도(Score_llm) 및 최종 리포트 생성 중...")

    system_prompt, user_prompt = _build_prompt(user_query, rag_context_list)

    try:
        resp = _CLIENT.chat.completions.create(
            model=_MODEL_LLM,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            response_format={"type": "json_object"},
        )

        raw = resp.choices[0].message.content
        data = json.loads(raw)

        score_llm = float(data.get("score_llm", 0.0))
        violated_law = data.get("violated_law", "") or ""
        analysis = data.get("analysis_and_cases", "") or ""

        return {
            "score_llm": score_llm,
            "violated_law": violated_law,
            "analysis": analysis,
        }

    except Exception as e:
        print(f"LLM 점수/분석 생성 중 오류: {e}")
        return {
            "score_llm": 0.0,
            "violated_law": "",
            "analysis": f"LLM 분석 실패: {e}",
        }
