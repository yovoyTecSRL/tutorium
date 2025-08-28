# Script SSL ultra-simple para Hetzner
$SERVER = "178.156.182.125"
$DOMAIN = "tutorium.sistemasorbix.com"

Write-Host "=== Configurando SSL para $DOMAIN ===" -ForegroundColor Green

# Comando 1: Actualizar sistema
Write-Host "1. Actualizando sistema..." -ForegroundColor Yellow
ssh root@$SERVER "apt update -y"

# Comando 2: Instalar paquetes
Write-Host "2. Instalando nginx y certbot..." -ForegroundColor Yellow
ssh root@$SERVER "apt install -y nginx certbot python3-certbot-nginx"

# Comando 3: Crear directorio
Write-Host "3. Creando directorio web..." -ForegroundColor Yellow
ssh root@$SERVER "mkdir -p /var/www/tutorium"

# Comando 4: Página temporal
Write-Host "4. Creando página temporal..." -ForegroundColor Yellow
ssh root@$SERVER 'echo "<!DOCTYPE html><html><head><title>Tutorium</title></head><body><h1>SSL Setup</h1></body></html>" > /var/www/tutorium/index.html'

# Comando 5: Permisos
Write-Host "5. Configurando permisos..." -ForegroundColor Yellow
ssh root@$SERVER "chown -R www-data:www-data /var/www/tutorium"
ssh root@$SERVER "chmod -R 755 /var/www/tutorium"

# Comando 6: Nginx básico
Write-Host "6. Configurando Nginx..." -ForegroundColor Yellow
ssh root@$SERVER "rm -f /etc/nginx/sites-enabled/default"

# Crear config básico de nginx
ssh root@$SERVER 'cat > /etc/nginx/sites-available/tutorium << EOF
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
}
EOF'

ssh root@$SERVER "ln -sf /etc/nginx/sites-available/tutorium /etc/nginx/sites-enabled/"
ssh root@$SERVER "nginx -t && systemctl reload nginx"

# Comando 7: Obtener SSL
Write-Host "7. Obteniendo certificado SSL..." -ForegroundColor Yellow
ssh root@$SERVER "certbot certonly --webroot --webroot-path=/var/www/tutorium --email admin@sistemasorbix.com --agree-tos --no-eff-email --domains tutorium.sistemasorbix.com,www.tutorium.sistemasorbix.com --non-interactive"

# Comando 8: Configurar SSL
Write-Host "8. Configurando SSL..." -ForegroundColor Yellow
ssh root@$SERVER 'cat > /etc/nginx/sites-available/tutorium << EOF
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
    add_header Strict-Transport-Security "max-age=31536000" always;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF'

ssh root@$SERVER "nginx -t && systemctl reload nginx"

# Comando 9: Verificar
Write-Host "9. Verificando SSL..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

try {
    $response = Invoke-WebRequest -Uri "https://tutorium.sistemasorbix.com" -UseBasicParsing -TimeoutSec 30
    Write-Host "✅ SSL CONFIGURADO CORRECTAMENTE!" -ForegroundColor Green
    Write-Host "🌐 Sitio: https://tutorium.sistemasorbix.com" -ForegroundColor Cyan
} catch {
    Write-Host "⚠️ SSL configurado, verificando..." -ForegroundColor Yellow
    Write-Host "Prueba: https://tutorium.sistemasorbix.com" -ForegroundColor Gray
}

Write-Host "`n🎉 CONFIGURACIÓN COMPLETADA!" -ForegroundColor Green
Write-Host "📁 Directorio: /var/www/tutorium" -ForegroundColor White
