from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.user import User
from app.models.item import ListItem
from app.schemas.item import ListItemCreate, ListItemUpdate, ListItemResponse
from app.services.list_access import check_list_access
from app.api.deps import get_current_user

router = APIRouter(prefix="/lists/{list_id}/items", tags=["Item Management"])

@router.post("", response_model=ListItemResponse, status_code=status.HTTP_201_CREATED)
def add_item_to_list(
    list_id: str,
    item_in: ListItemCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    check_list_access(db, list_id, current_user, require_write=True)
    
    new_item = ListItem(
        list_id=list_id,
        name=item_in.name.strip(),
        quantity=item_in.quantity,
        unit=item_in.unit.strip(),
        note=item_in.note.strip() if item_in.note else None,
        is_checked=False,
        version=1
    )
    db.add(new_item)
    db.commit()
    db.refresh(new_item)
    return new_item

@router.patch("/{item_id}", response_model=ListItemResponse)
def update_item(
    list_id: str,
    item_id: str,
    item_in: ListItemUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    check_list_access(db, list_id, current_user, require_write=True)
    
    item = db.query(ListItem).filter(
        ListItem.id == item_id,
        ListItem.list_id == list_id
    ).first()
    
    if not item:
        raise HTTPException(status_code=404, detail="Item not found in this list")
        
    # Optimistic Concurrency Control Check
    if item_in.expected_version is not None and item.version != item_in.expected_version:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Item was updated by another member. Please refresh."
        )
        
    if item_in.name is not None:
        item.name = item_in.name.strip()
    if item_in.quantity is not None:
        item.quantity = item_in.quantity
    if item_in.unit is not None:
        item.unit = item_in.unit.strip()
    if item_in.is_checked is not None:
        item.is_checked = item_in.is_checked
    if item_in.note is not None:
        item.note = item_in.note.strip() if item_in.note else None
        
    # Increment version
    item.version += 1
    
    db.commit()
    db.refresh(item)
    return item

@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_item(
    list_id: str,
    item_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    check_list_access(db, list_id, current_user, require_write=True)
    
    item = db.query(ListItem).filter(
        ListItem.id == item_id,
        ListItem.list_id == list_id
    ).first()
    
    if not item:
        raise HTTPException(status_code=404, detail="Item not found in this list")
        
    db.delete(item)
    db.commit()
    return None
