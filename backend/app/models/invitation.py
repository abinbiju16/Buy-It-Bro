import uuid
from datetime import datetime
from sqlalchemy import String, ForeignKey, Boolean, DateTime, CheckConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import Base, TimestampMixin

def generate_uuid() -> str:
    return str(uuid.uuid4())

class Invitation(Base, TimestampMixin):
    __tablename__ = "invitations"
    __table_args__ = (
        CheckConstraint("role IN ('ADMIN', 'MEMBER')", name="ck_invitation_role"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    group_id: Mapped[str] = mapped_column(String(36), ForeignKey("groups.id", ondelete="CASCADE"), nullable=False, index=True)
    token_hash: Mapped[str] = mapped_column(String(64), unique=True, nullable=False, index=True)
    role: Mapped[str] = mapped_column(String(20), default="MEMBER", nullable=False)
    created_by: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    is_revoked: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    group: Mapped["Group"] = relationship("Group", back_populates="invitations")
