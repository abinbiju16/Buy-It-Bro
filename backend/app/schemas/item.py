from datetime import datetime
from decimal import Decimal
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict

class ListItemBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    quantity: Decimal = Field(default=Decimal("1.00"), ge=0)
    unit: str = Field(default="pieces", max_length=30)
    note: Optional[str] = Field(None, max_length=500)

class ListItemCreate(ListItemBase):
    pass

class ListItemUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    quantity: Optional[Decimal] = Field(None, ge=0)
    unit: Optional[str] = Field(None, max_length=30)
    is_checked: Optional[bool] = None
    note: Optional[str] = None
    expected_version: Optional[int] = Field(None, description="For optimistic concurrency control")

class ListItemResponse(ListItemBase):
    id: str
    list_id: str
    is_checked: bool
    version: int
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)
