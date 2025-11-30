#!/usr/bin/env bash
# ===================================================================
# Orbix Sentinel - Comprehensive Security Audit Script
# Sistemas Orbix - Non-destructive Security Assessment Tool
# ===================================================================
# 
# OBJETIVO: Realizar auditoría completa de seguridad e integridad
# MODO: Solo lectura - No destructivo
# SALIDA: Paquete forense estructurado en /tmp/orbix-sentinel-<timestamp>
#
# Uso: ./orbix_audit.sh [--install-tools] [--quick]
# ===================================================================

set +e  # No salir en errores para continuar auditoría

# ===================================================================
# CONFIGURACIÓN Y VARIABLES
# ===================================================================

TS=$(date +"%Y%m%d-%H%M%S")
WORKDIR="/tmp/orbix-sentinel-${TS}"
LOG="$WORKDIR/run.log"
INSTALL_TOOLS=false
QUICK_MODE=false

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ===================================================================
# FUNCIONES AUXILIARES
# ===================================================================

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}" | tee -a "$LOG"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" | tee -a "$LOG"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}" | tee -a "$LOG"
}

critical() {
    echo -e "${RED}[CRITICAL] $1${NC}" | tee -a "$LOG"
}

# Función para ejecutar comandos con logging
run_cmd() {
    local cmd="$1"
    local desc="$2"
    local output_file="$3"
    
    info "Ejecutando: $desc"
    echo "# Command: $cmd" >> "$LOG"
    echo "# Description: $desc" >> "$LOG"
    echo "# Timestamp: $(date -u)" >> "$LOG"
    
    if [ -n "$output_file" ]; then
        eval "$cmd" >> "$output_file" 2>&1
        local exit_code=$?
        echo "# Exit code: $exit_code" >> "$LOG"
        if [ $exit_code -ne 0 ]; then
            warning "Comando falló con código $exit_code: $cmd"
        fi
    else
        eval "$cmd" >> "$LOG" 2>&1
        local exit_code=$?
        if [ $exit_code -ne 0 ]; then
            warning "Comando falló con código $exit_code: $cmd"
        fi
    fi
}

# ===================================================================
# PROCESAMIENTO DE ARGUMENTOS
# ===================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --install-tools)
            INSTALL_TOOLS=true
            shift
            ;;
        --quick)
            QUICK_MODE=true
            shift
            ;;
        -h|--help)
            echo "Orbix Sentinel - Security Audit Script"
            echo "Uso: $0 [--install-tools] [--quick]"
            echo "  --install-tools: Instalar herramientas faltantes"
            echo "  --quick: Modo rápido (omite scans largos)"
            exit 0
            ;;
        *)
            error "Argumento desconocido: $1"
            exit 1
            ;;
    esac
done

# ===================================================================
# BANNER Y CONFIGURACIÓN INICIAL
# ===================================================================

echo -e "${CYAN}"
echo "═══════════════════════════════════════════════════════════════"
echo "🛡️  ORBIX SENTINEL - SECURITY AUDIT SYSTEM"
echo "═══════════════════════════════════════════════════════════════"
echo -e "${NC}"
echo -e "${BLUE}🎯 Objetivo: Auditoría de seguridad no destructiva${NC}"
echo -e "${BLUE}📁 Directorio: ${WORKDIR}${NC}"
echo -e "${BLUE}⏰ Timestamp: ${TS}${NC}"
echo ""

# ===================================================================
# 1) PREPARACIÓN
# ===================================================================

log "Iniciando preparación del entorno..."

# Crear directorio de trabajo
mkdir -p "$WORKDIR" && chmod 700 "$WORKDIR"
if [ $? -ne 0 ]; then
    error "No se pudo crear directorio de trabajo: $WORKDIR"
    exit 1
fi

# Crear subdirectorios
mkdir -p "$WORKDIR"/{logs,scans,analysis,evidence,reports}

# Inicializar log principal
echo "═══════════════════════════════════════════════════════════════" > "$LOG"
echo "ORBIX SENTINEL - SECURITY AUDIT LOG" >> "$LOG"
echo "Start time: $(date -u)" >> "$LOG"
echo "Workdir: $WORKDIR" >> "$LOG"
echo "User: $(whoami)" >> "$LOG"
echo "Host: $(hostname)" >> "$LOG"
echo "═══════════════════════════════════════════════════════════════" >> "$LOG"

log "✅ Preparación completada"

# ===================================================================
# 2) INFORMACIÓN BÁSICA DEL SISTEMA
# ===================================================================

log "Recopilando información básica del sistema..."

run_cmd "id" "Información del usuario actual" "$WORKDIR/logs/user_info.txt"
run_cmd "whoami" "Usuario actual" "$WORKDIR/logs/user_info.txt"
run_cmd "uname -a" "Información del kernel" "$WORKDIR/logs/system_info.txt"
run_cmd "uptime" "Tiempo de actividad" "$WORKDIR/logs/system_info.txt"
run_cmd "date -u" "Fecha y hora UTC" "$WORKDIR/logs/system_info.txt"
run_cmd "df -hT" "Información de discos" "$WORKDIR/logs/disk_info.txt"
run_cmd "free -h" "Información de memoria" "$WORKDIR/logs/memory_info.txt"
run_cmd "lscpu" "Información de CPU" "$WORKDIR/logs/cpu_info.txt"

# Red e interfaces
run_cmd "ip addr show" "Interfaces de red" "$WORKDIR/logs/network_info.txt"
run_cmd "ip route" "Tabla de rutas" "$WORKDIR/logs/network_info.txt"
run_cmd "ss -tulpen" "Puertos en escucha" "$WORKDIR/logs/network_ports.txt"

log "✅ Información básica recopilada"

# ===================================================================
# 3) USUARIOS Y PERMISOS
# ===================================================================

log "Analizando usuarios y permisos..."

# Usuarios con shell
run_cmd "awk -F: '\$7 ~ /(\/bin\/bash|\/bin\/sh|\/bin\/zsh)/ {print \$1\":\"\$6\":\"\$7}' /etc/passwd" "Usuarios con shell válido" "$WORKDIR/logs/users_with_shell.txt"

# Últimos logins
run_cmd "last -n 100" "Últimos 100 logins" "$WORKDIR/logs/last_logins.txt"

# Grupos privilegiados
run_cmd "getent group sudo" "Grupo sudo" "$WORKDIR/logs/privileged_groups.txt"
run_cmd "getent group wheel" "Grupo wheel" "$WORKDIR/logs/privileged_groups.txt"
run_cmd "getent group adm" "Grupo adm" "$WORKDIR/logs/privileged_groups.txt"

# Sudoers
if [ -r /etc/sudoers ]; then
    run_cmd "cat /etc/sudoers" "Configuración sudoers" "$WORKDIR/logs/sudoers.txt"
fi

# Directorios home
run_cmd "ls -la /home" "Directorios home" "$WORKDIR/logs/home_dirs.txt"

# Procesos por usuario
run_cmd "ps aux --sort=-%mem" "Procesos ordenados por memoria" "$WORKDIR/logs/processes_memory.txt"
run_cmd "ps -eo pid,ppid,cmd,user,etimes,%mem,%cpu --sort=-etimes" "Procesos por tiempo de ejecución" "$WORKDIR/logs/processes_time.txt"

log "✅ Análisis de usuarios completado"

# ===================================================================
# 4) SERVICIOS Y PROCESOS
# ===================================================================

log "Analizando servicios y procesos..."

# Servicios systemd
run_cmd "systemctl list-units --type=service --state=running --no-pager" "Servicios activos" "$WORKDIR/logs/services_running.txt"
run_cmd "systemctl --failed --no-pager" "Servicios fallidos" "$WORKDIR/logs/services_failed.txt"

# Journal reciente
run_cmd "journalctl -n 500 --no-pager" "Journal reciente (500 líneas)" "$WORKDIR/logs/journal_recent.log"

# Procesos sospechosos (sin binario en paths estándar)
run_cmd "ps aux" "Todos los procesos" "$WORKDIR/logs/all_processes.txt"

# Conexiones de red activas
run_cmd "ss -tunap" "Conexiones de red activas" "$WORKDIR/logs/network_connections.txt"
run_cmd "lsof -i -Pn" "Archivos abiertos en red" "$WORKDIR/logs/network_files.txt"

log "✅ Análisis de servicios completado"

# ===================================================================
# 5) CONTENEDORES Y VIRTUALIZACIÓN
# ===================================================================

log "Verificando contenedores y virtualización..."

# Docker si existe
if command -v docker >/dev/null 2>&1; then
    info "Docker detectado, analizando contenedores..."
    run_cmd "docker ps -a --no-trunc --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}'" "Contenedores Docker" "$WORKDIR/logs/docker_containers.txt"
    run_cmd "docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}'" "Imágenes Docker" "$WORKDIR/logs/docker_images.txt"
    
    # Logs de contenedores activos
    mkdir -p "$WORKDIR/logs/docker_logs"
    for container in $(docker ps -q); do
        if [ -n "$container" ]; then
            run_cmd "docker logs --tail 200 $container" "Logs contenedor $container" "$WORKDIR/logs/docker_logs/container_${container}.log"
        fi
    done
else
    info "Docker no encontrado"
fi

# Podman si existe
if command -v podman >/dev/null 2>&1; then
    info "Podman detectado"
    run_cmd "podman ps -a" "Contenedores Podman" "$WORKDIR/logs/podman_containers.txt"
fi

log "✅ Análisis de contenedores completado"

# ===================================================================
# 6) PAQUETES Y ACTUALIZACIONES
# ===================================================================

log "Analizando paquetes y actualizaciones..."

# Sistema de paquetes Debian/Ubuntu
if command -v apt >/dev/null 2>&1; then
    run_cmd "grep 'upgrade\\|install\\|remove' /var/log/dpkg.log* /var/log/apt/history.log* 2>/dev/null | tail -n 100" "Historial de paquetes APT" "$WORKDIR/logs/package_history.txt"
    run_cmd "dpkg -l" "Paquetes instalados" "$WORKDIR/logs/packages_installed.txt"
    
    # Verificar integridad de paquetes si debsums está disponible
    if command -v debsums >/dev/null 2>&1; then
        info "Verificando integridad de paquetes con debsums..."
        run_cmd "debsums -s 2>/dev/null" "Archivos modificados (debsums)" "$WORKDIR/scans/debsums_changed.txt"
    else
        warning "debsums no disponible para verificar integridad"
    fi
fi

# Sistema de paquetes RedHat/CentOS
if command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
    run_cmd "rpm -qa" "Paquetes instalados (RPM)" "$WORKDIR/logs/packages_rpm.txt"
fi

log "✅ Análisis de paquetes completado"

# ===================================================================
# 7) ARCHIVOS SUID/SGID Y PERMISOS ESPECIALES
# ===================================================================

log "Buscando archivos con permisos especiales..."

# Archivos SUID/SGID
run_cmd "find / -xdev \\( -perm -4000 -o -perm -2000 \\) -type f -print 2>/dev/null" "Archivos SUID/SGID" "$WORKDIR/scans/suid_files.txt"

# Archivos escribibles por world
run_cmd "find / -xdev -type f -perm -002 -print 2>/dev/null | head -n 1000" "Archivos escribibles por todos" "$WORKDIR/scans/world_writable.txt"

# Directorios con sticky bit
run_cmd "find / -xdev -type d \\( -perm -1000 \\) -print 2>/dev/null" "Directorios con sticky bit" "$WORKDIR/scans/sticky_dirs.txt"

log "✅ Análisis de permisos especiales completado"

# ===================================================================
# 8) CRON JOBS Y TAREAS PROGRAMADAS
# ===================================================================

log "Analizando tareas programadas..."

# Crontab del usuario actual
run_cmd "crontab -l 2>/dev/null || echo 'No crontab for current user'" "Crontab usuario actual" "$WORKDIR/logs/crontab_current.txt"

# Crontabs de todos los usuarios
for user in $(cut -f1 -d: /etc/passwd); do
    run_cmd "crontab -u $user -l 2>/dev/null" "Crontab usuario $user" "$WORKDIR/logs/crontab_${user}.txt"
done

# Cron del sistema
run_cmd "ls -la /etc/cron*" "Archivos cron del sistema" "$WORKDIR/logs/system_cron.txt"
if [ -d /etc/cron.d ]; then
    run_cmd "find /etc/cron.d -type f -exec cat {} +" "Contenido /etc/cron.d" "$WORKDIR/logs/cron_d_contents.txt"
fi

# Systemd timers
run_cmd "systemctl list-timers --all --no-pager" "Systemd timers" "$WORKDIR/logs/systemd_timers.txt"

log "✅ Análisis de tareas programadas completado"

# ===================================================================
# 9) LOGS DE AUTENTICACIÓN Y ACCESOS
# ===================================================================

log "Recopilando logs de autenticación..."

# Auth logs
if [ -f /var/log/auth.log ]; then
    run_cmd "tail -n 2000 /var/log/auth.log" "Auth log reciente" "$WORKDIR/logs/auth_recent.log"
elif [ -f /var/log/secure ]; then
    run_cmd "tail -n 2000 /var/log/secure" "Secure log reciente" "$WORKDIR/logs/auth_recent.log"
else
    run_cmd "journalctl -u ssh -n 2000 --no-pager" "SSH journal" "$WORKDIR/logs/auth_recent.log"
fi

# Syslog
if [ -f /var/log/syslog ]; then
    run_cmd "tail -n 1000 /var/log/syslog" "Syslog reciente" "$WORKDIR/logs/syslog_recent.log"
fi

# Nginx logs si existen
if [ -f /var/log/nginx/access.log ]; then
    run_cmd "tail -n 1000 /var/log/nginx/access.log" "Nginx access log" "$WORKDIR/logs/nginx_access_recent.log"
fi

if [ -f /var/log/nginx/error.log ]; then
    run_cmd "tail -n 1000 /var/log/nginx/error.log" "Nginx error log" "$WORKDIR/logs/nginx_error_recent.log"
fi

# Apache logs si existen
if [ -f /var/log/apache2/access.log ]; then
    run_cmd "tail -n 1000 /var/log/apache2/access.log" "Apache access log" "$WORKDIR/logs/apache_access_recent.log"
fi

log "✅ Recopilación de logs completada"

# ===================================================================
# 10) DETECCIÓN DE WEBSHELLS Y ARCHIVOS SOSPECHOSOS
# ===================================================================

log "Buscando webshells y archivos sospechosos..."

# Archivos modificados recientemente en webroot
if [ -d /var/www ]; then
    run_cmd "find /var/www -type f -mtime -30 -print 2>/dev/null" "Archivos web modificados (30 días)" "$WORKDIR/scans/web_modified_30d.txt"
fi

if [ -d /srv ]; then
    run_cmd "find /srv -type f -mtime -30 -print 2>/dev/null" "Archivos srv modificados (30 días)" "$WORKDIR/scans/srv_modified_30d.txt"
fi

# Buscar patrones sospechosos en archivos web
info "Buscando patrones sospechosos en webroot..."
grep -RIn --exclude-dir=node_modules --exclude-dir=vendor \
    -E "eval\\(|base64_decode\\(|shell_exec\\(|exec\\(|passthru\\(|wget\\s+http|curl\\s+http|/bin/bash -c|nc\\s+-e|bash -i" \
    /var/www /srv 2>/dev/null > "$WORKDIR/scans/web_suspicious_patterns.txt" || true

# Buscar archivos PHP sospechosos
if [ -d /var/www ] || [ -d /srv ]; then
    info "Buscando archivos PHP con nombres sospechosos..."
    find /var/www /srv -type f -name "*.php" \
        -exec grep -l "eval\\|base64_decode\\|shell_exec\\|exec\\|passthru" {} + 2>/dev/null \
        > "$WORKDIR/scans/suspicious_php_files.txt" || true
fi

log "✅ Búsqueda de webshells completada"

# ===================================================================
# 11) SCANS DE ROOTKITS Y MALWARE
# ===================================================================

log "Ejecutando scans de seguridad..."

# rkhunter si está disponible
if command -v rkhunter >/dev/null 2>&1; then
    info "Ejecutando rkhunter..."
    run_cmd "rkhunter --check --sk --rwo" "rkhunter scan" "$WORKDIR/scans/rkhunter.log"
elif [ "$INSTALL_TOOLS" = true ]; then
    warning "rkhunter no encontrado. Instalando..."
    if command -v apt >/dev/null 2>&1; then
        apt update && apt install -y rkhunter
        run_cmd "rkhunter --check --sk --rwo" "rkhunter scan" "$WORKDIR/scans/rkhunter.log"
    fi
else
    warning "rkhunter no instalado (usar --install-tools para instalar)"
fi

# chkrootkit si está disponible
if command -v chkrootkit >/dev/null 2>&1; then
    info "Ejecutando chkrootkit..."
    run_cmd "chkrootkit" "chkrootkit scan" "$WORKDIR/scans/chkrootkit.log"
elif [ "$INSTALL_TOOLS" = true ]; then
    warning "chkrootkit no encontrado. Instalando..."
    if command -v apt >/dev/null 2>&1; then
        apt install -y chkrootkit
        run_cmd "chkrootkit" "chkrootkit scan" "$WORKDIR/scans/chkrootkit.log"
    fi
else
    warning "chkrootkit no instalado (usar --install-tools para instalar)"
fi

# ClamAV si está disponible y no es modo rápido
if [ "$QUICK_MODE" = false ]; then
    if command -v clamscan >/dev/null 2>&1; then
        info "Ejecutando ClamAV scan en webroot..."
        run_cmd "clamscan -r -i /var/www /srv" "ClamAV webroot scan" "$WORKDIR/scans/clamav_webroot.log"
        
        info "Ejecutando ClamAV scan en /tmp..."
        run_cmd "clamscan -r -i /tmp" "ClamAV tmp scan" "$WORKDIR/scans/clamav_tmp.log"
    elif [ "$INSTALL_TOOLS" = true ]; then
        warning "ClamAV no encontrado. Instalando..."
        if command -v apt >/dev/null 2>&1; then
            apt install -y clamav clamav-daemon
            freshclam
            run_cmd "clamscan -r -i /var/www /srv" "ClamAV webroot scan" "$WORKDIR/scans/clamav_webroot.log"
        fi
    else
        warning "ClamAV no instalado (usar --install-tools para instalar)"
    fi
else
    info "Modo rápido: omitiendo ClamAV scan"
fi

log "✅ Scans de seguridad completados"

# ===================================================================
# 12) ANÁLISIS DE ARCHIVOS TEMPORALES Y CACHE
# ===================================================================

log "Analizando archivos temporales..."

# Archivos recientes en /tmp
run_cmd "find /tmp -type f -mtime -7 -print 2>/dev/null" "Archivos /tmp (7 días)" "$WORKDIR/scans/tmp_recent.txt"

# Archivos en /dev/shm
run_cmd "find /dev/shm -type f -print 2>/dev/null" "Archivos /dev/shm" "$WORKDIR/scans/devshm_files.txt"

# Procesos usando /tmp
run_cmd "lsof +D /tmp 2>/dev/null" "Procesos usando /tmp" "$WORKDIR/scans/tmp_processes.txt"

log "✅ Análisis de temporales completado"

# ===================================================================
# 13) VERIFICACIÓN DE CERTIFICADOS SSL
# ===================================================================

log "Verificando certificados SSL..."

if command -v openssl >/dev/null 2>&1; then
    # Buscar dominios en configuración nginx
    if [ -d /etc/nginx/sites-enabled ]; then
        for domain in $(grep -h "server_name" /etc/nginx/sites-enabled/* 2>/dev/null | \
                       awk '{for(i=2;i<=NF;i++) print $i}' | \
                       tr -d ';' | sort -u | grep -v '_'); do
            if [ "$domain" != "localhost" ] && [ "$domain" != "default_server" ]; then
                info "Verificando certificado para $domain..."
                echo "=== Certificado para $domain ===" >> "$WORKDIR/logs/ssl_certificates.txt"
                echo | openssl s_client -connect "${domain}:443" -servername "${domain}" 2>/dev/null | \
                    openssl x509 -noout -dates -subject -issuer >> "$WORKDIR/logs/ssl_certificates.txt" 2>&1 || \
                    echo "Error verificando $domain" >> "$WORKDIR/logs/ssl_certificates.txt"
            fi
        done
    fi
fi

log "✅ Verificación SSL completada"

# ===================================================================
# 14) ANÁLISIS DE SERVICIOS CRÍTICOS
# ===================================================================

log "Analizando servicios críticos..."

# Puertos críticos
run_cmd "ss -tunap | grep -E ':(80|443|22|3306|5432|6379|8069|3000|8000)'" "Puertos críticos" "$WORKDIR/logs/critical_ports.txt"

# Estado de servicios web
for service in nginx apache2 httpd; do
    if systemctl is-active --quiet "$service"; then
        run_cmd "systemctl status $service --no-pager" "Estado $service" "$WORKDIR/logs/service_${service}.txt"
    fi
done

# Estado de bases de datos
for service in mysql postgresql redis-server; do
    if systemctl is-active --quiet "$service"; then
        run_cmd "systemctl status $service --no-pager" "Estado $service" "$WORKDIR/logs/service_${service}.txt"
    fi
done

log "✅ Análisis de servicios críticos completado"

# ===================================================================
# 15) BÚSQUEDA DE ORBIX SENTINEL EXISTENTE
# ===================================================================

log "Buscando instalaciones previas de Orbix Sentinel..."

# Buscar scripts sentinel
for path in /usr/local/bin /opt /srv /root /usr/bin /usr/local/sbin; do
    find "$path" -name "*orbix*" -o -name "*sentinel*" 2>/dev/null >> "$WORKDIR/logs/orbix_files.txt" || true
done

# Ejecutar diagnósticos si existen
for script in /usr/local/bin/orbix_sentinel* /opt/orbix/sentinel* /root/orbix* /srv/orbix*; do
    if [ -x "$script" ]; then
        info "Ejecutando diagnóstico Orbix: $script"
        run_cmd "$script --diagnostic 2>&1 || true" "Orbix diagnostic" "$WORKDIR/logs/orbix_diagnostic.log"
    fi
done

log "✅ Búsqueda Orbix completada"

# ===================================================================
# 16) INVENTARIO DE BINARIOS Y HASHES
# ===================================================================

log "Generando inventario de binarios..."

# Hashes de binarios críticos
run_cmd "find /usr/bin /usr/local/bin /sbin /bin -type f -executable -print0 | xargs -0 sha256sum 2>/dev/null" "Hashes binarios" "$WORKDIR/evidence/bin_hashes.sha256"

# Lista de paquetes para inventario
if command -v dpkg >/dev/null 2>&1; then
    run_cmd "dpkg -l" "Inventario paquetes DEB" "$WORKDIR/evidence/package_inventory.txt"
elif command -v rpm >/dev/null 2>&1; then
    run_cmd "rpm -qa" "Inventario paquetes RPM" "$WORKDIR/evidence/package_inventory.txt"
fi

log "✅ Inventario completado"

# ===================================================================
# 17) ANÁLISIS DE BINARIOS SOSPECHOSOS
# ===================================================================

log "Analizando binarios con strings..."

mkdir -p "$WORKDIR/evidence/binary_analysis"

# Analizar binarios ejecutables encontrados en ubicaciones inusuales
if [ -f "$WORKDIR/scans/tmp_recent.txt" ]; then
    while IFS= read -r file; do
        if [ -x "$file" ] && file "$file" | grep -qi "executable"; then
            basename_file=$(basename "$file")
            info "Analizando binario: $file"
            strings "$file" 2>/dev/null | \
                grep -iE "base64|bash -c|/bin/sh|curl http|wget http|nc -e|/dev/tcp" | \
                head -n 50 > "$WORKDIR/evidence/binary_analysis/${basename_file}.strings" 2>/dev/null || true
        fi
    done < "$WORKDIR/scans/tmp_recent.txt"
fi

log "✅ Análisis de binarios completado"

# ===================================================================
# 18) GENERACIÓN DE RESUMEN Y ANÁLISIS
# ===================================================================

log "Generando resumen de hallazgos..."

# Crear resumen ejecutivo
cat > "$WORKDIR/reports/summary.txt" << EOF
═══════════════════════════════════════════════════════════════
ORBIX SENTINEL - RESUMEN EJECUTIVO
═══════════════════════════════════════════════════════════════

Fecha del análisis: $(date -u)
Sistema: $(uname -a)
Usuario: $(whoami)
Directorio de trabajo: $WORKDIR

INDICADORES CRÍTICOS:
$(grep -iE "fail|error|unauthorized|invalid|refused|denied|segfault|panic|expired|warning|critical" "$WORKDIR"/logs/* "$WORKDIR"/scans/* 2>/dev/null | head -n 50 | sed 's/^/  /')

PROCESOS CON MAYOR USO DE RECURSOS:
$(ps aux --sort=-%mem | head -n 20)

CONEXIONES DE RED ACTIVAS:
$(ss -tunap | grep ESTAB | head -n 20)

ARCHIVOS SUID/SGID ENCONTRADOS:
$(wc -l < "$WORKDIR/scans/suid_files.txt" 2>/dev/null || echo "0") archivos

PATRONES SOSPECHOSOS EN WEB:
$(wc -l < "$WORKDIR/scans/web_suspicious_patterns.txt" 2>/dev/null || echo "0") coincidencias

RECOMENDACIONES INMEDIATAS:
- Preservar este directorio para análisis forense: $WORKDIR
- Si hay conexiones sospechosas, considerar aislamiento de red
- Cambiar claves SSH y rotar secretos si hay accesos no autorizados
- No reiniciar ni eliminar logs hasta completar investigación
- Realizar snapshot del sistema para preservar evidencia

SIGUIENTE PASO:
- Descargar paquete completo: ${WORKDIR}.tar.gz
- Ejecutar análisis detallado con herramientas forenses especializadas
EOF

# Crear lista de hallazgos críticos
cat > "$WORKDIR/reports/critical_findings.txt" << EOF
HALLAZGOS CRÍTICOS - ORBIX SENTINEL
═══════════════════════════════════

$(head -n 100 "$WORKDIR/scans/web_suspicious_patterns.txt" 2>/dev/null | sed 's/^/WEBSHELL_PATTERN: /')

$(grep -iE "unauthorized|refused|invalid" "$WORKDIR/logs/auth_recent.log" 2>/dev/null | head -n 50 | sed 's/^/AUTH_FAIL: /')

$(find "$WORKDIR/scans" -name "*.txt" -exec grep -l "INFECTED\|FOUND\|WARNING" {} + 2>/dev/null | sed 's/^/MALWARE_SCAN: /')
EOF

log "✅ Resumen generado"

# ===================================================================
# 19) EMPAQUETADO FINAL
# ===================================================================

log "Empaquetando resultados..."

cd /tmp
tar -czf "${WORKDIR}.tar.gz" -C "$(dirname "$WORKDIR")" "$(basename "$WORKDIR")" 2>/dev/null

if [ $? -eq 0 ]; then
    log "✅ Paquete creado: ${WORKDIR}.tar.gz"
    ls -lh "${WORKDIR}.tar.gz"
else
    error "Error creando paquete"
fi

# ===================================================================
# 20) REPORTE FINAL
# ===================================================================

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🎉 ORBIX SENTINEL - AUDITORÍA COMPLETADA${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}📁 Directorio de trabajo: ${WORKDIR}${NC}"
echo -e "${GREEN}📦 Paquete generado: ${WORKDIR}.tar.gz${NC}"
echo -e "${GREEN}📊 Resumen: ${WORKDIR}/reports/summary.txt${NC}"
echo -e "${GREEN}🚨 Hallazgos críticos: ${WORKDIR}/reports/critical_findings.txt${NC}"
echo ""
echo -e "${YELLOW}⚠️ IMPORTANTE:${NC}"
echo -e "${YELLOW}• Descargar el paquete a ubicación segura antes de su eliminación${NC}"
echo -e "${YELLOW}• No exfiltrar sin autorización${NC}"
echo -e "${YELLOW}• Preservar evidencia según políticas de respuesta a incidentes${NC}"
echo ""
echo -e "${BLUE}🔍 Para análisis forense detallado, usar el script orbix_analysis.sh${NC}"
echo ""

# Mostrar estadísticas finales
echo -e "${CYAN}📈 ESTADÍSTICAS:${NC}"
echo -e "  • Archivos analizados: $(find "$WORKDIR" -type f | wc -l)"
echo -e "  • Logs recopilados: $(find "$WORKDIR/logs" -type f | wc -l)"
echo -e "  • Scans realizados: $(find "$WORKDIR/scans" -type f | wc -l)"
echo -e "  • Tamaño total: $(du -sh "$WORKDIR" | cut -f1)"
echo ""

log "Auditoría Orbix Sentinel completada exitosamente"

exit 0