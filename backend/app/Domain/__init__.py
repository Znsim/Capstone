from pathlib import Path
import importlib
from fastapi import APIRouter

domains = [
    p for p in Path('./Domain').glob('*')
    if p.is_dir() and p.name not in ("__pycache__", "default")
]
names = [domain.name for domain in domains]
routers = []

for domain in domains:
    router_file = Path(domain) / 'router.py'
    if router_file.exists():
        try:
            module_name = f"Domain.{domain.name}.router"
            router_module = importlib.import_module(module_name)
            
            if hasattr(router_module, 'router'):
                router = getattr(router_module, 'router')
                routers.append(router)
            else:
                print(f"Router variable not found in {domain.name}/router.py")
        except ModuleNotFoundError as e:
            print(f"Module {module_name} not found: {e}")
    else:
        print(f"router.py not found in {domain.name}")

router = APIRouter()
i = 0
for r in routers:
    router.include_router(
        r,
        prefix="/"+names[i],
        tags=[f"{names[i]}"],
        dependencies=[],
    )
    i += 1