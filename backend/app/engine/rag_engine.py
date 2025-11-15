# backend/app/engine/rag_engine.py
# pgvector 기반 RAG DB 검색 엔진 (의미/문맥 기반 공용 모듈)

from __future__ import annotations

import os
import json
from typing import List, Dict, Any

import numpy as np
import psycopg2
from pgvector.psycopg2 import register_vector
from dotenv import load_dotenv
from openai import OpenAI

from core.config import get_config

# ----- 환경 변수 로드 -----
load_dotenv()

# ----- OpenAI / 임베딩 설정 -----
_cfg = get_config()
_CLIENT = OpenAI(api_key=_cfg.openai_api_key)
_EMBED_MODEL = "text-embedding-3-small"
_EMBED_DIM = int(os.getenv("EMBED_DIM", "256"))

# ----- DB 설정 -----
_DB_HOST = os.getenv("RETRIEVAL_DB_HOST")
_DB_PORT = os.getenv("RETRIEVAL_DB_PORT", "5432")
_DB_NAME = os.getenv("RETRIEVAL_DB_NAME")
_DB_USER = os.getenv("RETRIEVAL_DB_USER")
_DB_PASS = os.getenv("RETRIEVAL_DB_PASSWORD")
_TABLE_NAME = os.getenv("RETRIEVAL_TABLE", "legal_embeddings")

if not all([_DB_HOST, _DB_NAME, _DB_USER, _DB_PASS]):
    raise RuntimeError(
        "[RAG] RETRIEVAL_DB_* 환경변수가 설정되지 않았습니다. "
        ".env 에 RETRIEVAL_DB_HOST / RETRIEVAL_DB_NAME / "
        "RETRIEVAL_DB_USER / RETRIEVAL_DB_PASSWORD 를 확인해 주세요."
    )

# ----- DB 커넥션 준비 -----
try:
    _CONN = psycopg2.connect(
        host=_DB_HOST,
        port=_DB_PORT,
        dbname=_DB_NAME,
        user=_DB_USER,
        password=_DB_PASS,
        sslmode="require",
    )
    register_vector(_CONN)
    _CUR = _CONN.cursor()
    print(f"[RAG] pgvector DB 연결 성공: "
          f"{_DB_HOST}:{_DB_PORT}/{_DB_NAME}, table={_TABLE_NAME}")
except Exception as e:
    raise RuntimeError(f"[RAG] pgvector DB 연결 실패: {e}")


# ----- 유틸 함수들 -----
def _cosine(a, b) -> float:
    a = np.array(a, dtype=np.float32)
    b = np.array(b, dtype=np.float32)
    if a.size == 0 or b.size == 0:
        return 0.0
    denom = float(np.linalg.norm(a) * np.linalg.norm(b))
    if denom == 0.0:
        return 0.0
    return float(np.dot(a, b) / denom)


def _clean_text(text: str) -> str:
    """
    RAG 문맥용으로만 간단 정리.
    (search_service의 clean_text와 동일한 로직)
    """
    import re

    text = re.sub(r"\(전화번호[^)]*\)", "", text)
    text = re.sub(r"[A-Za-z]\s*문자", "", text)
    text = re.sub(r"[A-Za-z]\d+", "", text)
    text = re.sub(r"\d{2,4}[:.\-]\d{2,4}", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


# ----- 메인 RAG 함수 -----
def get_rag_context(user_query: str, top_k: int = 5) -> List[Dict[str, Any]]:
    """
    사용자 쿼리를 받아 pgvector 기반으로 유사 문장을 검색해
    다음 형태의 리스트를 반환한다.

    [
      {
        "score": float,          # 코사인 유사도 (0~1 근사)
        "text": str,             # 정리된 chunk_text
        "source_file": str,      # 원본 파일명(또는 ID)
      },
      ...
    ]
    """
    print(f"[RAG] pgvector 기반 검색 시작: query='{user_query}', top_k={top_k}")

    # 1) 쿼리 임베딩
    try:
        emb_resp = _CLIENT.embeddings.create(
            model=_EMBED_MODEL,
            input=user_query,
            dimensions=_EMBED_DIM,
        )
        query_emb = np.array(emb_resp.data[0].embedding, dtype=np.float32)
    except Exception as e:
        print(f"[RAG] 쿼리 임베딩 생성 실패: {e}")
        return []

    # 2) 전체 행 조회 후 파이썬에서 코사인 정렬 (현재 구현과 동일 방식)
    try:
        sql = f"""
            SELECT source_file, chunk_text, embedding
            FROM {_TABLE_NAME}
        """
        _CUR.execute(sql)
        rows = _CUR.fetchall()
    except Exception as e:
        print(f"[RAG] DB 조회 실패: {e}")
        return []

    docs: List[Dict[str, Any]] = []
    scores: List[float] = []

    for source_file, chunk_text, vec in rows:
        # embedding 컬럼이 JSON 문자열일 수도 있으므로 처리
        if isinstance(vec, str):
            try:
                vec = json.loads(vec)
            except Exception:
                continue

        vec_arr = np.array(vec, dtype=np.float32)
        score = _cosine(vec_arr, query_emb)

        docs.append(
            {
                "source_file": source_file,
                "text": _clean_text(chunk_text or ""),
            }
        )
        scores.append(score)

    if not docs:
        print("[RAG] 검색 결과가 비어 있습니다.")
        return []

    # 3) 코사인 유사도 기준으로 정렬 후 상위 top_k 반환
    paired = list(zip(docs, scores))
    paired.sort(key=lambda x: x[1], reverse=True)

    top = paired[: max(1, top_k)]
    contexts: List[Dict[str, Any]] = [
        {
            "score": float(s),
            "text": d["text"],
            "source_file": d["source_file"],
        }
        for d, s in top
    ]

    print("[RAG] 상위 결과:")
    for c in contexts:
        print(f"   - (유사도 {c['score']:.4f}) {c['text'][:80]}...")

    return contexts
