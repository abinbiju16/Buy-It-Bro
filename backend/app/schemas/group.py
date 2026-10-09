from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict
from app.schemas.user import UserResponse

class GroupMemberResponse(BaseModel):
    id: str
    group_id: str
    user_id: str
    role: str
    joined_at: datetime
    user: Optional[UserResponse] = None
    model_config = ConfigDict(from_attributes=True)

class GroupCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=120)

class GroupResponse(BaseModel):
    id: str
    name: str
    created_by: str
    created_at: datetime
    members: Optional[List[GroupMemberResponse]] = None
    member_count: int = 0
    list_count: int = 0
    model_config = ConfigDict(from_attributes=True)

class InvitationCreate(BaseModel):
    role: str = Field(default="MEMBER", pattern="^(ADMIN|MEMBER)$")
    expires_in_days: int = Field(default=7, ge=1, le=30)

class InvitationResponse(BaseModel):
    id: str
    group_id: str
    role: str
    token: str
    expires_at: datetime
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

class InvitationAccept(BaseModel):
    token: str
