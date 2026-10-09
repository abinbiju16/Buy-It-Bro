from fastapi import APIRouter
from app.api.v1.auth import router as auth_router
from app.api.v1.personal_lists import router as personal_lists_router
from app.api.v1.groups import router as groups_router
from app.api.v1.lists import router as lists_router
from app.api.v1.items import router as items_router

api_router = APIRouter()
api_router.include_router(auth_router)
api_router.include_router(personal_lists_router)
api_router.include_router(groups_router)
api_router.include_router(lists_router)
api_router.include_router(items_router)
