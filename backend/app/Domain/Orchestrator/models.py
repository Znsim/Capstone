from pydantic import BaseModel, Field
from typing import List,Literal, Dict, Any

RiskLabel = Literal["Safe","Caution","Threat","High Risk","Unknown"]

class RewriteItem(BaseModel):
    tone: str
    text: str

class RuleHit(BaseModel):
    category: str
    keyword_hits: List[str] = Field(default_factory=list)
    regex_hits: List[str] = Field(default_factory=list)
    weight: float = 0.0
    score: float = 0.0

class AnalyzeRequest(BaseModel):
    text: str
    top_k: int = 3

class AnalyzeResult(BaseModel):
    risk: RiskLabel = "Safe"
    score: float = Field(0.0, ge=0.0, le=1.0)         # 최종 앙상블 점수
    llm_score: float = 0.0
    rule_score: float = 0.0
    rule_hits: List[RuleHit] = Field(default_factory=list)
    reasons: List[str] = Field(default_factory=list)
    rewrites: List[RewriteItem] = Field(default_factory=list)
    contexts: List[Dict[str, Any]] = Field(default_factory=list)
    
