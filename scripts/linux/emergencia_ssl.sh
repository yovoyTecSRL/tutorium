#!/bin/bash
# Script de emergencia para configuración rápida
echo "🚨 CONFIGURACIÓN RÁPIDA DE EMERGENCIA"
echo "===================================="

# Configurar SSH con contraseña
echo "🔐 Configurando SSH..."
echo "root:fTeRLCxfnaRL" | chpasswd
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Instalar lo básico
echo "📦 Instalando paquetes..."
apt update -y
apt install -y nginx certbot python3-certbot-nginx

# Configurar directorio web
echo "📁 Creando directorio web..."
mkdir -p /var/www/tutorium
echo "<h1>Tutorium - Servidor funcionando</h1><p>IP: $(hostname -I | awk '{print $1}')</p>" > /var/www/tutorium/index.html
chown -R www-data:www-data /var/www/tutorium

# Configurar Nginx básico
echo "⚙️ Configurando Nginx..."
rm -f /etc/nginx/sites-enabled/default
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
ln -sf /etc/nginx/sites-available/tutorium /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# Obtener SSL
echo "🔒 Obteniendo SSL..."
certbot certonly --webroot --webroot-path=/var/www/tutorium --email admin@sistemasorbix.com --agree-tos --no-eff-email --domains tutorium.sistemasorbix.com,www.tutorium.sistemasorbix.com --non-interactive

# Configurar SSL
echo "🔐 Configurando SSL..."
if [ -f "/etc/letsencrypt/live/tutorium.sistemasorbix.com/fullchain.pem" ]; then
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
    location / { try_files $uri $uri/ =404; }
}
EOF
nginx -t && systemctl reload nginx
fi

echo "✅ CONFIGURACIÓN RÁPIDA COMPLETADA"
echo "🌐 Sitio: https://tutorium.sistemasorbix.com"
echo "🔗 SSH: ssh root@$(hostname -I | awk '{print $1}')"
echo "🔑 Contraseña: fTeRLCxfnaRL"
