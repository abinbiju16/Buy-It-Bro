import uuid
from typing import List
from sqlalchemy import String, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import Base, TimestampMixin

def generate_uuid() -> str:
    return str(uuid.uuid4())

class User(Base, TimestampMixin):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    display_name: Mapped[str] = mapped_column(String(100), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Relationships
    group_memberships: Mapped[List["GroupMember"]] = relationship("GroupMember", back_populates="user", cascade="all, delete-orphan")
    private_lists: Mapped[List["GroceryList"]] = relationship("GroceryList", back_populates="owner", cascade="all, delete-orphan")
