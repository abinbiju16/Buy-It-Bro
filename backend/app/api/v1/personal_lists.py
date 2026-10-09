from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.user import User
from app.models.list import GroceryList
from app.schemas.list import ListCreate, ListResponse
from app.schemas.item import ListItemResponse
from app.api.deps import get_current_user

router = APIRouter(prefix="/me/lists", tags=["Personal Lists"])

@router.get("", response_model=List[ListResponse])
def get_my_lists(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    lists = db.query(GroceryList).filter(GroceryList.owner_user_id == current_user.id).order_by(GroceryList.created_at.desc()).all()
    results = []
    for l in lists:
        total = len(l.items)
        checked = sum(1 for item in l.items if item.is_checked)
        results.append(ListResponse(
            id=l.id,
            title=l.title,
            owner_user_id=l.owner_user_id,
            group_id=l.group_id,
            item_count=total,
            checked_count=checked,
            created_at=l.created_at,
            updated_at=l.updated_at,
            items=[ListItemResponse.model_validate(it) for it in l.items]
        ))
    return results

@router.post("", response_model=ListResponse, status_code=status.HTTP_201_CREATED)
def create_personal_list(
    list_in: ListCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    new_list = GroceryList(
        title=list_in.title.strip(),
        owner_user_id=current_user.id,
        group_id=None
    )
    db.add(new_list)
    db.commit()
    db.refresh(new_list)
    
    return ListResponse(
        id=new_list.id,
        title=new_list.title,
        owner_user_id=new_list.owner_user_id,
        group_id=new_list.group_id,
        item_count=0,
        checked_count=0,
        created_at=new_list.created_at,
        updated_at=new_list.updated_at,
        items=[]
    )
