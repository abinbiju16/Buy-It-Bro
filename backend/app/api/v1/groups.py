import secrets
import hashlib
from datetime import datetime, timedelta, timezone
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.user import User
from app.models.group import Group, GroupMember
from app.models.list import GroceryList
from app.models.invitation import Invitation
from app.schemas.group import (
    GroupCreate, GroupUpdate, GroupResponse, GroupMemberResponse,
    InvitationCreate, InvitationResponse, InvitationAccept
)
from app.schemas.list import ListCreate, ListResponse
from app.schemas.item import ListItemResponse
from app.schemas.user import UserResponse
from app.api.deps import get_current_user

router = APIRouter(tags=["Groups & Collaboration"])

@router.get("/groups", response_model=List[GroupResponse])
def get_user_groups(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    memberships = db.query(GroupMember).filter(GroupMember.user_id == current_user.id).all()
    results = []
    for m in memberships:
        g = m.group
        member_count = len(g.members)
        list_count = len(g.lists)
        results.append(GroupResponse(
            id=g.id,
            name=g.name,
            created_by=g.created_by,
            created_at=g.created_at,
            member_count=member_count,
            list_count=list_count
        ))
    return results

@router.post("/groups", response_model=GroupResponse, status_code=status.HTTP_201_CREATED)
def create_group(
    group_in: GroupCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    new_group = Group(
        name=group_in.name.strip(),
        created_by=current_user.id
    )
    db.add(new_group)
    db.flush()  # assign new_group.id
    
    # Creator becomes ADMIN
    admin_member = GroupMember(
        group_id=new_group.id,
        user_id=current_user.id,
        role="ADMIN"
    )
    db.add(admin_member)
    db.commit()
    db.refresh(new_group)
    
    return GroupResponse(
        id=new_group.id,
        name=new_group.name,
        created_by=new_group.created_by,
        created_at=new_group.created_at,
        member_count=1,
        list_count=0
    )

@router.get("/groups/{group_id}", response_model=GroupResponse)
def get_group_details(
    group_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Verify user is a member
    membership = db.query(GroupMember).filter(
        GroupMember.group_id == group_id,
        GroupMember.user_id == current_user.id
    ).first()
    if not membership:
        raise HTTPException(status_code=403, detail="You are not a member of this group")
    
    group = db.query(Group).filter(Group.id == group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
    
    members = []
    for m in group.members:
        u = db.query(User).filter(User.id == m.user_id).first()
        members.append(GroupMemberResponse(
            id=m.id,
            group_id=m.group_id,
            user_id=m.user_id,
            role=m.role,
            joined_at=m.created_at,
            user=UserResponse.model_validate(u) if u else None
        ))
    
    return GroupResponse(
        id=group.id,
        name=group.name,
        created_by=group.created_by,
        created_at=group.created_at,
        members=members,
        member_count=len(members),
        list_count=len(group.lists)
    )

@router.patch("/groups/{group_id}", response_model=GroupResponse)
def update_group(
    group_id: str,
    group_in: GroupUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    membership = db.query(GroupMember).filter(
        GroupMember.group_id == group_id,
        GroupMember.user_id == current_user.id
    ).first()
    if not membership or membership.role != "ADMIN":
        raise HTTPException(status_code=403, detail="Only group admins can rename the group")
    
    group = db.query(Group).filter(Group.id == group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
        
    group.name = group_in.name.strip()
    db.commit()
    db.refresh(group)
    
    return GroupResponse(
        id=group.id,
        name=group.name,
        created_by=group.created_by,
        created_at=group.created_at,
        member_count=len(group.members),
        list_count=len(group.lists)
    )

@router.delete("/groups/{group_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_group(
    group_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    membership = db.query(GroupMember).filter(
        GroupMember.group_id == group_id,
        GroupMember.user_id == current_user.id
    ).first()
    if not membership or membership.role != "ADMIN":
        raise HTTPException(status_code=403, detail="Only group admins can delete the group")
        
    group = db.query(Group).filter(Group.id == group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
        
    db.delete(group)
    db.commit()
    return None

@router.post("/groups/{group_id}/invitations", response_model=InvitationResponse)
def create_invitation(
    group_id: str,
    inv_in: InvitationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Must be admin of group
    membership = db.query(GroupMember).filter(
        GroupMember.group_id == group_id,
        GroupMember.user_id == current_user.id
    ).first()
    if not membership or membership.role != "ADMIN":
        raise HTTPException(status_code=403, detail="Only group admins can create invite links")
    
    raw_token = secrets.token_urlsafe(32)
    token_hash = hashlib.sha256(raw_token.encode()).hexdigest()
    expires_at = datetime.now(timezone.utc) + timedelta(days=inv_in.expires_in_days)
    
    invitation = Invitation(
        group_id=group_id,
        token_hash=token_hash,
        role=inv_in.role,
        created_by=current_user.id,
        expires_at=expires_at
    )
    db.add(invitation)
    db.commit()
    db.refresh(invitation)
    
    return InvitationResponse(
        id=invitation.id,
        group_id=invitation.group_id,
        role=invitation.role,
        token=raw_token,
        expires_at=invitation.expires_at,
        created_at=invitation.created_at
    )

@router.post("/invitations/accept", response_model=GroupResponse)
def accept_invitation(
    accept_in: InvitationAccept,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    token_hash = hashlib.sha256(accept_in.token.encode()).hexdigest()
    invitation = db.query(Invitation).filter(Invitation.token_hash == token_hash).first()
    
    if not invitation:
        raise HTTPException(status_code=404, detail="Invalid invitation token")
    if invitation.is_revoked:
        raise HTTPException(status_code=400, detail="This invitation has been revoked")
    expires_at = invitation.expires_at
    now = datetime.now(timezone.utc) if expires_at.tzinfo is not None else datetime.now(timezone.utc).replace(tzinfo=None)
    if expires_at < now:
        raise HTTPException(status_code=400, detail="This invitation has expired")
    
    # Check if already a member
    existing_member = db.query(GroupMember).filter(
        GroupMember.group_id == invitation.group_id,
        GroupMember.user_id == current_user.id
    ).first()
    if existing_member:
        group = db.query(Group).filter(Group.id == invitation.group_id).first()
        return GroupResponse(
            id=group.id,
            name=group.name,
            created_by=group.created_by,
            created_at=group.created_at,
            member_count=len(group.members),
            list_count=len(group.lists)
        )
    
    new_member = GroupMember(
        group_id=invitation.group_id,
        user_id=current_user.id,
        role=invitation.role
    )
    db.add(new_member)
    db.commit()
    
    group = db.query(Group).filter(Group.id == invitation.group_id).first()
    return GroupResponse(
        id=group.id,
        name=group.name,
        created_by=group.created_by,
        created_at=group.created_at,
        member_count=len(group.members),
        list_count=len(group.lists)
    )

@router.get("/groups/{group_id}/lists", response_model=List[ListResponse])
def get_group_lists(
    group_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Verify membership
    membership = db.query(GroupMember).filter(
        GroupMember.group_id == group_id,
        GroupMember.user_id == current_user.id
    ).first()
    if not membership:
        raise HTTPException(status_code=403, detail="You are not a member of this group")
    
    lists = db.query(GroceryList).filter(GroceryList.group_id == group_id).order_by(GroceryList.created_at.desc()).all()
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

@router.post("/groups/{group_id}/lists", response_model=ListResponse, status_code=status.HTTP_201_CREATED)
def create_group_list(
    group_id: str,
    list_in: ListCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Verify membership
    membership = db.query(GroupMember).filter(
        GroupMember.group_id == group_id,
        GroupMember.user_id == current_user.id
    ).first()
    if not membership:
        raise HTTPException(status_code=403, detail="You are not a member of this group")
    
    new_list = GroceryList(
        title=list_in.title.strip(),
        owner_user_id=None,
        group_id=group_id
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
