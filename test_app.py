import pytest

from app import ORDERS, app


@pytest.fixture
def client():
    ORDERS.clear()
    app.config["TESTING"] = True
    with app.test_client() as test_client:
        yield test_client


def test_create_order(client):
    response = client.post(
        "/orders", json={"items": [{"sku": "WIDGET-A", "quantity": 2}]}
    )

    assert response.status_code == 201
    assert response.json["items"][0]["unit_price_cents"] == 2500
    assert response.json["total_cents"] == 5000


def test_get_order(client):
    created = client.post(
        "/orders", json={"items": [{"sku": "DESK-LAMP", "quantity": 1}]}
    ).json

    response = client.get(f"/orders/{created['id']}")

    assert response.status_code == 200
    assert response.json == created


def test_unknown_sku_returns_404(client):
    response = client.get("/products/NONEXISTENT")

    assert response.status_code == 404
