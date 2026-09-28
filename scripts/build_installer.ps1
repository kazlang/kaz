# ==============================================================================
# Kaz - Script de Construção do Instalador Windows (NSIS)
# ==============================================================================

$ErrorActionPreference = "Stop"
$rootDir = (Get-Item $PSScriptRoot).Parent.FullName
Set-Location $rootDir

Write-Host "=== Construindo Kaz Release e Instalador NSIS ===" -ForegroundColor Cyan

# 1. Compilar release se o binário não existir ou for mais antigo
$binPath = Join-Path $rootDir "target\release\kaz.exe"
if (-not (Test-Path $binPath)) {
    Write-Host "[1/3] Compilando kaz.exe em modo release..." -ForegroundColor Yellow
    cargo build --release
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Falha na compilação do kaz.exe!"
    }
} else {
    Write-Host "[1/3] kaz.exe em modo release encontrado." -ForegroundColor Green
}

# 2. Localizar o executável do NSIS (makensis.exe)
Write-Host "[2/3] Localizando NSIS (makensis)..." -ForegroundColor Yellow
$makensis = Get-Command "makensis" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $makensis) {
    $candidates = @(
        "C:\Program Files (x86)\NSIS\makensis.exe",
        "C:\Program Files\NSIS\makensis.exe"
    )
    foreach ($cand in $candidates) {
        if (Test-Path $cand) {
            $makensis = $cand
            break
        }
    }
}

if (-not $makensis) {
    Write-Error "makensis.exe do NSIS não foi encontrado no PATH nem nos diretórios padrão do Program Files!"
}
Write-Host "NSIS encontrado em: $makensis" -ForegroundColor Green

# 3. Garantir diretório dist
$distDir = Join-Path $rootDir "dist"
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
}

# 4. Executar compilação do instalador NSIS
$nsiFile = Join-Path $PSScriptRoot "installer.nsi"
Write-Host "[3/3] Compilando instalador NSIS: $nsiFile..." -ForegroundColor Yellow

& $makensis $nsiFile
if ($LASTEXITCODE -ne 0) {
    Write-Error "Erro ao compilar o instalador NSIS!"
}

$installerExe = Join-Path $distDir "kaz-v1.1.0-windows-x64-setup.exe"
if (Test-Path $installerExe) {
    $sizeMb = [math]::Round((Get-Item $installerExe).Length / 1MB, 2)
    Write-Host "=== Instalador gerado com sucesso! ===" -ForegroundColor Green
    Write-Host "Arquivo: $installerExe ($sizeMb MB)" -ForegroundColor Cyan
} else {
    Write-Warning "Instalador compilado, verifique a pasta dist."
}
