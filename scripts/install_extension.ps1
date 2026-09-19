# ============================================================================
#   Instalador da Extensão Kaz Language para Lumina IDE & VS Code 🦅
#   Propriedade Intelectual (c) 2026 Armando Soares
# ============================================================================

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectRoot = Split-Path -Parent $scriptDir
$extensionDir = Join-Path $projectRoot "editors\vscode"
$distDir = Join-Path $projectRoot "dist"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   Instalador da Extensão Kaz Language para IDEs 🦅    " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

if (-not (Test-Path $extensionDir)) {
    Write-Host "ERRO: Diretório da extensão não encontrado em: $extensionDir" -ForegroundColor Red
    exit 1
}

$targetDirs = @(
    (Join-Path $env:USERPROFILE ".lumina-editor\extensions\kaz-language"),
    (Join-Path $env:USERPROFILE ".lumina-editor-dev\extensions\kaz-language"),
    (Join-Path $env:USERPROFILE ".vscode\extensions\kaz-language")
)

$installedCount = 0

foreach ($target in $targetDirs) {
    $parentDir = Split-Path -Parent $target
    if (Test-Path $parentDir) {
        Write-Host "`nInstalando em: $target ..." -ForegroundColor Yellow
        if (-not (Test-Path $target)) {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
        }

        # Copia arquivos essenciais da extensão
        Copy-Item -Path (Join-Path $extensionDir "package.json") -Destination $target -Force
        Copy-Item -Path (Join-Path $extensionDir "language-configuration.json") -Destination $target -Force
        Copy-Item -Path (Join-Path $extensionDir "README.md") -Destination $target -Force
        if (Test-Path (Join-Path $extensionDir "icon.png")) {
            Copy-Item -Path (Join-Path $extensionDir "icon.png") -Destination $target -Force
        }

        # Copia syntaxes
        $syntaxTarget = Join-Path $target "syntaxes"
        if (-not (Test-Path $syntaxTarget)) { New-Item -ItemType Directory -Path $syntaxTarget -Force | Out-Null }
        Copy-Item -Path (Join-Path $extensionDir "syntaxes\*") -Destination $syntaxTarget -Recurse -Force

        # Copia snippets
        $snippetTarget = Join-Path $target "snippets"
        if (-not (Test-Path $snippetTarget)) { New-Item -ItemType Directory -Path $snippetTarget -Force | Out-Null }
        Copy-Item -Path (Join-Path $extensionDir "snippets\*") -Destination $snippetTarget -Recurse -Force

        Write-Host "OK: Extensão Kaz instalada com sucesso!" -ForegroundColor Green
        $installedCount++
    }
}

# Garante o empacotamento do VSIX na pasta dist
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
}
$vsixSource = Join-Path $extensionDir "kaz-language-1.0.0.vsix"
if (Test-Path $vsixSource) {
    Copy-Item -Path $vsixSource -Destination (Join-Path $distDir "kaz-language-1.0.0.vsix") -Force
    Write-Host "`nPacote VSIX copiado para: $distDir\kaz-language-1.0.0.vsix" -ForegroundColor Cyan
}

Write-Host "`n========================================================" -ForegroundColor Green
Write-Host "  Instalação Concluída com Sucesso! ($installedCount IDEs atualizadas)  " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Para ativar a coloração sintática:" -ForegroundColor White
Write-Host "  1. Reinicie ou recarregue a Lumina IDE (Ctrl+Shift+P -> 'Developer: Reload Window')" -ForegroundColor White
Write-Host "  2. Ao abrir qualquer arquivo .kaz, o código agora estará totalmente colorido!" -ForegroundColor White
Write-Host "========================================================`n" -ForegroundColor Green
