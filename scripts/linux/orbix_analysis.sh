#!/usr/bin/env bash
# ===================================================================
# Orbix Analysis - Forensic Package Analysis Script
# Sistemas Orbix - Security Package Analyzer
# ===================================================================
# 
# OBJETIVO: Analizar paquetes forenses generados por Orbix Sentinel
# ENTRADA: /tmp/orbix-sentinel-*.tar.gz
# SALIDA: Reportes estructurados y hallazgos priorizados
#
# Uso: ./orbix_analysis.sh [--package /path/to/package.tar.gz]
# ===================================================================

set +e  # No salir en errores para continuar análisis

# ===================================================================
# CONFIGURACIÓN Y VARIABLES
# ===================================================================

TS=$(date +"%Y%m%d-%H%M%S")
OUTDIR="/tmp/orbix-analysis-${TS}"
PACKAGE_PATH=""
AUTO_FIND=true

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# ===================================================================
# FUNCIONES AUXILIARES
# ===================================================================

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

critical() {
    echo -e "${RED}[CRITICAL] $1${NC}"
}

# ===================================================================
# PROCESAMIENTO DE ARGUMENTOS
# ===================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --package)
            PACKAGE_PATH="$2"
            AUTO_FIND=false
            shift 2
            ;;
        -h|--help)
            echo "Orbix Analysis - Forensic Package Analyzer"
            echo "Uso: $0 [--package /path/to/package.tar.gz]"
            echo "  --package: Especificar paquete específico a analizar"
            exit 0
            ;;
        *)
            error "Argumento desconocido: $1"
            exit 1
            ;;
    esac
done

# ===================================================================
# BANNER
# ===================================================================

echo -e "${PURPLE}"
echo "═══════════════════════════════════════════════════════════════"
echo "🔍 ORBIX ANALYSIS - FORENSIC PACKAGE ANALYZER"
echo "═══════════════════════════════════════════════════════════════"
echo -e "${NC}"

# ===================================================================
# 1) DETECTAR PAQUETE MÁS RECIENTE
# ===================================================================

if [ "$AUTO_FIND" = true ]; then
    log "Detectando paquete más reciente..."
    LATEST_TAR=$(ls -1t /tmp/orbix-sentinel-*.tar.gz 2>/dev/null | head -n1)
    
    if [ -z "$LATEST_TAR" ]; then
        error "No se encontró ningún paquete /tmp/orbix-sentinel-*.tar.gz"
        echo "Ejecute primero el script orbix_audit.sh para generar un paquete"
        exit 1
    fi
    
    PACKAGE_PATH="$LATEST_TAR"
fi

log "Usando paquete: $PACKAGE_PATH"

if [ ! -f "$PACKAGE_PATH" ]; then
    error "Paquete no encontrado: $PACKAGE_PATH"
    exit 1
fi

# ===================================================================
# 2) CREAR DIRECTORIO DE ANÁLISIS
# ===================================================================

log "Creando directorio de análisis: $OUTDIR"
mkdir -p "$OUTDIR"
if [ $? -ne 0 ]; then
    error "No se pudo crear directorio: $OUTDIR"
    exit 1
fi

# ===================================================================
# 3) EXTRAER PAQUETE
# ===================================================================

log "Extrayendo paquete forense..."
tar -xzf "$PACKAGE_PATH" -C "$OUTDIR" --no-same-owner

if [ $? -ne 0 ]; then
    error "Error extrayendo paquete"
    exit 1
fi

# Encontrar directorio extraído
EXTRACTED_DIR=$(find "$OUTDIR" -maxdepth 1 -type d -name "orbix-sentinel-*" | head -n1)
if [ -z "$EXTRACTED_DIR" ]; then
    error "No se encontró directorio extraído"
    exit 1
fi

log "Paquete extraído en: $EXTRACTED_DIR"

# ===================================================================
# 4) GENERAR ÁRBOL DE CONTENIDO
# ===================================================================

log "Generando árbol de contenido..."
find "$EXTRACTED_DIR" -maxdepth 4 -type f -printf '%TY-%Tm-%Td %TH:%TM %p\n' | \
    sort -r > "$OUTDIR/tree.txt"

info "Archivos encontrados: $(wc -l < "$OUTDIR/tree.txt")"

# ===================================================================
# 5) BUSCAR PATRONES SOSPECHOSOS
# ===================================================================

log "Analizando patrones sospechosos..."

# Consolidar todos los archivos de patrones sospechosos
find "$EXTRACTED_DIR" -name "*suspicious*" -o -name "*pattern*" | while read -r file; do
    if [ -f "$file" ]; then
        cat "$file" >> "$OUTDIR/all_suspicious_patterns.txt" 2>/dev/null
    fi
done

# Buscar patrones adicionales en logs
grep -RIn --exclude-dir=node_modules --exclude-dir=vendor \
    -E "eval\\(|base64_decode\\(|shell_exec\\(|exec\\(|passthru\\(|wget\\s+http|curl\\s+http|openssl\\s+req|/bin/bash -c|nc\\s+-e|bash -i" \
    "$EXTRACTED_DIR" > "$OUTDIR/suspicious_patterns.txt" 2>/dev/null || true

log "Patrones sospechosos encontrados: $(wc -l < "$OUTDIR/suspicious_patterns.txt" 2>/dev/null || echo "0")"

# ===================================================================
# 6) CONTEO Y PRIORIZACIÓN
# ===================================================================

log "Generando conteo de hits por archivo..."

if [ -f "$OUTDIR/suspicious_patterns.txt" ]; then
    awk -F: '{print $1}' "$OUTDIR/suspicious_patterns.txt" | \
        sort | uniq -c | sort -rn | head -n 50 > "$OUTDIR/suspicious_counts.txt"
fi

# ===================================================================
# 7) ANÁLISIS DE IPs Y CONEXIONES
# ===================================================================

log "Analizando IPs y conexiones..."

# Extraer IPs de logs de auth y nginx
find "$EXTRACTED_DIR" -name "*auth*" -o -name "*nginx*access*" | while read -r logfile; do
    if [ -f "$logfile" ]; then
        grep -hEo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$logfile" 2>/dev/null
    fi
done | sort | uniq -c | sort -rn | head -n 50 > "$OUTDIR/top_ips.txt" 2>/dev/null || true

# Geolocalización básica de top IPs
if [ -f "$OUTDIR/top_ips.txt" ] && command -v whois >/dev/null 2>&1; then
    info "Geolocalizando top IPs..."
    head -n 10 "$OUTDIR/top_ips.txt" | while read -r count ip; do
        if [ -n "$ip" ] && [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "=== IP: $ip (Count: $count) ===" >> "$OUTDIR/ip_geolocation.txt"
            whois "$ip" | grep -iE "country|netname|orgname" | head -n 5 >> "$OUTDIR/ip_geolocation.txt" 2>/dev/null || true
            echo "" >> "$OUTDIR/ip_geolocation.txt"
        fi
    done
fi

# ===================================================================
# 8) SCAN ANTIVIRUS (SI DISPONIBLE)
# ===================================================================

if command -v clamscan >/dev/null 2>&1; then
    log "Ejecutando scan antivirus..."
    clamscan -r --infected "$EXTRACTED_DIR" > "$OUTDIR/clamscan.txt" 2>&1 || true
else
    echo "clamscan no disponible; saltando" > "$OUTDIR/clamscan.txt"
fi

# ===================================================================
# 9) EXTRAER ARCHIVOS SOSPECHOSOS
# ===================================================================

log "Recopilando archivos sospechosos..."

mkdir -p "$OUTDIR/suspect_files"

if [ -f "$OUTDIR/suspicious_patterns.txt" ]; then
    awk -F: '{print $1}' "$OUTDIR/suspicious_patterns.txt" | sort -u | while read -r filepath; do
        if [ -f "$filepath" ]; then
            # Crear estructura de directorios relativa
            rel_path=$(echo "$filepath" | sed "s|$EXTRACTED_DIR||" | sed 's|^/||')
            target_dir="$OUTDIR/suspect_files/$(dirname "$rel_path")"
            mkdir -p "$target_dir"
            
            # Copiar archivo
            cp "$filepath" "$target_dir/" 2>/dev/null || true
            
            # Generar hash
            sha256sum "$filepath" >> "$OUTDIR/suspect_files.sha256" 2>/dev/null || true
        fi
    done
fi

# ===================================================================
# 10) ANÁLISIS DE BINARIOS
# ===================================================================

log "Analizando binarios sospechosos..."

mkdir -p "$OUTDIR/bin_strings"

find "$EXTRACTED_DIR" -type f -perm /111 -exec file {} \; 2>/dev/null | \
    grep -iE "elf|executable|script" | awk -F: '{print $1}' | while read -r binary; do
    if [ -f "$binary" ]; then
        basename_bin=$(basename "$binary")
        strings "$binary" 2>/dev/null | \
            grep -iE "base64|bash -c|/bin/sh|curl http|wget http|nc -e|/dev/tcp" | \
            head -n 200 > "$OUTDIR/bin_strings/${basename_bin}.txt" 2>/dev/null || true
    fi
done

# ===================================================================
# 11) CONSOLIDAR RESULTADOS DE SEGURIDAD
# ===================================================================

log "Consolidando resultados de herramientas de seguridad..."

# Buscar resultados de rkhunter/chkrootkit/clamscan en el paquete
find "$EXTRACTED_DIR" -name "rkhunter*" -o -name "chkrootkit*" -o -name "clamav*" | while read -r secfile; do
    if [ -f "$secfile" ]; then
        basename_sec=$(basename "$secfile")
        cp "$secfile" "$OUTDIR/security_${basename_sec}" 2>/dev/null || true
    fi
done

# ===================================================================
# 12) GENERAR FINDINGS.JSON
# ===================================================================

log "Generando findings.json estructurado..."

python3 -c "
import os
import json
import re
import sys

findings = []
finding_id = 1

# Procesar patrones sospechosos
suspicious_file = '$OUTDIR/suspicious_patterns.txt'
if os.path.exists(suspicious_file):
    with open(suspicious_file, 'r', errors='ignore') as f:
        for line_num, line in enumerate(f, 1):
            if ':' in line:
                parts = line.strip().split(':', 2)
                if len(parts) >= 2:
                    path = parts[0]
                    evidence = line.strip()
                    
                    # Determinar severidad basada en patrones
                    severity = 'P1'  # Default
                    if any(pattern in evidence.lower() for pattern in ['shell_exec', 'exec(', 'eval(']):
                        severity = 'P0'
                    elif any(pattern in evidence.lower() for pattern in ['base64_decode', 'wget', 'curl']):
                        severity = 'P1'
                    else:
                        severity = 'P2'
                    
                    # Determinar tipo
                    file_type = 'unknown'
                    if path.endswith('.php'):
                        file_type = 'webshell'
                    elif 'log' in path.lower():
                        file_type = 'log_entry'
                    elif any(ext in path.lower() for ext in ['.sh', '.py', '.pl']):
                        file_type = 'script'
                    
                    findings.append({
                        'id': finding_id,
                        'path': path,
                        'type': file_type,
                        'severity': severity,
                        'evidence': evidence[:200] + '...' if len(evidence) > 200 else evidence,
                        'recommended_action': 'Investigate and remove if malicious'
                    })
                    finding_id += 1
                    
                    if finding_id > 1000:  # Limitar para evitar archivos enormes
                        break

# Procesar resultados de seguridad
security_files = ['$OUTDIR/clamscan.txt', '$OUTDIR/security_rkhunter.log', '$OUTDIR/security_chkrootkit.log']
for sec_file in security_files:
    if os.path.exists(sec_file):
        with open(sec_file, 'r', errors='ignore') as f:
            content = f.read()
            if 'FOUND' in content or 'INFECTED' in content or 'WARNING' in content:
                findings.append({
                    'id': finding_id,
                    'path': sec_file,
                    'type': 'security_scan',
                    'severity': 'P0',
                    'evidence': 'Security tool detected threats',
                    'recommended_action': 'Immediate investigation required'
                })
                finding_id += 1

# Generar JSON
result = {
    'analysis_timestamp': '$(date -u -Iseconds)',
    'source_package': '$PACKAGE_PATH',
    'total_findings': len(findings),
    'findings': findings
}

with open('$OUTDIR/findings.json', 'w') as f:
    json.dump(result, f, indent=2, ensure_ascii=False)

print(f'Generated {len(findings)} findings')
" 2>/dev/null || echo "Error generando findings.json"

# ===================================================================
# 13) GENERAR SUMMARY.MD
# ===================================================================

log "Generando resumen ejecutivo..."

cat > "$OUTDIR/summary.md" << EOF
# Orbix Analysis Summary

**Generado:** $(date -u)  
**Paquete fuente:** $PACKAGE_PATH  
**Directorio de análisis:** $OUTDIR

## Resumen Ejecutivo

### Estado de Compromiso
$(if [ -s "$OUTDIR/suspicious_patterns.txt" ]; then echo "🔴 **PROBABLE** - Se detectaron patrones sospechosos"; else echo "🟡 **INDETERMINADO** - Análisis requiere revisión manual"; fi)

### Estadísticas de Análisis
- **Archivos analizados:** $(find "$EXTRACTED_DIR" -type f | wc -l)
- **Patrones sospechosos:** $(wc -l < "$OUTDIR/suspicious_patterns.txt" 2>/dev/null || echo "0")
- **IPs únicas detectadas:** $(wc -l < "$OUTDIR/top_ips.txt" 2>/dev/null || echo "0")
- **Archivos sospechosos recopilados:** $(find "$OUTDIR/suspect_files" -type f 2>/dev/null | wc -l)

## Hallazgos Críticos (P0)

### Top Archivos con Patrones Sospechosos
\`\`\`
$(head -n 20 "$OUTDIR/suspicious_counts.txt" 2>/dev/null || echo "Sin patrones detectados")
\`\`\`

### Top IPs en Logs de Acceso
\`\`\`
$(head -n 15 "$OUTDIR/top_ips.txt" 2>/dev/null || echo "Sin IPs detectadas")
\`\`\`

### Resultados de Antivirus
\`\`\`
$(grep -E "FOUND|INFECTED" "$OUTDIR/clamscan.txt" 2>/dev/null | head -n 10 || echo "Sin detecciones de malware")
\`\`\`

## Acciones Inmediatas Recomendadas

$(if [ -s "$OUTDIR/suspicious_patterns.txt" ]; then
cat << 'IMMEDIATE'
### 🚨 RESPUESTA INMEDIATA
1. **AISLAR** el sistema de la red inmediatamente
2. **PRESERVAR** evidencia - no modificar archivos del sistema
3. **SNAPSHOT** del sistema antes de cualquier cambio
4. **ROTAR** todas las credenciales de acceso (SSH, bases de datos, APIs)
5. **REVISAR** archivos en \`$OUTDIR/suspect_files/\`

### 🔍 INVESTIGACIÓN FORENSE
1. Analizar archivos sospechosos identificados
2. Verificar integridad de binarios del sistema
3. Revisar logs de acceso para actividad maliciosa
4. Examinar procesos y conexiones de red activas
IMMEDIATE
else
cat << 'ROUTINE'
### ✅ ACCIONES DE RUTINA
1. **VERIFICAR** configuración de seguridad
2. **ACTUALIZAR** sistema y aplicaciones
3. **ROTAR** credenciales como medida preventiva
4. **MONITOREAR** logs de acceso continuamente
ROUTINE
fi)

## Archivos para Descarga y Análisis Detallado

### Evidencia Crítica
- \`$OUTDIR/findings.json\` - Hallazgos estructurados machine-readable
- \`$OUTDIR/critical_findings.txt\` - Lista de archivos críticos
- \`$OUTDIR/suspect_files/\` - Directorio con archivos sospechosos
- \`$OUTDIR/suspect_files.sha256\` - Hashes de archivos sospechosos

### Logs de Análisis
- \`$OUTDIR/suspicious_patterns.txt\` - Patrones detectados
- \`$OUTDIR/ip_geolocation.txt\` - Información de IPs sospechosas
- \`$OUTDIR/clamscan.txt\` - Resultados antivirus

### Datos de Inventario
- \`$OUTDIR/tree.txt\` - Árbol de archivos analizados
- \`$OUTDIR/bin_strings/\` - Análisis de binarios

## Recomendaciones de Seguimiento

1. **Preservar** este directorio: \`$OUTDIR\`
2. **Descargar** paquete completo para análisis offline
3. **Revisar** manualmente archivos en suspect_files/
4. **Consultar** especialista en seguridad si hay indicadores P0
5. **Implementar** monitoreo continuo post-incidente

---
*Generado por Orbix Analysis v1.0 - Sistemas Orbix*
EOF

# ===================================================================
# 14) GENERAR CRITICAL_FINDINGS.TXT
# ===================================================================

log "Generando lista de hallazgos críticos..."

cat > "$OUTDIR/critical_findings.txt" << EOF
ORBIX ANALYSIS - HALLAZGOS CRÍTICOS
═══════════════════════════════════
Generado: $(date -u)
Paquete: $PACKAGE_PATH

ARCHIVOS CON PATRONES SOSPECHOSOS:
$(head -n 100 "$OUTDIR/suspicious_patterns.txt" 2>/dev/null | while read -r line; do
    echo "PATTERN: $line"
done)

TOP IPS SOSPECHOSAS:
$(head -n 20 "$OUTDIR/top_ips.txt" 2>/dev/null | while read -r line; do
    echo "IP_ACTIVITY: $line"
done)

RESULTADOS ANTIVIRUS:
$(grep -E "FOUND|INFECTED|WARNING" "$OUTDIR/clamscan.txt" 2>/dev/null | while read -r line; do
    echo "MALWARE: $line"
done)

ARCHIVOS RECOPILADOS PARA ANÁLISIS:
$(find "$OUTDIR/suspect_files" -type f 2>/dev/null | while read -r file; do
    echo "SUSPECT_FILE: $file"
done)

BINARIOS CON STRINGS SOSPECHOSOS:
$(find "$OUTDIR/bin_strings" -name "*.txt" -size +0c 2>/dev/null | while read -r stringfile; do
    echo "SUSPICIOUS_BINARY: $(basename "$stringfile" .txt)"
done)
EOF

# ===================================================================
# 15) GENERAR ISSUES.MD (TICKETS PRIORIZADOS)
# ===================================================================

log "Generando tickets priorizados..."

cat > "$OUTDIR/issues.md" << EOF
# Security Issues - Orbix Analysis

*Generado automáticamente desde análisis forense*

$(if [ -s "$OUTDIR/suspicious_patterns.txt" ]; then
    echo "## 🔴 P0 - CRÍTICO (Acción Inmediata)"
    echo ""
    echo "### [P0-001] Posible Compromiso de Sistema Detectado"
    echo "**Prioridad:** P0 - Crítica"
    echo "**Descripción:** Se detectaron patrones sospechosos que indican posible compromiso"
    echo "**Evidencia:** $(wc -l < "$OUTDIR/suspicious_patterns.txt") archivos con patrones maliciosos"
    echo "**Acción:** Aislar sistema, preservar evidencia, análisis forense inmediato"
    echo "**Archivos:** \`$OUTDIR/suspect_files/\`"
    echo ""
fi)

$(if [ -f "$OUTDIR/top_ips.txt" ] && [ -s "$OUTDIR/top_ips.txt" ]; then
    echo "### [P0-002] Actividad de Red Sospechosa"
    echo "**Prioridad:** P0 - Crítica"
    echo "**Descripción:** Conexiones desde IPs potencialmente maliciosas"
    echo "**Evidencia:** $(head -n 5 "$OUTDIR/top_ips.txt" | while read count ip; do echo "- $ip ($count conexiones)"; done)"
    echo "**Acción:** Bloquear IPs, revisar firewall, analizar tráfico"
    echo ""
fi)

## 🟡 P1 - ALTO (Resolución en 24h)

### [P1-001] Auditoría de Archivos Web Modificados
**Prioridad:** P1 - Alta  
**Descripción:** Revisar archivos web modificados recientemente  
**Acción:** Verificar integridad y legitimidad de cambios  
**Timeline:** 24 horas  

### [P1-002] Rotación de Credenciales
**Prioridad:** P1 - Alta  
**Descripción:** Rotar todas las credenciales como medida preventiva  
**Acción:** SSH keys, database passwords, API tokens  
**Timeline:** 24 horas  

## 🔵 P2 - MEDIO (Resolución en 72h)

### [P2-001] Actualización de Sistema
**Prioridad:** P2 - Media  
**Descripción:** Verificar y aplicar actualizaciones de seguridad  
**Acción:** apt update && apt upgrade, verificar CVEs  
**Timeline:** 72 horas  

### [P2-002] Hardening de Configuración
**Prioridad:** P2 - Media  
**Descripción:** Revisar configuración de seguridad del sistema  
**Acción:** SSH config, firewall rules, service permissions  
**Timeline:** 72 horas  

### [P2-003] Implementar Monitoreo Continuo
**Prioridad:** P2 - Media  
**Descripción:** Establecer monitoreo proactivo de seguridad  
**Acción:** OSSEC/HIDS, file integrity monitoring, log analysis  
**Timeline:** 1 semana  

---

## Checklist de Respuesta

- [ ] Sistema aislado de red (si P0)
- [ ] Snapshot/imagen del sistema creada
- [ ] Credenciales SSH rotadas
- [ ] Credenciales de DB rotadas
- [ ] API tokens rotados
- [ ] Archivos sospechosos analizados
- [ ] IPs maliciosas bloqueadas
- [ ] Logs preservados y respaldados
- [ ] Equipo de seguridad notificado
- [ ] Plan de recuperación preparado

## Contactos de Escalación

**Sistemas Orbix Security Team**
- Slack: #security-incidents
- Email: security@sistemasorbix.com
- On-call: +1-XXX-XXX-XXXX

EOF

# ===================================================================
# 16) CREAR PAQUETE FINAL
# ===================================================================

log "Creando paquete de análisis..."

cd /tmp
tar -czf "${OUTDIR}.tar.gz" -C "$(dirname "$OUTDIR")" "$(basename "$OUTDIR")" 2>/dev/null

if [ $? -eq 0 ]; then
    log "✅ Paquete de análisis creado: ${OUTDIR}.tar.gz"
    ls -lh "${OUTDIR}.tar.gz"
fi

# ===================================================================
# 17) REPORTE FINAL
# ===================================================================

echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}🎯 ORBIX ANALYSIS - ANÁLISIS COMPLETADO${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Estadísticas finales
TOTAL_FINDINGS=$(wc -l < "$OUTDIR/suspicious_patterns.txt" 2>/dev/null || echo "0")
SUSPECT_FILES=$(find "$OUTDIR/suspect_files" -type f 2>/dev/null | wc -l)
TOP_IPS=$(wc -l < "$OUTDIR/top_ips.txt" 2>/dev/null || echo "0")

echo -e "${GREEN}📊 ESTADÍSTICAS DEL ANÁLISIS:${NC}"
echo -e "  • Patrones sospechosos detectados: ${TOTAL_FINDINGS}"
echo -e "  • Archivos sospechosos recopilados: ${SUSPECT_FILES}"
echo -e "  • IPs únicas en logs: ${TOP_IPS}"
echo -e "  • Directorio de análisis: ${OUTDIR}"
echo ""

echo -e "${CYAN}📁 ARCHIVOS PRINCIPALES:${NC}"
echo -e "  • ${GREEN}summary.md${NC} - Resumen ejecutivo"
echo -e "  • ${GREEN}findings.json${NC} - Hallazgos estructurados"
echo -e "  • ${GREEN}critical_findings.txt${NC} - Lista de críticos"
echo -e "  • ${GREEN}issues.md${NC} - Tickets priorizados"
echo -e "  • ${GREEN}suspect_files/${NC} - Archivos sospechosos"
echo ""

# Determinar nivel de riesgo
if [ "$TOTAL_FINDINGS" -gt 0 ]; then
    echo -e "${RED}🚨 NIVEL DE RIESGO: ALTO${NC}"
    echo -e "${RED}   Compromiso probable detectado - Acción inmediata requerida${NC}"
    echo ""
    echo -e "${YELLOW}🔧 PRÓXIMOS PASOS INMEDIATOS:${NC}"
    echo -e "   1. Revisar: ${OUTDIR}/summary.md"
    echo -e "   2. Analizar: ${OUTDIR}/suspect_files/"
    echo -e "   3. Ejecutar: Plan de respuesta a incidentes"
    echo -e "   4. Preservar: Todo el directorio ${OUTDIR}"
else
    echo -e "${YELLOW}⚠️ NIVEL DE RIESGO: INDETERMINADO${NC}"
    echo -e "${YELLOW}   Sin patrones críticos detectados - Revisión manual recomendada${NC}"
    echo ""
    echo -e "${BLUE}🔍 PRÓXIMOS PASOS:${NC}"
    echo -e "   1. Revisar: ${OUTDIR}/summary.md"
    echo -e "   2. Verificar: Configuración de seguridad"
    echo -e "   3. Implementar: Monitoreo preventivo"
fi

echo ""
echo -e "${PURPLE}📦 Paquete completo: ${OUTDIR}.tar.gz${NC}"
echo -e "${PURPLE}📍 Ubicación: ${OUTDIR}${NC}"
echo ""

log "Análisis forense completado exitosamente"

exit 0