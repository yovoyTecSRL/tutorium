Write-Host "===============================================" -ForegroundColor Green
Write-Host "ASISTENTE SSL PARA TUTORIUM.SISTEMASORBIX.COM"
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "PASO 1: Conectar al servidor"
Write-Host "ssh root@178.156.182.125" -ForegroundColor Cyan
Write-Host ""
Write-Host "PASO 2: Ejecutar estos comandos uno por uno:"
Write-Host ""
Write-Host "# Actualizar sistema"
Write-Host "apt update -y" -ForegroundColor Cyan
Write-Host ""
Write-Host "# Instalar paquetes"
Write-Host "apt install -y nginx certbot python3-certbot-nginx" -ForegroundColor Cyan
Write-Host ""
Write-Host "# Crear directorio web"
Write-Host "mkdir -p /var/www/tutorium" -ForegroundColor Cyan
Write-Host ""
Write-Host "# Crear pagina temporal"
Write-Host "echo '<html><head><title>Tutorium SSL</title></head><body><h1>Configurando SSL...</h1></body></html>' > /var/www/tutorium/index.html" -ForegroundColor Cyan
Write-Host ""
Write-Host "# Configurar permisos"
Write-Host "chown -R www-data:www-data /var/www/tutorium" -ForegroundColor Cyan
Write-Host "chmod -R 755 /var/www/tutorium" -ForegroundColor Cyan
Write-Host ""
Write-Host "# Remover sitio default"
Write-Host "rm -f /etc/nginx/sites-enabled/default" -ForegroundColor Cyan
Write-Host ""
Write-Host "PASO 3: Configurar Nginx basico (copiar todo el bloque):"
Write-Host ""
Write-Host "cat > /etc/nginx/sites-available/tutorium << 'EOF'
server {
    listen 80;
    server_name tutorium.sistemasorbix.com www.tutorium.sistemasorbix.com;
    root /var/www/tutorium;
    index index.html;
    location / { try_files \$uri \$uri/ =404; }
    location /.well-known/acme-challenge/ { root /var/www/tutorium; }
}
EOF" -ForegroundColor Cyan
Write-Host ""
Write-Host "PASO 4: Habilitar sitio"
Write-Host "ln -sf /etc/nginx/sites-available/tutorium /etc/nginx/sites-enabled/" -ForegroundColor Cyan
Write-Host "nginx -t && systemctl reload nginx" -ForegroundColor Cyan
Write-Host ""
Write-Host "PASO 5: Obtener certificado SSL"
Write-Host "certbot certonly --webroot --webroot-path=/var/www/tutorium --email admin@sistemasorbix.com --agree-tos --no-eff-email --domains tutorium.sistemasorbix.com,www.tutorium.sistemasorbix.com --non-interactive" -ForegroundColor Cyan
Write-Host ""
Write-Host "PASO 6: Configurar SSL en Nginx (copiar todo el bloque):"
Write-Host ""
Write-Host "cat > /etc/nginx/sites-available/tutorium << 'EOF'
server {
    listen 80;
    server_name tutorium.sistemasorbix.com www.tutorium.sistemasorbix.com;
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name tutorium.sistemasorbix.com www.tutorium.sistemasorbix.com;
    root /var/www/tutorium;
    index index.html;
    ssl_certificate /etc/letsencrypt/live/tutorium.sistemasorbix.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tutorium.sistemasorbix.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    location / { try_files \$uri \$uri/ =404; }
}
EOF" -ForegroundColor Cyan
Write-Host ""
Write-Host "PASO 7: Recargar Nginx"
Write-Host "nginx -t && systemctl reload nginx" -ForegroundColor Cyan
Write-Host ""
Write-Host "PASO 8: Verificar SSL"
Write-Host "curl -I https://tutorium.sistemasorbix.com" -ForegroundColor Cyan
Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "Ejecuta estos pasos en el servidor SSH"
Write-Host "===============================================" -ForegroundColor Green
