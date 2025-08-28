# ═══════════════════════════════════════════════════════════════
# 🔍 ORBIX - Detección de Rutas Inconsistentes en Tutorium
# Busca archivos y líneas que mencionan rutas incorrectas o duplicadas
# ═══════════════════════════════════════════════════════════════

$basePath = "D:\ORBIX"
$searchTerms = @("tutorium\\", "tutorium-sistemasorbix\\", "tutorium/", "tutorium-sistemasorbix/")

Write-Host "`n🔍 Buscando referencias a rutas inconsistentes..." -ForegroundColor Cyan

foreach ($term in $searchTerms) {
    Write-Host "`n--- Buscando coincidencias para: '$term' ---" -ForegroundColor Yellow
    Get-ChildItem -Path $basePath -Recurse -Include *.js,*.sh,*.py,*.ps1,*.json,*.html,*.md,*.txt |
        Select-String -Pattern $term |
        ForEach-Object {
            Write-Host "🧠 Archivo: $($_.Path)"
            Write-Host "📄 Línea: $($_.Line.Trim())`n"
        }
}

Write-Host "`n✅ Escaneo completo. Revisa las rutas mostradas arriba." -ForegroundColor Green
