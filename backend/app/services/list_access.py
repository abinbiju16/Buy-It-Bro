from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.models.list import GroceryList
from app.models.group import GroupMember
from app.models.user import User

def check_list_access(db: Session, list_id: str, user: User, require_write: bool = False) -> GroceryList:
    """Verifies that the user has permission to access or modify a list."""
    grocery_list = db.query(GroceryList).filter(GroceryList.id == list_id).first()
    if not grocery_list:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="List not found"
        )
    
    # 1. Private List: only owner can access
    if grocery_list.owner_user_id:
        if grocery_list.owner_user_id != user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have access to this private list"
            )
        return grocery_list

    # 2. Group List: user must be an active member of the group
    if grocery_list.group_id:
        membership = db.query(GroupMember).filter(
            GroupMember.group_id == grocery_list.group_id,
            GroupMember.user_id == user.id
        ).first()
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You are not a member of the group that owns this list"
            )
        return grocery_list

    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail="List has invalid ownership metadata"
    )
