def test_create_product(client, admin_user):
    client.login(admin_user)
    resp = client.post("/products/create", data={
        "sku": "SKU9999",
        "name": "Test Product",
        "price": 99.99,
        "cost": 50.00,
        "tax_rate": 0.16,
        "stock": 10,
        "is_active": True,
    })
    assert resp.status_code == 302
