# ===================================================================
# Manual SSL Configuration for Tutorium
# Copy and paste this into your server terminal
# ===================================================================

# 1. Update system
sudo apt update && sudo apt upgrade -y

# 2. Install required packages
sudo apt install -y nginx certbot python3-certbot-nginx

# 3. Create web directory
sudo mkdir -p /var/www/tutorium

# 4. Create temporary index.html
sudo tee /var/www/tutorium/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tutorium - SSL Setup</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            margin: 0;
            padding: 50px;
            text-align: center;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: rgba(255,255,255,0.1);
            padding: 40px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }
        h1 { color: #fff; font-size: 2.5em; margin-bottom: 20px; }
        .loading { font-size: 1.2em; margin: 20px 0; }
        .icon { font-size: 3em; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">🔒</div>
        <h1>Tutorium SSL Setup</h1>
        <div class="loading">Configurando certificados SSL...</div>
        <p>Domain: tutorium.sistemasorbix.com</p>
        <p>Status: Configurando servidor...</p>
    </div>
</body>
</html>
EOF

# 5. Set permissions
sudo chown -R www-data:www-data /var/www/tutorium
sudo chmod -R 755 /var/www/tutorium

# 6. Create initial Nginx config
sudo tee /etc/nginx/sites-available/tutorium > /dev/null << 'EOF'
server {
    listen 80;
    server_name tutorium.sistemasorbix.com www.tutorium.sistemasorbix.com;
    
    root /var/www/tutorium;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location /.well-known/acme-challenge/ {
        root /var/www/tutorium;
    }
    
    access_log /var/log/nginx/tutorium.access.log;
    error_log /var/log/nginx/tutorium.error.log;
}
EOF

# 7. Enable site
sudo ln -sf /etc/nginx/sites-available/tutorium /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# 8. Test and reload Nginx
sudo nginx -t && sudo systemctl reload nginx

# 9. Get SSL certificate
sudo certbot certonly \
    --webroot \
    --webroot-path=/var/www/tutorium \
    --email admin@sistemasorbix.com \
    --agree-tos \
    --no-eff-email \
    --domains tutorium.sistemasorbix.com,www.tutorium.sistemasorbix.com \
    --non-interactive

# 10. Update Nginx config with SSL
sudo tee /etc/nginx/sites-available/tutorium > /dev/null << 'EOF'
server {
    listen 80;
    server_name tutorium.sistemasorbix.com www.tutorium.sistemasorbix.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name tutorium.sistemasorbix.com www.tutorium.sistemasorbix.com;
    
    root /var/www/tutorium;
    index index.html;
    
    ssl_certificate /etc/letsencrypt/live/tutorium.sistemasorbix.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tutorium.sistemasorbix.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    access_log /var/log/nginx/tutorium.access.log;
    error_log /var/log/nginx/tutorium.error.log;
}
EOF

# 11. Test and reload Nginx
sudo nginx -t && sudo systemctl reload nginx

# 12. Set up automatic renewal
sudo tee /etc/cron.d/certbot-renew > /dev/null << 'EOF'
0 12 * * * root certbot renew --quiet --nginx --post-hook "systemctl reload nginx"
EOF

# 13. Test SSL
echo "🔍 Testing SSL configuration..."
curl -I https://tutorium.sistemasorbix.com

echo "✅ SSL setup completed!"
echo "🌐 Site: https://tutorium.sistemasorbix.com"
echo "📁 Web root: /var/www/tutorium"
echo "🔧 Config: /etc/nginx/sites-available/tutorium"
echo "📋 Logs: /var/log/nginx/tutorium.*.log"
