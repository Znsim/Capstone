from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from Domain import routers
from core.database import init_db
from core.config import get_config
from Domain import routers
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse  
from pathlib import Path

app = FastAPI(
    openapi_url="/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

for router in routers:
    app.include_router(router)

# 정적 파일 서빙
static_dir = Path(__file__).resolve().parent / "static"
if static_dir.exists():
    app.mount("/static", StaticFiles(directory=static_dir), name="static")

# 채팅 페이지 엔드포인트  
@app.get("/chat", response_class=HTMLResponse)
async def get_chat_page():
    chat_file = Path(__file__).resolve().parent / "static" / "chat.html"
    if chat_file.exists():
        with open(chat_file, "r", encoding="utf-8") as f:
            html_content = f.read()
        return HTMLResponse(content=html_content)
    else:
        return HTMLResponse(content="<h1>Chat page not found</h1>", status_code=404)

# 루트 리다이렉트
@app.get("/")
async def root():
    from fastapi.responses import RedirectResponse
    return RedirectResponse(url="/chat")

init_db(config=get_config())

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)