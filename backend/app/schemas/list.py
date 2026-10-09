from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict
from app.schemas.item import ListItemResponse

class ListCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=150)

class ListUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=150)

class ListResponse(BaseModel):
    id: str
    title: str
    owner_user_id: Optional[str] = None
    group_id: Optional[str] = None
    item_count: int = 0
    checked_count: int = 0
    created_at: datetime
    updated_at: datetime
    items: Optional[List[ListItemResponse]] = None
    model_config = ConfigDict(from_attributes=True)
