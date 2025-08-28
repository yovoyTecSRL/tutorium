def test_login_required(client):
    resp = client.get("/products")
    assert resp.status_code == 302

def test_admin_access(client, admin_user):
    client.login(admin_user)
    resp = client.get("/admin/users")
    assert resp.status_code == 200
