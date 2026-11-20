param(
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

Write-Host "==> ServiceTrack: Iniciando build e verificações locais..." -ForegroundColor Cyan

if ($Clean) {
    Write-Host "==> Limpando artefatos anteriores..." -ForegroundColor Yellow
    flutter clean
}

Write-Host "==> Resolvendo dependencias..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha ao resolver dependencias do Flutter."
    exit 1
}

Write-Host "==> Executando analise estatica estrita..." -ForegroundColor Cyan
flutter analyze --fatal-infos
if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha na analise estatica."
    exit 1
}

Write-Host "==> Executando suite de testes..." -ForegroundColor Cyan
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha na suite de testes."
    exit 1
}

Write-Host "==> Sucesso! Build, linters e testes 100% verdes." -ForegroundColor Green
exit 0
