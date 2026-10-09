import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.main import app
from app.db.session import get_db
from app.models.base import Base

# In-memory SQLite for super-fast, clean isolated testing
TEST_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.fixture(autouse=True)
def setup_database():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)

client = TestClient(app)

def test_full_collaborative_grocery_workflow():
    # 1. Register User A (Alice)
    res_a = client.post("/api/v1/auth/register", json={
        "email": "alice@example.com",
        "password": "password123",
        "display_name": "Alice"
    })
    assert res_a.status_code == 201
    token_a = res_a.json()["access_token"]
    headers_a = {"Authorization": f"Bearer {token_a}"}

    # 2. Register User B (Bob)
    res_b = client.post("/api/v1/auth/register", json={
        "email": "bob@example.com",
        "password": "password123",
        "display_name": "Bob"
    })
    assert res_b.status_code == 201
    token_b = res_b.json()["access_token"]
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # 3. Alice creates a private list
    res_list = client.post("/api/v1/me/lists", headers=headers_a, json={
        "title": "Alice's Secret Snacks"
    })
    assert res_list.status_code == 201
    private_list_id = res_list.json()["id"]

    # 4. Bob tries to access Alice's private list -> MUST BE 403 FORBIDDEN
    res_bob_leak = client.get(f"/api/v1/lists/{private_list_id}", headers=headers_b)
    assert res_bob_leak.status_code == 403

    # 5. Alice creates a Group "Apartment 101"
    res_group = client.post("/api/v1/groups", headers=headers_a, json={
        "name": "Apartment 101"
    })
    assert res_group.status_code == 201
    group_id = res_group.json()["id"]

    # 6. Alice creates an invitation link for the group
    res_inv = client.post(f"/api/v1/groups/{group_id}/invitations", headers=headers_a, json={
        "role": "MEMBER",
        "expires_in_days": 7
    })
    assert res_inv.status_code == 200
    invite_token = res_inv.json()["token"]

    # 7. Bob accepts the invitation and joins the group
    res_join = client.post("/api/v1/invitations/accept", headers=headers_b, json={
        "token": invite_token
    })
    assert res_join.status_code == 200

    # 8. Bob creates a shared list in the group "Weekend Groceries"
    res_shared_list = client.post(f"/api/v1/groups/{group_id}/lists", headers=headers_b, json={
        "title": "Weekend Groceries"
    })
    assert res_shared_list.status_code == 201
    shared_list_id = res_shared_list.json()["id"]

    # 9. Alice adds "Basmati Rice" - 5 kg to the shared list
    res_item = client.post(f"/api/v1/lists/{shared_list_id}/items", headers=headers_a, json={
        "name": "Basmati Rice",
        "quantity": 5.0,
        "unit": "kg",
        "note": "Get royal brand"
    })
    assert res_item.status_code == 201
    item_id = res_item.json()["id"]
    assert res_item.json()["is_checked"] is False

    # 10. Bob views the shared list and sees the item added by Alice
    res_bob_view = client.get(f"/api/v1/lists/{shared_list_id}", headers=headers_b)
    assert res_bob_view.status_code == 200
    assert len(res_bob_view.json()["items"]) == 1
    assert res_bob_view.json()["items"][0]["name"] == "Basmati Rice"

    # 11. Bob marks the item as purchased (is_checked = True)
    res_check = client.patch(f"/api/v1/lists/{shared_list_id}/items/{item_id}", headers=headers_b, json={
        "is_checked": True
    })
    assert res_check.status_code == 200
    assert res_check.json()["is_checked"] is True

    # 12. Alice views the list again and sees it is now marked as purchased!
    res_alice_view = client.get(f"/api/v1/lists/{shared_list_id}", headers=headers_a)
    assert res_alice_view.status_code == 200
    assert res_alice_view.json()["checked_count"] == 1
    assert res_alice_view.json()["items"][0]["is_checked"] is True
