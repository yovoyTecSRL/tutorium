#!/bin/bash
# ===================================================================
# SSL Setup Script for tutorium.sistemasorbix.com
# Orbix Systems - Automated SSL Certificate Installation
# ===================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
DOMAIN="tutorium.sistemasorbix.com"
WEBROOT="/var/www/tutorium.sistemasorbix.com/html"
NGINX_CONFIG="/etc/nginx/sites-available/tutorium.conf"
EMAIL="admin@sistemasorbix.com"

echo -e "${BLUE}🔒 ORBIX SSL Setup para ${DOMAIN}${NC}"
echo "=" * 60

# Función para logging
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Verificar si se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   error "Este script debe ejecutarse como root"
fi

# Actualizar sistema
log "Actualizando sistema..."
apt update && apt upgrade -y

# Instalar dependencias
log "Instalando dependencias..."
apt install -y nginx certbot python3-certbot-nginx ufw curl wget

# Crear directorio web
log "Creando estructura de directorios..."
mkdir -p $WEBROOT
mkdir -p /var/log/nginx
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

# Configurar firewall
log "Configurando firewall..."
ufw --force enable
ufw allow 'Nginx Full'
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp

# Copiar archivos del sitio web
log "Copiando archivos del sitio web..."
if [ -f "/tmp/tutorium-deploy/index.html" ]; then
    cp -r /tmp/tutorium-deploy/* $WEBROOT/
else
    # Crear archivo temporal si no existe
    cat > $WEBROOT/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Tutorium - Configurando SSL...</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .container { max-width: 600px; margin: 0 auto; }
        h1 { color: #00f7ff; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔒 Tutorium SSL Setup</h1>
        <p>Configurando certificados SSL para tutorium.sistemasorbix.com...</p>
        <p>Este proceso tomará unos minutos.</p>
    </div>
</body>
</html>
EOF
fi

# Configurar permisos
chown -R www-data:www-data $WEBROOT
chmod -R 755 $WEBROOT

# Configuración inicial de Nginx (HTTP solamente)
log "Configurando Nginx inicial..."
cat > /etc/nginx/sites-available/tutorium-temp.conf << 'EOF'
server {
    listen 80;
    server_name tutorium.sistemasorbix.com www.tutorium.sistemasorbix.com;
    
    root /var/www/tutorium.sistemasorbix.com/html;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location /.well-known/acme-challenge/ {
        root /var/www/tutorium.sistemasorbix.com/html;
    }
}
EOF

# Activar configuración temporal
ln -sf /etc/nginx/sites-available/tutorium-temp.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Verificar configuración de Nginx
log "Verificando configuración de Nginx..."
nginx -t || error "Error en la configuración de Nginx"

# Reiniciar Nginx
log "Reiniciando Nginx..."
systemctl restart nginx
systemctl enable nginx

# Esperar a que Nginx esté listo
sleep 5

# Verificar que el dominio responde
log "Verificando conectividad del dominio..."
if curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN | grep -q "200"; then
    log "✅ Dominio respondiendo correctamente"
else
    warning "⚠️ Dominio no responde, continuando con SSL..."
fi

# Obtener certificado SSL
log "Obteniendo certificado SSL de Let's Encrypt..."
certbot certonly \
    --webroot \
    --webroot-path=$WEBROOT \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --domains $DOMAIN,www.$DOMAIN \
    --non-interactive \
    --verbose

# Verificar que el certificado se obtuvo correctamente
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    log "✅ Certificado SSL obtenido exitosamente"
else
    error "❌ Error obteniendo certificado SSL"
fi

# Copiar configuración final de Nginx con SSL
log "Configurando Nginx con SSL..."
cp /tmp/tutorium-deploy/nginx/tutorium.conf /etc/nginx/sites-available/tutorium.conf

# Remover configuración temporal
rm -f /etc/nginx/sites-enabled/tutorium-temp.conf
rm -f /etc/nginx/sites-available/tutorium-temp.conf

# Activar configuración final
ln -sf /etc/nginx/sites-available/tutorium.conf /etc/nginx/sites-enabled/

# Verificar configuración final
log "Verificando configuración final de Nginx..."
nginx -t || error "Error en la configuración final de Nginx"

# Reiniciar Nginx con configuración SSL
log "Reiniciando Nginx con SSL..."
systemctl restart nginx

# Configurar renovación automática
log "Configurando renovación automática de certificados..."
cat > /etc/cron.d/certbot-renew << 'EOF'
0 12 * * * root certbot renew --quiet --nginx --post-hook "systemctl reload nginx"
EOF

# Verificar SSL
log "Verificando SSL..."
sleep 10
if curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN | grep -q "200"; then
    log "✅ SSL configurado correctamente"
else
    warning "⚠️ SSL podría necesitar tiempo para propagarse"
fi

# Mostrar información final
log "🎉 Configuración completada!"
echo ""
echo -e "${GREEN}✅ Sitio web: https://$DOMAIN${NC}"
echo -e "${GREEN}✅ Certificado SSL: Activo${NC}"
echo -e "${GREEN}✅ Redirección HTTP->HTTPS: Activa${NC}"
echo -e "${GREEN}✅ Renovación automática: Configurada${NC}"
echo ""
echo -e "${BLUE}📋 Información adicional:${NC}"
echo -e "   - Archivos web: $WEBROOT"
echo -e "   - Logs Nginx: /var/log/nginx/"
echo -e "   - Certificados: /etc/letsencrypt/live/$DOMAIN/"
echo -e "   - Configuración: /etc/nginx/sites-available/tutorium.conf"
echo ""
echo -e "${YELLOW}🔄 Para renovar manualmente: certbot renew --nginx${NC}"
echo -e "${YELLOW}🔍 Para verificar SSL: curl -I https://$DOMAIN${NC}"
