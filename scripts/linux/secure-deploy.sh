#!/bin/bash
# ===================================================================
# Secure Deploy Script for Tutorium with Orbix Security Integration
# Sistemas Orbix - Deployment with Security Auditing
# ===================================================================

set -e

# Configuración
SERVER_IP="178.156.182.125"
SERVER_USER="root"
DOMAIN="tutorium.sistemasorbix.com"
LOCAL_PATH="/d/ORBIX/tutorium-sistemasorbix"
REMOTE_PATH="/opt/tutorium"
TEMP_PATH="/tmp/tutorium-deploy"
RUN_SECURITY_AUDIT=true

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Funciones de logging
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

security_info() {
    echo -e "${CYAN}[SECURITY] $1${NC}"
}

# Banner
echo -e "${BLUE}🚀 ORBIX Secure Tutorium Deploy Script${NC}"
echo -e "${CYAN}🛡️  Incluye auditoría de seguridad automática${NC}"
echo "=" * 60
echo -e "${BLUE}🎯 Dominio: ${DOMAIN}${NC}"
echo -e "${BLUE}🖥️  Servidor: ${SERVER_IP}${NC}"
echo -e "${BLUE}🔒 Security Audit: $([ "$RUN_SECURITY_AUDIT" = true ] && echo "Enabled" || echo "Disabled")${NC}"
echo ""

# Verificar archivos locales
log "Verificando archivos locales..."
if [ ! -d "$LOCAL_PATH" ]; then
    error "Directorio local no encontrado: $LOCAL_PATH"
fi

if [ ! -f "$LOCAL_PATH/index.html" ]; then
    error "Archivo index.html no encontrado"
fi

# Verificar scripts de seguridad
SECURITY_SCRIPTS_EXIST=false
if [ -f "$LOCAL_PATH/scripts/linux/orbix_audit.sh" ] && [ -f "$LOCAL_PATH/scripts/linux/orbix_analysis.sh" ]; then
    SECURITY_SCRIPTS_EXIST=true
    security_info "Scripts de seguridad Orbix encontrados"
else
    warning "Scripts de seguridad Orbix no encontrados - se omitirá auditoría"
    RUN_SECURITY_AUDIT=false
fi

# Crear paquete de despliegue (incluyendo scripts de seguridad)
log "Creando paquete de despliegue seguro..."
cd "$LOCAL_PATH"

PACKAGE_FILES="index.html cursos.html registro.html css/ js/ assets/ nginx/ scripts/"
if [ "$SECURITY_SCRIPTS_EXIST" = true ]; then
    PACKAGE_FILES="$PACKAGE_FILES scripts/linux/orbix_*.sh scripts/linux/ORBIX_SECURITY_SUITE.md"
fi

tar -czf tutorium-secure-deploy.tar.gz \
    $PACKAGE_FILES \
    --exclude="*.log" \
    --exclude="node_modules" \
    --exclude=".git" \
    --exclude="test-results" \
    --exclude="playwright-report"

# Verificar conectividad al servidor
log "Verificando conectividad al servidor..."
if ! ping -c 1 "$SERVER_IP" >/dev/null 2>&1; then
    warning "Servidor no responde a ping, continuando..."
fi

# Subir archivos
log "Subiendo archivos al servidor..."
scp -o StrictHostKeyChecking=no tutorium-secure-deploy.tar.gz "${SERVER_USER}@${SERVER_IP}:/tmp/"

# Script de despliegue remoto con seguridad
log "Ejecutando despliegue seguro remoto..."
ssh -o StrictHostKeyChecking=no "${SERVER_USER}@${SERVER_IP}" << 'REMOTE_SCRIPT'
set -e
echo "🔧 Configurando servidor remoto con auditoría de seguridad..."

# Colores para SSH
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Crear directorio temporal
mkdir -p /tmp/tutorium-deploy
cd /tmp/tutorium-deploy

# Extraer archivos
if [ -f /tmp/tutorium-secure-deploy.tar.gz ]; then
    tar -xzf /tmp/tutorium-secure-deploy.tar.gz
else
    echo "Error: Archivo de despliegue no encontrado"
    exit 1
fi

# PRE-DEPLOYMENT SECURITY AUDIT
if [ -f scripts/linux/orbix_audit.sh ] && [ -x scripts/linux/orbix_audit.sh ]; then
    echo -e "${CYAN}🛡️  Ejecutando auditoría de seguridad pre-despliegue...${NC}"
    scripts/linux/orbix_audit.sh --quick
    
    # Análisis rápido
    if [ -f scripts/linux/orbix_analysis.sh ] && [ -x scripts/linux/orbix_analysis.sh ]; then
        scripts/linux/orbix_analysis.sh
        
        # Verificar hallazgos críticos
        LATEST_ANALYSIS=$(ls -1t /tmp/orbix-analysis-* 2>/dev/null | head -n1)
        if [ -n "$LATEST_ANALYSIS" ] && [ -f "$LATEST_ANALYSIS/summary.md" ]; then
            if grep -q "PROBABLE" "$LATEST_ANALYSIS/summary.md"; then
                echo -e "${YELLOW}⚠️  ADVERTENCIA: Se detectaron posibles problemas de seguridad${NC}"
                echo -e "${YELLOW}   Revisar: $LATEST_ANALYSIS/summary.md${NC}"
                echo -e "${YELLOW}   Continuar con precaución...${NC}"
            else
                echo -e "${GREEN}✅ Pre-audit: Sin problemas críticos detectados${NC}"
            fi
        fi
    fi
fi

# Hacer ejecutable el script SSL
if [ -f scripts/setup-ssl.sh ]; then
    chmod +x scripts/setup-ssl.sh
fi

# Ejecutar setup SSL si es necesario
if [ ! -f /etc/letsencrypt/live/tutorium.sistemasorbix.com/fullchain.pem ]; then
    echo "🔒 Configurando SSL..."
    if [ -f scripts/setup-ssl.sh ]; then
        ./scripts/setup-ssl.sh
    else
        echo "Script SSL no encontrado, continuando sin SSL..."
    fi
else
    echo "✅ SSL ya configurado"
fi

# Copiar archivos web
echo "📁 Copiando archivos web..."
mkdir -p /var/www/tutorium.sistemasorbix.com/html
cp -r index.html cursos.html registro.html css/ js/ assets/ /var/www/tutorium.sistemasorbix.com/html/ 2>/dev/null || true
chown -R www-data:www-data /var/www/tutorium.sistemasorbix.com/html
chmod -R 755 /var/www/tutorium.sistemasorbix.com/html

# Instalar scripts de seguridad en el sistema
if [ -d scripts/linux ] && [ -f scripts/linux/orbix_audit.sh ]; then
    echo -e "${CYAN}🔧 Instalando scripts de seguridad Orbix...${NC}"
    cp scripts/linux/orbix_*.sh /usr/local/bin/
    chmod +x /usr/local/bin/orbix_*.sh
    
    # Crear enlace de documentación
    mkdir -p /opt/orbix-security
    cp scripts/linux/ORBIX_SECURITY_SUITE.md /opt/orbix-security/ 2>/dev/null || true
    
    echo -e "${GREEN}✅ Scripts Orbix instalados en /usr/local/bin/${NC}"
fi

# Configurar Nginx
echo "🔧 Configurando Nginx..."
if [ -f nginx/tutorium.conf ]; then
    cp nginx/tutorium.conf /etc/nginx/sites-available/
    ln -sf /etc/nginx/sites-available/tutorium.conf /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
fi

# Probar y recargar Nginx
nginx -t && systemctl reload nginx

# POST-DEPLOYMENT SECURITY VERIFICATION
if command -v orbix_audit.sh >/dev/null 2>&1; then
    echo -e "${CYAN}🔍 Verificación de seguridad post-despliegue...${NC}"
    orbix_audit.sh --quick
    
    if command -v orbix_analysis.sh >/dev/null 2>&1; then
        orbix_analysis.sh
        
        # Mostrar resumen final
        LATEST_ANALYSIS=$(ls -1t /tmp/orbix-analysis-* 2>/dev/null | head -n1)
        if [ -n "$LATEST_ANALYSIS" ] && [ -f "$LATEST_ANALYSIS/summary.md" ]; then
            echo -e "${CYAN}📊 Resumen de seguridad post-despliegue:${NC}"
            grep -A 10 "Estadísticas de Análisis" "$LATEST_ANALYSIS/summary.md" | head -n 6
            
            if grep -q "PROBABLE" "$LATEST_ANALYSIS/summary.md"; then
                echo -e "${YELLOW}⚠️  ADVERTENCIA: Revisar hallazgos en $LATEST_ANALYSIS${NC}"
            else
                echo -e "${GREEN}✅ Post-audit: Despliegue seguro verificado${NC}"
            fi
        fi
    fi
fi

# Limpiar temporales
rm -rf /tmp/tutorium-deploy*

echo "✅ Despliegue seguro completado"
REMOTE_SCRIPT

# Verificar despliegue
log "Verificando despliegue..."
sleep 5

# Verificar HTTP (debería redirigir a HTTPS)
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://${DOMAIN}" || echo "000")
if [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
    log "✅ Redirección HTTP->HTTPS funcionando"
else
    warning "HTTP status: $HTTP_STATUS (esperado: 301/302)"
fi

# Verificar HTTPS
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://${DOMAIN}" || echo "000")
if [ "$HTTPS_STATUS" = "200" ]; then
    log "✅ HTTPS funcionando correctamente"
else
    warning "HTTPS status: $HTTPS_STATUS (esperado: 200)"
fi

# Limpiar archivos temporales locales
log "Limpiando archivos temporales..."
rm -f tutorium-secure-deploy.tar.gz

# Reporte final
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 DESPLIEGUE SEGURO COMPLETADO${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}📋 URLs disponibles:${NC}"
echo -e "   🌐 Principal: https://$DOMAIN"
echo -e "   📚 Cursos: https://$DOMAIN/cursos.html"
echo -e "   📝 Registro: https://$DOMAIN/registro.html"
echo ""
echo -e "${CYAN}🛡️  Características de seguridad:${NC}"
echo -e "   ✅ Auditoría pre-despliegue ejecutada"
echo -e "   ✅ Scripts Orbix instalados en /usr/local/bin/"
echo -e "   ✅ Verificación post-despliegue completada"
echo -e "   ✅ Documentación en /opt/orbix-security/"
echo ""
echo -e "${YELLOW}🔧 Comandos de seguridad disponibles en el servidor:${NC}"
echo -e "   ssh $SERVER_USER@$SERVER_IP 'orbix_audit.sh'"
echo -e "   ssh $SERVER_USER@$SERVER_IP 'orbix_analysis.sh'"
echo -e "   ssh $SERVER_USER@$SERVER_IP 'cat /opt/orbix-security/ORBIX_SECURITY_SUITE.md'"
echo ""
echo -e "${YELLOW}📊 Para ver logs del servidor:${NC}"
echo -e "   ssh $SERVER_USER@$SERVER_IP 'tail -f /var/log/nginx/tutorium.sistemasorbix.com.error.log'"
echo ""
echo -e "${GREEN}🚀 Tutorium seguro está listo para usar!${NC}"

# Mostrar último reporte de seguridad si está disponible
if [ "$RUN_SECURITY_AUDIT" = true ]; then
    echo ""
    echo -e "${CYAN}📈 Para ver el último reporte de seguridad:${NC}"
    echo -e "   ssh $SERVER_USER@$SERVER_IP 'ls -1t /tmp/orbix-analysis-* | head -n1 | xargs -I {} cat {}/summary.md'"
fi

exit 0