# backend/app/Domain/retrieval/search_service.py

import os
import re
import json
from typing import List, Dict, Any

from dotenv import load_dotenv

from engine.rag_engine import get_rag_context  # 🔹 공용 RAG 엔진 사용

load_dotenv()

# ========== ① 경로 세팅 ==========
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
LEX_PATH = os.path.join(BASE_DIR, "risk_lexemes.jsonl")
PAT_PATH = os.path.join(BASE_DIR, "risk_patterns.jsonl")


# ========== ② 욕설 사전 로드 ==========
def load_lexemes(path: str) -> List[str]:
    words: List[str] = []
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                try:
                    item = json.loads(line)
                    if item.get("category") == "profanity":
                        words.append(item["term"])
                except Exception:
                    continue
    return words


def load_patterns(path: str) -> List[str]:
    patterns: List[str] = []
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                try:
                    item = json.loads(line)
                    if item.get("category") == "profanity":
                        patterns.append(item["pattern"])
                except Exception:
                    continue
    return patterns


LEXEMES = load_lexemes(LEX_PATH)
PATTERNS = load_patterns(PAT_PATH)
print(f"🚀 Loaded {len(LEXEMES)} lexemes, {len(PATTERNS)} patterns.")


# ========== ③ 텍스트 전처리 (fallback, 필요 시 사용) ==========
def clean_text(text: str) -> str:
    text = re.sub(r"\(전화번호[^)]*\)", "", text)
    text = re.sub(r"[A-Za-z]\s*문자", "", text)
    text = re.sub(r"[A-Za-z]\d+", "", text)
    text = re.sub(r"\d{2,4}[:.\-]\d{2,4}", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


# ========== ④ 욕 탐지 ==========
def detect_profanity(query: str) -> List[str]:
    hits: List[str] = []
    clean_query = re.sub(r"[\s·♡❤💖⭐️\*]+", "", query.lower())

    for w in LEXEMES:
        if re.search(rf"{re.escape(w)}", clean_query):
            hits.append(w)

    for p in PATTERNS:
        if re.search(p, clean_query):
            hits.append(p)

    # TODO: “시발” ↔ “씨발” 같은 변형 매핑을 넣고 싶으면 여기에 추가
    return list(set(hits))


# ========== ⑤ 검색 (pgvector RAG + 욕설 필터 래핑) ==========
def search_jsonl(query: str, top_k: int = 5) -> Dict[str, Any]:
    """
    - engine.rag_engine.get_rag_context() 를 호출해서 pgvector RAG 검색을 수행하고
    - 욕이 섞인 쿼리라면, 욕이 들어간 문장 위주로 필터링하는 하이브리드 모드로 동작
    - 최종 결과는 기존과 같은 형태:
      {"results": [{"score": ..., "source_file": ..., "chunk_text": ...}, ...]}
    """
    print(f"[테스트 쿼리]: {query}")
    bad_hits = detect_profanity(query)
    is_profanity_query = len(bad_hits) > 0
    print(f"  -> 감지된 욕: {bad_hits if bad_hits else '없음'}")
    print(f"  -> 모드: {'⚠️ 욕설 탐지 모드' if is_profanity_query else '💬 일반 검색 모드'}")

    # 🔹 RAG 컨텍스트 (pgvector + OpenAI 임베딩) 호출
    #    욕 필터링을 위해 여유 있게 top_k*3 정도 가져오고 나중에 다시 슬라이싱
    raw_contexts = get_rag_context(query, top_k=max(top_k * 3, top_k))

    if not raw_contexts:
        print("⚠️ RAG 검색 결과가 없어 기본 법령 반환.")
        return {
            "results": [
                {
                    "score": 1.0,
                    "source_file": "default",
                    "chunk_text": (
                        "형법 제311조(모욕) 공연히 사람을 모욕한 자는 "
                        "1년 이하의 징역 또는 200만원 이하의 벌금에 처한다."
                    ),
                }
            ]
        }

    # 🔹 욕설 쿼리인 경우, 욕이 포함된 문장만 필터링
    contexts = raw_contexts
    if is_profanity_query:
        filtered: List[Dict[str, Any]] = []
        for c in raw_contexts:
            text = (c.get("text") or "").lower()
            if any(w in text for w in bad_hits):
                filtered.append(c)

        if filtered:
            contexts = filtered
        else:
            # 욕 감지는 됐지만, RAG 결과에 욕이 안 들어간 경우 → 그냥 RAG 결과 사용
            contexts = raw_contexts

    # 🔹 최종 top_k만 잘라서 기존 스키마에 맞게 변환
    top_contexts = contexts[:top_k]

    top_results = [
        {
            "score": float(c.get("score", 0.0)),
            "source_file": c.get("source_file", "unknown"),
            "chunk_text": c.get("text", ""),
        }
        for c in top_contexts
    ]

    print("2. RAG 검색 결과 (상위 결과):")
    for r in top_results:
        print(f"   - (유사도 {r['score']:.4f}) {r['chunk_text'][:80]}...")

    return {"results": top_results}


print("✅ Using engine.rag_engine(pgvector) + local profanity hybrid search model.")
