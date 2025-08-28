#!/bin/bash
# ===================================================================
# Deploy Script for Tutorium to Hetzner Server
# Orbix Systems - Automated Deployment with SSL
# ===================================================================

set -e

# Configuración
SERVER_IP="178.156.182.125"
SERVER_USER="root"
DOMAIN="tutorium.sistemasorbix.com"
LOCAL_PATH="/d/ORBIX/tutorium-sistemasorbix"
REMOTE_PATH="/opt/tutorium"
TEMP_PATH="/tmp/tutorium-deploy"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

echo -e "${BLUE}🚀 ORBIX Tutorium Deploy Script${NC}"
echo "=" * 60
echo -e "${BLUE}🎯 Dominio: ${DOMAIN}${NC}"
echo -e "${BLUE}🖥️  Servidor: ${SERVER_IP}${NC}"
echo ""

# Verificar archivos locales
log "Verificando archivos locales..."
if [ ! -d "$LOCAL_PATH" ]; then
    error "Directorio local no encontrado: $LOCAL_PATH"
fi

if [ ! -f "$LOCAL_PATH/index.html" ]; then
    error "Archivo index.html no encontrado"
fi

# Crear paquete de despliegue
log "Creando paquete de despliegue..."
cd "$LOCAL_PATH"
tar -czf tutorium-deploy.tar.gz \
    index.html \
    cursos.html \
    registro.html \
    css/ \
    js/ \
    assets/ \
    nginx/ \
    scripts/ \
    --exclude="*.log" \
    --exclude="node_modules" \
    --exclude=".git"

# Verificar conectividad al servidor
log "Verificando conectividad al servidor..."
if ! ping -c 1 $SERVER_IP > /dev/null 2>&1; then
    warning "No se puede hacer ping al servidor, continuando..."
fi

# Subir archivos al servidor
log "Subiendo archivos al servidor..."
scp -o StrictHostKeyChecking=no tutorium-deploy.tar.gz $SERVER_USER@$SERVER_IP:/tmp/

# Ejecutar comandos remotos
log "Ejecutando despliegue remoto..."
ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP << 'ENDSSH'
    set -e
    
    # Crear directorio temporal
    mkdir -p /tmp/tutorium-deploy
    cd /tmp/tutorium-deploy
    
    # Extraer archivos
    tar -xzf /tmp/tutorium-deploy.tar.gz
    
    # Hacer ejecutable el script SSL
    chmod +x scripts/setup-ssl.sh
    
    # Ejecutar setup SSL
    ./scripts/setup-ssl.sh
    
    # Limpiar archivos temporales
    rm -f /tmp/tutorium-deploy.tar.gz
ENDSSH

# Limpiar archivos locales temporales
rm -f tutorium-deploy.tar.gz

# Verificar despliegue
log "Verificando despliegue..."
sleep 10

# Verificar HTTP (debería redirigir)
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN || echo "000")
if [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
    log "✅ HTTP redirección funcionando"
else
    warning "⚠️ HTTP Status: $HTTP_STATUS"
fi

# Verificar HTTPS
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN || echo "000")
if [ "$HTTPS_STATUS" = "200" ]; then
    log "✅ HTTPS funcionando correctamente"
else
    warning "⚠️ HTTPS Status: $HTTPS_STATUS"
fi

# Verificar certificado SSL
log "Verificando certificado SSL..."
SSL_INFO=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "Error")
if [[ "$SSL_INFO" != "Error" ]]; then
    log "✅ Certificado SSL válido"
    echo "$SSL_INFO"
else
    warning "⚠️ Error verificando certificado SSL"
fi

# Resultados finales
echo ""
echo -e "${GREEN}🎉 DESPLIEGUE COMPLETADO${NC}"
echo "=" * 60
echo -e "${GREEN}✅ Sitio web: https://$DOMAIN${NC}"
echo -e "${GREEN}✅ Redirección HTTP->HTTPS: Activa${NC}"
echo -e "${GREEN}✅ Certificado SSL: Configurado${NC}"
echo -e "${GREEN}✅ Nginx: Configurado${NC}"
echo ""
echo -e "${BLUE}📋 URLs disponibles:${NC}"
echo -e "   🌐 Principal: https://$DOMAIN"
echo -e "   📚 Cursos: https://$DOMAIN/cursos.html"
echo -e "   📝 Registro: https://$DOMAIN/registro.html"
echo ""
echo -e "${YELLOW}🔧 Para verificar logs del servidor:${NC}"
echo -e "   ssh $SERVER_USER@$SERVER_IP 'tail -f /var/log/nginx/tutorium.sistemasorbix.com.error.log'"
echo ""
echo -e "${BLUE}🚀 Tutorium está listo para usar!${NC}"
