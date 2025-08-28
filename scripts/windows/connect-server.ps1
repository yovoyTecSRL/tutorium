# Script para conectar al servidor y configurar SSL
# Ejecutar como administrador

Write-Host "🔧 Configurando SSL para Tutorium" -ForegroundColor Green
Write-Host "Servidor: 178.156.182.125" -ForegroundColor Yellow
Write-Host "Dominio: tutorium.sistemasorbix.com" -ForegroundColor Yellow

# Verificar conectividad
Write-Host "`n🔍 Verificando conectividad..." -ForegroundColor Cyan
try {
    $ping = Test-Connection -ComputerName 178.156.182.125 -Count 1 -ErrorAction Stop
    Write-Host "✅ Servidor responde: $($ping.ResponseTime)ms" -ForegroundColor Green
} catch {
    Write-Host "❌ Error conectando al servidor" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Intentar SSH con diferentes métodos
Write-Host "`n🔐 Intentando conexión SSH..." -ForegroundColor Cyan

$sshCommands = @(
    "ssh -o ConnectTimeout=10 root@178.156.182.125",
    "ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@178.156.182.125",
    "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@178.156.182.125"
)

foreach ($cmd in $sshCommands) {
    Write-Host "Probando: $cmd" -ForegroundColor Yellow
    try {
        $result = Invoke-Expression $cmd
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Conexión SSH exitosa" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "❌ Falló: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Si SSH falla, crear comandos para ejecutar manualmente
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n⚠️ SSH automático falló. Creando comandos manuales..." -ForegroundColor Yellow
    
    # Crear archivo con comandos para ejecutar en el servidor
    $serverCommands = @"
#!/bin/bash
# Comandos para ejecutar en el servidor manualmente

echo "🔧 Configurando SSL para Tutorium..."

# 1. Actualizar sistema
apt update && apt upgrade -y

# 2. Instalar paquetes necesarios
apt install -y nginx certbot python3-certbot-nginx

# 3. Crear directorio web
mkdir -p /var/www/tutorium
chown -R www-data:www-data /var/www/tutorium

# 4. Crear página temporal
cat > /var/www/tutorium/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Tutorium SSL Setup</title>
    <style>
        body { font-family: Arial; background: #667eea; color: white; text-align: center; padding: 50px; }
        .container { max-width: 600px; margin: 0 auto; background: rgba(255,255,255,0.1); padding: 40px; border-radius: 15px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔒 Tutorium SSL Setup</h1>
        <p>Configurando certificados SSL...</p>
        <p>Domain: tutorium.sistemasorbix.com</p>
    </div>
</body>
</html>
EOF

# 5. Configurar Nginx inicial
cat > /etc/nginx/sites-available/tutorium << 'EOF'
server {
    listen 80;
    server_name tutorium.sistemasorbix.com www.tutorium.sistemasorbix.com;
    root /var/www/tutorium;
    index index.html;
    
    location / {
        try_files `$uri `$uri/ =404;
    }
    
    location /.well-known/acme-challenge/ {
        root /var/www/tutorium;
    }
}
EOF

# 6. Habilitar sitio
ln -sf /etc/nginx/sites-available/tutorium /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 7. Probar y recargar Nginx
nginx -t && systemctl reload nginx

# 8. Obtener certificado SSL
certbot certonly --webroot --webroot-path=/var/www/tutorium --email admin@sistemasorbix.com --agree-tos --no-eff-email --domains tutorium.sistemasorbix.com,www.tutorium.sistemasorbix.com --non-interactive

# 9. Configurar Nginx con SSL
cat > /etc/nginx/sites-available/tutorium << 'EOF'
server {
    listen 80;
    server_name tutorium.sistemasorbix.com www.tutorium.sistemasorbix.com;
    return 301 https://`$server_name`$request_uri;
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
    
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    
    location / {
        try_files `$uri `$uri/ =404;
    }
}
EOF

# 10. Reiniciar Nginx
nginx -t && systemctl reload nginx

# 11. Verificar SSL
echo "✅ SSL configurado!"
echo "🌐 Probando: https://tutorium.sistemasorbix.com"
curl -I https://tutorium.sistemasorbix.com

echo "🔧 Configuración completada!"
"@

    # Guardar comandos en archivo
    $serverCommands | Out-File -FilePath ".\ssl-commands.sh" -Encoding UTF8
    
    Write-Host "📝 Comandos guardados en: ssl-commands.sh" -ForegroundColor Green
    Write-Host "`n🔧 INSTRUCCIONES MANUALES:" -ForegroundColor Cyan
    Write-Host "1. Conecta al servidor por otro método (panel web, VNC, etc.)" -ForegroundColor Yellow
    Write-Host "2. Copia el contenido de 'ssl-commands.sh' al servidor" -ForegroundColor Yellow
    Write-Host "3. Ejecuta: chmod +x ssl-commands.sh && ./ssl-commands.sh" -ForegroundColor Yellow
    Write-Host "4. Espera a que complete la configuración SSL" -ForegroundColor Yellow
    Write-Host "5. Verifica en: https://tutorium.sistemasorbix.com" -ForegroundColor Yellow
}

Write-Host "`n🚀 Presiona cualquier tecla para continuar..." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
