# Instalador Oficial da Linguagem Kaz para Windows

$ErrorActionPreference = "Stop"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "     Instalador Oficial da Linguagem Kaz                " -ForegroundColor Cyan
Write-Host "                 Versao 1.1.0                           " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Localizar o executavel pre-compilado
$scriptDir = $PSScriptRoot
if (-not $scriptDir -and $MyInvocation.MyCommand.Path) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }

$kazExe = $null

$candidates = @(
    (Join-Path $scriptDir "bin\kaz.exe"),
    (Join-Path $scriptDir "kaz.exe"),
    (Join-Path $scriptDir "target\release\kaz.exe"),
    (Join-Path $scriptDir "target\debug\kaz.exe")
)

foreach ($c in $candidates) {
    if (Test-Path $c) {
        $kazExe = $c
        break
    }
}

# Se nao encontrou binario pre-compilado e existe Cargo.toml (ambiente de desenvolvimento), compila
if (-not $kazExe) {
    $cargoToml = Join-Path $scriptDir "Cargo.toml"
    if (Test-Path $cargoToml) {
        Write-Host "Ambiente de desenvolvimento detectado. Compilando via cargo..." -ForegroundColor Yellow
        if (Get-Command cargo -ErrorAction SilentlyContinue) {
            Push-Location $scriptDir
            cargo build --release
            Pop-Location
            $releaseExe = Join-Path $scriptDir "target\release\kaz.exe"
            if (Test-Path $releaseExe) {
                $kazExe = $releaseExe
            }
        }
    }
}

if (-not $kazExe -or -not (Test-Path $kazExe)) {
    Write-Host "ERRO: O executavel 'bin\kaz.exe' nao foi encontrado nesta pasta." -ForegroundColor Red
    Write-Host "Certifique-se de extrair todos os arquivos do pacote oficial da linguagem Kaz." -ForegroundColor Yellow
    exit 1
}

# 2. Definir diretorio de instalacao
$targetDir = Join-Path $env:LOCALAPPDATA "Kaz\bin"
Write-Host "Instalando em: $targetDir ..." -ForegroundColor White

if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

# 3. Copiar executavel
$installedExe = Join-Path $targetDir "kaz.exe"
Copy-Item $kazExe $installedExe -Force
Write-Host "OK: Executavel copiado para: $installedExe" -ForegroundColor Green

# 4. Configurar PATH do Usuario de forma permanente
$userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
if (-not $userPath) { $userPath = "" }

$paths = $userPath.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
if ($paths -notcontains $targetDir) {
    Write-Host "Adicionando $targetDir ao PATH do Usuario..." -ForegroundColor White
    $newPath = ($paths + $targetDir) -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)
    Write-Host "OK: PATH atualizado permanentemente no Registro do Windows." -ForegroundColor Green
} else {
    Write-Host "OK: Diretorio ja esta presente no PATH do Usuario." -ForegroundColor Green
}

# Atualiza a sessao atual do terminal
$env:Path = "$env:Path;$targetDir"

# 5. Testar execucao
Write-Host ""
Write-Host "Testando instalacao..." -ForegroundColor White
try {
    $versionOutput = & $installedExe --version
    Write-Host "OK: $versionOutput instalado e verificado com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "Aviso: Falha ao invocar executavel instalado." -ForegroundColor Yellow
}

# 6. Instalar Extensão para Lumina IDE & VS Code
$extInstaller = Join-Path $PSScriptRoot "scripts\install_extension.ps1"
if (Test-Path $extInstaller) {
    try {
        & powershell -ExecutionPolicy Bypass -File $extInstaller | Out-Null
        Write-Host "OK: Extensão de coloração sintática instalada na Lumina IDE / VS Code!" -ForegroundColor Green
    } catch {
        Write-Host "Aviso: Não foi possível instalar a extensão automaticamente." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  Instalacao concluida com sucesso!" -ForegroundColor Green
Write-Host "  Voce pode abrir qualquer terminal e digitar:" -ForegroundColor White
Write-Host "    kaz --help" -ForegroundColor Yellow
Write-Host "    kaz repl" -ForegroundColor Yellow
Write-Host "    kaz programa.kaz" -ForegroundColor Yellow
Write-Host "  Lumina IDE e VS Code agora suportam coloração sintática Kaz!" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""


