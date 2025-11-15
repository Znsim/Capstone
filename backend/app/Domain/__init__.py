from pathlib import Path
import importlib
from fastapi import APIRouter

# 📁 Domain/ 하위 폴더 중 "__pycache__"와 "default"는 제외
domains = [
    p for p in Path(__file__).resolve().parent.glob('*')
    if p.is_dir() and p.name not in ("__pycache__", "default")
]

routers = []

for domain in domains:
    router_file = domain / 'router.py'
    if router_file.exists():
        try:
            module_name = f"Domain.{domain.name}.router"
            router_module = importlib.import_module(module_name)

            if hasattr(router_module, 'router'):
                router = getattr(router_module, 'router')
                routers.append(router)
            else:
                print(f"❌ 'router' 변수 없음: {domain.name}/router.py")
        except ModuleNotFoundError as e:
            print(f"❌ 모듈 임포트 실패: {module_name} → {e}")
    else:
        print(f"❌ router.py 없음: {domain.name}/router.py")
