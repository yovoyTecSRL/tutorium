#!/bin/bash
# QUICK_SSL_FIX.sh - Script rápido para resolver SSL

echo "🚀 QUICK SSL FIX para tutorium.sistemasorbix.com"

# Comando único para ejecutar en el servidor
apt update && apt install -y nginx certbot python3-certbot-nginx

# Crear directorio y página temporal
mkdir -p /var/www/tutorium
echo '<h1>SSL Setup in Progress...</h1>' > /var/www/tutorium/index.html

# Configurar Nginx básico
cat > /etc/nginx/sites-available/tutorium << 'EOF'
server {
    listen 80;
    server_name tutorium.sistemasorbix.com www.tutorium.sistemasorbix.com;
    root /var/www/tutorium;
    index index.html;
    location / { try_files $uri $uri/ =404; }
    location /.well-known/acme-challenge/ { root /var/www/tutorium; }
}
EOF

# Habilitar sitio
ln -sf /etc/nginx/sites-available/tutorium /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# Obtener certificado SSL
certbot --nginx -d tutorium.sistemasorbix.com -d www.tutorium.sistemasorbix.com --email admin@sistemasorbix.com --agree-tos --non-interactive

# Verificar
curl -I https://tutorium.sistemasorbix.com

echo "✅ SSL configurado! Visita: https://tutorium.sistemasorbix.com"
