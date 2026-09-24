# ============================================================================
#   Instalador da Extensao Kaz Language para Lumina IDE & VS Code
#   Propriedade Intelectual (c) 2026 Armando Soares
# ============================================================================

$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
if (-not $scriptDir -and $MyInvocation.MyCommand.Path) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }

$projectRoot = Split-Path -Parent $scriptDir
$extensionDir = Join-Path $projectRoot "editors\vscode"

if (-not (Test-Path $extensionDir)) {
    Write-Host "AVISO: Diretorio da extensao nao encontrado em: $extensionDir" -ForegroundColor Yellow
    exit 0
}

$targetDirs = @(
    (Join-Path $env:USERPROFILE ".lumina-editor\extensions\kaz-language"),
    (Join-Path $env:USERPROFILE ".lumina-editor-dev\extensions\kaz-language"),
    (Join-Path $env:USERPROFILE ".vscode\extensions\kaz-language"),
    (Join-Path $env:USERPROFILE ".vscode-insiders\extensions\kaz-language")
)

$installedCount = 0

foreach ($target in $targetDirs) {
    $parentDir = Split-Path -Parent $target
    $editorRoot = Split-Path -Parent $parentDir
    # Instala se o diretorio base do editor existir
    if (Test-Path $editorRoot) {
        Write-Host "Instalando extensao em: $target ..." -ForegroundColor Yellow
        if (-not (Test-Path $target)) {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
        }

        # Copia arquivos essenciais da extensao
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

        Write-Host "OK: Extensao Kaz instalada em: $target" -ForegroundColor Green
        $installedCount++
    }
}

if ($installedCount -gt 0) {
    Write-Host "OK: Extensao Kaz configurada com sucesso em $installedCount IDE(s)!" -ForegroundColor Green
} else {
    Write-Host "Aviso: Nenhuma pasta de IDE (.vscode, .lumina-editor) foi encontrada em $env:USERPROFILE." -ForegroundColor Gray
}
