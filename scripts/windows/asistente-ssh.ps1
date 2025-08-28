# ═══════════════════════════════════════════════════════════════
# 🔧 ORBIX - Asistente de Conexión SSH y Configuración SSL
# Te guía paso a paso para conectar al servidor y configurar SSL
# ═══════════════════════════════════════════════════════════════

$SERVER = "178.156.182.125"
$DOMAIN = "tutorium.sistemasorbix.com"
$USER = "root"

Write-Host "`n🔐 ORBIX - Asistente de Conexión SSH para SSL" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host "🌐 Servidor: $SERVER" -ForegroundColor Cyan
Write-Host "👤 Usuario: $USER" -ForegroundColor Cyan
Write-Host "📄 Dominio: $DOMAIN" -ForegroundColor Cyan

# Paso 1: Verificar conectividad
Write-Host "`n🔍 PASO 1: Verificando conectividad al servidor..." -ForegroundColor Yellow

try {
    $testConnection = Test-NetConnection -ComputerName $SERVER -Port 22 -InformationLevel Quiet
    if ($testConnection) {
        Write-Host "✅ Servidor accesible en puerto 22" -ForegroundColor Green
    } else {
        Write-Host "❌ Servidor no accesible" -ForegroundColor Red
        Write-Host "   Verifica tu conexión a internet" -ForegroundColor Gray
        exit 1
    }
} catch {
    Write-Host "❌ Error de conectividad: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Paso 2: Preparar comando SSH
Write-Host "`n🔗 PASO 2: Preparando conexión SSH..." -ForegroundColor Yellow

$sshCommand = "ssh $USER@$SERVER"
Write-Host "Comando SSH: $sshCommand" -ForegroundColor White

# Paso 3: Mostrar instrucciones
Write-Host "`n📋 PASO 3: INSTRUCCIONES DE CONEXIÓN" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Gray

Write-Host "1. Ejecuta el siguiente comando en una nueva ventana de PowerShell:" -ForegroundColor White
Write-Host "   $sshCommand" -ForegroundColor Cyan

Write-Host "`n2. Una vez conectado, ejecuta estos comandos UNO POR UNO:" -ForegroundColor White

$commands = @(
    "# Actualizar sistema",
    "apt update -y",
    "",
    "# Instalar paquetes necesarios", 
    "apt install -y nginx certbot python3-certbot-nginx",
    "",
    "# Crear directorio web",
    "mkdir -p /var/www/tutorium",
    "",
    "# Crear página temporal",
    "echo '<!DOCTYPE html><html><head><title>Tutorium SSL</title></head><body><h1>Configurando SSL...</h1></body></html>' > /var/www/tutorium/index.html",
    "",
    "# Configurar permisos",
    "chown -R www-data:www-data /var/www/tutorium",
    "chmod -R 755 /var/www/tutorium",
    "",
    "# Remover sitio default",
    "rm -f /etc/nginx/sites-enabled/default"
)

foreach ($command in $commands) {
    if ($command -eq "") {
        Write-Host ""
    } elseif ($command.StartsWith("#")) {
        Write-Host $command -ForegroundColor Green
    } else {
        Write-Host "   $command" -ForegroundColor Cyan
    }
}

Write-Host "`n3. Configurar Nginx básico:" -ForegroundColor White
Write-Host "   Ejecuta el siguiente bloque completo:" -ForegroundColor Gray

$nginxConfig = @"
cat > /etc/nginx/sites-available/tutorium << 'EOF'
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    root /var/www/tutorium;
    index index.html;
    location / { try_files `$uri `$uri/ =404; }
    location /.well-known/acme-challenge/ { root /var/www/tutorium; }
}
EOF
"@

Write-Host $nginxConfig -ForegroundColor Cyan

Write-Host "`n4. Habilitar el sitio:" -ForegroundColor White
Write-Host "   ln -sf /etc/nginx/sites-available/tutorium /etc/nginx/sites-enabled/" -ForegroundColor Cyan
Write-Host "   nginx -t && systemctl reload nginx" -ForegroundColor Cyan

Write-Host "`n5. Obtener certificado SSL:" -ForegroundColor White
$certCommand = "certbot certonly --webroot --webroot-path=/var/www/tutorium --email admin@sistemasorbix.com --agree-tos --no-eff-email --domains $DOMAIN,www.$DOMAIN --non-interactive"
Write-Host "   $certCommand" -ForegroundColor Cyan

Write-Host "`n6. Configurar SSL en Nginx:" -ForegroundColor White
Write-Host "   Ejecuta el siguiente bloque completo:" -ForegroundColor Gray

$sslConfig = @"
cat > /etc/nginx/sites-available/tutorium << 'EOF'
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://`$server_name`$request_uri;
}
server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    root /var/www/tutorium;
    index index.html;
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    location / { try_files `$uri `$uri/ =404; }
}
EOF
"@

Write-Host $sslConfig -ForegroundColor Cyan

Write-Host "`n7. Recargar Nginx:" -ForegroundColor White
Write-Host "   nginx -t && systemctl reload nginx" -ForegroundColor Cyan

Write-Host "`n8. Verificar SSL:" -ForegroundColor White
Write-Host "   curl -I https://$DOMAIN" -ForegroundColor Cyan

# Paso 4: Esperan confirmación
Write-Host "`n⏳ PASO 4: Esperando confirmación..." -ForegroundColor Yellow
Write-Host "Presiona ENTER cuando hayas completado la configuración SSL en el servidor..." -ForegroundColor Gray
Read-Host

# Paso 5: Verificar resultado
Write-Host "`n🔍 PASO 5: Verificando resultado..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri "https://$DOMAIN" -UseBasicParsing -TimeoutSec 15
    if ($response.StatusCode -eq 200) {
        Write-Host "🎉 ¡SSL CONFIGURADO EXITOSAMENTE!" -ForegroundColor Green
        Write-Host "✅ Estado: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "🌐 Sitio disponible en: https://$DOMAIN" -ForegroundColor Cyan
    } else {
        Write-Host "⚠️ SSL responde pero con estado: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ SSL aún no funciona: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Revisa que hayas ejecutado todos los pasos correctamente" -ForegroundColor Yellow
}

Write-Host "`n📋 RESUMEN:" -ForegroundColor Cyan
Write-Host "1. Conexión SSH: $sshCommand" -ForegroundColor White
Write-Host "2. Dominio: https://$DOMAIN" -ForegroundColor White
Write-Host "3. Directorio web: /var/www/tutorium" -ForegroundColor White

Write-Host "`n🎉 Asistente completado!" -ForegroundColor Green
