#!/bin/bash

# Script simple para desplegar Tutorium con SSL
# Uso: ./simple-deploy.sh

echo "🚀 Desplegando Tutorium con SSL..."

# Variables
DOMAIN="tutorium.sistemasorbix.com"
SERVER_IP="178.156.182.125"
WEBROOT="/var/www/tutorium"

# Crear directorio web
echo "📁 Creando directorio web..."
mkdir -p $WEBROOT

# Copiar archivos (asumiendo que ya están en el servidor)
echo "📋 Copiando archivos..."
cp -r /tmp/tutorium/* $WEBROOT/ 2>/dev/null || echo "⚠️  Archivos no encontrados en /tmp/"

# Crear página temporal
echo "📄 Creando página temporal..."
cat > $WEBROOT/index.html << 'EOF'
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
        .loading { font-size: 1.2em; margin: 20px 0; }
        .icon { font-size: 3em; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">🔒</div>
        <h1>Tutorium SSL Setup</h1>
        <div class="loading">Configurando certificados SSL...</div>
        <p>Este proceso tomará unos minutos.</p>
        <p>Domain: tutorium.sistemasorbix.com</p>
        <p>Server: 178.156.182.125</p>
    </div>
</body>
</html>
EOF

# Configurar permisos
chown -R www-data:www-data $WEBROOT
chmod -R 755 $WEBROOT

# Configurar Nginx básico
echo "🌐 Configurando Nginx..."
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
}
EOF

# Activar sitio
ln -sf /etc/nginx/sites-available/tutorium /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Verificar configuración
nginx -t

# Reiniciar Nginx
systemctl reload nginx

# Obtener certificado SSL
echo "🔒 Obteniendo certificado SSL..."
certbot certonly \
    --webroot \
    --webroot-path=$WEBROOT \
    --email admin@sistemasorbix.com \
    --agree-tos \
    --no-eff-email \
    --domains $DOMAIN \
    --non-interactive

# Configurar Nginx con SSL
echo "🔐 Configurando Nginx con SSL..."
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
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    access_log /var/log/nginx/tutorium.access.log;
    error_log /var/log/nginx/tutorium.error.log;
}
EOF

# Recargar Nginx
systemctl reload nginx

echo "✅ Despliegue completado!"
echo "🌐 Sitio: https://tutorium.sistemasorbix.com"
echo "🔒 SSL: Configurado"
