# ═══════════════════════════════════════════════════════════════
# 🔧 ORBIX - Corrector Automático de Rutas Inconsistentes
# Reemplaza automáticamente rutas antiguas por las correctas
# ═══════════════════════════════════════════════════════════════

param(
    [switch]$DryRun = $false,
    [switch]$Force = $false
)

$basePath = "D:\ORBIX"
$correctPath = "tutorium-sistemasorbix"

# Patrones a reemplazar
$replacements = @{
    "tutorium\\" = "tutorium-sistemasorbix\"
    "tutorium/" = "tutorium-sistemasorbix/"
    "/tutorium" = "/tutorium-sistemasorbix"
    "\\tutorium" = "\tutorium-sistemasorbix"
    "D:\ORBIX\tutorium" = "D:\ORBIX\tutorium-sistemasorbix"
}

Write-Host "`n🔧 ORBIX - Corrector de Rutas Inconsistentes" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════" -ForegroundColor Gray

if ($DryRun) {
    Write-Host "🧪 MODO PRUEBA - No se realizarán cambios reales" -ForegroundColor Yellow
} else {
    Write-Host "⚠️ MODO PRODUCCIÓN - Se realizarán cambios reales" -ForegroundColor Red
    if (-not $Force) {
        $confirm = Read-Host "¿Continuar? (y/N)"
        if ($confirm -ne "y" -and $confirm -ne "Y") {
            Write-Host "❌ Operación cancelada" -ForegroundColor Red
            exit
        }
    }
}

# Contador de cambios
$filesChanged = 0
$totalChanges = 0

# Función para procesar archivos
function ProcessFile {
    param(
        [string]$filePath,
        [hashtable]$replacements,
        [bool]$dryRun
    )
    
    try {
        $content = Get-Content -Path $filePath -Raw -ErrorAction Stop
        $fileChanges = 0
        
        # Aplicar reemplazos
        foreach ($pattern in $replacements.Keys) {
            $replacement = $replacements[$pattern]
            
            # Contar ocurrencias antes del reemplazo
            $patternMatches = [regex]::Matches($content, [regex]::Escape($pattern))
            if ($patternMatches.Count -gt 0) {
                $content = $content -replace [regex]::Escape($pattern), $replacement
                $fileChanges += $patternMatches.Count
                
                Write-Host "  📝 Reemplazando '$pattern' → '$replacement' ($($patternMatches.Count) veces)" -ForegroundColor Cyan
            }
        }
        
        # Si hay cambios, guardar o mostrar
        if ($fileChanges -gt 0) {
            Write-Host "📁 $filePath" -ForegroundColor White
            Write-Host "  ✅ $fileChanges cambios encontrados" -ForegroundColor Green
            
            if (-not $dryRun) {
                Set-Content -Path $filePath -Value $content -ErrorAction Stop
                Write-Host "  💾 Archivo actualizado" -ForegroundColor Green
            } else {
                Write-Host "  🧪 Cambios simulados (DryRun)" -ForegroundColor Yellow
            }
            
            return $fileChanges
        }
        
        return 0
        
    } catch {
        Write-Host "❌ Error procesando $filePath`: $($_.Exception.Message)" -ForegroundColor Red
        return 0
    }
}

# Buscar archivos para procesar
Write-Host "`n🔍 Buscando archivos para procesar..." -ForegroundColor Cyan

$fileTypes = @("*.js", "*.sh", "*.py", "*.ps1", "*.json", "*.html", "*.md", "*.txt", "*.css", "*.yml", "*.yaml")

foreach ($fileType in $fileTypes) {
    Write-Host "`n--- Procesando archivos $fileType ---" -ForegroundColor Yellow
    
    $files = Get-ChildItem -Path $basePath -Recurse -Include $fileType -ErrorAction SilentlyContinue
    
    foreach ($file in $files) {
        # Excluir ciertos directorios
        if ($file.FullName -match "node_modules|\.git|\.vscode|bin|obj") {
            continue
        }
        
        $changes = ProcessFile -filePath $file.FullName -replacements $replacements -dryRun $DryRun
        
        if ($changes -gt 0) {
            $filesChanged++
            $totalChanges += $changes
        }
    }
}

# Resumen final
Write-Host "`n📋 RESUMEN DE OPERACIÓN" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host "📁 Archivos procesados: $filesChanged" -ForegroundColor White
Write-Host "🔄 Total de cambios: $totalChanges" -ForegroundColor White

if ($DryRun) {
    Write-Host "🧪 Modo prueba - No se realizaron cambios reales" -ForegroundColor Yellow
    Write-Host "💡 Para aplicar cambios ejecuta: .\corregir-rutas.ps1 -Force" -ForegroundColor Cyan
} else {
    Write-Host "✅ Cambios aplicados exitosamente" -ForegroundColor Green
}

Write-Host "`n🎉 Operación completada!" -ForegroundColor Green
