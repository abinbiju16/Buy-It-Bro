from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.user import User
from app.models.list import GroceryList
from app.models.group import GroupMember
from app.schemas.list import ListUpdate, ListResponse
from app.schemas.item import ListItemResponse
from app.services.list_access import check_list_access
from app.api.deps import get_current_user

router = APIRouter(prefix="/lists", tags=["List Management"])

@router.get("/{list_id}", response_model=ListResponse)
def get_list(
    list_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    l = check_list_access(db, list_id, current_user)
    total = len(l.items)
    checked = sum(1 for item in l.items if item.is_checked)
    
    return ListResponse(
        id=l.id,
        title=l.title,
        owner_user_id=l.owner_user_id,
        group_id=l.group_id,
        item_count=total,
        checked_count=checked,
        created_at=l.created_at,
        updated_at=l.updated_at,
        items=[ListItemResponse.model_validate(it) for it in l.items]
    )

@router.patch("/{list_id}", response_model=ListResponse)
def update_list(
    list_id: str,
    list_in: ListUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    l = check_list_access(db, list_id, current_user, require_write=True)
    if list_in.title is not None:
        l.title = list_in.title.strip()
    db.commit()
    db.refresh(l)
    
    total = len(l.items)
    checked = sum(1 for item in l.items if item.is_checked)
    return ListResponse(
        id=l.id,
        title=l.title,
        owner_user_id=l.owner_user_id,
        group_id=l.group_id,
        item_count=total,
        checked_count=checked,
        created_at=l.created_at,
        updated_at=l.updated_at,
        items=[ListItemResponse.model_validate(it) for it in l.items]
    )

@router.delete("/{list_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_list(
    list_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    l = check_list_access(db, list_id, current_user, require_write=True)
    
    # If group list, only group ADMIN or creator can delete
    if l.group_id:
        membership = db.query(GroupMember).filter(
            GroupMember.group_id == l.group_id,
            GroupMember.user_id == current_user.id
        ).first()
        if not membership or membership.role != "ADMIN":
            raise HTTPException(status_code=403, detail="Only group admins can delete group lists")
            
    db.delete(l)
    db.commit()
    return None
