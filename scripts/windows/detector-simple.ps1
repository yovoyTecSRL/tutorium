# Script detector de rutas inconsistentes
$basePath = "D:\ORBIX"
$searchTerms = @("tutorium\\", "tutorium-sistemasorbix\\", "tutorium/", "tutorium-sistemasorbix/")

Write-Host "Buscando referencias a rutas inconsistentes..." -ForegroundColor Cyan

foreach ($term in $searchTerms) {
    Write-Host "--- Buscando coincidencias para: '$term' ---" -ForegroundColor Yellow
    
    Get-ChildItem -Path $basePath -Recurse -Include *.js,*.sh,*.py,*.ps1,*.json,*.html,*.md,*.txt -ErrorAction SilentlyContinue |
        Select-String -Pattern $term -ErrorAction SilentlyContinue |
        ForEach-Object {
            Write-Host "Archivo: $($_.Path)" -ForegroundColor White
            Write-Host "Linea: $($_.Line.Trim())" -ForegroundColor Gray
            Write-Host ""
        }
}

Write-Host "Escaneo completo." -ForegroundColor Green
