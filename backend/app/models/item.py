import uuid
from typing import Optional
from decimal import Decimal
from sqlalchemy import String, Numeric, Boolean, Text, Integer, ForeignKey, CheckConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import Base, TimestampMixin

def generate_uuid() -> str:
    return str(uuid.uuid4())

class ListItem(Base, TimestampMixin):
    __tablename__ = "list_items"
    __table_args__ = (
        CheckConstraint("quantity >= 0", name="ck_item_positive_quantity"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    list_id: Mapped[str] = mapped_column(String(36), ForeignKey("lists.id", ondelete="CASCADE"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    quantity: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False, default=Decimal("1.00"))
    unit: Mapped[str] = mapped_column(String(30), nullable=False, default="pieces")
    is_checked: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False, index=True)
    note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)

    grocery_list: Mapped["GroceryList"] = relationship("GroceryList", back_populates="items")
