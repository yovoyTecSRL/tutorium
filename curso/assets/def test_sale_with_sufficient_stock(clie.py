def test_sale_with_sufficient_stock(client, admin_user, product):
    client.login(admin_user)
    resp = client.post("/pos/checkout", data={
        "cart": [{"product_id": product.id, "qty": 2, "unit_price": product.price, "tax_rate": product.tax_rate, "discount_percent": 0}],
        "customer_id": 1,
        "payments": [{"method": "cash", "amount": product.price * 2}],
    })
    assert resp.status_code == 200

def test_sale_with_insufficient_stock(client, admin_user, product):
    client.login(admin_user)
    resp = client.post("/pos/checkout", data={
        "cart": [{"product_id": product.id, "qty": 999, "unit_price": product.price, "tax_rate": product.tax_rate, "discount_percent": 0}],
        "customer_id": 1,
        "payments": [{"method": "cash", "amount": product.price * 999}],
    })
    assert b"Stock insuficiente" in resp.data
