# Script simplificado para configurar SSL en Hetzner
$SERVER_IP = "178.156.182.125"
$DOMAIN = "tutorium.sistemasorbix.com"

Write-Host "🔐 Configurando SSL para $DOMAIN..." -ForegroundColor Green

# Test de conexión
Write-Host "🔍 Probando conexión SSH..." -ForegroundColor Yellow
try {
    $testSSH = ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@$SERVER_IP "echo 'Conexión exitosa'"
    Write-Host "✅ Conexión SSH establecida" -ForegroundColor Green
} catch {
    Write-Host "❌ Error de conexión SSH" -ForegroundColor Red
    Write-Host "Verifica que tengas acceso SSH al servidor" -ForegroundColor Yellow
    exit 1
}

# Ejecutar comandos paso a paso
Write-Host "📋 Ejecutando configuración SSL..." -ForegroundColor Cyan

# 1. Actualizar sistema
Write-Host "🔄 Actualizando sistema..." -ForegroundColor Yellow
ssh root@$SERVER_IP "apt update -y"

# 2. Instalar paquetes
Write-Host "📦 Instalando paquetes..." -ForegroundColor Yellow  
ssh root@$SERVER_IP "apt install -y nginx certbot python3-certbot-nginx"

# 3. Crear directorio
Write-Host "📁 Creando directorio web..." -ForegroundColor Yellow
ssh root@$SERVER_IP "mkdir -p /var/www/tutorium"

# 4. Crear página temporal
Write-Host "📄 Creando página temporal..." -ForegroundColor Yellow
ssh root@$SERVER_IP "echo '<!DOCTYPE html><html><head><title>Tutorium SSL</title></head><body><h1>Configurando SSL...</h1></body></html>' > /var/www/tutorium/index.html"

# 5. Configurar permisos
Write-Host "🔧 Configurando permisos..." -ForegroundColor Yellow
ssh root@$SERVER_IP "chown -R www-data:www-data /var/www/tutorium && chmod -R 755 /var/www/tutorium"

# 6. Configurar Nginx
Write-Host "⚙️ Configurando Nginx..." -ForegroundColor Yellow
$nginxConfig = @"
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    root /var/www/tutorium;
    index index.html;
    location / { try_files \$uri \$uri/ =404; }
    location /.well-known/acme-challenge/ { root /var/www/tutorium; }
}
"@

ssh root@$SERVER_IP "echo '$nginxConfig' > /etc/nginx/sites-available/tutorium"
ssh root@$SERVER_IP "ln -sf /etc/nginx/sites-available/tutorium /etc/nginx/sites-enabled/"
ssh root@$SERVER_IP "rm -f /etc/nginx/sites-enabled/default"
ssh root@$SERVER_IP "nginx -t && systemctl reload nginx"

# 7. Obtener certificado SSL
Write-Host "🔒 Obteniendo certificado SSL..." -ForegroundColor Yellow
ssh root@$SERVER_IP "certbot certonly --webroot --webroot-path=/var/www/tutorium --email admin@sistemasorbix.com --agree-tos --no-eff-email --domains $DOMAIN,www.$DOMAIN --non-interactive"

# 8. Configurar SSL en Nginx
Write-Host "🔐 Configurando SSL en Nginx..." -ForegroundColor Yellow
$sslConfig = @"
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    root /var/www/tutorium;
    index index.html;
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    add_header Strict-Transport-Security \"max-age=31536000\" always;
    location / { try_files \$uri \$uri/ =404; }
}
"@

ssh root@$SERVER_IP "echo '$sslConfig' > /etc/nginx/sites-available/tutorium"
ssh root@$SERVER_IP "nginx -t && systemctl reload nginx"

# 9. Verificar SSL
Write-Host "🔍 Verificando SSL..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
try {
    $response = Invoke-WebRequest -Uri "https://$DOMAIN" -UseBasicParsing -TimeoutSec 30
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ ¡SSL configurado correctamente!" -ForegroundColor Green
        Write-Host "🌐 Sitio disponible en: https://$DOMAIN" -ForegroundColor Cyan
    }
} catch {
    Write-Host "⚠️ SSL configurado, verificando propagación..." -ForegroundColor Yellow
    Write-Host "Prueba manualmente: https://$DOMAIN" -ForegroundColor Gray
}

Write-Host "`n🎉 ¡Configuración completada!" -ForegroundColor Green
Write-Host "📁 Directorio web: /var/www/tutorium" -ForegroundColor White
Write-Host "🔧 Ahora puedes subir tus archivos al servidor" -ForegroundColor Cyan
