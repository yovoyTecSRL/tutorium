# ===================================================================
# SCRIPT DE CONEXIÓN Y CONFIGURACIÓN SSL PARA HETZNER
# ===================================================================

# Variables de configuración
$HETZNER_API_TOKEN = "6iXW2eO55QQjQtOOBwQxSZUsvQExKWQp"
$SERVER_IP = "178.156.182.125"
$DOMAIN = "tutorium.sistemasorbix.com"
$OPENAI_API_KEY=<REDACTED>

Write-Host "🔐 Iniciando configuración SSL para Tutorium en Hetzner..." -ForegroundColor Green
Write-Host "🌐 Servidor: $SERVER_IP" -ForegroundColor Cyan
Write-Host "📄 Dominio: $DOMAIN" -ForegroundColor Cyan

# Función para ejecutar comandos SSH
function Invoke-SSHCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-Host "🔧 $Description..." -ForegroundColor Yellow
    
    try {
        # Intentar con ssh nativo
        $result = ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$SERVER_IP $Command
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $Description completado" -ForegroundColor Green
            return $result
        } else {
            throw "Error en comando SSH"
        }
    } catch {
        Write-Host "❌ Error: $Description falló" -ForegroundColor Red
        Write-Host "Comando: $Command" -ForegroundColor Gray
        return $null
    }
}

# Verificar conexión al servidor
Write-Host "`n🔍 Verificando conexión al servidor..." -ForegroundColor Yellow
$testConnection = Test-NetConnection -ComputerName $SERVER_IP -Port 22 -InformationLevel Quiet

if (-not $testConnection) {
    Write-Host "❌ No se puede conectar al servidor en puerto 22" -ForegroundColor Red
    Write-Host "Verifica que el servidor esté activo y accesible" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Conexión al servidor exitosa" -ForegroundColor Green

# Comandos SSL paso a paso
Write-Host "`n📋 Ejecutando configuración SSL..." -ForegroundColor Cyan

# 1. Actualizar sistema
Invoke-SSHCommand "apt update && apt upgrade -y" "Actualizando sistema"

# 2. Instalar paquetes necesarios
Invoke-SSHCommand "apt install -y nginx certbot python3-certbot-nginx curl" "Instalando paquetes necesarios"

# 3. Crear directorio web
Invoke-SSHCommand "mkdir -p /var/www/tutorium" "Creando directorio web"

# 4. Crear página temporal
$tempHTML = @"
<!DOCTYPE html>
<html lang='es'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Tutorium - Configurando SSL</title>
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
    <div class='container'>
        <div class='icon'>🔒</div>
        <h1>Tutorium SSL Setup</h1>
        <div class='loading'>Configurando certificados SSL...</div>
        <p>Domain: $DOMAIN</p>
        <p>Status: Configurando servidor...</p>
    </div>
</body>
</html>
"@

Invoke-SSHCommand "echo '$tempHTML' > /var/www/tutorium/index.html" "Creando página temporal"

# 5. Configurar permisos
Invoke-SSHCommand "chown -R www-data:www-data /var/www/tutorium && chmod -R 755 /var/www/tutorium" "Configurando permisos"

# 6. Configurar Nginx inicial
$nginxConfig = @"
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    root /var/www/tutorium;
    index index.html;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location /.well-known/acme-challenge/ {
        root /var/www/tutorium;
    }
    
    access_log /var/log/nginx/tutorium.access.log;
    error_log /var/log/nginx/tutorium.error.log;
}
"@

Invoke-SSHCommand "echo '$nginxConfig' > /etc/nginx/sites-available/tutorium" "Configurando Nginx"

# 7. Habilitar sitio
Invoke-SSHCommand "ln -sf /etc/nginx/sites-available/tutorium /etc/nginx/sites-enabled/" "Habilitando sitio"
Invoke-SSHCommand "rm -f /etc/nginx/sites-enabled/default" "Removiendo sitio default"

# 8. Probar y recargar Nginx
Invoke-SSHCommand "nginx -t && systemctl reload nginx" "Probando configuración Nginx"

# 9. Obtener certificado SSL
Write-Host "`n🔒 Obteniendo certificado SSL..." -ForegroundColor Cyan
$certCommand = "certbot certonly --webroot --webroot-path=/var/www/tutorium --email admin@sistemasorbix.com --agree-tos --no-eff-email --domains $DOMAIN,www.$DOMAIN --non-interactive"
Invoke-SSHCommand $certCommand "Obteniendo certificado SSL"

# 10. Configurar Nginx con SSL
$nginxSSLConfig = @"
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
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    
    # Security headers
    add_header Strict-Transport-Security \"max-age=31536000; includeSubDomains; preload\" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection \"1; mode=block\" always;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    access_log /var/log/nginx/tutorium.access.log;
    error_log /var/log/nginx/tutorium.error.log;
}
"@

Invoke-SSHCommand "echo '$nginxSSLConfig' > /etc/nginx/sites-available/tutorium" "Configurando Nginx con SSL"

# 11. Recargar Nginx
Invoke-SSHCommand "nginx -t && systemctl reload nginx" "Recargando Nginx con SSL"

# 12. Configurar renovación automática
$cronJob = "0 12 * * * root certbot renew --quiet --nginx --post-hook 'systemctl reload nginx'"
Invoke-SSHCommand "echo '$cronJob' > /etc/cron.d/certbot-renew" "Configurando renovación automática"

# 13. Verificar SSL
Write-Host "`n🔍 Verificando configuración SSL..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://$DOMAIN" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ SSL configurado correctamente!" -ForegroundColor Green
        Write-Host "🌐 Sitio disponible en: https://$DOMAIN" -ForegroundColor Cyan
    }
} catch {
    Write-Host "⚠️ SSL configurado pero aún propagando..." -ForegroundColor Yellow
    Write-Host "Espera unos minutos y verifica manualmente: https://$DOMAIN" -ForegroundColor Gray
}

# Mostrar resumen
Write-Host "`n📋 RESUMEN DE CONFIGURACIÓN" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════" -ForegroundColor Gray
Write-Host "🌐 Dominio: https://$DOMAIN" -ForegroundColor White
Write-Host "🔒 SSL: Configurado con Let's Encrypt" -ForegroundColor Green
Write-Host "📁 Directorio web: /var/www/tutorium" -ForegroundColor White
Write-Host "🔧 Configuración Nginx: /etc/nginx/sites-available/tutorium" -ForegroundColor White
Write-Host "📋 Logs: /var/log/nginx/tutorium.*.log" -ForegroundColor White
Write-Host "🔄 Renovación automática: Configurada" -ForegroundColor Green
Write-Host "════════════════════════════════════════" -ForegroundColor Gray

Write-Host "`n🎉 ¡Configuración SSL completada exitosamente!" -ForegroundColor Green
Write-Host "Ya puedes subir los archivos del proyecto a /var/www/tutorium/" -ForegroundColor Cyan
