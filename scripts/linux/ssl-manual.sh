# ===================================================================
# CONFIGURACIÓN SSL MANUAL - COPIA Y PEGA EN EL SERVIDOR
# ===================================================================

# INSTRUCCIONES:
# 1. Conecta al servidor: ssh root@178.156.182.125
# 2. Copia y pega CADA BLOQUE de comandos uno por uno

echo "🔐 CONFIGURANDO SSL PARA TUTORIUM"
echo "🌐 Dominio: tutorium.sistemasorbix.com"
echo "📅 $(date)"

# ===================================================================
# BLOQUE 1: PREPARACIÓN DEL SISTEMA
# ===================================================================

echo "🔄 Actualizando sistema..."
apt update -y
apt upgrade -y

echo "📦 Instalando paquetes necesarios..."
apt install -y nginx certbot python3-certbot-nginx curl

echo "✅ Sistema preparado"

# ===================================================================
# BLOQUE 2: CONFIGURAR DIRECTORIO WEB
# ===================================================================

echo "📁 Creando directorio web..."
mkdir -p /var/www/tutorium

echo "📄 Creando página temporal..."
cat > /var/www/tutorium/index.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
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
        .status { font-size: 1.2em; margin: 20px 0; color: #00ff00; }
        .icon { font-size: 3em; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">🔒</div>
        <h1>Tutorium SSL Setup</h1>
        <div class="status">Configurando certificados SSL...</div>
        <p>Dominio: tutorium.sistemasorbix.com</p>
        <p>Estado: Preparando servidor...</p>
    </div>
</body>
</html>
EOF

echo "🔧 Configurando permisos..."
chown -R www-data:www-data /var/www/tutorium
chmod -R 755 /var/www/tutorium

echo "✅ Directorio web configurado"

# ===================================================================
# BLOQUE 3: CONFIGURAR NGINX BÁSICO
# ===================================================================

echo "⚙️ Configurando Nginx..."

# Remover configuración default
rm -f /etc/nginx/sites-enabled/default

# Crear configuración básica para obtener SSL
cat > /etc/nginx/sites-available/tutorium << 'EOF'
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

# Habilitar sitio
ln -sf /etc/nginx/sites-available/tutorium /etc/nginx/sites-enabled/

# Probar configuración
nginx -t

# Recargar Nginx
systemctl reload nginx

echo "✅ Nginx configurado"

# ===================================================================
# BLOQUE 4: OBTENER CERTIFICADO SSL
# ===================================================================

echo "🔒 Obteniendo certificado SSL..."

# Obtener certificado con Let's Encrypt
certbot certonly \
    --webroot \
    --webroot-path=/var/www/tutorium \
    --email admin@sistemasorbix.com \
    --agree-tos \
    --no-eff-email \
    --domains tutorium.sistemasorbix.com,www.tutorium.sistemasorbix.com \
    --non-interactive

echo "✅ Certificado SSL obtenido"

# ===================================================================
# BLOQUE 5: CONFIGURAR NGINX CON SSL
# ===================================================================

echo "🔐 Configurando Nginx con SSL..."

# Crear configuración completa con SSL
cat > /etc/nginx/sites-available/tutorium << 'EOF'
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

# Probar configuración
nginx -t

# Recargar Nginx
systemctl reload nginx

echo "✅ SSL configurado en Nginx"

# ===================================================================
# BLOQUE 6: CONFIGURAR RENOVACIÓN AUTOMÁTICA
# ===================================================================

echo "🔄 Configurando renovación automática..."

# Crear cron job para renovación
cat > /etc/cron.d/certbot-renew << 'EOF'
0 12 * * * root certbot renew --quiet --nginx --post-hook "systemctl reload nginx"
EOF

echo "✅ Renovación automática configurada"

# ===================================================================
# BLOQUE 7: VERIFICACIÓN FINAL
# ===================================================================

echo "🔍 Verificando configuración..."

# Verificar que Nginx está funcionando
systemctl status nginx

# Verificar certificados
certbot certificates

# Probar conexión SSL
curl -I https://tutorium.sistemasorbix.com

echo ""
echo "🎉 ¡CONFIGURACIÓN SSL COMPLETADA!"
echo "════════════════════════════════════════"
echo "🌐 Sitio: https://tutorium.sistemasorbix.com"
echo "📁 Directorio: /var/www/tutorium"
echo "🔧 Config Nginx: /etc/nginx/sites-available/tutorium"
echo "📋 Logs: /var/log/nginx/tutorium.*.log"
echo "🔄 Renovación: Configurada automáticamente"
echo "════════════════════════════════════════"
echo ""
echo "📋 COMANDOS ÚTILES:"
echo "• Ver logs: tail -f /var/log/nginx/tutorium.error.log"
echo "• Verificar SSL: curl -I https://tutorium.sistemasorbix.com"
echo "• Renovar SSL: certbot renew --nginx"
echo "• Reiniciar Nginx: systemctl restart nginx"
