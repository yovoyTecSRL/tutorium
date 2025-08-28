#!/bin/bash
# SSL_SETUP_DIRECT.sh - Script para ejecutar directamente en el servidor

echo "🔧 Configurando SSL para tutorium.sistemasorbix.com..."
echo "📅 $(date)"

# Verificar si estamos ejecutando como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script debe ejecutarse como root"
    echo "💡 Ejecuta: sudo bash ssl_setup_direct.sh"
    exit 1
fi

# 1. Actualizar sistema
echo "🔄 Actualizando sistema..."
apt update && apt upgrade -y

# 2. Instalar paquetes necesarios
echo "📦 Instalando paquetes..."
apt install -y nginx certbot python3-certbot-nginx curl

# 3. Verificar dominio
echo "🌐 Verificando dominio..."
nslookup tutorium.sistemasorbix.com

# 4. Detener Apache si está corriendo
systemctl stop apache2 2>/dev/null || true

# 5. Crear directorio web
echo "📁 Creando directorio web..."
mkdir -p /var/www/tutorium

# 6. Crear página temporal
echo "📄 Creando página temporal..."
cat > /var/www/tutorium/index.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tutorium - SSL Setup</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            margin: 0;
            padding: 0;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .container {
            max-width: 600px;
            text-align: center;
            background: rgba(255,255,255,0.1);
            padding: 40px;
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        }
        h1 { 
            font-size: 3em; 
            margin-bottom: 20px; 
            text-shadow: 0 2px 10px rgba(0,0,0,0.3);
        }
        .status {
            font-size: 1.3em;
            margin: 20px 0;
            padding: 15px;
            background: rgba(255,255,255,0.2);
            border-radius: 10px;
        }
        .success {
            background: rgba(76, 175, 80, 0.3);
            border: 2px solid #4CAF50;
        }
        .loading {
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }
        .icon { font-size: 4em; margin-bottom: 20px; }
        .details {
            font-size: 1.1em;
            margin: 10px 0;
            opacity: 0.9;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">🔐</div>
        <h1>Tutorium SSL</h1>
        <div class="status loading">
            ⚡ Configurando certificados SSL...
        </div>
        <div class="details">Dominio: tutorium.sistemasorbix.com</div>
        <div class="details">Servidor: 178.156.182.125</div>
        <div class="details">Estado: Instalando certificados</div>
        <div class="details">Fecha: $(date)</div>
    </div>
</body>
</html>
EOF

# 7. Configurar permisos
chown -R www-data:www-data /var/www/tutorium
chmod -R 755 /var/www/tutorium

# 8. Crear configuración inicial de Nginx
echo "🔧 Configurando Nginx..."
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

# 9. Habilitar sitio
ln -sf /etc/nginx/sites-available/tutorium /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 10. Probar configuración
echo "🧪 Probando configuración de Nginx..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuración de Nginx OK"
    systemctl restart nginx
    systemctl enable nginx
else
    echo "❌ Error en configuración de Nginx"
    exit 1
fi

# 11. Verificar que Nginx esté corriendo
echo "🔍 Verificando estado de Nginx..."
systemctl status nginx --no-pager

# 12. Obtener certificado SSL
echo "🔐 Obteniendo certificado SSL..."
certbot certonly \
    --webroot \
    --webroot-path=/var/www/tutorium \
    --email admin@sistemasorbix.com \
    --agree-tos \
    --no-eff-email \
    --domains tutorium.sistemasorbix.com,www.tutorium.sistemasorbix.com \
    --non-interactive \
    --verbose

# 13. Verificar que el certificado se obtuvo
if [ -f "/etc/letsencrypt/live/tutorium.sistemasorbix.com/fullchain.pem" ]; then
    echo "✅ Certificado SSL obtenido exitosamente"
    
    # 14. Configurar Nginx con SSL
    echo "🔒 Configurando Nginx con SSL..."
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
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    access_log /var/log/nginx/tutorium.access.log;
    error_log /var/log/nginx/tutorium.error.log;
}
EOF

    # 15. Probar y recargar Nginx
    nginx -t && systemctl reload nginx
    
    # 16. Crear página de éxito
    cat > /var/www/tutorium/index.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tutorium - SSL Configurado</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            margin: 0;
            padding: 0;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .container {
            max-width: 600px;
            text-align: center;
            background: rgba(255,255,255,0.1);
            padding: 40px;
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        }
        h1 { 
            font-size: 3em; 
            margin-bottom: 20px; 
            text-shadow: 0 2px 10px rgba(0,0,0,0.3);
        }
        .status {
            font-size: 1.3em;
            margin: 20px 0;
            padding: 15px;
            background: rgba(76, 175, 80, 0.3);
            border: 2px solid #4CAF50;
            border-radius: 10px;
        }
        .icon { font-size: 4em; margin-bottom: 20px; }
        .details {
            font-size: 1.1em;
            margin: 10px 0;
            opacity: 0.9;
        }
        .next-steps {
            background: rgba(255,255,255,0.1);
            padding: 20px;
            border-radius: 10px;
            margin-top: 20px;
            text-align: left;
        }
        .next-steps h3 {
            margin-top: 0;
            color: #FFD700;
        }
        .next-steps ul {
            padding-left: 20px;
        }
        .next-steps li {
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">🎉</div>
        <h1>¡SSL Configurado!</h1>
        <div class="status">
            ✅ Certificado SSL instalado exitosamente
        </div>
        <div class="details">Dominio: tutorium.sistemasorbix.com</div>
        <div class="details">Servidor: 178.156.182.125</div>
        <div class="details">SSL: Let's Encrypt</div>
        <div class="details">Fecha: $(date)</div>
        
        <div class="next-steps">
            <h3>📋 Próximos pasos:</h3>
            <ul>
                <li>Subir archivos HTML del proyecto</li>
                <li>Configurar API de OpenAI</li>
                <li>Instalar dependencias JavaScript</li>
                <li>Configurar sistema de cursos</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

    # 17. Configurar renovación automática
    echo "🔄 Configurando renovación automática..."
    cat > /etc/cron.d/certbot-renew << 'EOF'
0 12 * * * root certbot renew --quiet --nginx --post-hook "systemctl reload nginx"
EOF

    echo "✅ SSL configurado exitosamente!"
    echo "🌐 Sitio: https://tutorium.sistemasorbix.com"
    echo "📄 Directorio web: /var/www/tutorium"
    echo "🔧 Configuración: /etc/nginx/sites-available/tutorium"
    
    # 18. Verificar SSL
    echo "🔍 Verificando SSL..."
    curl -I https://tutorium.sistemasorbix.com
    
else
    echo "❌ Error: No se pudo obtener el certificado SSL"
    echo "🔍 Verificando logs..."
    tail -20 /var/log/letsencrypt/letsencrypt.log
    exit 1
fi

echo "🎯 Configuración completada!"
echo "📋 Para subir archivos, usar: /var/www/tutorium/"
echo "📊 Ver logs: tail -f /var/log/nginx/tutorium.access.log"
