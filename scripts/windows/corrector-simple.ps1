# Corrector simple de rutas inconsistentes
param(
    [switch]$DryRun = $false,
    [switch]$Force = $false
)

$basePath = "D:\ORBIX"

Write-Host "ORBIX - Corrector de Rutas Inconsistentes" -ForegroundColor Green

if ($DryRun) {
    Write-Host "MODO PRUEBA - No se realizaran cambios reales" -ForegroundColor Yellow
} else {
    Write-Host "MODO PRODUCCION - Se realizaran cambios reales" -ForegroundColor Red
    if (-not $Force) {
        $confirm = Read-Host "Continuar? (y/N)"
        if ($confirm -ne "y" -and $confirm -ne "Y") {
            Write-Host "Operacion cancelada" -ForegroundColor Red
            exit
        }
    }
}

# Patrones a reemplazar (solo los importantes)
$patterns = @(
    @{ Find = "D:\ORBIX\tutorium-sistemasorbix\"; Replace = "D:\ORBIX\tutorium-sistemasorbix\" },
    @{ Find = "D:\ORBIX\tutorium-sistemasorbix/"; Replace = "D:\ORBIX\tutorium-sistemasorbix/" },
    @{ Find = "D:\ORBIX\tutorium-sistemasorbix\"; Replace = "d:\ORBIX\tutorium-sistemasorbix\" },
    @{ Find = "D:\ORBIX\tutorium-sistemasorbix/"; Replace = "d:\ORBIX\tutorium-sistemasorbix/" }
)

$filesChanged = 0
$totalChanges = 0

# Buscar archivos
$files = Get-ChildItem -Path $basePath -Recurse -Include *.ps1,*.sh,*.md,*.txt,*.html,*.js,*.json -ErrorAction SilentlyContinue

foreach ($file in $files) {
    # Excluir ciertos directorios y archivos
    if ($file.FullName -match "node_modules|\.git|\.vscode|bin|obj|detector-simple|corregir-rutas") {
        continue
    }
    
    try {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        $originalContent = $content
        $fileChanges = 0
        
        # Aplicar cada patrón
        foreach ($pattern in $patterns) {
            if ($content -match [regex]::Escape($pattern.Find)) {
                $content = $content -replace [regex]::Escape($pattern.Find), $pattern.Replace
                $fileChanges++
            }
        }
        
        # Si hay cambios
        if ($fileChanges -gt 0) {
            Write-Host "Archivo: $($file.FullName)" -ForegroundColor White
            Write-Host "  Cambios: $fileChanges" -ForegroundColor Green
            
            if (-not $DryRun) {
                Set-Content -Path $file.FullName -Value $content -ErrorAction Stop
                Write-Host "  Actualizado" -ForegroundColor Green
            } else {
                Write-Host "  Simulado (DryRun)" -ForegroundColor Yellow
            }
            
            $filesChanged++
            $totalChanges += $fileChanges
        }
        
    } catch {
        Write-Host "Error procesando $($file.FullName): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Resumen
Write-Host "`nRESUMEN:" -ForegroundColor Cyan
Write-Host "Archivos procesados: $filesChanged" -ForegroundColor White
Write-Host "Total de cambios: $totalChanges" -ForegroundColor White

if ($DryRun) {
    Write-Host "Modo prueba - No se realizaron cambios reales" -ForegroundColor Yellow
    Write-Host "Para aplicar cambios ejecuta: .\corrector-simple.ps1 -Force" -ForegroundColor Cyan
} else {
    Write-Host "Cambios aplicados exitosamente" -ForegroundColor Green
}

Write-Host "`nOperacion completada!" -ForegroundColor Green

