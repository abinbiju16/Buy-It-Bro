import uuid
from typing import List, Optional
from sqlalchemy import String, ForeignKey, CheckConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import Base, TimestampMixin

def generate_uuid() -> str:
    return str(uuid.uuid4())

class GroceryList(Base, TimestampMixin):
    __tablename__ = "lists"
    __table_args__ = (
        CheckConstraint(
            "(owner_user_id IS NOT NULL AND group_id IS NULL) OR "
            "(owner_user_id IS NULL AND group_id IS NOT NULL)",
            name="ck_list_exclusive_ownership"
        ),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    title: Mapped[str] = mapped_column(String(150), nullable=False)
    owner_user_id: Mapped[Optional[str]] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=True, index=True
    )
    group_id: Mapped[Optional[str]] = mapped_column(
        String(36), ForeignKey("groups.id", ondelete="CASCADE"), nullable=True, index=True
    )

    # Relationships
    owner: Mapped[Optional["User"]] = relationship("User", back_populates="private_lists")
    group: Mapped[Optional["Group"]] = relationship("Group", back_populates="lists")
    items: Mapped[List["ListItem"]] = relationship(
        "ListItem", back_populates="grocery_list", cascade="all, delete-orphan", order_by="ListItem.created_at"
    )
